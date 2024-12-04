// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
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
    defineReflectiveTests(SuperTest);
  });
}

@reflectiveTest
class SuperTest extends AbstractLspAnalysisServerTest {
  /// Class augmentations do not affect super behaviour.
  Future<void> test_augmentation_class() async {
    await verifyGoToSuper(
      TestCode.parse('''
class [!A!] {}

augment class A {}

class B^ extends A {}
'''),
    );
  }

  Future<void> test_augmentation_constructor() async {
    await verifyGoToSuper(
      TestCode.parse('''
class A {
  A();
}

augment class A {
  augment A();
}

augment class A {
  augment [!A!]();
}

class B extends A {
  B^();
}
'''),
    );
  }

  /// "Go to Super" for method goes to the last item in the augmentation chain
  /// of the super method since that's what `super.x()` would invoke.
  Future<void> test_augmentation_method() async {
    await verifyGoToSuper(
      TestCode.parse('''
class A {
  void foo() {}
}

augment class A {
  augment void foo() {}
}

augment class A {
  augment void [!foo!]() {}
}

class B extends A {}

class C extends B {
  @override
  void fo^o() {}
}
'''),
    );
  }

  Future<void> test_className() async {
    await verifyGoToSuper(
      TestCode.parse('''
class A {}

class [!B!] extends A {}

class C^ extends B {}
'''),
    );
  }

  Future<void> test_className_underscore() async {
    await verifyGoToSuper(
      TestCode.parse('''
class A {}

class [!_!] extends A {}

class C^ extends _ {}
'''),
    );
  }

  Future<void> test_constructor_named_callsSuperNamed() async {
    await verifyGoToSuper(
      TestCode.parse('''
class A {
  A();
  A.foo();
  A.[!bar!]();
}

class B extends A {
  B.foo(): super.bar() {
    ^
  }
}
'''),
    );
  }

  Future<void> test_constructor_named_callsSuperUnnamed() async {
    await verifyGoToSuper(
      TestCode.parse('''
class A {
  [!A!]();
  A.foo();
}

class B extends A {
  B.foo() {
    ^
  }
}
'''),
    );
  }

  Future<void> test_constructor_unnamed_callsSuperNamed() async {
    await verifyGoToSuper(
      TestCode.parse('''
class A {
  A();
  A.[!foo!]();
}

class B extends A {
  B^() : super.foo();
}

'''),
    );
  }

  Future<void> test_constructor_unnamed_callsSuperUnnamed() async {
    await verifyGoToSuper(
      TestCode.parse('''
class A {
  [!A!]();
}

class B extends A {
  B^();
}

'''),
    );
  }

  Future<void> test_getter() async {
    await verifyGoToSuper(
      TestCode.parse('''
class A {
  String get [!foo!] => '';
}

class B extends A {}

class C extends B {
  @override
  String get fo^o => '';
}
'''),
    );
  }

  Future<void> test_getter_underscore() async {
    await verifyGoToSuper(
      TestCode.parse('''
class A {
  String get [!_!] => '';
}

class B extends A {}

class C extends B {
  @override
  String get ^_ => '';
}
'''),
    );
  }

  Future<void> test_insideClass() async {
    await verifyGoToSuper(
      TestCode.parse('''
class A {}

class [!B!] extends A {}

class C extends B {
  ^
}
'''),
    );
  }

  Future<void> test_insideMethod() async {
    await verifyGoToSuper(
      TestCode.parse('''
class A {
  void [!foo!]() {}
}

class B extends A {}

class C extends B {
  @override
  void foo() {
    ^
  }
}
'''),
    );
  }

  Future<void> test_methodName() async {
    await verifyGoToSuper(
      TestCode.parse('''
class A {
  void [!foo!]() {}
}

class B extends A {}

class C extends B {
  @override
  void fo^o() {}
}
'''),
    );
  }

  Future<void> test_methodName_startOfParameterList() async {
    await verifyGoToSuper(
      TestCode.parse('''
class A {
  void [!foo!]() {}
}

class B extends A {}

class C extends B {
  @override
  void foo^() {}
}
'''),
    );
  }

  Future<void> test_methodName_startOfTypeParameterList() async {
    await verifyGoToSuper(
      TestCode.parse('''
class A {
  void [!foo!]<T>() {}
}

class B extends A {}

class C extends B {
  @override
  void foo^<T>() {}
}
'''),
    );
  }

  Future<void> test_methodName_underscore() async {
    await verifyGoToSuper(
      TestCode.parse('''
class A {
  void [!_!]() {}
}

class B extends A {}

class C extends B {
  @override
  void ^_() {}
}
'''),
    );
  }

  Future<void> test_methodReturnType() async {
    await verifyGoToSuper(
      TestCode.parse('''
class A {
  void [!foo!]() {}
}

class B extends A {}

class C extends B {
  @override
  vo^id foo() {}
}
'''),
    );
  }

  Future<void> test_setter() async {
    await verifyGoToSuper(
      TestCode.parse('''
class A {
  set [!foo!](String value) {}
}

class B extends A {}

class C extends B {
  @override
  set fo^o(String value) {}
}
'''),
    );
  }

  Future<void> test_setter_underscore() async {
    await verifyGoToSuper(
      TestCode.parse('''
class A {
  set [!_!](String value) {}
}

class B extends A {}

class C extends B {
  @override
  set ^_(String value) {}
}
'''),
    );
  }

  Future<void> verifyGoToSuper(TestCode code) async {
    await initialize();
    await openFile(mainFileUri, code.code);
    var res = await getSuper(mainFileUri, code.position.position);

    expect(res, equals(Location(uri: mainFileUri, range: code.range.range)));
  }
}
