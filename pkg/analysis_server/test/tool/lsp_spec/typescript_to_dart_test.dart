// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
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
  SomeOptions(this.options);

  /// Options used by something.
  final List<OptionKind> options;
}
    ''';
      convertAndCompare(input, expectedOutput);
    });

    test('uses aliases types in place of aliases', () {
      final String input = '''
type DocumentUri = string;

export interface SomeDocumentThing {
	uris: DocumentUri[];
}
    ''';
      final String expectedOutput = '''
class SomeDocumentThing {
  SomeDocumentThing(this.uris);

  final List<String /*DocumentUri*/ > uris;
}
    ''';
      convertAndCompare(input, expectedOutput);
    });

    test('outputs references in comments in the correct format', () {
      final String input = '''
export interface One {
}

/**
 *  This may refer to [a one](#One) or just [One](#One).
 */
export interface Two {
}
    ''';
      final String expectedOutput = '''
class One {}

/// This may refer to a one ([One]) or just [One].
class Two {}
    ''';
      convertAndCompare(input, expectedOutput);
    });
  });
}
