// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MetadataResolutionTest);
  });
}

@reflectiveTest
class MetadataResolutionTest extends DriverResolutionTest {
  test_constructor_named() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  final int f;
  const A.named(this.f);
}
''');

    newFile('/test/lib/b.dart', content: r'''
import 'a.dart';

@A.named(42)
class B {}
''');

    addTestFile(r'''
import 'b.dart';

B b;
''');
    await resolveTestFile();
    assertNoTestErrors();

    var classB = findNode.typeName('B b;').name.staticElement;
    var annotation = classB.metadata.single;
    var value = annotation.computeConstantValue();
    expect(value, isNotNull);
    expect(value.getField('f').toIntValue(), 42);
  }

  test_constructor_unnamed() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  final int f;
  const A(this.f);
}
''');

    newFile('/test/lib/b.dart', content: r'''
import 'a.dart';

@A(42)
class B {}
''');

    addTestFile(r'''
import 'b.dart';

B b;
''');
    await resolveTestFile();
    assertNoTestErrors();

    var classB = findNode.typeName('B b;').name.staticElement;
    var annotation = classB.metadata.single;
    var value = annotation.computeConstantValue();
    expect(value, isNotNull);
    expect(value.getField('f').toIntValue(), 42);
  }

  test_implicitConst() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  final int f;
  const A(this.f);
}

class B {
  final A a;
  const B(this.a);
}

@B( A(42) )
class C {}
''');

    addTestFile(r'''
import 'a.dart';

C c;
''');
    await resolveTestFile();
    assertNoTestErrors();

    var classC = findNode.typeName('C c;').name.staticElement;
    var annotation = classC.metadata.single;
    var value = annotation.computeConstantValue();
    expect(value, isNotNull);
    expect(value.getField('a').getField('f').toIntValue(), 42);
  }
}
