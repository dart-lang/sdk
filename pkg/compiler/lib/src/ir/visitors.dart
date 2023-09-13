// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../constants/constant_system.dart' as constant_system;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../ir/element_map.dart';
import 'util.dart' show recordShapeOfRecordType;

/// Visitor that converts string literals and concatenations of string literals
/// into the string value.
class Stringifier extends ir.ExpressionVisitor<String?> {
  @override
  String visitStringLiteral(ir.StringLiteral node) => node.value;

  @override
  String? visitStringConcatenation(ir.StringConcatenation node) {
    StringBuffer sb = StringBuffer();
    for (ir.Expression expression in node.expressions) {
      String? value = expression.accept(this);
      if (value == null) return null;
      sb.write(value);
    }
    return sb.toString();
  }

  @override
  String? visitConstantExpression(ir.ConstantExpression node) {
    ir.Constant constant = node.constant;
    if (constant is ir.StringConstant) {
      return constant.value;
    }
    return null;
  }

  @override
  String? defaultExpression(ir.Expression node) => null;
}

/// Visitor that converts kernel dart types into [DartType].
class DartTypeConverter extends ir.DartTypeVisitor<DartType> {
  final IrToElementMap elementMap;
  final Map<ir.TypeParameter, DartType> currentFunctionTypeParameters =
      <ir.TypeParameter, DartType>{};

  DartTypeConverter(this.elementMap);

  DartTypes get _dartTypes => elementMap.commonElements.dartTypes;

  DartType _convertNullability(
      DartType baseType, ir.DartType nullabilitySource) {
    final nullability = nullabilitySource.nullability;
    switch (nullability) {
      case ir.Nullability.nonNullable:
        return baseType;
      case ir.Nullability.nullable:
        return _dartTypes.nullableType(baseType);
      case ir.Nullability.legacy:
        return _dartTypes.legacyType(baseType);
      case ir.Nullability.undetermined:
        // Type parameters may have undetermined nullability since it is derived
        // from the intersection of the declared nullability with the
        // nullability of the bound. We don't need a nullability wrapper in this
        // case.
        if (nullabilitySource is ir.TypeParameterType) return baseType;

        // Iff `T` has undetermined nullability, then so will `FutureOr<T>`
        // since it's the union of `T`, which has undetermined nullability, and
        // `Future<T>`, which does not. We can treat the `Future`/`FutureOr` as
        // non-nullable and rely on the conversion of the type argument to
        // produce the right nullability.
        if (nullabilitySource is ir.FutureOrType &&
            nullabilitySource.typeArgument.nullability ==
                ir.Nullability.undetermined) {
          return baseType;
        }

        throw UnsupportedError(
            'Undetermined nullability on $nullabilitySource');
    }
  }

  DartType visitType(ir.DartType type) {
    return type.accept(this);
  }

  InterfaceType visitSupertype(ir.Supertype node) =>
      visitInterfaceType(node.asInterfaceType).withoutNullability
          as InterfaceType;

  List<DartType> visitTypes(List<ir.DartType> types) {
    return List.generate(
        types.length, (int index) => types[index].accept(this));
  }

  @override
  DartType visitTypeParameterType(ir.TypeParameterType node) {
    DartType? typeParameter = currentFunctionTypeParameters[node.parameter];
    if (typeParameter != null) {
      return _convertNullability(typeParameter, node);
    }
    if (node.parameter.declaration is ir.Typedef) {
      // Typedefs are only used in type literals so we never need their type
      // variables.
      return _dartTypes.dynamicType();
    }
    return _convertNullability(
        _dartTypes.typeVariableType(elementMap.getTypeVariable(node.parameter)),
        node);
  }

  @override
  DartType visitIntersectionType(ir.IntersectionType node) {
    return node.left.accept(this);
  }

