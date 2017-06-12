// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/type_inference/type_schema.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/visitor.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnknownTypeTest);
  });
}

typedef U _UnaryFunction<T, U>(T t);

@reflectiveTest
class UnknownTypeTest {
  static const unknownType = const UnknownType();

  void test_equality() {
    expect(unknownType, equals(unknownType));
    expect(unknownType, equals(new UnknownType()));
    expect(unknownType, isNot(equals(const DynamicType())));
  }

  void test_isKnown() {
    expect(isKnown(unknownType), isFalse);
    expect(isKnown(const DynamicType()), isTrue);
    var classA = new Class(name: 'A');
    var A = new InterfaceType(classA);
    var typedefF = new Typedef('F', A);
    expect(isKnown(A), isTrue);
    expect(isKnown(new InterfaceType(classA, [A])), isTrue);
    expect(isKnown(new InterfaceType(classA, [unknownType])), isFalse);
    expect(isKnown(new FunctionType([], const VoidType())), isTrue);
    expect(isKnown(new FunctionType([], unknownType)), isFalse);
    expect(isKnown(new FunctionType([A], const VoidType())), isTrue);
    expect(isKnown(new FunctionType([unknownType], const VoidType())), isFalse);
    expect(
        isKnown(new FunctionType([], const VoidType(),
            namedParameters: [new NamedType('x', A)])),
        isTrue);
    expect(
        isKnown(new FunctionType([], const VoidType(),
            namedParameters: [new NamedType('x', unknownType)])),
        isFalse);
    expect(isKnown(new TypedefType(typedefF)), isTrue);
    expect(isKnown(new TypedefType(typedefF, [A])), isTrue);
    expect(isKnown(new TypedefType(typedefF, [unknownType])), isFalse);
  }

  void test_ordinary_visitor_noOverrides() {
    expect(unknownType.accept(new _OrdinaryVisitor()), isNull);
  }

  void test_ordinary_visitor_overrideDefault() {
    expect(unknownType
        .accept(new _OrdinaryVisitor<String>(defaultDartType: (DartType node) {
      expect(node, same(unknownType));
      return 'defaultDartType';
    })), 'defaultDartType');
  }

  void test_type_schema_visitor_noOverrides() {
    expect(unknownType.accept(new _TypeSchemaVisitor()), isNull);
  }

  void test_type_schema_visitor_overrideDefault() {
    expect(unknownType.accept(
        new _TypeSchemaVisitor<String>(defaultDartType: (DartType node) {
      expect(node, same(unknownType));
      return 'defaultDartType';
    })), 'defaultDartType');
  }

  void test_type_schema_visitor_overrideVisitUnknownType() {
    expect(unknownType.accept(
        new _TypeSchemaVisitor<String>(visitUnknownType: (UnknownType node) {
      expect(node, same(unknownType));
      return 'visitUnknownType';
    })), 'visitUnknownType');
  }

  void test_typeSchemaToString() {
    expect(unknownType.toString(), isNot('?'));
    expect(typeSchemaToString(unknownType), '?');
    expect(
        typeSchemaToString(
            new FunctionType([unknownType, unknownType], unknownType)),
        '(?, ?) → ?');
  }

  void test_visitChildren() {
    unknownType
        .visitChildren(new _TypeSchemaVisitor(defaultDartType: (DartType node) {
      fail('Should not have visited anything');
    }));
  }
}

class _OrdinaryVisitor<R> extends Visitor<R> {
  final _UnaryFunction<DartType, R> _defaultDartType;

  _OrdinaryVisitor({_UnaryFunction<DartType, R> defaultDartType})
      : _defaultDartType = defaultDartType;

  @override
  R defaultDartType(DartType node) {
    if (_defaultDartType != null) {
      return _defaultDartType(node);
    } else {
      return super.defaultDartType(node);
    }
  }
}

class _TypeSchemaVisitor<R> extends Visitor<R> implements TypeSchemaVisitor<R> {
  final _UnaryFunction<DartType, R> _defaultDartType;
  final _UnaryFunction<UnknownType, R> _visitUnknownType;

  _TypeSchemaVisitor(
      {_UnaryFunction<DartType, R> defaultDartType,
      _UnaryFunction<UnknownType, R> visitUnknownType})
      : _defaultDartType = defaultDartType,
        _visitUnknownType = visitUnknownType;

  @override
  R defaultDartType(DartType node) {
    if (_defaultDartType != null) {
      return _defaultDartType(node);
    } else {
      return super.defaultDartType(node);
    }
  }

  @override
  R visitUnknownType(UnknownType node) {
    if (_visitUnknownType != null) {
      return _visitUnknownType(node);
    } else {
      return defaultDartType(node);
    }
  }
}
