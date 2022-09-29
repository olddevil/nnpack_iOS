

## 脚本说明



支持iOS本地自动打包并分发到不同渠道的脚本





## 文件说明

- nnconfig.sh：配置文件，配置脚本执行的必须参数及适合自己的默认配置
- nnpack.sh：执行的脚本文件
- adHocExportOptions.plist：ad-hoc包所需的plist文件
- distributionExportOptions.plist：appstore包所需的plist文件

**tips：打包时指定的plist路径一定要对应想要的分发渠道，脚本附带的plist文件是模版，部分内容需要自己填写，也可手动打包一次，在导出的.ipa文件夹内获取ExportOptions.plist文件**





## 使用前提



- 需安装了jq或者homebrew， jq用于json解析
- 需配置nnconfig.sh中的重要参数，除必须配置的项目路径、打包所需plist文件路径(也可通过-p参数指定)、各种key等，还可配置默认的打包参数





## 使用方式



- 终端cd到nnpack.sh目录

- 执行`sh nnpack.sh`

- 支持的参数

  - -p|--plistpath - 打包后导出ipa所需的配置文件路径, 与平时手动导出ipa包中的ExportOptions.plist一样
  - -b|--branch  - 指定打包分支, 不指定则默认当前分支
  - -t|--target  - 指定打包Target，不指定则使用nnconfig.sh中定义的，如nnconfig.sh中未指定则使用与项目名同名的target
  - -c|--configuration - 指定打包方式: Release、Debug, 也可以自定义build configuration
  - -m|--message - 钉钉消息显示的tips
  - -d|--channel - distribute channel支持: pgyer(蒲公英)、apple(苹果商店)
  - -s|--save - 发布成功后是否保存打包相关数据
  - -h|--help - 展示使用方法"

- 参数都是可选的，如果不指定参数，则默认使用nnconfig.sh中定义的参数（如nnconfig.sh中target参数未配置则使用与项目名同名的target），各参数必须用空格分隔开，注：`-s`后不需要参数

- 举例如下，可根据自己需求排列组合

  - 指定打包的target

    ```
    sh nnpack.sh -t AppTest
    ```

  - 指定分支、钉钉tips

    ```
    sh nnpack.sh -t AppTest -m tips
    ```

  - 指定target、分支、渠道等

    ```
    sh nnpack.sh -t App -b dev -c Release -p xxx/xxx.plist -m 这个是tips信息 -s
    ```







  ​       

  ​        

  ​        

  ​        

  ​        

