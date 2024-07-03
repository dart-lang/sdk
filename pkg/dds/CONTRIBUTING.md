# Development for `package:dds`

One way to get stdout from files in DDS while debugging is to log messages to a file. You can add a method such as:

```dart
void _fileLog(String message) {
  final file = File('/tmp/dds.log');
  if (!file.existsSync()) {
    file.createSync();
  }
  file.writeAsStringSync(
'''
$message
''',
    mode: FileMode.append,
    flush: true,
  );
}
```

Then you can call `_fileLog('some print debugging message')`, and the log message will be written to a temp file.

To get logging output in real time, run `tail -f /tmp/dds.log`.

## Running DDS tests

From the `$DART_SDK_ROOT` directory, run:

```shell
 dart --packages=.dart_tool/package_config.json pkg/dds/test/path/to/your_test.dart
```

## Making changes to `package:dds` and `package:devtools_shared`

**If you do not need to build the Dart SDK** to test your changes, you
can add a `dependency_overrides` for `devtools_shared` that points to your
local `devtools_shared` directory from path:

```yaml
dependency_overrides:
  devtools_shared:
    path: ../../relative_path_to/devtools/packages/devtools_shared
```

**If you do need to build the Dart SDK** to test your changes, in addition
to adding the dependency override above, you will need to add a symbolic link
to your local `devtools_shared` directory:

From the `$DART_SDK_ROOT` directory, run:
```shell
rm -rf third_party/devtools/devtools_shared;
ln -s /absolute_path_to/devtools/packages/devtools_shared third_party/devtools/devtools_shared
```

**WARNING**: do not run `gclient sync -D` while the symbolic link is present,
as this could cause issues with your local `devtools_shared` code.

To delete the symbolic link after you are done with development, run:
```shell
rm -rf third_party/devtools/devtools_shared
```

## Making changes to `package:dds` and `devtools_app`

To test any changes made in `devtools_app`, you will need to first build DevTools.

- If you have not already, make sure to [set-up your DevTools development environment](https://github.com/flutter/devtools/blob/master/CONTRIBUTING.md#set-up-your-devtools-environment) so that you can use the `devtools_tool` command.

- Then build DevTools with `devtools_tool build`.

In the SDK, add a symbolic link to your local `devtools/packages/devtools_app/build/web` directory.

From the `$DART_SDK_ROOT` directory, run:

```shell
rm -rf third_party/devtools/web;
ln -s /absolute_path_to/devtools/devtools/packages/devtools_app/build/web third_party/devtools/web
```

**WARNING**: do not run `gclient sync -D` while the symbolic link is present,
as this could cause issues with your local `devtools_app` code.

Then, build the Dart SDK.

From the `$DART_SDK_ROOT` directory, run:

```shell
./tools/build.py -mrelease -ax64 create_sdk
```

To delete the symbolic link after you are done with development, run:

**WARNING**: do not run `gclient sync -D` while the symbolic link is present,
as this could cause issues with your local `devtools_app` code.

```shell
rm -rf third_party/devtools/web
```

Then, run `gclient sync` to pull down the checked in version of DevTools.
