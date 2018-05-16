#!/usr/bin/env bash
# Updates the checked in SDKs
set -e
set -x

if [ -z "$1" ]; then
  echo "Usage: update.sh version"
  exit 1
fi

channel="stable"
case "$1" in
*-dev.*) channel="dev";;
esac

tmpdir=$(mktemp -d)
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT HUP INT QUIT TERM PIPE
pushd "$tmpdir"

gsutil cp "gs://dart-archive/channels/$channel/release/$1/sdk/dartsdk-linux-x64-release.zip" .
gsutil cp "gs://dart-archive/channels/$channel/release/$1/sdk/dartsdk-linux-arm-release.zip" .
gsutil cp "gs://dart-archive/channels/$channel/release/$1/sdk/dartsdk-linux-arm64-release.zip" .
gsutil cp "gs://dart-archive/channels/$channel/release/$1/sdk/dartsdk-macos-x64-release.zip" .
gsutil cp "gs://dart-archive/channels/$channel/release/$1/sdk/dartsdk-windows-ia32-release.zip" .

unzip -q dartsdk-linux-arm-release.zip dart-sdk/bin/dart
mv dart-sdk/bin/dart dart-sdk/bin/dart-arm
unzip -q dartsdk-linux-arm64-release.zip dart-sdk/bin/dart
mv dart-sdk/bin/dart dart-sdk/bin/dart-arm64
unzip -q dartsdk-linux-x64-release.zip
tar -czf dart-sdk.tar.gz dart-sdk
upload_to_google_storage.py -b dart-dependencies dart-sdk.tar.gz
mv dart-sdk.tar.gz.sha1 dart-sdk.tar.gz.sha1-linux
rm -rf dart-sdk

unzip -q dartsdk-macos-x64-release.zip
tar -czf dart-sdk.tar.gz dart-sdk
upload_to_google_storage.py -b dart-dependencies dart-sdk.tar.gz
mv dart-sdk.tar.gz.sha1 dart-sdk.tar.gz.sha1-mac
rm -rf dart-sdk

unzip -q dartsdk-windows-ia32-release.zip
tar -czf dart-sdk.tar.gz dart-sdk
upload_to_google_storage.py -b dart-dependencies dart-sdk.tar.gz
mv dart-sdk.tar.gz.sha1 dart-sdk.tar.gz.sha1-win
rm -rf dart-sdk

popd

mv $tmpdir/dart-sdk.tar.gz.sha1-linux linux/dart-sdk.tar.gz.sha1
mv $tmpdir/dart-sdk.tar.gz.sha1-mac mac/dart-sdk.tar.gz.sha1
mv $tmpdir/dart-sdk.tar.gz.sha1-win win/dart-sdk.tar.gz.sha1
