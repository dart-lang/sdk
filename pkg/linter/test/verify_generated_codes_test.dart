// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../tool/codes/generate.dart';
import '../tool/util/path_utils.dart';

void main() {
  group('up-to-date generation tests', () {
    test('ensure lint codes are up to date', () async {
      expect(await generateCodesFile().check(linterPackageRoot), isTrue,
          reason: "The generated lint codes at 'lib/src/linter_lint_codes.dart'"
              'need to be regenerated. '
              "Run 'dart run pkg/linter/tool/codes/generate.dart' to update.");
    });
  });
}
