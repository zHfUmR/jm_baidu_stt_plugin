#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint jm_baidu_stt_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'jm_baidu_stt_plugin'
  s.version          = '0.0.6' # 建议同步升级到你准备发布的版本号
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
  
  # 资源引用：注意这里要包含你下载的模型文件路径
  s.resources = ['Assets/**/*', 'Resources/**/*']

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