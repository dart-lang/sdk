// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedConstructorInInitializerTest);
  });
}

@reflectiveTest
class UndefinedConstructorInInitializerTest extends PubPackageResolutionTest {
  test_explicit_named_defined_constructor() async {
    await assertNoErrorsInCode(r'''
class A {
  A.named() {}
}
class B extends A {
  B() : super.named();
}
''');
  }

  test_explicit_named_defined_primaryConstructorBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A.named() {}
}
class B() extends A {
  this : super.named();
}
''');
  }

  test_explicit_named_notDefined_constructor() async {
    await assertErrorsInCode(
      r'''
class A {}
class B extends A {
  B() : super.named();
}
''',
      [
        error(
          diag.undefinedConstructorInInitializer,
          39,
          13,
          messageContains: ["class 'A'", "named 'named'"],
        ),
      ],
    );
  }

  test_explicit_named_notDefined_primateConstructorBody() async {
    await assertErrorsInCode(
      r'''
class A {}
class B() extends A {
  this : super.named();
}
''',
      [
        error(
          diag.undefinedConstructorInInitializer,
          42,
          13,
          messageContains: ["class 'A'", "named 'named'"],
        ),
      ],
    );
  }

  test_explicit_unnamed_defined_constructor() async {
    await assertNoErrorsInCode(r'''
class A {
  A() {}
}
class B extends A {
  B() : super();
}
''');
  }

  test_explicit_unnamed_defined_primaryConstructorBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A() {}
}
class B() extends A {
  this : super();
}
''');
  }

  test_explicit_unnamed_notDefined_constructor() async {
    await assertErrorsInCode(
      r'''
class A {
  A.named() {}
}
class B extends A {
  B() : super();
}
''',
      [error(diag.undefinedConstructorInInitializerDefault, 55, 7)],
    );
  }

  test_explicit_unnamed_notDefined_primaryConstructorBody() async {
    await assertErrorsInCode(
      r'''
class A {
  A.named() {}
}
class B() extends A {
  this : super();
}
''',
      [error(diag.undefinedConstructorInInitializerDefault, 58, 7)],
    );
  }
}
