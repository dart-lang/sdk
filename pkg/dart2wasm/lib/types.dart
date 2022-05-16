// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart2wasm/class_info.dart';
import 'package:dart2wasm/code_generator.dart';
import 'package:dart2wasm/translator.dart';

import 'package:kernel/ast.dart';

import 'package:wasm_builder/wasm_builder.dart' as w;

/// Helper class for building runtime types.
class Types {
  final Translator translator;
  late final typeClassInfo = translator.classInfo[translator.typeClass]!;
  late final w.ValueType typeListExpectedType = classAndFieldToType(
      translator.interfaceTypeClass, FieldIndex.interfaceTypeTypeArguments);
  late final w.ValueType namedParametersExpectedType = classAndFieldToType(
      translator.functionTypeClass, FieldIndex.functionTypeNamedParameters);

  Types(this.translator);

  w.ValueType classAndFieldToType(Class cls, int fieldIndex) =>
      translator.classInfo[cls]!.struct.fields[fieldIndex].type.unpacked;

  Iterable<Class> _getConcreteSubtypes(Class cls) =>
      translator.subtypes.getSubtypesOf(cls).where((c) => !c.isAbstract);

  w.ValueType get nullableTypeType => typeClassInfo.nullableType;

  w.ValueType get nonNullableTypeType => typeClassInfo.nonNullableType;

  InterfaceType get namedParameterType =>
      InterfaceType(translator.namedParameterClass, Nullability.nonNullable);

  /// Build a [Map<int, List<int>>] to store subtype information.
  Map<int, List<int>> _buildSubtypeMap() {
    List<ClassInfo> classes = translator.classes;
    Map<int, List<int>> subtypeMap = {};
    for (ClassInfo classInfo in classes) {
      if (classInfo.cls == null) continue;
      List<int> classIds = _getConcreteSubtypes(classInfo.cls!)
          .map((cls) => translator.classInfo[cls]!.classId)
          .where((classId) => classId != classInfo.classId)
          .toList();

      if (classIds.isEmpty) continue;
      subtypeMap[classInfo.classId] = classIds;
    }
    return subtypeMap;
  }

  /// Builds the subtype map and pushes it onto the stack.
  w.ValueType makeSubtypeMap(w.Instructions b) {
    // Instantiate subtype map constant.
    Map<int, List<int>> subtypeMap = _buildSubtypeMap();
    ClassInfo immutableMapInfo =
        translator.classInfo[translator.immutableMapClass]!;
    w.ValueType expectedType = immutableMapInfo.nonNullableType;
    DartType mapAndSetKeyType = translator.coreTypes.intNonNullableRawType;
    DartType mapValueType = InterfaceType(translator.immutableListClass,
        Nullability.nonNullable, [mapAndSetKeyType]);
    List<ConstantMapEntry> entries = subtypeMap.entries.map((mapEntry) {
      return ConstantMapEntry(
          IntConstant(mapEntry.key),
          ListConstant(mapAndSetKeyType,
              mapEntry.value.map((i) => IntConstant(i)).toList()));
    }).toList();
    translator.constants.instantiateConstant(null, b,
        MapConstant(mapAndSetKeyType, mapValueType, entries), expectedType);
    return expectedType;
  }

  bool isGenericFunction(FunctionType type) => type.typeParameters.isNotEmpty;

  bool _isTypeConstant(DartType type) {
    return type is DynamicType ||
        type is VoidType ||
        type is NeverType ||
        type is NullType ||
        type is FutureOrType && _isTypeConstant(type.typeArgument) ||
        (type is FunctionType &&
            type.typeParameters.isEmpty && // TODO(joshualitt) generic functions
            _isTypeConstant(type.returnType) &&
            type.positionalParameters.every(_isTypeConstant) &&
            type.namedParameters.every((n) => _isTypeConstant(n.type))) ||
        type is InterfaceType && type.typeArguments.every(_isTypeConstant);
  }

  Class classForType(DartType type) {
    if (type is DynamicType) {
      return translator.dynamicTypeClass;
    } else if (type is VoidType) {
      return translator.voidTypeClass;
    } else if (type is NeverType) {
      // For runtime types with sound null safety, `Never?` is the same as
      // `Null`.
      if (type.nullability == Nullability.nullable) {
        return translator.nullTypeClass;
      } else {
        return translator.neverTypeClass;
      }
    } else if (type is NullType) {
      return translator.nullTypeClass;
    } else if (type is FutureOrType) {
      return translator.futureOrTypeClass;
    } else if (type is InterfaceType) {
      return translator.interfaceTypeClass;
    } else if (type is FunctionType) {
      if (isGenericFunction(type)) {
        return translator.genericFunctionTypeClass;
      } else {
        return translator.functionTypeClass;
      }
    }
    throw "Unexpected DartType: $type";
  }

