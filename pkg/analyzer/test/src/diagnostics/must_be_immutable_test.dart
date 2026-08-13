// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MustBeImmutableTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MustBeImmutableTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_directAnnotation() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class A {
//    ^
// [diag.mustBeImmutable] This class (or a class that this class inherits from) is marked as '@immutable', but one or more of its instance fields aren't final: A.x
  int x = 0;
}
''');
  }

  test_directAnnotation_declaredInPrimaryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class A(var int x);
//    ^
// [diag.mustBeImmutable] This class (or a class that this class inherits from) is marked as '@immutable', but one or more of its instance fields aren't final: A.x
''');
  }

  test_directMixinAnnotation() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
mixin A {
//    ^
// [diag.mustBeImmutable] This class (or a class that this class inherits from) is marked as '@immutable', but one or more of its instance fields aren't final: A.x
  int x = 0;
}
''');
  }

  test_extendsClassWithAnnotation() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class A {}
class B extends A {
//    ^
// [diag.mustBeImmutable] This class (or a class that this class inherits from) is marked as '@immutable', but one or more of its instance fields aren't final: B.x
  int x = 0;
}
''');
  }

  test_finalField() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class A {
  final x = 7;
}
''');
  }

  test_fromMixinWithAnnotation() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class A {}
mixin B {
  int x = 0;
}
class C extends A with B {}
//    ^
// [diag.mustBeImmutable] This class (or a class that this class inherits from) is marked as '@immutable', but one or more of its instance fields aren't final: B.x
''');
  }

  test_mixinApplication() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class A {}
mixin B {
  int x = 0;
}
class C = A with B;
//    ^
// [diag.mustBeImmutable] This class (or a class that this class inherits from) is marked as '@immutable', but one or more of its instance fields aren't final: B.x
''');
  }

  test_mixinApplicationBase() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  int x = 0;
}
mixin B {}
@immutable
class C = A with B;
//    ^
// [diag.mustBeImmutable] This class (or a class that this class inherits from) is marked as '@immutable', but one or more of its instance fields aren't final: A.x
''');
  }

  test_staticField() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class A {
  static int x = 0;
}
''');
  }
}
