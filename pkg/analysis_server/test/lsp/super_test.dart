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
  Future<void> test_className() async {
    final code = TestCode.parse('''
class A {}

class [!B!] extends A {}

class C^ extends B {}
''');
    await initialize();
    await openFile(mainFileUri, code.code);
    final res = await getSuper(
      mainFileUri,
      code.position.position,
    );

    expect(res, equals(Location(uri: mainFileUri, range: code.range.range)));
  }

  Future<void> test_insideClass() async {
    final code = TestCode.parse('''
class A {}

class [!B!] extends A {}

class C extends B {
  ^
}
''');
    await initialize();
    await openFile(mainFileUri, code.code);
    final res = await getSuper(
      mainFileUri,
      code.position.position,
    );

    expect(res, equals(Location(uri: mainFileUri, range: code.range.range)));
  }

  Future<void> test_insideMethod() async {
    final code = TestCode.parse('''
class A {
  void [!foo!]() {}
}

class B extends A {}

class C extends B {
  @override
  void foo() {
    // fo^oC
  }
}
''');
    await initialize();
    await openFile(mainFileUri, code.code);
    final res = await getSuper(
      mainFileUri,
      code.position.position,
    );

    expect(res, equals(Location(uri: mainFileUri, range: code.range.range)));
  }

  Future<void> test_methodName() async {
    final code = TestCode.parse('''
class A {
  void [!foo!]() {}
}

class B extends A {}

class C extends B {
  @override
  void fo^o() {
    // fooC
  }
}
''');
    await initialize();
    await openFile(mainFileUri, code.code);
    final res = await getSuper(
      mainFileUri,
      code.position.position,
    );

    expect(res, equals(Location(uri: mainFileUri, range: code.range.range)));
  }

  Future<void> test_methodName_startOfParameterList() async {
    final code = TestCode.parse('''
class A {
  void [!foo!]() {}
}

class B extends A {}

class C extends B {
  @override
  void foo^() {
    // fooC
  }
}
''');
    await initialize();
    await openFile(mainFileUri, code.code);
    final res = await getSuper(
      mainFileUri,
      code.position.position,
    );

    expect(res, equals(Location(uri: mainFileUri, range: code.range.range)));
  }

  Future<void> test_methodName_startOfTypeParameterList() async {
    final code = TestCode.parse('''
class A {
  void [!foo!]<T>() {}
}

class B extends A {}

class C extends B {
  @override
  void foo^<T>() {
    // fooC
  }
}
''');
    await initialize();
    await openFile(mainFileUri, code.code);
    final res = await getSuper(
      mainFileUri,
      code.position.position,
    );

    expect(res, equals(Location(uri: mainFileUri, range: code.range.range)));
  }

  Future<void> test_methodReturnType() async {
    final code = TestCode.parse('''
class A {
  void [!foo!]() {}
}

class B extends A {}

class C extends B {
  @override
  vo^id foo() {
    // fooC
  }
}
''');
    await initialize();
    await openFile(mainFileUri, code.code);
    final res = await getSuper(
      mainFileUri,
      code.position.position,
    );

    expect(res, equals(Location(uri: mainFileUri, range: code.range.range)));
  }
}