  void _makeTypeList(
      CodeGenerator codeGen, List<DartType> types, TreeNode node) {
    w.ValueType listType = codeGen.makeList(
        types.map((t) => TypeLiteral(t)).toList(),
        translator.fixedLengthListClass,
        InterfaceType(translator.typeClass, Nullability.nonNullable),
        node);
    translator.convertType(codeGen.function, listType, typeListExpectedType);
  }

  void _makeInterfaceType(CodeGenerator codeGen, ClassInfo info,
      InterfaceType type, TreeNode node) {
    w.Instructions b = codeGen.b;
    ClassInfo typeInfo = translator.classInfo[type.classNode]!;
    encodeNullability(b, type);
    b.i64_const(typeInfo.classId);
    _makeTypeList(codeGen, type.typeArguments, node);
  }

  void _makeFutureOrType(
      CodeGenerator codeGen, FutureOrType type, TreeNode node) {
    w.Instructions b = codeGen.b;
    w.DefinedFunction function = codeGen.function;

    // We canonicalize `FutureOr<T?>` to `FutureOr<T?>?`. However, we have to
    // take special care to handle the case where we have
    // undetermined nullability. To handle this, we emit the type argument, and
    // read back its nullability at runtime.
    if (type.nullability == Nullability.undetermined) {
      w.ValueType typeArgumentType = makeType(codeGen, type.typeArgument, node);
      w.Local typeArgumentTemporary = codeGen.addLocal(typeArgumentType);
      b.local_tee(typeArgumentTemporary);
      b.struct_get(typeClassInfo.struct, FieldIndex.typeIsNullable);
      b.local_get(typeArgumentTemporary);
      translator.convertType(function, typeArgumentType, nonNullableTypeType);
    } else {
      encodeNullability(b, type);
      makeType(codeGen, type.typeArgument, node);
    }
  }

  void _makeFunctionType(
      CodeGenerator codeGen, ClassInfo info, FunctionType type, TreeNode node) {
    w.Instructions b = codeGen.b;
    encodeNullability(b, type);
    makeType(codeGen, type.returnType, node);
    if (type.positionalParameters.every(_isTypeConstant)) {
      translator.constants.instantiateConstant(
          codeGen.function,
          b,
          translator.constants.makeTypeList(type.positionalParameters),
          typeListExpectedType);
    } else {
      _makeTypeList(codeGen, type.positionalParameters, node);
    }
    b.i64_const(type.requiredParameterCount);
    if (type.namedParameters.every((n) => _isTypeConstant(n.type))) {
      translator.constants.instantiateConstant(
          codeGen.function,
          b,
          translator.constants.makeNamedParametersList(type),
          namedParametersExpectedType);
    } else {
      Class namedParameterClass = translator.namedParameterClass;
      Constructor namedParameterConstructor =
          namedParameterClass.constructors.single;
      List<Expression> expressions = [];
      for (NamedType n in type.namedParameters) {
        expressions.add(_isTypeConstant(n.type)
            ? ConstantExpression(
                translator.constants.makeNamedParameterConstant(n),
                namedParameterType)
            : ConstructorInvocation(
                namedParameterConstructor,
                Arguments([
                  StringLiteral(n.name),
                  TypeLiteral(n.type),
                  BoolLiteral(n.isRequired)
                ])));
      }
      w.ValueType namedParametersListType = codeGen.makeList(expressions,
          translator.fixedLengthListClass, namedParameterType, node);
      translator.convertType(codeGen.function, namedParametersListType,
          namedParametersExpectedType);
    }
  }

  /// Makes a `_Type` object on the stack.
  /// TODO(joshualitt): Refactor this logic to remove the dependency on
  /// CodeGenerator.
  w.ValueType makeType(CodeGenerator codeGen, DartType type, TreeNode node) {
    w.Instructions b = codeGen.b;
    if (_isTypeConstant(type)) {
      translator.constants.instantiateConstant(
          codeGen.function, b, TypeLiteralConstant(type), nonNullableTypeType);
      return nonNullableTypeType;
    }
    // All of the singleton types represented by canonical objects should be
    // created const.
    assert(type is TypeParameterType ||
        type is InterfaceType ||
        type is FutureOrType ||
        type is FunctionType);
    if (type is TypeParameterType) {
      if (type.parameter.parent is FunctionNode) {
        // Type argument to function
        w.Local? local = codeGen.typeLocals[type.parameter];
        if (local != null) {
          b.local_get(local);
          translator.convertType(
              codeGen.function, local.type, nonNullableTypeType);
          return nonNullableTypeType;
        } else {
          codeGen.unimplemented(node, "Type parameter access inside lambda",
              [nonNullableTypeType]);
          return nonNullableTypeType;
        }
      }
      // Type argument of class
      Class cls = type.parameter.parent as Class;
      ClassInfo info = translator.classInfo[cls]!;
      int fieldIndex = translator.typeParameterIndex[type.parameter]!;
      w.ValueType thisType = codeGen.visitThis(info.nonNullableType);
      translator.convertType(codeGen.function, thisType, info.nonNullableType);
      b.struct_get(info.struct, fieldIndex);
      b.ref_as_non_null();
      return nonNullableTypeType;
    }
    ClassInfo info = translator.classInfo[classForType(type)]!;
    translator.functions.allocateClass(info.classId);
    b.i32_const(info.classId);
    b.i32_const(initialIdentityHash);
    if (type is InterfaceType) {
      _makeInterfaceType(codeGen, info, type, node);
    } else if (type is FutureOrType) {
      _makeFutureOrType(codeGen, type, node);
    } else if (type is FunctionType) {
      if (isGenericFunction(type)) {
        // TODO(joshualitt): Implement generic function types and share most of
        // the logic with _makeFunctionType.
        print("Not implemented: RTI ${type}");
        encodeNullability(b, type);
      } else {
        _makeFunctionType(codeGen, info, type, node);
      }
    } else {
      throw '`$type` should have already been handled.';
    }
    translator.struct_new(b, info);
    return info.nonNullableType;
  }

