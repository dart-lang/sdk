// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';
import 'resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantDriverTest);
  });
}

@reflectiveTest
class ConstantDriverTest extends DriverResolutionTest with ConstantMixin {}

mixin ConstantMixin implements ResolutionTest {
  test_annotation_constructor_named() async {
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

  test_annotation_constructor_unnamed() async {
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

  test_constantValue_defaultParameter_noDefaultValue() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  const A({int p});
}
''');
    addTestFile(r'''
import 'a.dart';
const a = const A();
''');
    await resolveTestFile();
    assertNoTestErrors();

    var aLib = findElement.import('package:test/a.dart').importedLibrary;
    var aConstructor = aLib.getType('A').constructors.single;
    DefaultParameterElementImpl p = aConstructor.parameters.single;

    // To evaluate `const A()` we have to evaluate `{int p}`.
    // Even if its value is `null`.
    expect(p.isConstantEvaluated, isTrue);
    expect(p.constantValue.isNull, isTrue);
  }

  test_constFactoryRedirection_super() async {
    addTestFile(r'''
class I {
  const factory I(int f) = B;
}

class A implements I {
  final int f;

  const A(this.f);
}

class B extends A {
  const B(int f) : super(f);
}

@I(42)
main() {}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var node = findNode.annotation('@I');
    var value = node.elementAnnotation.constantValue;
    expect(value.getField('(super)').getField('f').toIntValue(), 42);
  }

  test_constNotInitialized() async {
    addTestFile(r'''
class B {
  const B(_);
}

class C extends B {
  static const a;
  const C() : super(a);
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER,
      CompileTimeErrorCode.CONST_NOT_INITIALIZED,
      CompileTimeErrorCode.CONST_NOT_INITIALIZED,
    ]);
  }
}
