// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';
import 'resolution.dart';
import 'task_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GenericTypeAliasDriverResolutionTest);
    defineReflectiveTests(GenericTypeAliasTaskResolutionTest);
  });
}

@reflectiveTest
class GenericTypeAliasDriverResolutionTest extends DriverResolutionTest
    with GenericTypeAliasResolutionMixin {}

abstract class GenericTypeAliasResolutionMixin implements ResolutionTest {
  test_typeParameters() async {
    addTestFile(r'''
class A {}

class B {}

typedef F<T extends A> = B<T> Function<U extends B>(T a, U b);
''');
    await resolveTestFile();

    var f = findElement.genericTypeAlias('F');
    expect(f.typeParameters, hasLength(1));

    var t = f.typeParameters[0];
    expect(t.name, 'T');
    assertElementTypeString(t.bound, 'A');

    var ff = f.function;
    expect(ff.typeParameters, hasLength(1));

    var u = ff.typeParameters[0];
    expect(u.name, 'U');
    assertElementTypeString(u.bound, 'B');
  }
}

@reflectiveTest
class GenericTypeAliasTaskResolutionTest extends TaskResolutionTest
    with GenericTypeAliasResolutionMixin {}
