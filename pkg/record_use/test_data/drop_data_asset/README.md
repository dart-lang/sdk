# Tree-shaking Data Assets with Record Use

This sample demonstrates how the `record-use` feature can be utilized to
tree-shake (remove) unused data assets from the build output.

## Usage

The `record-use` and `native-assets` experiments need to be enabled.

### JS

Run either `dart compile js --write-resources bin/drop_data_asset_calls.dart` or `dart compile js --write-resources bin/drop_data_asset_instances.dart`.

### Native

Run either `dart --enable-experiment=native-assets,record-use build bin/drop_data_asset_calls.dart` or `dart --enable-experiment=native-assets,record-use build bin/drop_data_asset_instances.dart`.

