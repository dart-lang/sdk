// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

import 'utils.dart';

void main() {
  late TestProject p;

  tearDown(() async => await p.dispose());

  test("Fallback to dartdev.dill from dartdev.dart.snapshot for 'Hello World'",
      () async {
    p = project(mainSrc: "void main() { print('Hello World'); }");
    // The DartDev snapshot includes the --use_field_guards flag. If
    // --no-use-field-guards is passed, the VM will fail to load the
    // snapshot and should fall back to using the DartDev dill file.
    ProcessResult result =
        await p.run(['--no-use-field-guards', 'run', p.relativeFilePath]);

    expect(result.stdout, contains('Hello World'));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  });
}
