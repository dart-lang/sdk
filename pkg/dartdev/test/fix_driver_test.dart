// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../tool/fix_driver.dart';
import 'utils.dart';

void main() {
  group('Driver', _driver);
}

Future<FixOutput> runFix(List<String> args) async {
  var runner = FixRunner(logger: CapturingLogger());
  var result = await runner.runFix(args);
  return FixOutput(result);
}

void _driver() {
  TestProject p;
  tearDown(() => p?.dispose());

  test('no fixes', () async {
    p = project(mainSrc: 'int get foo => 1;\n');
    var result = await runFix(['--apply', p.dirPath]);
    expect(result.stdout, contains('Nothing to fix!'));
    expect(result.returnCode, 0);
  });
}

class FixOutput {
  final FixResult<CapturingLogger> result;
  FixOutput(this.result);

  int get returnCode => result.returnCode;
  String get stderr => result.logger.output.stderr.toString();
  String get stdout => result.logger.output.stdout.toString();
}
