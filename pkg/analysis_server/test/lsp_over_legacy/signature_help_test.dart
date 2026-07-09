// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SignatureHelpTest);
  });
}

@reflectiveTest
class SignatureHelpTest extends LspOverLegacyTest {
  Future<void> test_signatureHelp() async {
    var content = '''
/// My function.
void f(String a) {
  f(^);
}
''';
    var code = TestCode.parse(content);
    newFile(testFilePath, code.code);
    var results = await getSignatureHelp(testFileUri, code.position.position);
    var result = results!.signatures.single;

    expect(result.label, 'f(String a)');
    expect(result.parameters!.single.label, 'String a');
    var documentation = result.documentation?.map(
      (markup) => markup.value,
      (string) => string,
    );
    expect(documentation, 'My function.');
  }
}