  @override
  DartType visitFunctionType(ir.FunctionType node) {
    int index = 0;
    List<FunctionTypeVariable>? typeVariables;
    for (ir.TypeParameter typeParameter in node.typeParameters) {
      FunctionTypeVariable typeVariable =
          _dartTypes.functionTypeVariable(index);
      currentFunctionTypeParameters[typeParameter] = typeVariable;
      typeVariables ??= <FunctionTypeVariable>[];
      typeVariables.add(typeVariable);
      index++;
    }
    if (typeVariables != null) {
      for (int index = 0; index < typeVariables.length; index++) {
        typeVariables[index].bound =
            node.typeParameters[index].bound.accept(this);
      }
    }

    FunctionType functionType = _dartTypes.functionType(
        visitType(node.returnType),
        visitTypes(node.positionalParameters
            .take(node.requiredParameterCount)
            .toList()),
        visitTypes(node.positionalParameters
            .skip(node.requiredParameterCount)
            .toList()),
        node.namedParameters.map((n) => n.name).toList(),
        node.namedParameters
            .where((n) => n.isRequired)
            .map((n) => n.name)
            .toSet(),
        node.namedParameters.map((n) => visitType(n.type)).toList(),
        typeVariables ?? const <FunctionTypeVariable>[]);
    DartType type = _convertNullability(functionType, node);
    for (ir.TypeParameter typeParameter in node.typeParameters) {
      currentFunctionTypeParameters.remove(typeParameter);
    }
    return type;
  }

  @override
  DartType visitInterfaceType(ir.InterfaceType node) {
    ClassEntity cls = elementMap.getClass(node.classNode);
    return _convertNullability(
        _dartTypes.interfaceType(cls, visitTypes(node.typeArguments)), node);
  }

  @override
  DartType visitRecordType(ir.RecordType node) {
    final shape = recordShapeOfRecordType(node);
    List<DartType> fields = [
      for (final type in node.positional) visitType(type),
      for (final namedType in node.named) visitType(namedType.type)
    ].toList(growable: false);
    return _convertNullability(_dartTypes.recordType(shape, fields), node);
  }

  @override
  DartType visitFutureOrType(ir.FutureOrType node) {
    return _convertNullability(
        _dartTypes.futureOrType(visitType(node.typeArgument)), node);
  }

  @override
  DartType visitVoidType(ir.VoidType node) {
    return _dartTypes.voidType();
  }

  @override
  DartType visitDynamicType(ir.DynamicType node) {
    return _dartTypes.dynamicType();
  }

  @override
  DartType visitInvalidType(ir.InvalidType node) {
    // Root uses such a `o is Unresolved` and `o as Unresolved` must be special
    // cased in the builder, nested invalid types are treated as `dynamic`.
    return _dartTypes.dynamicType();
  }

  @override
  DartType visitNeverType(ir.NeverType node) {
    return _convertNullability(_dartTypes.neverType(), node);
  }

  @override
  DartType visitNullType(ir.NullType node) {
    return elementMap.commonElements.nullType;
  }

  @override
  DartType visitExtensionType(ir.ExtensionType node) {
    return node.typeErasure.accept(this);
  }

  @override
  DartType defaultDartType(ir.DartType node) {
    throw UnsupportedError('Unsupported type $node (${node.runtimeType})');
  }

  @override
  DartType visitTypedefType(ir.TypedefType node) {
    throw UnsupportedError('Unsupported type $node (${node.runtimeType})');
  }
}

