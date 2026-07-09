// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidOverrideOfNonVirtualMemberTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class InvalidOverrideOfNonVirtualMemberTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_class_field() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  int g = 0;
}

class B extends C  {
  @override
  int g = 0;
//    ^
// [diag.invalidOverrideOfNonVirtualMember] The member 'g' is declared non-virtual in 'C' and can't be overridden in subclasses.
}
''');
  }

  test_class_field_2() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  int g = 0;
}

class B extends C  {
  int g = 0, h = 1;
//    ^
// [diag.invalidOverrideOfNonVirtualMember] The member 'g' is declared non-virtual in 'C' and can't be overridden in subclasses.
}
''');
  }

  test_class_field_overriddenByGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  int g = 0;
}

class B extends C  {
  @override
  int get g => 0;
//        ^
// [diag.invalidOverrideOfNonVirtualMember] The member 'g' is declared non-virtual in 'C' and can't be overridden in subclasses.
}
''');
  }

  test_class_field_overriddenBySetter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  int g = 0;
}

class B extends C  {
  @override
  set g(int v) {}
//    ^
// [diag.invalidOverrideOfNonVirtualMember] The member 'g' is declared non-virtual in 'C' and can't be overridden in subclasses.
}
''');
  }

  test_class_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  int get g => 0;
}

class B extends C  {
  @override
  int get g => 0;
//        ^
// [diag.invalidOverrideOfNonVirtualMember] The member 'g' is declared non-virtual in 'C' and can't be overridden in subclasses.
}
''');
  }

  test_class_getter_overriddenByField() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  int get g => 0;
}

class B extends C  {
  @override
  int g = 0;
//    ^
// [diag.invalidOverrideOfNonVirtualMember] The member 'g' is declared non-virtual in 'C' and can't be overridden in subclasses.
}
''');
  }

  test_class_implements_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  int get g => 0;
}

class B implements C  {
  @override
  int get g => 0; //OK
}
''');
  }

  test_class_implements_method() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  void f() {}
}

class B implements C  {
  @override
  void f() {} //OK
}
''');
  }

  test_class_method() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  void f() {}
}

class B extends C  {
  @override
  void f() {}
//     ^
// [diag.invalidOverrideOfNonVirtualMember] The member 'f' is declared non-virtual in 'C' and can't be overridden in subclasses.
}
''');
  }

  test_class_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  set g(int v) {}
}

class B extends C  {
  @override
  set g(int v) {}
//    ^
// [diag.invalidOverrideOfNonVirtualMember] The member 'g' is declared non-virtual in 'C' and can't be overridden in subclasses.
}
''');
  }

  test_class_setter_overriddenByField() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  set g(int v) {}
}

class B extends C  {
  @override
  int g = 0;
//    ^
// [diag.invalidOverrideOfNonVirtualMember] The member 'g' is declared non-virtual in 'C' and can't be overridden in subclasses.
}
''');
  }

  test_mixin_method() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

mixin M {
  @nonVirtual
  void f() {}
}

class B with M {
  @override
  void f() {}
//     ^
// [diag.invalidOverrideOfNonVirtualMember] The member 'f' is declared non-virtual in 'M' and can't be overridden in subclasses.
}
''');
  }

  test_mixin_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

mixin M {
  @nonVirtual
  set g(int v) {}
}

class B with M {
  @override
  set g(int v) {}
//    ^
// [diag.invalidOverrideOfNonVirtualMember] The member 'g' is declared non-virtual in 'M' and can't be overridden in subclasses.
}
''');
  }
}
