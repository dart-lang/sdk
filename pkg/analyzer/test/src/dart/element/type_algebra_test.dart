// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubstituteEmptyTest);
    defineReflectiveTests(SubstituteFromInterfaceTypeTest);
    defineReflectiveTests(SubstituteFromPairsTest);
    defineReflectiveTests(SubstituteFromUpperAndLowerBoundsTest);
    defineReflectiveTests(SubstituteTest);
  });
}

@reflectiveTest
class SubstituteEmptyTest extends DriverResolutionTest {
  test_interface() async {
    addTestFile(r'''
class A<T> {}
''');
    await resolveTestFile();

    var type = findElement.class_('A').type;
    var result = Substitution.empty.substituteType(type);
    expect(result, same(type));
  }
}

@reflectiveTest
class SubstituteFromInterfaceTypeTest extends _Base {
  test_interface() async {
    addTestFile(r'''
class A<T> {}
class B<U> extends A<U> {}
''');
    await resolveTestFile();

    var a = findElement.class_('A');
    var b = findElement.class_('B');
    var u = b.typeParameters.single;

    var bType = _instantiate(b, [intType]);
    var substitution = Substitution.fromInterfaceType(bType);

    // `extends A<U>`
    var type = _instantiate(a, [u.type]);
    assertElementTypeString(type, 'A<U>');

    var result = substitution.substituteType(type);
    assertElementTypeString(result, 'A<int>');
  }
}

@reflectiveTest
class SubstituteFromPairsTest extends DriverResolutionTest {
  test_interface() async {
    addTestFile(r'''
class A<T, U> {}
''');
    await resolveTestFile();

    var a = findElement.class_('A');
    var result = Substitution.fromPairs(
      a.typeParameters,
      [intType, doubleType],
    ).substituteType(a.type);
    assertElementTypeString(result, 'A<int, double>');
  }
}

@reflectiveTest
class SubstituteFromUpperAndLowerBoundsTest extends DriverResolutionTest {
  test_function() async {
    addTestFile(r'''
typedef F<T> = T Function(T);
''');
    await resolveTestFile();

    var type = findElement.genericTypeAlias('F').function.type;
    var t = findElement.typeParameter('T');

    var result = Substitution.fromUpperAndLowerBounds(
      {t: intType},
      {t: BottomTypeImpl.instance},
    ).substituteType(type);
    assertElementTypeString(result, 'int Function(Never)');
  }
}

@reflectiveTest
class SubstituteTest extends _Base {
  test_bottom() async {
    addTestFile(r'''
class A<T> {}
''');
    await resolveTestFile();

    var t = findElement.typeParameter('T');
    _assertIdenticalType(typeProvider.bottomType, {t: intType});
  }

  test_dynamic() async {
    addTestFile(r'''
class A<T> {}
''');
    await resolveTestFile();

    var t = findElement.typeParameter('T');
    _assertIdenticalType(typeProvider.dynamicType, {t: intType});
  }

  test_function_noTypeParameters() async {
    addTestFile(r'''
typedef F = bool Function(int);
class B<T> {}
''');
    await resolveTestFile();

    var type = findElement.genericTypeAlias('F').function.type;
    var t = findElement.typeParameter('T');
    _assertIdenticalType(type, {t: intType});
  }

  test_function_typeFormals() async {
    addTestFile(r'''
typedef F<T> = T Function<U extends T>(U);
''');
    await resolveTestFile();

    var type = findElement.genericTypeAlias('F').function.type;
    var t = findElement.typeParameter('T');
    assertElementTypeString(type, 'T Function<U extends T>(U)');
    _assertSubstitution(
      type,
      {t: intType},
      'int Function<U extends int>(U)',
    );
  }

  test_function_typeParameters() async {
    addTestFile(r'''
typedef F<T, U> = T Function(U u, bool);
''');
    await resolveTestFile();

    var type = findElement.genericTypeAlias('F').function.type;
    var t = findElement.typeParameter('T');
    var u = findElement.typeParameter('U');
    assertElementTypeString(type, 'T Function(U, bool)');
    _assertSubstitution(
      type,
      {t: intType},
      'int Function(U, bool)',
    );
    _assertSubstitution(
      type,
      {t: intType, u: doubleType},
      'int Function(double, bool)',
    );
  }

  test_interface_arguments() async {
    addTestFile(r'''
class A<T> {}
class B<U> {}
''');
    await resolveTestFile();

    var a = findElement.class_('A');
    var u = findElement.typeParameter('U');
    var uType = new TypeParameterTypeImpl(u);

    var type = _instantiate(a, [uType]);
    assertElementTypeString(type, 'A<U>');
    _assertSubstitution(type, {u: intType}, 'A<int>');
  }

  test_interface_arguments_deep() async {
    addTestFile(r'''
class A<T> {}
class B<U> {}
''');
    await resolveTestFile();

    var a = findElement.class_('A');
    var u = findElement.typeParameter('U');
    var uType = new TypeParameterTypeImpl(u);

    var type = _instantiate(a, [
      _instantiate(listElement, [uType])
    ]);
    assertElementTypeString(type, 'A<List<U>>');
    _assertSubstitution(type, {u: intType}, 'A<List<int>>');
  }

  test_interface_noArguments() async {
    addTestFile(r'''
class A {}
class B<T> {}
''');
    await resolveTestFile();

    var a = findElement.class_('A');
    var t = findElement.typeParameter('T');
    _assertIdenticalType(a.type, {t: intType});
  }

  test_interface_noArguments_inArguments() async {
    addTestFile(r'''
class A<T> {}
class B<U> {}
''');
    await resolveTestFile();

    var a = findElement.class_('A');
    var u = findElement.typeParameter('U');
    _assertIdenticalType(
      _instantiate(a, [intType]),
      {u: doubleType},
    );
  }

  test_void() async {
    addTestFile(r'''
class A<T> {}
''');
    await resolveTestFile();

    var t = findElement.typeParameter('T');
    _assertIdenticalType(voidType, {t: intType});
  }

  test_void_emptyMap() async {
    addTestFile('');
    await resolveTestFile();
    _assertIdenticalType(voidType, {});
  }

  void _assertIdenticalType(
      DartType type, Map<TypeParameterElement, DartType> substitution) {
    var result = substitute(type, substitution);
    expect(result, same(type));
  }

  void _assertSubstitution(
    DartType type,
    Map<TypeParameterElement, DartType> substitution,
    String expected,
  ) {
    var result = substitute(type, substitution);
    assertElementTypeString(result, expected);
  }
}

class _Base extends DriverResolutionTest {
  /// Intentionally low-level implementation for creating [InterfaceType]
  /// for [ClassElement] and type arguments. We just create it explicitly,
  /// without using `InterfaceType.instantiate()`.
  InterfaceType _instantiate(ClassElement element, List<DartType> arguments) {
    return new InterfaceTypeImpl(element)..typeArguments = arguments;
  }
}
