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

  Types(this.translator);

  Iterable<Class> _getConcreteSubtypes(Class cls) =>
      translator.subtypes.getSubtypesOf(cls).where((c) => !c.isAbstract);

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

  bool _isTypeConstant(DartType type) {
    return type is DynamicType ||
        type is VoidType ||
        type is NeverType ||
        type is NullType ||
        type is FunctionType ||
        type is InterfaceType && type.typeArguments.every(_isTypeConstant);
  }

  Class classForType(DartType type) {
    if (type is DynamicType) {
      return translator.dynamicTypeClass;
    } else if (type is VoidType) {
      return translator.voidTypeClass;
    } else if (type is NeverType) {
      return translator.neverTypeClass;
    } else if (type is NullType) {
      return translator.nullTypeClass;
    } else if (type is FutureOrType) {
      return translator.futureOrTypeClass;
    } else if (type is InterfaceType) {
      return translator.interfaceTypeClass;
    } else if (type is FunctionType) {
      if (type.typeParameters.isEmpty) {
        return translator.functionTypeClass;
      } else {
        return translator.genericFunctionTypeClass;
      }
    }
    throw "Unexpected DartType: $type";
  }

  /// Makes a `_Type` object on the stack.
  /// TODO(joshualitt): Refactor this logic to remove the dependency on
  /// CodeGenerator.
  w.ValueType makeType(CodeGenerator codeGen, DartType type, TreeNode node) {
    w.ValueType typeType =
        translator.classInfo[translator.typeClass]!.nullableType;
    w.Instructions b = codeGen.b;
    if (_isTypeConstant(type)) {
      translator.constants.instantiateConstant(
          codeGen.function, b, TypeLiteralConstant(type), typeType);
      return typeType;
    }
    if (type is TypeParameterType) {
      if (type.parameter.parent is FunctionNode) {
        // Type argument to function
        w.Local? local = codeGen.typeLocals[type.parameter];
        if (local != null) {
          b.local_get(local);
          return local.type;
        } else {
          codeGen.unimplemented(
              node, "Type parameter access inside lambda", [typeType]);
          return typeType;
        }
      }
      // Type argument of class
      Class cls = type.parameter.parent as Class;
      ClassInfo info = translator.classInfo[cls]!;
      int fieldIndex = translator.typeParameterIndex[type.parameter]!;
      w.ValueType thisType = codeGen.visitThis(info.nullableType);
      translator.convertType(codeGen.function, thisType, info.nullableType);
      b.struct_get(info.struct, fieldIndex);
      return typeType;
    }
    ClassInfo info = translator.classInfo[classForType(type)]!;
    translator.functions.allocateClass(info.classId);
    if (type is! InterfaceType) {
      if (type is FutureOrType || type is FunctionType) {
        // TODO(joshualitt): Finish RTI.
        print("Not implemented: RTI ${type}");
      }
      b.i32_const(info.classId);
      b.i32_const(initialIdentityHash);
      translator.struct_new(b, info);
      return info.nonNullableType;
    }
    ClassInfo typeInfo = translator.classInfo[type.classNode]!;
    w.ValueType typeListExpectedType =
        info.struct.fields[FieldIndex.interfaceTypeTypeArguments].type.unpacked;
    b.i32_const(info.classId);
    b.i32_const(initialIdentityHash);
    b.i64_const(typeInfo.classId);
    b.i32_const(isNullable(type) ? 1 : 0);
    w.DefinedFunction function = codeGen.function;
    if (type.typeArguments.isEmpty) {
      b.global_get(translator.constants.emptyTypeList);
      translator.convertType(function,
          translator.constants.emptyTypeList.type.type, typeListExpectedType);
    } else if (type.typeArguments.every(_isTypeConstant)) {
      ListConstant typeArgs = ListConstant(
          InterfaceType(translator.typeClass, Nullability.nonNullable),
          type.typeArguments.map((t) => TypeLiteralConstant(t)).toList());
      translator.constants
          .instantiateConstant(function, b, typeArgs, typeListExpectedType);
    } else {
      w.ValueType listType = codeGen.makeList(
          type.typeArguments.map((t) => TypeLiteral(t)).toList(),
          translator.fixedLengthListClass,
          InterfaceType(translator.typeClass, Nullability.nonNullable),
          node);
      translator.convertType(function, listType, typeListExpectedType);
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
      b.i32_const(isNullable(type) ? 1 : 0);
      b.end(); // resultLabel
    }
  }

  bool isNullable(InterfaceType type) {
    Nullability nullability = type.declaredNullability;
    // TODO(joshualitt): Enable assert when spurious 'legacy' values are fixed.
    // assert(nullability == Nullability.nonNullable ||
    //    nullability == Nullability.nullable);
    return nullability == Nullability.nullable ? true : false;
  }
}
