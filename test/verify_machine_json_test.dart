// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../tool/machine.dart';

void main() {
  test('ensure `rules.json` is up to date', () async {
    var rulesFilePath = path.join('tool', 'machine', 'rules.json');
    var onDisk = File(rulesFilePath).readAsStringSync();
    var generated = await generateRulesJson();
    expect(generated, onDisk, reason: '''`rules.json` is out of date.
  Regenerate by running `dart tool/machine.dart -w`
''');
  });
}
