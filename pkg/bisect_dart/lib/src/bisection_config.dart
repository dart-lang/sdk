// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:cli_config/cli_config.dart';
import 'package:intl/intl.dart';

class BisectionConfig {
  /// A way to identify this bisection.
  ///
  /// Used for log names etc.
  final String name;

  static const String _nameKey = 'name';

  /// Hash of the first commit.
  final String start;

  static const String _startKey = 'start';

  /// Hash of the last commit.
  final String end;

  static const String _endKey = 'end';

  /// The commands to run.
  ///
  /// Typically a `python3 tools/test.py --build [...]`.
  ///
  /// Commands are run in [sdkPath] as working directory.
  final List<String> testCommands;

  static const String _testCommandsKey = 'test_command';

  /// The pattern to recognize in the stdout or stderr of the last item in
  /// [testCommands].
  final String failureString;

  static const String _failureStringKey = 'failure_string';

  // This will likely be extended later to support regexes.
  Pattern get failurePattern => failureString.toPattern();

  /// The SDK checkout to use for bisecting.
  ///
  /// This will modify the SDK checkout!
  ///
  /// Will be created if it doens't exist.
  final Uri sdkPath;

  static const _sdkPathKey = 'sdk_path';

  BisectionConfig({
    required this.name,
    required this.start,
    required this.end,
    required this.testCommands,
    required this.sdkPath,
    required this.failureString,
  });

  factory BisectionConfig.fromConfig(Config config) {
    final testCommands = config.stringList(_testCommandsKey);
    final name = config.optionalString(_nameKey) ??
        '${DateFormat('yyyyMMdd').format(DateTime.now())}_'
            '${testCommands.last.split(' ').last.split('/').last}';
    final sdkPath = config.optionalPath(_sdkPathKey, mustExist: true) ??
        Directory.current.uri;
    return BisectionConfig(
      name: name,
      start: config.string(_startKey),
      end: config.string(_endKey),
      testCommands: testCommands,
      sdkPath: sdkPath,
      failureString: config.string(_failureStringKey),
    );
  }

  Map<String, Object> asMap() => {
        _startKey: start,
        _endKey: end,
        _testCommandsKey: testCommands,
        _failureStringKey: failureString,
        _sdkPathKey: sdkPath.toFilePath(),
        _nameKey: name,
      };

  @override
  String toString() {
    return 'BisectionConfig(${asMap()})';
  }

  static final BisectionConfig _example = BisectionConfig(
    name: '20230712_package_resolve_test',
    start: '23f41452',
    end: '2c97bd78',
    testCommands: [
      'python3 tools/test.py --build -n dartk-linux-debug-x64 lib_2/isolate/package_resolve_test',
    ],
    sdkPath: Directory.current.uri,
    failureString:
        "Error: The argument type 'String' can't be assigned to the parameter type 'Uri'.",
  );

  static const _argumentDescriptions = {
    _startKey: 'The commit has at the start of the commit range.',
    _endKey: 'The commit has at the end of the commit range.',
    _testCommandsKey: '''The command(s) to run to reproduce the failure.
Typically this is "python3 tools/test.py --build [...]"
This should be within quotes when passed in terminal because of spaces.
This command can be supplied multiple times to run multiple commands to
reproduce a failure.
''',
    _failureStringKey: '''A string from the failing output.
Regexes are not yet supported.
This should be within quotes when passed in terminal when containing spaces.
''',
    _sdkPathKey: '''The SDK path is optional.
The SDK path defaults to the current working directory.
''',
    _nameKey: '''The name is optional.
The name defaults to the current date and the recognized test name.
The name is used for distinguishing logs.
''',
  };

  static String helpMessage() {
    final exampleArguments = _example.asMap().entries.map((e) {
      var value = e.value;
      if (value is List) {
        value = value.first;
      }
      if ((value as String).contains(' ')) {
        value = '"$value"';
      }
      return '-D${e.key}=$value';
    }).join(' ');
    const padding = _failureStringKey.length;
    final descriptions = _argumentDescriptions.entries.map((e) {
      final value = e.value
          .split('\n')
          .map((l) => '${' ' * (padding + 3)}$l')
          .join('\n')
          .trim();
      return '${e.key.padRight(padding)} : $value';
    }).join('\n');
    return '''
Usage: tools/bisect.dart $exampleArguments

This script starts a bisection in the provided SDK path.

It will write logs to .dart_tool/bisect_dart/.

$descriptions
''';
  }
}

extension on String {
  toPattern() => RegExp(RegExp.escape(this));
}
