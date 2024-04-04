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

From the `sdk/` directory, run:
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
