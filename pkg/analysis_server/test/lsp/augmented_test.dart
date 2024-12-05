// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentedTest);
  });
}

@reflectiveTest
class AugmentedTest extends AbstractLspAnalysisServerTest {
  Future<void> test_class_body_augmentationToAugmentation() async {
    await verifyGoToAugmented('''
class A {}

augment class [!A!] {}

augment class A {
  ^
}
''');
  }

  Future<void> test_class_body_augmentationToDeclaration() async {
    await verifyGoToAugmented('''
class [!A!] {}

augment class A {
  ^
}
''');
  }

  Future<void> test_class_name_augmentationToAugmentation() async {
    await verifyGoToAugmented('''
class A {}

augment class [!A!] {}

augment class A^ {}
''');
  }

  Future<void> test_class_name_augmentationToDeclaration() async {
    await verifyGoToAugmented('''
class [!A!] {}

augment class ^A {}
''');
  }

  Future<void> test_constructor_body_augmentationToAugmentation() async {
    await verifyGoToAugmented('''
class A {
  A();
}

augment class A {
  augment [!A!]();
}

augment class A {
  augment A() {
    ^
  }
}
''');
  }

  Future<void> test_constructor_body_augmentationToDeclaration() async {
    await verifyGoToAugmented('''
class A {
  [!A!]();
}

augment class A {
  augment A() {
    ^
  }
}
''');
  }

  Future<void> test_constructor_name_augmentationToAugmentation() async {
    await verifyGoToAugmented('''
class A {
  A();
}

augment class A {
  augment [!A!]();
}

augment class A {
  augment A^();
}
''');
  }

  Future<void> test_constructor_name_augmentationToDeclaration() async {
    await verifyGoToAugmented('''
class A {
  [!A!]();
}

augment class A {
  augment A^();
}
''');
  }

  Future<void> test_getter_body() async {
    await verifyGoToAugmented('''
class A {
  String get [!foo!] => '';
}

augment class A {
  augment String get foo => '^';
}
''');
  }

  Future<void> test_getter_name() async {
    await verifyGoToAugmented('''
class A {
  String get [!foo!] => '';
}

augment class A {
  augment String get fo^o => '';
}
''');
  }

  Future<void> test_invalidLocation() async {
    await verifyNoAugmented('''
class A {}

^
''');
  }

  Future<void> test_method_body_augmentationToAugmentation() async {
    await verifyGoToAugmented('''
class A {
  void foo() {}
}

augment class A {
  augment void [!foo!]() {}
}

augment class A {
  augment void foo() {
    ^
  }
}
''');
  }

  Future<void> test_method_body_augmentationToDeclaration() async {
    await verifyGoToAugmented('''
class A {
  void [!foo!]() {}
}

augment class A {
  augment void foo() {
    ^
  }
}
''');
  }

  Future<void> test_method_name_augmentationToAugmentation() async {
    await verifyGoToAugmented('''
class A {
  void foo() {}
}

augment class A {
  augment void [!foo!]() {}
}

augment class A {
  augment void fo^o() {}
}
''');
  }

  Future<void> test_method_name_augmentationToDeclaration() async {
    await verifyGoToAugmented('''
class A {
  void [!foo!]() {}
}

augment class A {
  augment void f^oo() {}
}
''');
  }

  Future<void> test_setter_body() async {
    await verifyGoToAugmented('''
class A {
  set [!foo!](String value) {}
}

augment class A {
  augment set foo(String value) {
    ^
  }
}
''');
  }

  Future<void> test_setter_name() async {
    await verifyGoToAugmented('''
class A {
  set [!foo!](String value) {}
}

augment class A {
  augment set fo^o(String value) {}
}
''');
  }

  Future<void> verifyGoToAugmented(String content) async {
    // Build an augmentation library for mainFileUri.
    var code = TestCode.parse('''
part of '$mainFileUri';

$content
''');

    newFile(mainFilePath, "part 'main_augmentation.dart';");
    newFile(mainFileAugmentationPath, code.code);
    await initialize();
    var res = await getAugmented(
      mainFileAugmentationUri,
      code.position.position,
    );

    expect(
      res,
      equals(Location(uri: mainFileAugmentationUri, range: code.range.range)),
    );
  }

  Future<void> verifyNoAugmented(String content) async {
    // Build an augmentation library for mainFileUri.
    var code = TestCode.parse('''
part of '$mainFileUri';

$content
''');

    newFile(mainFilePath, "part 'main_augmentation.dart';");
    newFile(mainFileAugmentationPath, code.code);
    await initialize();
    var res = await getAugmented(
      mainFileAugmentationUri,
      code.position.position,
    );

    expect(res, isNull);
  }
}
