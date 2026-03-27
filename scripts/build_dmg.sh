#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="${ROOT_DIR}/MacPaste.xcodeproj"
SCHEME="MacPaste"
CONFIGURATION="Release"
APP_NAME="MacPaste"
VOL_NAME="MacPaste"
SKIP_BUILD="false"
VERSION=""

usage() {
  cat <<EOF
用法:
  $(basename "$0") [选项]

选项:
  -s, --scheme <name>        Xcode Scheme 名称（默认: MacPaste）
  -c, --configuration <name> 构建配置（默认: Release）
  -a, --app-name <name>      App 名称（默认: MacPaste）
  -n, --volume-name <name>   DMG 卷名（默认: MacPaste）
  -v, --version <ver>        DMG 版本号后缀（例如 1.0.0）
      --skip-build           跳过 xcodebuild，仅用已有 archive 打包
  -h, --help                 显示帮助
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--scheme)
      SCHEME="$2"
      shift 2
      ;;
    -c|--configuration)
      CONFIGURATION="$2"
      shift 2
      ;;
    -a|--app-name)
      APP_NAME="$2"
      shift 2
      ;;
    -n|--volume-name)
      VOL_NAME="$2"
      shift 2
      ;;
    -v|--version)
      VERSION="$2"
      shift 2
      ;;
    --skip-build)
      SKIP_BUILD="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "未知参数: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ ! -d "${PROJECT_PATH}" ]]; then
  echo "未找到 Xcode 项目: ${PROJECT_PATH}"
  exit 1
fi

BUILD_DIR="${ROOT_DIR}/build"
DIST_DIR="${ROOT_DIR}/dist"
ARCHIVE_PATH="${BUILD_DIR}/${SCHEME}.xcarchive"
EXPORT_APP_PATH="${ARCHIVE_PATH}/Products/Applications/${APP_NAME}.app"
STAGING_DIR="${BUILD_DIR}/dmg-staging"
TMP_DMG="${BUILD_DIR}/${APP_NAME}-tmp.dmg"

mkdir -p "${BUILD_DIR}" "${DIST_DIR}"

if [[ "${SKIP_BUILD}" != "true" ]]; then
  echo "==> 开始构建并归档 (${SCHEME} / ${CONFIGURATION})"
  xcodebuild \
    -project "${PROJECT_PATH}" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -archivePath "${ARCHIVE_PATH}" \
    archive
fi

if [[ ! -d "${EXPORT_APP_PATH}" ]]; then
  echo "未找到归档后的应用: ${EXPORT_APP_PATH}"
  echo "请先成功执行构建，或检查 --scheme / --app-name 参数。"
  exit 1
fi

if [[ -z "${VERSION}" ]]; then
  VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${EXPORT_APP_PATH}/Contents/Info.plist" 2>/dev/null || true)"
fi

if [[ -z "${VERSION}" ]]; then
  VERSION="$(date +%Y%m%d%H%M)"
fi

DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_PATH="${DIST_DIR}/${DMG_NAME}"

echo "==> 准备 DMG 内容目录"
rm -rf "${STAGING_DIR}" "${TMP_DMG}" "${DMG_PATH}"
mkdir -p "${STAGING_DIR}"
cp -R "${EXPORT_APP_PATH}" "${STAGING_DIR}/"
ln -s /Applications "${STAGING_DIR}/Applications"

echo "==> 生成临时 DMG"
hdiutil create \
  -volname "${VOL_NAME}" \
  -srcfolder "${STAGING_DIR}" \
  -ov \
  -format UDRW \
  "${TMP_DMG}"

echo "==> 压缩为最终 DMG"
hdiutil convert "${TMP_DMG}" -format UDZO -imagekey zlib-level=9 -o "${DMG_PATH}"

echo "==> 清理临时文件"
rm -rf "${STAGING_DIR}" "${TMP_DMG}"

echo "完成: ${DMG_PATH}"
