#!/bin/sh

SECONDS=0

source nnconfig.sh

if [[ ! -d $project_path ]]; then
    echo "\033[31m请在nnconfig.sh文件中配置正确项目路径\033[0m"
    exit 1
fi

cd $project_path >> /dev/null 2>&1

project_name=`find . -name *.xcodeproj | awk -F "[/.]" '{print $(NF-1)}'`
if [[ -z $project_name ]]; then
    echo "\033[31m请在nnconfig.sh文件中配置正确项目路径\033[0m"
    exit 1
fi

# common parameters
current_branch=`git rev-parse --symbolic-full-name --abbrev-ref HEAD`
user_name=`id -un`
build_type="project"
if [[ -z $target ]]; then 
    target="${project_name}"
fi

# paths 
now=$(date +"%Y-%m-%d_%H-%M-%S")

desktop_path="/Users/${user_name}/Desktop"
pack_file_path="/Users/${user_name}/Desktop/${project_name}_package"
export_path="${pack_file_path}/${now}"
export_ipa_library_path="${export_path}/ipa"
export_ipa_path="${export_path}/ipa/${project_name}.ipa"
archive_path="${export_path}/archive/${target}.xcarchive"

# appstore logs path
apple_archive_log="${export_path}/log/apple_archive_log.json"
apple_export_log="${export_path}/log/apple_export_log.json"
apple_validate_log="${export_path}/log/apple_validate_log.json"
apple_upload_log="${export_path}/log/apple_upload_log.json"

pgyer_upload_json="${export_path}/log/pgyer_upload.json"

function clean() {
    if [[ -e ${export_path} ]]; then
        rm -rf $export_path
    fi
}

function to_apple() {
    echo "\033[32m正在校验包\033[0m"
    xcrun altool --validate-app -f ${export_ipa_path} -t ios --apiKey ${appstore_key} --apiIssuer ${api_issuer} > $apple_validate_log 2>&1
    validate_res=`grep "No errors validating archive at" $apple_validate_log`
    if [[ -z $validate_res ]]; then
        echo "\033[31m包校验失败, 错误日志路径: $apple_validate_log\033[0m"
        open $apple_validate_log
        exit 1
    else
        echo "\033[32m包校验成功\033[0m"
    fi
    echo "\033[32m正在上传到appstore connect\033[0m"
    xcrun altool --upload-app -f ${export_ipa_path} -t ios --apiKey ${appstore_key} --apiIssuer ${api_issuer} --verbose --output-format xml > $apple_upload_log 2>&1
    upload_res=`grep "No errors uploading" $apple_upload_log`
    if [[ -z $upload_res ]]; then
        echo "\033[31m上传到appstore connect失败, 错误日志路径: $apple_upload_log\033[0m"
        open $apple_upload_log
        exit 1
    else
        echo "\033[32m成功上传到appstore connect\033[0m"
    fi

    if [[ $save == "false" ]]; then
        clean
    fi
}

