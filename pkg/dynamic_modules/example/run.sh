#!/bin/bash
# Exit on error
set -e

# Create a temporary directory for all build artifacts
BUILD_DIR=$(mktemp -d -t dart_dyn_mod_build_XXXXXX)
echo "Created temporary build directory: $BUILD_DIR"

# Create a temporary directory for application data (system temp)
APP_DATA_DIR=$(mktemp -d -t dart_dyn_mod_app_XXXXXX)
echo "Created temporary app data directory: $APP_DATA_DIR"

# Ensure cleanup on exit (even on error)
cleanup() {
  rm -rf "$BUILD_DIR"
  rm -rf "$APP_DATA_DIR"
  echo "Cleaned up temporary directories."
}
trap cleanup EXIT

echo "Building Dart SDK artifacts with dynamic modules support"
./tools/build.py -m release --dart-dynamic-modules \
  runtime runtime_precompiled utils/gen_kernel

# Define paths
SDK_OUT="out/ReleaseX64"
GEN_KERNEL="$SDK_OUT/gen/gen_kernel_aot.dart.snapshot"
GEN_SNAPSHOT="$SDK_OUT/gen_snapshot_product"
DART2BYTECODE="$SDK_OUT/gen/dart2bytecode.dart.snapshot"
AOT_RUNTIME="$SDK_OUT/dartaotruntime_product"
VM_PLATFORM="$SDK_OUT/vm_platform.dill"

EXAMPLE_DIR="pkg/dynamic_modules/example"
HOST_DIR="$EXAMPLE_DIR/host"
MODULES_DIR="$EXAMPLE_DIR/modules"
COMMON_DIR="$EXAMPLE_DIR/common"
INTERFACE_YAML="$EXAMPLE_DIR/dynamic_interface.yaml"

echo "Compiling host application (non-AOT)..."
$AOT_RUNTIME $GEN_KERNEL \
  --target vm \
  --packages .dart_tool/package_config.json \
  -Ddart.vm.profile=false \
  -Ddart.vm.product=true \
  -Ddynamic.modules.test.mode=aot \
  --no-aot \
  --no-embed-sources \
  --platform $VM_PLATFORM \
  --output $BUILD_DIR/main_no_aot.dill \
  --dynamic-interface $INTERFACE_YAML \
  $HOST_DIR/main.dart

echo "Compiling host application (AOT)..."
$AOT_RUNTIME $GEN_KERNEL \
  --target vm \
  --packages .dart_tool/package_config.json \
  -Ddart.vm.profile=false \
  -Ddart.vm.product=true \
  -Ddynamic.modules.test.mode=aot \
  --aot \
  --no-embed-sources \
  --platform $VM_PLATFORM \
  --output $BUILD_DIR/main_aot.dill \
  --dynamic-interface $INTERFACE_YAML \
  $HOST_DIR/main.dart

echo "Generating host AOT snapshot..."
$GEN_SNAPSHOT \
  --snapshot-kind=app-aot-elf \
  --elf=$BUILD_DIR/main.snapshot \
  $BUILD_DIR/main_aot.dill

echo "Compiling dynamic modules..."
for module in basic exponent trigonometry; do
  echo "  Compiling module: $module"
  $AOT_RUNTIME $DART2BYTECODE \
    --platform $VM_PLATFORM \
    --target vm \
    --packages .dart_tool/package_config.json \
    -Ddart.vm.profile=false \
    -Ddart.vm.product=true \
    -Ddynamic.modules.test.mode=aot \
    --import-dill $BUILD_DIR/main_no_aot.dill \
    --validate $INTERFACE_YAML \
    --bytecode-options=source-positions \
    --allow-dynamic-calls-in-dynamic-modules \
    --extra-selectors-allowed-in-dynamic-calls=m5,m6,m7,m10,m11,m15,m16,call \
    --output $APP_DATA_DIR/$module.bytecode \
    --prefix-library-uris import/prefix \
    $MODULES_DIR/$module.dart
done

echo "Launching application..."
echo "To exit, type 'exit'."
echo "To load basic operations, type: load basic"
echo "To load exponent operations, type: load exponent"
echo "To load trigonometry operations, type: load trigonometry"
echo "To use addition: + 1 2 3"
echo "To use subtraction (after load basic): - 10 3"
echo "To use exponent (after load exponent): ^ 2 3"
echo "To use trigonometry (after load trigonometry): sin 1.57079"

$AOT_RUNTIME $BUILD_DIR/main.snapshot "$APP_DATA_DIR"
