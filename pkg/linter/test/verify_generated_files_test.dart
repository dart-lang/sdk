// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../tool/generate_lints.dart';
import '../tool/util/path_utils.dart';

void main() {
  group('up-to-date generation tests', () {
    test('ensure lint names are up to date', () async {
      expect(await generatedNamesFile.check(linterPackageRoot), isTrue,
          reason: "The generated lint codes at 'lib/src/lint_names.dart'"
              'need to be regenerated. '
              "Run 'dart run pkg/linter/tool/generate_lints.dart' to update.");
    });

    test('ensure lint codes are up to date', () async {
      expect(await generatedCodesFile.check(linterPackageRoot), isTrue,
          reason: "The generated lint codes at 'lib/src/lint_codes.dart'"
              'need to be regenerated. '
              "Run 'dart run pkg/linter/tool/generate_lints.dart' to update.");
    });
  });
}
