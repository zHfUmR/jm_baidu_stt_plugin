#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint jm_baidu_stt_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'jm_baidu_stt_plugin'
  s.version          = '0.1.0' # 建议同步升级到你准备发布的版本号
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

  # Baidu iOS SDK 体积较大：建议不要把二进制/模型文件长期提交到 Git。
  # 这里用 `prepare_command` 做“缺失则下载”的兜底：
  # - 如果本地已存在 `libBaiduSpeechSDK.a` 和模型文件，则直接使用（离线可用）
  # - 如果缺失，则从你指定的 URL 下载（适合发布到私有/公有仓库，但不带大文件）
  #
  # 你可以通过环境变量指定下载地址：
  # - JM_BAIDU_STT_IOS_LIB_URL   : 直接下载 libBaiduSpeechSDK.a
  # - JM_BAIDU_STT_IOS_MODEL_URL : 直接下载 bds_easr_input_model.dat
  # 或者：
  # - JM_BAIDU_STT_IOS_SDK_ZIP_URL: 下载一个 zip，内部包含上述两个文件（脚本会自动查找）
  #
  # 可选校验：
  # - JM_BAIDU_STT_IOS_LIB_SHA256
  # - JM_BAIDU_STT_IOS_MODEL_SHA256
  # - JM_BAIDU_STT_IOS_SDK_ZIP_SHA256
  #
  # 其他控制：
  # - JM_BAIDU_STT_IOS_SKIP_DOWNLOAD=1  (缺失时直接失败，不尝试下载)
  # - JM_BAIDU_STT_IOS_FORCE_DOWNLOAD=1 (即使存在也重新下载)
  s.prepare_command = <<-CMD
    set -euo pipefail

    LIB_PATH="Libs/BDSClientLib/libBaiduSpeechSDK.a"
    MODEL_PATH="Assets/BDSClientEASRResources/bds_easr_input_model.dat"

    mkdir -p "$(dirname "$LIB_PATH")"
    mkdir -p "$(dirname "$MODEL_PATH")"

    need_download=0
    if [ "${JM_BAIDU_STT_IOS_FORCE_DOWNLOAD:-}" = "1" ]; then
      need_download=1
    else
      if [ ! -f "$LIB_PATH" ] || [ ! -f "$MODEL_PATH" ]; then
        need_download=1
      fi
    fi

    if [ "$need_download" = "1" ]; then
      if [ "${JM_BAIDU_STT_IOS_SKIP_DOWNLOAD:-}" = "1" ]; then
        echo "[jm_baidu_stt_plugin] iOS Baidu SDK artifacts missing and download is disabled (JM_BAIDU_STT_IOS_SKIP_DOWNLOAD=1)." >&2
        echo "  - Missing: $LIB_PATH or $MODEL_PATH" >&2
        exit 1
      fi

      download_file() {
        local url="$1"
        local out="$2"
        echo "[jm_baidu_stt_plugin] Downloading: $url" >&2
        curl -fL --retry 3 --retry-delay 1 -o "$out" "$url"
      }

      verify_sha256_if_provided() {
        local file="$1"
        local expected="$2"
        if [ -n "$expected" ]; then
          # macOS: shasum; Linux: sha256sum
          if command -v shasum >/dev/null 2>&1; then
            actual="$(shasum -a 256 "$file" | awk '{print $1}')"
          else
            actual="$(sha256sum "$file" | awk '{print $1}')"
          fi

          if [ "$actual" != "$expected" ]; then
            echo "[jm_baidu_stt_plugin] SHA256 mismatch for $file" >&2
            echo "  expected: $expected" >&2
            echo "  actual  : $actual" >&2
            exit 1
          fi
        fi
      }

      tmp_dir="$(mktemp -d 2>/dev/null || mktemp -d -t jm_baidu_stt_plugin)"
      trap 'rm -rf "$tmp_dir"' EXIT

      if [ -n "${JM_BAIDU_STT_IOS_LIB_URL:-}" ] && [ -n "${JM_BAIDU_STT_IOS_MODEL_URL:-}" ]; then
        lib_tmp="$tmp_dir/libBaiduSpeechSDK.a"
        model_tmp="$tmp_dir/bds_easr_input_model.dat"

        download_file "$JM_BAIDU_STT_IOS_LIB_URL" "$lib_tmp"
        verify_sha256_if_provided "$lib_tmp" "${JM_BAIDU_STT_IOS_LIB_SHA256:-}"
        cp -f "$lib_tmp" "$LIB_PATH"

        download_file "$JM_BAIDU_STT_IOS_MODEL_URL" "$model_tmp"
        verify_sha256_if_provided "$model_tmp" "${JM_BAIDU_STT_IOS_MODEL_SHA256:-}"
        cp -f "$model_tmp" "$MODEL_PATH"

      elif [ -n "${JM_BAIDU_STT_IOS_SDK_ZIP_URL:-}" ]; then
        zip_tmp="$tmp_dir/baidu_ios_sdk.zip"
        download_file "$JM_BAIDU_STT_IOS_SDK_ZIP_URL" "$zip_tmp"
        verify_sha256_if_provided "$zip_tmp" "${JM_BAIDU_STT_IOS_SDK_ZIP_SHA256:-}"

        unzip_dir="$tmp_dir/unzip"
        mkdir -p "$unzip_dir"
        unzip -oq "$zip_tmp" -d "$unzip_dir"

        found_lib="$(find "$unzip_dir" -type f -name 'libBaiduSpeechSDK.a' -print -quit || true)"
        found_model="$(find "$unzip_dir" -type f -name 'bds_easr_input_model.dat' -print -quit || true)"

        if [ -z "$found_lib" ] || [ -z "$found_model" ]; then
          echo "[jm_baidu_stt_plugin] Failed to locate required files in zip." >&2
          echo "  - Need: libBaiduSpeechSDK.a, bds_easr_input_model.dat" >&2
          exit 1
        fi

        cp -f "$found_lib" "$LIB_PATH"
        cp -f "$found_model" "$MODEL_PATH"

      else
        echo "[jm_baidu_stt_plugin] Missing iOS Baidu SDK artifacts." >&2
        echo "  - Missing: $LIB_PATH or $MODEL_PATH" >&2
        echo "  - Provide either:" >&2
        echo "      * JM_BAIDU_STT_IOS_LIB_URL + JM_BAIDU_STT_IOS_MODEL_URL" >&2
        echo "      * or JM_BAIDU_STT_IOS_SDK_ZIP_URL" >&2
        exit 1
      fi
    fi

    if [ ! -f "$LIB_PATH" ]; then
      echo "[jm_baidu_stt_plugin] Missing $LIB_PATH" >&2
      exit 1
    fi
    if [ ! -f "$MODEL_PATH" ]; then
      echo "[jm_baidu_stt_plugin] Missing $MODEL_PATH" >&2
      exit 1
    fi
  CMD

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
    'Resources/*.bundle',
    # 5. Privacy manifest (required by App Store submissions)
    'Resources/PrivacyInfo.xcprivacy'
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
