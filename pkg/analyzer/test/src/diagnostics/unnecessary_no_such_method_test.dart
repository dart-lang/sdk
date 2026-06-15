// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNoSuchMethodTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnnecessaryNoSuchMethodTest extends PubPackageResolutionTest {
  test_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B extends A {
  mmm();
  noSuchMethod(y) {
//^^^^^^^^^^^^
// [diag.unnecessaryNoSuchMethod] Unnecessary 'noSuchMethod' declaration.
    return super.noSuchMethod(y);
  }
}
''');
  }

  test_blockBody_notReturnStatement() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B extends A {
  mmm();
  noSuchMethod(y) {
    print(y);
  }
}
''');
  }

  test_blockBody_notSingleStatement() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B extends A {
  mmm();
  noSuchMethod(y) {
    print(y);
    return super.noSuchMethod(y);
  }
}
''');
  }

  test_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B extends A {
  mmm();
  noSuchMethod(y) => super.noSuchMethod(y);
//^^^^^^^^^^^^
// [diag.unnecessaryNoSuchMethod] Unnecessary 'noSuchMethod' declaration.
}
''');
  }

  test_expressionBody_notNoSuchMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B extends A {
  mmm();
  noSuchMethod(y) => super.hashCode;
}
''');
  }

  test_expressionBody_notSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B extends A {
  mmm();
  noSuchMethod(y) => 42;
}
''');
  }
}