  /// Test value against a Dart type. Expects the value on the stack as a
  /// (ref null #Top) and leaves the result on the stack as an i32.
  /// TODO(joshualitt): Remove dependency on [CodeGenerator]
  void emitTypeTest(CodeGenerator codeGen, DartType type, DartType operandType,
      TreeNode node) {
    w.Instructions b = codeGen.b;
    if (type is! InterfaceType) {
      // TODO(askesc): Implement type test for remaining types
      print("Not implemented: Type test with non-interface type $type"
          " at ${node.location}");
      b.drop();
      b.i32_const(1);
      return;
    }
    bool isPotentiallyNullable = operandType.isPotentiallyNullable;
    w.Label? resultLabel;
    if (isPotentiallyNullable) {
      // Store operand in a temporary variable, since Binaryen does not support
      // block inputs.
      w.Local operand = codeGen.addLocal(translator.topInfo.nullableType);
      b.local_set(operand);
      resultLabel = b.block(const [], const [w.NumType.i32]);
      w.Label nullLabel = b.block(const [], const []);
      b.local_get(operand);
      b.br_on_null(nullLabel);
    }
    if (type.typeArguments.any((t) => t is! DynamicType)) {
      // If the tested-against type as an instance of the static operand type
      // has the same type arguments as the static operand type, it is not
      // necessary to test the type arguments.
      Class cls = translator.classForType(operandType);
      InterfaceType? base = translator.hierarchy
          .getTypeAsInstanceOf(type, cls, codeGen.member.enclosingLibrary)
          ?.withDeclaredNullability(operandType.declaredNullability);
      if (base != operandType) {
        print("Not implemented: Type test with type arguments"
            " at ${node.location}");
      }
    }
    List<Class> concrete = _getConcreteSubtypes(type.classNode).toList();
    if (type.classNode == translator.coreTypes.functionClass) {
      ClassInfo functionInfo = translator.classInfo[translator.functionClass]!;
      translator.ref_test(b, functionInfo);
    } else if (concrete.isEmpty) {
      b.drop();
      b.i32_const(0);
    } else if (concrete.length == 1) {
      ClassInfo info = translator.classInfo[concrete.single]!;
      b.struct_get(translator.topInfo.struct, FieldIndex.classId);
      b.i32_const(info.classId);
      b.i32_eq();
    } else {
      w.Local idLocal = codeGen.addLocal(w.NumType.i32);
      b.struct_get(translator.topInfo.struct, FieldIndex.classId);
      b.local_set(idLocal);
      w.Label done = b.block(const [], const [w.NumType.i32]);
      b.i32_const(1);
      for (Class cls in concrete) {
        ClassInfo info = translator.classInfo[cls]!;
        b.i32_const(info.classId);
        b.local_get(idLocal);
        b.i32_eq();
        b.br_if(done);
      }
      b.drop();
      b.i32_const(0);
      b.end(); // done
    }
    if (isPotentiallyNullable) {
      b.br(resultLabel!);
      b.end(); // nullLabel
      encodeNullability(b, type);
      b.end(); // resultLabel
    }
  }

  /// Returns true if a given type is nullable, and false otherwise. This
  /// function should not be used on [DartType]s with undetermined nullability.
  bool isNullable(DartType type) {
    Nullability nullability = type.nullability;
    assert(nullability == Nullability.nullable ||
        nullability == Nullability.nonNullable);
    return nullability == Nullability.nullable ? true : false;
  }

  void encodeNullability(w.Instructions b, DartType type) =>
      b.i32_const(isNullable(type) ? 1 : 0);
}