function to_dingding() {
    if [[ -z $dingding_access_token ]]; then
        echo "\033[31m分发已成功\033[0m"
        echo "\033[31m暂时无法发送到钉钉群\033[0m"
        echo "\033[31m如想使用此功能,请先配置钉钉access_token\033[0m"
        echo "\033[31m获取方式: 要发布消息的群-->群设置-->智能群助手-->选择自定义-->从Webhook截取token\033[0m"
        exit 1
    fi
    echo "\033[32m正在发送到钉钉\033[0m"
    dingding_result=$(curl -H "Content-Type: application/json" -d "{\"msgtype\": \"markdown\", \"markdown\": { \"text\": \"### $1_iOS\n\nTarget: $2\n\n版本信息: $3(build $4)\n\n分支: ${pack_branch}\n\n[下载地址]("https://www.pgyer.com/$5")\n\n$6\n ###### ${msg}\", \"title\": \"#### $1_iOS\"}}" "https://oapi.dingtalk.com/robot/send?access_token=${dingding_access_token}")
}

function to_pgyer() {
    echo "\033[32m正在上传到蒲公英\033[0m"
    token_result=$(curl --form-string "buildType=ipa" --form-string "_api_key=${pgyer_api_key}" "https://www.pgyer.com/apiv2/app/getCOSToken")
    endpoint=`echo ${token_result} | jq -r '.data' | jq -r '.endpoint'`
    key=`echo ${token_result} | jq -r '.data' | jq -r '.key'`
    signature=`echo ${token_result} | jq -r '.data' | jq -r '.params' | jq -r '.signature'`
    x_cos_security_token=`echo ${token_result} | jq -r '.data' | jq -r '.params' | jq -r 'to_entries| .[]| select(.key == "x-cos-security-token")| .value'`

    $(curl --form-string "key=${key}" --form-string "signature=${signature}" --form-string "x-cos-security-token=${x_cos_security_token}" -F "file=@${export_ipa_path}" ${endpoint})

    echo "\033[32m等待发布中\033[0m"
    sleep 20
    upload_result=$(curl --form-string "buildKey=${key}" --form-string "_api_key=${pgyer_api_key}" "https://www.pgyer.com/apiv2/app/buildInfo")
    echo $upload_result>"$pgyer_upload_json"
    parse_result=$(cat "$pgyer_upload_json" | sed s/[[:space:]]//g)

    qrcode=`echo ${parse_result} | jq -r '.data' | jq -r '.buildQRCodeURL'`
    build_name=`echo ${parse_result} | jq -r '.data' | jq -r '.buildName'`
    app_version=`echo ${parse_result} | jq -r '.data' | jq -r '.buildVersion'`
    app_build=`echo ${parse_result} | jq -r '.data' | jq -r '.buildVersionNo'`
    build_version=`echo ${parse_result} | jq -r '.data' | jq -r '.buildBuildVersion'`
    screenshot="![screenshot](${qrcode})"
    short_url=`echo ${parse_result} | jq -r '.data' | jq -r '.buildShortcutUrl'`

    rm -rf "$pgyer_upload_json"

    to_dingding $build_name $target $app_version $app_build $short_url $screenshot
    
    if [[ $save == "false" ]]; then
        clean
    fi
}

function export_ipa() {
    if [[ ! -d $pack_file_path ]]; then
        pushd $desktop_path >> /dev/null 2>&1
        mkdir "${project_name}_package"
        popd >> /dev/null 2>&1
    fi
    pushd $pack_file_path >> /dev/null 2>&1
    mkdir $now
    pushd $export_path >> /dev/null 2>&1
    mkdir "log"
    popd >> /dev/null 2>&1
    popd >> /dev/null 2>&1

    if [[ ! -f $plist_path ]]; then
        echo "\033[31m请在nnconfig.sh文件中配置正确的plist文件路径\033[0m"
        exit 1
    fi

    if [[ $pack_branch != "" ]] && [[ $pack_branch != $current_branch ]]; then 
        diffInfo=`git diff`
        if [[ "$diffInfo" = "" ]]; then
            `eval "git checkout ${pack_branch}"`
        else
            printf "\033[32m当前分支有代码未提交,是否提交[y/n]? \033[0m"
            read -n 1 allow
            echo ""
            if [[ $allow == "y" ]] || [[ $allow == "Y" ]]; then
                printf "\033[32m请输入提交信息:\033[0m"
                read commit_msg
                `eval "git pull"`
                `eval "git add ."`
                `eval "git commit -m ${commit_msg}"`
                `eval "git push"`
                `eval "git checkout ${pack_branch}"`
                echo "\033[32m代码提交完毕\033[0m"
            else 
                echo "\033[31m当前分支有代码未提交,提交后再执行打包脚本\033[0m"
                exit 1
            fi
        fi
    else 
        pack_branch=$current_branch
    fi
    # workspace/xcodeproj, 通过文件类型确定build_type
    if [[ -e "${project_path}/${project_name}.xcworkspace" ]];then
        build_file_path="${project_path}/${project_name}.xcworkspace"
        build_type="workspace"
    else
        build_file_path="${project_path}/${project_name}.xcodeproj"
        build_type="project"
    fi

    echo "\033[32m正在清理工程\033[0m"

    xcodebuild \
    clean -${build_type} ${build_file_path} \
    -scheme ${target} \
    -configuration ${configuration} >> /dev/null 2>&1 -quiet  || exit
    echo "\033[32m清理完成\033[0m"
    echo "\033[32m正在编译工程:${build_file_path}\033[0m"
   
    if [[ -d ${build_file_path} ]];then
        xcodebuild archive -${build_type} ${build_file_path} \
        -scheme ${target} \
        -configuration ${configuration} \
        -archivePath ${archive_path} \
        -destination 'generic/platform=iOS' > "$apple_archive_log" 2>&1 -quiet || exit
    else
        echo "\033[31mworkspace 不存在\033[0m"
    fi

    if [[ -d ${archive_path} ]] ; then
        echo "\033[32m项目编译成功\033[0m"
    else
        echo "\033[31m项目编译失败, 错误日志路径: $apple_archive_log\033[0m"
        open $apple_archive_log
        exit 1
    fi

    echo "\033[32m开始导出ipa包\033[0m"
    xcodebuild -exportArchive -archivePath ${archive_path} \
    -configuration ${configuration} \
    -exportPath ${export_ipa_library_path} \
    -allowProvisioningUpdates YES\
    -exportOptionsPlist ${plist_path} > $apple_export_log 2>&1 \
    -quiet || exit

    if [[ -e ${export_ipa_path} ]]; then
        echo "\033[32mipa包导出成功\033[0m"
        if [[ $channel == "apple" ]]; then
            to_apple
        else
            to_pgyer
        fi
    else
        echo "\033[31mipa包导出失败, 错误日志路径: $apple_export_log\033[0m"
        open $apple_export_log
        exit 1
    fi

    echo "\033[32m发布成功, 执行耗时: ${SECONDS}秒\033[0m"
    echo "🎉🍺🎉🍺🎉🍺🎉🍺🎉🍺🎉🍺"
}

function check_configure() {
    brew_list=`eval "brew list"`
    installed_jq=$(echo "${brew_list[@]}" | grep -wq "jq" &&  echo "true" || echo "false")
    if [[ $installed_jq == "false" ]]; then
        echo "\033[32m正在通过Homebrew安装JSON解析脚本jq\033[0m"
        echo $(eval "brew install jq")
    fi

    if [[ $channel == "apple" ]]; then
        if [[ -z $appstore_key ]]; then
            echo "\033[31m请先配置appstore_key\033[0m"
            echo "\033[31m获取地址: https://appstoreconnect.apple.com/access/api\033[0m"
            $(open 'https://appstoreconnect.apple.com/access/api')
            exit 1
        fi
        if [[ -z $api_issuer ]]; then
            echo "\033[31m请先配置apiIssuer\033[0m"
            echo "\033[31m获取地址: https://appstoreconnect.apple.com/access/api\033[0m"
            $(open 'https://appstoreconnect.apple.com/access/api')
            exit 1
        fi
    else
        if [[ -z $pgyer_api_key ]]; then
            echo "\033[31m请先配置pgyer_api_key\033[0m"
            echo "\033[31m文档地址: https://www.pgyer.com/doc/view/api#uploadApp\033[0m"
            $(open 'https://www.pgyer.com/doc/view/api#uploadApp')
            exit 1
        fi
    fi

    export_ipa
}

function show_usage() {
    echo "package.sh 
        -p|--plistpath - 打包后导出ipa所需的配置文件路径, 与平时手动导出ipa包中的ExportOptions.plist一样
        -b|--branch  - 指定打包分支, 不指定则默认当前分支
        -t|--target  - 指定打包Target
        -c|--configuration - 指定打包方式: Release、Debug, 也可以自定义build configuration
        -m|--message - 钉钉消息显示的tips
        -d|--channel - distribute channel(分发渠道)支持: pgyer、apple
        -s|--save - 发布成功后是否保存打包相关数据
        -h|--help - 展示使用方法"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    -p|--plistpath)
        shift
        plist_path="$1"
        shift
        ;;
    -b|--branch)
        shift
        pack_branch="$1"
        shift
        ;;
    -t|--target)
        shift
        target="$1"
        shift
        ;;
    -c|--configuration)
        shift
        configuration="$1"
        shift
        ;;
    -m|--message)
        shift
        msg="tips: "$1""
        shift
        ;;
    -d|--channel)
        shift
        channel=$1
        shift
        ;;
    -s|--svae)
        save="true"
        shift
        ;;
    -h|--help)
        show_usage
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        exit 1
    esac
done

check_configure

exit 0
