// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/handlers/custom/editable_arguments/handler_edit_argument.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../shared/shared_edit_argument_tests.dart';
import 'server_abstract.dart';

// ignore_for_file: prefer_single_quotes

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EditArgumentTest);
    defineReflectiveTests(ComputeStringValueTest);
  });
}

@reflectiveTest
class ComputeStringValueTest {
  test_doubleQuote_multi_notRaw() async {
    verifyStrings(
      [
        // Single quotes (not escaped).
        (r""" ' """, r'''""" ' """'''),
        // Double quotes (not escaped).
        (r""" " """, r'''""" " """'''),
        // Dollars (escaped).
        (r""" $ """, r'''""" \$ """'''),
        // Newlines (escaped).
        (""" \r\n """, r'''""" \r\n """'''),
      ],
      single: false,
      multi: true,
      raw: false,
    );
  }

  test_doubleQuote_multi_raw() async {
    verifyStrings(
      [
        // Single quotes (not escaped).
        (" ' ", r'''r""" ' """'''),
        // Double quotes (not escaped).
        (' " ', r'''r""" " """'''),
        // Three Single quotes (not escaped, backslashes are to nest quotes here).
        (" ''' ", '''r""" \''' """'''),
        // Three Double quotes (escaped, changed to non-raw because quotes in string).
        (' """ ', r'""" \"\"\" """'),
        // Dollars (not escaped).
        (r' $ ', r'r""" $ """'),
        // Newlines (escaped, changed to non-raw because newlines in string).
        (' \r\n ', r'""" \r\n """'),
      ],
      single: false,
      multi: true,
      raw: true,
    );
  }

  test_doubleQuote_notMulti_notRaw() async {
    verifyStrings(
      [
        // Single quotes (not escaped).
        (" ' ", r'''" ' "'''),
        // Double quotes (escaped).
        (' " ', r'''" \" "'''),
        // Three Single quotes (not escaped, backslashes are to nest quotes here).
        (" ''' ", '''" \'\'\' "'''),
        // Three Double quotes (escaped).
        (' """ ', r'" \"\"\" "'),
        // Dollars (escaped).
        (r' $ ', r'" \$ "'),
        // Newlines (escaped).
        (' \r\n ', r'" \r\n "'),
      ],
      single: false,
      multi: false,
      raw: false,
    );
  }

  test_doubleQuote_notMulti_raw() async {
    verifyStrings(
      [
        // Single quotes (not escaped).
        (" ' ", r'''r" ' "'''),
        // Double quotes  (escaped, changed to non-raw because quotes in string).
        (' " ', r'" \" "'),
        // Three Single quotes (not escaped, backslashes are to nest quotes here).
        (" ''' ", '''r" \''' "'''),
        // Three Double quotes (escaped, changed to non-raw because quotes in string).
        (' """ ', r'" \"\"\" "'),
        // Dollars (not escaped).
        (r' $ ', r'r" $ "'),
        // Newlines (escaped, changed to non-raw because newlines in string).
        (' \r\n ', r'" \r\n "'),
      ],
      single: false,
      multi: false,
      raw: true,
    );
  }

  test_singleQuote_multi_notRaw() async {
    verifyStrings(
      [
        // Single quotes (not escaped).
        (r""" ' """, r"""''' ' '''"""),
        // Double quotes (not escaped).
        (r""" " """, r"""''' " '''"""),
        // Dollars (escaped).
        (r""" $ """, r"""''' \$ '''"""),
        // Newlines (escaped).
        (""" \r\n """, r"""''' \r\n '''"""),
      ],
      single: true,
      multi: true,
      raw: false,
    );
  }

  test_singleQuote_multi_raw() async {
    verifyStrings(
      [
        // Single quotes (not escaped).
        (" ' ", r"r''' ' '''"),
        // Double quotes (not escaped).
        (' " ', r"""r''' " '''"""),
        // Three Single quotes (escaped, changed to non-raw because quotes in string).
        (" ''' ", r"''' \'\'\' '''"),
        // Three Double quotes (not escaped, backslashes are to nest quotes here).
        (' """ ', """r''' \""" '''"""),
        // Dollars (not escaped).
        (r' $ ', r"r''' $ '''"),
        // Newlines (escaped, changed to non-raw because newlines in string).
        (' \r\n ', r"''' \r\n '''"),
      ],
      single: true,
      multi: true,
      raw: true,
    );
  }

  test_singleQuote_notMulti_notRaw() async {
    verifyStrings(
      [
        // Single quotes (escaped).
        (" ' ", r"' \' '"),
        // Double quotes (not escaped).
        (' " ', r"""' " '"""),
        // Three Single quotes (escaped).
        (" ''' ", r"' \'\'\' '"),
        // Three Double quotes (not escaped, backslashes are to nest quotes here).
        (' """ ', """' \""" '"""),
        // Dollars (escaped).
        (r' $ ', r"' \$ '"),
        // Newlines (escaped).
        (' \r\n ', r"' \r\n '"),
      ],
      single: true,
      multi: false,
      raw: false,
    );
  }

  test_singleQuote_notMulti_raw() async {
    verifyStrings(
      [
        // Single quotes (escaped, changed to non-raw because quotes in string).
        (" ' ", r"' \' '"),
        // Double quotes (not escaped).
        (' " ', r"""r' " '"""),
        // Three Single quotes (escaped, changed to non-raw because quotes in string).
        (" ''' ", r"' \'\'\' '"),
        // Three Double quotes (not escaped, backslashes are to nest quotes here).
        (' """ ', """r' \""" '"""),
        // Dollars (not escaped).
        (r' $ ', r"r' $ '"),
        // Newlines (escaped, changed to non-raw because newlines in string).
        (' \r\n ', r"' \r\n '"),
      ],
      single: true,
      multi: false,
      raw: true,
    );
  }

  /// Verifies a set of strings in [tests] are written correctly as literal
  /// Dart strings.
  void verifyStrings(
    List<(String, String)> tests, {
    required bool single,
    required bool multi,
    required bool raw,
  }) {
    for (var (input, expected) in tests) {
      var result = EditArgumentHandler.computeStringValueCode(
        input,
        preferSingleQuotes: single,
        preferMultiline: multi,
        preferRaw: raw,
      );

      expect(
        result,
        expected,
        reason:
            '[$input] should be represented by the literal Dart code [$expected] but was [$result]',
      );
    }
  }
}

@reflectiveTest
class EditArgumentTest extends AbstractLspAnalysisServerTest
    with
        LspSharedTestMixin,
        // Tests are defined in SharedEditArgumentTests because they
        // are shared and run for both LSP and Legacy servers.
        SharedEditArgumentTests {
  @override
  Future<void> setUp() async {
    await super.setUp();

    writeTestPackageConfig(flutter: true);
  }
}
