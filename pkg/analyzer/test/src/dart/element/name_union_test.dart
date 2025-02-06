// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../summary/elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ElementNameUnionTest);
  });
}

@reflectiveTest
class ElementNameUnionTest extends ElementsBaseTest {
  @override
  bool get keepLinkingLibraries => false;

  test_class() async {
    var library = await buildLibrary(r'''
class MyClass {
  final myField = 0;
  int get myGetter => 0;
  set mySetter(int _) {}
  void myMethod() {}
}
''');

    var nameUnion = library.nameUnion;
    expect(nameUnion.contains('MyClass'), isTrue);
    expect(nameUnion.contains('NotMyClass'), isFalse);

    expect(nameUnion.contains('myField'), isTrue);
    expect(nameUnion.contains('NotMyField'), isFalse);

    expect(nameUnion.contains('myGetter'), isTrue);
    expect(nameUnion.contains('NotMyGetter'), isFalse);

    expect(nameUnion.contains('mySetter'), isTrue);
    expect(nameUnion.contains('NotMySetter'), isFalse);

    expect(nameUnion.contains('myMethod'), isTrue);
    expect(nameUnion.contains('NotMyMethod'), isFalse);
  }

  test_enum() async {
    var library = await buildLibrary(r'''
enum MyEnum {
  myValue
}
''');

    var nameUnion = library.nameUnion;
    expect(nameUnion.contains('MyEnum'), isTrue);
    expect(nameUnion.contains('NotMyEnum'), isFalse);

    expect(nameUnion.contains('MyValue'), isTrue);
    expect(nameUnion.contains('NotMyValue'), isFalse);
  }

  test_extension() async {
    var library = await buildLibrary(r'''
extension MyExtension on int {}
''');

    var nameUnion = library.nameUnion;
    expect(nameUnion.contains('MyExtension'), isTrue);
    expect(nameUnion.contains('NotMyExtension'), isFalse);
  }

  test_extensionType() async {
    var library = await buildLibrary(r'''
extension type MyExtensionType(int it) {}
''');

    var nameUnion = library.nameUnion;
    expect(nameUnion.contains('MyExtensionType'), isTrue);
    expect(nameUnion.contains('NotMyExtensionType'), isFalse);
  }

  test_mixin() async {
    var library = await buildLibrary(r'''
mixin MyMixin {}
''');

    var nameUnion = library.nameUnion;
    expect(nameUnion.contains('MyMixin'), isTrue);
    expect(nameUnion.contains('NotMyMixin'), isFalse);
  }

  test_topLevelVariable() async {
    var library = await buildLibrary(r'''
final myVariable = 0;
''');

    var nameUnion = library.nameUnion;
    expect(nameUnion.contains('myVariable'), isTrue);
    expect(nameUnion.contains('NotMyVariable'), isFalse);
  }

  test_typedef() async {
    var library = await buildLibrary(r'''
typedef MyTypedef = int;
''');

    var nameUnion = library.nameUnion;
    expect(nameUnion.contains('MyTypedef'), isTrue);
    expect(nameUnion.contains('NotMyTypedef'), isFalse);
  }
}
