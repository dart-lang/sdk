// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/class_hierarchy.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/test_utilities/test_library_builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassHierarchyTest);
  });
}

@reflectiveTest
class ClassHierarchyTest extends AbstractTypeSystemTest {
  test_invalid() {
    _checkA(
      specifiedInterfaces: ['A<int>', 'A<double>'],
      interfaces: ['A<int>'],
      errors: ['A<int> vs. A<double>'],
    );
  }

  test_valid_equal() {
    _checkA(specifiedInterfaces: ['A<int>', 'A<int>'], interfaces: ['A<int>']);
  }

  test_valid_equal_neverNone() {
    _checkA(
      specifiedInterfaces: ['A<Never>', 'A<Never>'],
      interfaces: ['A<Never>'],
    );
  }

  test_valid_merge() {
    _checkA(
      specifiedInterfaces: ['A<Object?>', 'A<dynamic>'],
      interfaces: ['A<Object?>'],
    );
  }

  void _assertErrors(List<ClassHierarchyError> errors, List<String> expected) {
    expect(
      errors.map((e) {
        if (e is IncompatibleInterfacesClassHierarchyError) {
          var firstStr = _interfaceString(e.first);
          var secondStr = _interfaceString(e.second);
          return '$firstStr vs. $secondStr';
        } else {
          throw UnimplementedError('${e.runtimeType}');
        }
      }).toList(),
      unorderedEquals(expected),
    );
  }

  void _assertInterfaces(
    List<InterfaceType> interfaces,
    List<String> expected,
  ) {
    var interfacesStr = interfaces.map(_interfaceString).toList();
    expect(interfacesStr, unorderedEquals(['Object', ...expected]));
  }

  void _checkA({
    required List<String> specifiedInterfaces,
    required List<String> interfaces,
    List<String> errors = const [],
  }) {
    var library = buildTestLibrary(
      classes: [
        ClassSpec('class A<T> extends Object'),
        ClassSpec(
          'class X extends Object implements ${specifiedInterfaces.join(', ')}',
        ),
      ],
    );
    var X = library.getClass('X')!;

    var classHierarchy = ClassHierarchy();

    var actualInterfaces = classHierarchy.implementedInterfaces(X);
    _assertInterfaces(actualInterfaces, interfaces);

    var actualErrors = classHierarchy.errors(X);
    _assertErrors(actualErrors, errors);
  }

  String _interfaceString(InterfaceType interface) {
    return (interface as InterfaceTypeImpl)
        .withNullability(NullabilitySuffix.none)
        .getDisplayString();
  }
}
