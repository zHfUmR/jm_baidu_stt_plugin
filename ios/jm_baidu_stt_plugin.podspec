#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint jm_baidu_stt_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'jm_baidu_stt_plugin'
  s.version          = '0.0.1'
  s.summary          = 'Baidu speech recognition & wake-up Flutter bindings.'
  s.description      = <<-DESC
最新百度语音识别/唤醒 SDK 的 Flutter 插件封装。
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{h,m,mm}'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.vendored_libraries = 'Libs/BDSClientLib/libBaiduSpeechSDK.a'
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