// TODO(fishythefish): Remove default mixin.
class ConstantValuefier extends ir.ComputeOnceConstantVisitor<ConstantValue>
    with ir.OnceConstantVisitorDefaultMixin<ConstantValue> {
  final IrToElementMap elementMap;

  ConstantValuefier(this.elementMap);

  DartTypes get _dartTypes => elementMap.commonElements.dartTypes;

  @override
  ConstantValue defaultConstant(ir.Constant node) {
    throw UnsupportedError("Unexpected constant $node (${node.runtimeType}).");
  }

  @override
  ConstantValue visitUnevaluatedConstant(ir.UnevaluatedConstant node) {
    throw UnsupportedError("Unexpected unevaluated constant $node.");
  }

  @override
  ConstantValue visitTypeLiteralConstant(ir.TypeLiteralConstant node) {
    DartType type = _dartTypes.eraseLegacy(elementMap.getDartType(node.type));
    return constant_system.createType(elementMap.commonElements, type);
  }

  @override
  ConstantValue visitStaticTearOffConstant(ir.StaticTearOffConstant node) {
    ir.Procedure member = node.target;
    FunctionEntity function = elementMap.getMethod(member);
    final type = elementMap.getFunctionType(member.function);
    return FunctionConstantValue(function, type);
  }

  @override
  ConstantValue visitInstantiationConstant(ir.InstantiationConstant node) {
    List<DartType> typeArguments = [];
    for (ir.DartType type in node.types) {
      typeArguments.add(elementMap.getDartType(type));
    }
    final function =
        visitConstant(node.tearOffConstant) as FunctionConstantValue;
    return InstantiationConstantValue(typeArguments, function);
  }

  @override
  ConstantValue visitInstanceConstant(ir.InstanceConstant node) {
    InterfaceType type =
        elementMap.createInterfaceType(node.classNode, node.typeArguments);
    Map<FieldEntity, ConstantValue> fields = {};
    node.fieldValues.forEach((ir.Reference reference, ir.Constant value) {
      FieldEntity field = elementMap.getField(reference.asField);
      fields[field] = visitConstant(value);
    });
    return ConstructedConstantValue(type, fields);
  }

  @override
  ConstantValue visitListConstant(ir.ListConstant node) {
    List<ConstantValue> elements = [];
    for (ir.Constant element in node.entries) {
      elements.add(visitConstant(element));
    }
    final type = elementMap.commonElements
        .listType(elementMap.getDartType(node.typeArgument));
    return constant_system.createList(
        elementMap.commonElements, type, elements);
  }

  @override
  ConstantValue visitSetConstant(ir.SetConstant node) {
    List<ConstantValue> elements = [];
    for (ir.Constant element in node.entries) {
      elements.add(visitConstant(element));
    }
    final type = elementMap.commonElements
        .setType(elementMap.getDartType(node.typeArgument));
    return constant_system.createSet(elementMap.commonElements, type, elements);
  }

  @override
  ConstantValue visitMapConstant(ir.MapConstant node) {
    List<ConstantValue> keys = [];
    List<ConstantValue> values = [];
    for (ir.ConstantMapEntry element in node.entries) {
      keys.add(visitConstant(element.key));
      values.add(visitConstant(element.value));
    }
    final type = elementMap.commonElements.mapType(
        elementMap.getDartType(node.keyType),
        elementMap.getDartType(node.valueType));
    return constant_system.createMap(
        elementMap.commonElements, type, keys, values);
  }

  @override
  ConstantValue visitRecordConstant(ir.RecordConstant node) {
    final shape = recordShapeOfRecordType(node.recordType);
    final fieldValues = [
      for (final value in node.positional) visitConstant(value),
      for (final value in node.named.values) visitConstant(value)
    ];
    return RecordConstantValue(shape, fieldValues);
  }

  @override
  ConstantValue visitSymbolConstant(ir.SymbolConstant node) {
    return constant_system.createSymbol(elementMap.commonElements, node.name);
  }

  @override
  ConstantValue visitStringConstant(ir.StringConstant node) {
    return constant_system.createString(node.value);
  }

  @override
  ConstantValue visitDoubleConstant(ir.DoubleConstant node) {
    return constant_system.createDouble(node.value);
  }

  @override
  ConstantValue visitIntConstant(ir.IntConstant node) {
    return constant_system.createIntFromInt(node.value);
  }

  @override
  ConstantValue visitBoolConstant(ir.BoolConstant node) {
    return constant_system.createBool(node.value);
  }

  @override
  ConstantValue visitNullConstant(ir.NullConstant node) {
    return constant_system.createNull();
  }
}
