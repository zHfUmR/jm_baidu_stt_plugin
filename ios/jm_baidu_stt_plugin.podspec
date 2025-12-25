#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint jm_baidu_stt_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'jm_baidu_stt_plugin'
  s.version          = '0.0.8' # 建议同步升级到你准备发布的版本号
  s.summary          = 'Baidu speech recognition & wake-up Flutter bindings.'
  s.description      = <<-DESC
最新百度语音识别/唤醒 SDK 的 Flutter 插件封装。
                       DESC
  # 建议修改为你的 GitHub 地址
  s.homepage         = 'https://github.com/zHfUmR/jm_baidu_stt_plugin'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{h,m,mm}'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # --- 新增下载脚本开始 ---
  s.prepare_command = <<-CMD
    # 创建存放 SDK 的目录（保持和你现在的目录结构一致）
    mkdir -p Libs/BDSClientLib
    mkdir -p Assets/BDSClientEASRResources

    # 下载静态库（请确保链接是你从 Release 页面复制出来的真实链接）
    echo "Downloading Baidu Speech SDK..."
    curl -L --progress-bar -o Libs/BDSClientLib/libBaiduSpeechSDK.a "https://github.com/zHfUmR/jm_baidu_stt_plugin/releases/download/v0.0.1-bin/libBaiduSpeechSDK.a"

    # 下载资源模型
    echo "Downloading Baidu STT Model Assets..."
    curl -L --progress-bar -o Assets/BDSClientEASRResources/bds_easr_input_model.dat "https://github.com/zHfUmR/jm_baidu_stt_plugin/releases/download/v0.0.1-bin/bds_easr_input_model.dat"
  CMD
  # --- 新增下载脚本结束 ---

  # 引用下载回来的库
  s.vendored_libraries = 'Libs/BDSClientLib/libBaiduSpeechSDK.a'
  
  # 资源引用：
  # CocoaPods 会把 `s.resources` 里匹配到的文件逐个拷贝到产物目录。
  # 之前使用 `Assets/**/*` 会同时匹配到 *.bundle 目录以及 bundle 内的文件，
  # 导致同名 PNG（不同主题 bundle 内）被“扁平化”复制到 framework 根目录，
  # 从而触发 Xcode: Multiple commands produce。
  # 这里改为：直接拷贝各个主题的 *.bundle 目录 + 其它非 bundle 资源。
  s.resources = [
    # 1. 离线模型文件夹（包含 .dat 等，保持目录结构）
    'Assets/BDSClientEASRResources/*.dat',
    # 2. UI 资源 Bundle（不要用 *** 展开，直接引用整个 .bundle）
    'Assets/BDSClientResources/Theme/*.bundle',
    # 3. 提示音等其他必要资源
    'Assets/BDSClientResources/Tone/*',
    # 4. 百度 SDK 原始 Resources 目录下的整个 Bundle
    'Resources/*.bundle'
  ]

  s.frameworks = 'AudioToolbox',
  'AVFoundation',
  'CFNetwork',
  'CoreLocation',
  'CoreTelephony',
  'SystemConfiguration',
  'GLKit'

  s.libraries = 'bz2','c++','iconv','resolv','z','sqlite3.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
end