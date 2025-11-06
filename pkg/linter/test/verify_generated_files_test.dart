// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:analyzer_utilities/generated_content_check.dart';
import 'package:test/test.dart';

import '../tool/generate_lints.dart';

void main() {
  group('up-to-date generation tests', () {
    test('ensure lint names are up to date', () async {
      expect(
        await generatedNamesFile.check(pkg_root.packageRoot),
        isTrue,
        reason:
            "The generated lint codes at 'lib/src/lint_names.dart' need to "
            'be regenerated. '
            "Run 'dart run pkg/linter/tool/generate_lints.dart' to update.",
      );
    });

    test('ensure lint codes are up to date', () async {
      expect(
        await generatedCodesFile.check(pkg_root.packageRoot),
        isTrue,
        reason:
            "The generated lint codes at 'lib/src/lint_codes.g.dart' need "
            'to be regenerated. '
            "Run 'dart run pkg/linter/tool/generate_lints.dart' to update.",
      );
    });
  });
}
