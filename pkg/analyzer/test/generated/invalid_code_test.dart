// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidCodeTest);
  });
}

/// Tests for various end-to-end cases when invalid code caused exceptions
/// in one or another Analyzer subsystem. We are not interested not in specific
/// errors generated, but we want to make sure that there is at least one,
/// and analysis finishes without exceptions.
@reflectiveTest
class InvalidCodeTest extends DriverResolutionTest {
  /// This code results in a method with the empty name, and the default
  /// constructor, which also has the empty name. The `Map` in `f` initializer
  /// references the empty name.
  test_constructorAndMethodNameCollision() async {
    await _assertCanBeAnalyzed('''
class C {
  var f = { : };
  @ ();
}
''');
  }

  test_constructorDeclaration_named_missingName() async {
    await _assertCanBeAnalyzed('''
class C {
  C.();
}
''');
  }

  test_constructorDeclaration_named_missingName_factory() async {
    await _assertCanBeAnalyzed('''
class C {
  factory C.();
}
''');
  }

  test_fuzz_01() async {
    await _assertCanBeAnalyzed(r'''
typedef F = void Function(bool, int a(double b));
''');
    var function = findElement.genericTypeAlias('F').function;
    assertElementTypeString(
      function.type,
      'void Function(bool, int Function(double))',
    );
  }

  test_fuzz_02() async {
    await _assertCanBeAnalyzed(r'''
class G<class G{d
''');
  }

  test_fuzz_03() async {
    await _assertCanBeAnalyzed('''
class{const():super.{n
''');
  }

  test_fuzz_04() async {
    await _assertCanBeAnalyzed('''
f({a: ({b = 0}) {}}) {}
''');
  }

  test_fuzz_05() async {
    // Here 'v' is used as both the local variable name, and its type.
    // This triggers "reference before declaration" diagnostics.
    // It attempts to ask the enclosing unit element for "v".
    // Every (not library or unit) element must have the enclosing unit.
    await _assertCanBeAnalyzed('''
f({a = [for (v v in [])]}) {}
''');
  }

  test_fuzz_06() async {
    await _assertCanBeAnalyzed(r'''
class C {
  int f;
  set f() {}
}
''');
  }

  test_fuzz_07() async {
    // typedef v(<T extends T>(e
    await _assertCanBeAnalyzed(r'''
typedef F(a<TT extends TT>(e));
''');
  }

  test_fuzz_08() async {
//    class{const v
//    v=((){try catch
    // When we resolve initializers of typed constant variables,
    // we should build locale elements.
    await _assertCanBeAnalyzed(r'''
class C {
  const Object v = () { var a = 0; };
}
''');
  }

  test_genericFunction_asTypeArgument_ofUnresolvedClass() async {
    await _assertCanBeAnalyzed(r'''
C<int Function()> c;
''');
  }

  test_keywordInConstructorInitializer_assert() async {
    await _assertCanBeAnalyzed('''
class C {
  C() : assert = 0;
}
''');
  }

  test_keywordInConstructorInitializer_null() async {
    await _assertCanBeAnalyzed('''
class C {
  C() : null = 0;
}
''');
  }

  test_keywordInConstructorInitializer_super() async {
    await _assertCanBeAnalyzed('''
class C {
  C() : super = 0;
}
''');
  }

  test_keywordInConstructorInitializer_this() async {
    await _assertCanBeAnalyzed('''
class C {
  C() : this = 0;
}
''');
  }

  Future<void> _assertCanBeAnalyzed(String text) async {
    addTestFile(text);
    await resolveTestFile();
    assertHasTestErrors();
  }
}
