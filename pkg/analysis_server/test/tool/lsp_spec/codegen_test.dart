// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../tool/lsp_spec/codegen_dart.dart';
import '../../../tool/lsp_spec/meta_model.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CodegenTest);
  });
}

@reflectiveTest
class CodegenTest {
  void test_enumMembersNamedNew() {
    var generatedCode = generateDartForTypes([
      LspEnum(
        name: 'x',
        typeOfValues: TypeReference.int,
        members: [
          Constant(name: 'new', type: TypeReference.string, value: '1'),
        ],
      ),
    ]);

    // Verify the generated code parses with no errors.
    parseString(content: generatedCode);

    // Verify some expected code.
    expect(generatedCode, contains('static const new_ = x(1)'));
  }

  void test_fieldsNamedDefault() {
    var generatedCode = generateDartForTypes([
      Interface(
        name: 'x',
        members: [
          Field(
            name: 'default',
            type: TypeReference.string,
            allowsNull: false,
            allowsUndefined: true,
          ),
        ],
      ),
    ]);

    // Verify the generated code parses with no errors.
    parseString(content: generatedCode);

    // Verify some expected code.
    expect(generatedCode, contains('final String? defaultValue'));
    expect(generatedCode, contains('this.defaultValue'));
    expect(generatedCode, contains('defaultValue.hashCode'));

    // JSON still uses the original protocol name.
    expect(generatedCode, contains("result['default'] = defaultValue"));
    expect(generatedCode, contains("defaultValueJson = json['default']"));
  }
}
