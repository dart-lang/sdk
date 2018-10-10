// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../../../tool/lsp_spec/codegen_dart.dart';
import '../../../tool/lsp_spec/typescript.dart';

main() {
  group('typescript converts to dart', () {
    void convertAndCompare(String input, String expectedOutput) {
      final String output = generateDartForTypes(extractTypes(input));
      expect(output.trim(), equals(expectedOutput.trim()));
    }

    // TODO(dantup): These types are missing constructors, toJson, fromJson, etc.

    test('for an interface', () {
      final String input = '''
/**
 * Some options.
 */
export interface SomeOptions {
	/**
	 * Options used by something.
	 */
	options?: OptionKind[];
}
    ''';
      final String expectedOutput = '''
/// Some options.
class SomeOptions {
  /// Options used by something.
  List<OptionKind> options;
}
    ''';
      convertAndCompare(input, expectedOutput);
    });
  });
}
