// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/type_inference/type_schema.dart';
import 'package:kernel/ast.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
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
    var classA = new Class(name: 'A', fileUri: dummyUri);
    var A = new InterfaceType(classA, Nullability.nonNullable);
    var typedefF = new Typedef('F', A, fileUri: dummyUri);
    expect(isKnown(A), isTrue);
    expect(
      isKnown(new InterfaceType(classA, Nullability.nonNullable, [A])),
      isTrue,
    );
    expect(
      isKnown(
        new InterfaceType(classA, Nullability.nonNullable, [unknownType]),
      ),
      isFalse,
    );
    expect(
      isKnown(new FunctionType([], const VoidType(), Nullability.nonNullable)),
      isTrue,
    );
    expect(
      isKnown(new FunctionType([], unknownType, Nullability.nonNullable)),
      isFalse,
    );
    expect(
      isKnown(new FunctionType([A], const VoidType(), Nullability.nonNullable)),
      isTrue,
    );
    expect(
      isKnown(
        new FunctionType(
          [unknownType],
          const VoidType(),
          Nullability.nonNullable,
        ),
      ),
      isFalse,
    );
    expect(
      isKnown(
        new FunctionType(
          [],
          const VoidType(),
          Nullability.nonNullable,
          namedParameters: [new NamedType('x', A)],
        ),
      ),
      isTrue,
    );
    expect(
      isKnown(
        new FunctionType(
          [],
          const VoidType(),
          Nullability.nonNullable,
          namedParameters: [new NamedType('x', unknownType)],
        ),
      ),
      isFalse,
    );
    expect(isKnown(new TypedefType(typedefF, Nullability.nonNullable)), isTrue);
    expect(
      isKnown(new TypedefType(typedefF, Nullability.nonNullable, [A])),
      isTrue,
    );
    expect(
      isKnown(
        new TypedefType(typedefF, Nullability.nonNullable, [unknownType]),
      ),
      isFalse,
    );
  }

  void test_ordinary_visitor_noOverrides() {
    expect(unknownType.accept(new _OrdinaryVisitor()), isNull);
  }

  void test_ordinary_visitor_overrideDefault() {
    expect(
      unknownType.accept(
        new _OrdinaryVisitor<String>(
          defaultDartType: (DartType node) {
            expect(node, same(unknownType));
            return 'defaultDartType';
          },
        ),
      ),
      'defaultDartType',
    );
  }

  void test_type_schema_visitor_noOverrides() {
    expect(unknownType.accept(new _TypeSchemaVisitor()), isNull);
  }

  void test_type_schema_visitor_overrideDefault() {
    expect(
      unknownType.accept(
        new _TypeSchemaVisitor<String>(
          defaultDartType: (DartType node) {
            expect(node, same(unknownType));
            return 'defaultDartType';
          },
        ),
      ),
      'defaultDartType',
    );
  }

  void test_type_schema_visitor_overrideVisitUnknownType() {
    expect(
      unknownType.accept(
        new _TypeSchemaVisitor<String>(
          visitUnknownType: (UnknownType node) {
            expect(node, same(unknownType));
            return 'visitUnknownType';
          },
        ),
      ),
      'visitUnknownType',
    );
  }

  void test_typeSchemaToString() {
    expect(unknownType.toString(), isNot('?'));
    expect(typeSchemaToString(unknownType), '?');
    expect(
      typeSchemaToString(
        new FunctionType(
          [unknownType, unknownType],
          unknownType,
          Nullability.nonNullable,
        ),
      ),
      '(?, ?) → ?',
    );
  }

  void test_visitChildren() {
    unknownType.visitChildren(
      new _TypeSchemaVisitor(
        defaultDartType: (DartType node) {
          fail('Should not have visited anything');
        },
      ),
    );
  }
}

class _OrdinaryVisitor<R> extends VisitorDefault<R?> with VisitorNullMixin<R> {
  final _UnaryFunction<DartType, R>? _defaultDartType;

  _OrdinaryVisitor({_UnaryFunction<DartType, R>? defaultDartType})
    : _defaultDartType = defaultDartType;

  @override
  R? defaultDartType(DartType node) {
    if (_defaultDartType != null) {
      return _defaultDartType(node);
    } else {
      return super.defaultDartType(node);
    }
  }
}

class _TypeSchemaVisitor<R> extends VisitorDefault<R?>
    with VisitorNullMixin<R> {
  final _UnaryFunction<DartType, R>? _defaultDartType;
  final _UnaryFunction<UnknownType, R>? _visitUnknownType;

  _TypeSchemaVisitor({
    _UnaryFunction<DartType, R>? defaultDartType,
    _UnaryFunction<UnknownType, R>? visitUnknownType,
  }) : _defaultDartType = defaultDartType,
       _visitUnknownType = visitUnknownType;

  @override
  R? defaultDartType(DartType node) {
    if (node is UnknownType && _visitUnknownType != null) {
      return _visitUnknownType(node);
    } else if (_defaultDartType != null) {
      return _defaultDartType(node);
    } else {
      return super.defaultDartType(node);
    }
  }
}
