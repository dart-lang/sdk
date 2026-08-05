// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreationOfStructOrUnionTest);
  });
}

@reflectiveTest
class CreationOfStructOrUnionTest extends PubPackageResolutionTest {
  test_struct() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

final class A extends Struct {
  @Int32()
  external int a;
}

void f() {
  A();
//^
// [diag.creationOfStructOrUnion] Subclasses of 'Struct' and 'Union' are backed by native memory, and can't be instantiated by a generative constructor.
}
''');
  }

  test_union() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

final class A extends Union {
  @Int32()
  external int a;
}

void f() {
  A();
//^
// [diag.creationOfStructOrUnion] Subclasses of 'Struct' and 'Union' are backed by native memory, and can't be instantiated by a generative constructor.
}
''');
  }
}
