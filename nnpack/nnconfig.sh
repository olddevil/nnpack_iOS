#!/bin/sh

# 项目地址, 必须配置
project_path=""

# 导出包所必须的plist文件, 可在此处配置默认路径
# 如果不知道plist文件内容，可以先手动打包一次，在导出的ipa包里面获取ExportOptions.plist即可
# 执行shell命令时可通过-p参数来指定plist文件路径, eg: sh nnpack.sh -p ./xxx.plist
plist_path=""

# 蒲公英parameters, 如使用蒲公英分发必须配置
# 获取地址: https://www.pgyer.com/doc/view/api#uploadApp
# 蒲公英key
pgyer_api_key=""

# 钉钉parameters, 如使用钉钉机器人必须配置
# 获取方式: 要发布消息的群-->群设置-->智能群助手-->选择自定义-->(安全设置我选择了自定义关键词: iOS, 因为发送的钉钉消息模版中有iOS关键字)-->从Webhook截取token
# dingding_access_token: 钉钉access_token
dingding_access_token=""

# appstore parameters, 如上传到appstore connect必须配置
# 获取地址: https://appstoreconnect.apple.com/access/api
# 登录后选择Users and Access --> Keys
# 生成API key后需要将其对应私钥下载下来，放到一个固定目录: '~/private_keys'内, 如无此目录需手动创建
appstore_key=""
api_issuer=""



# 默认配置, 可以配置适合自己的默认打包方式, 不可删除字段

# 指定打包的Target, 如不设置则默认与项目同名的target
# 执行shell命令时可通过-t参数来指定target, eg: sh nnpack.sh -t xxxx
target=""

# 指定打包的分支, 如不设置则默认当前项目使用分支
# 执行shell命令时可通过-b参数来指定打包分支, eg: sh nnpack.sh -b dev
pack_branch=""

# 配置打包样式：一般有Release/Debug，也可自定义, 必须有默认值
# 执行shell命令时可通过-c参数来指定build configuration, eg: sh nnpack.sh -c Debug
configuration='Debug'

# 分发渠道(distribution channel): pgyer、apple, 默认pgyer
# 执行shell命令时可通过-d参数来指定打包渠道, eg: sh nnpack.sh -d apple
channel="pgyer"

# 是否保存打包后的文件, true保存, false不保存
# 当执行shell命令有-s参数时会保存打包后的文件, eg: sh nnpack.sh -s
save="false"

# 钉钉默认显示的tips, 没有则不显示
# 执行shell命令时可通过-m参数来指定钉钉消息的tips, eg: sh nnpack.sh -m 这是tips信息
msg=""