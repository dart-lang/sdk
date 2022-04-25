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

  List<Class> _getConcreteSubtypes(Class cls) => translator.subtypes
      .getSubtypesOf(cls)
      .where((c) => !c.isAbstract)
      .toList();

  bool _isTypeConstant(DartType type) {
    return type is DynamicType ||
        type is VoidType ||
        type is NeverType ||
        type is NullType ||
        type is FunctionType ||
        type is InterfaceType && type.typeArguments.every(_isTypeConstant);
  }

  /// Makes a `_Type` object on the stack.
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
    ClassInfo info = translator.classInfo[translator.typeClass]!;
    translator.functions.allocateClass(info.classId);
    if (type is FutureOrType) {
      // TODO(askesc): Have an actual representation of FutureOr types
      b.ref_null(info.nullableType.heapType);
      return info.nullableType;
    }
    if (type is! InterfaceType) {
      codeGen.unimplemented(node, type, [info.nullableType]);
      return info.nullableType;
    }
    ClassInfo typeInfo = translator.classInfo[type.classNode]!;
    w.ValueType typeListExpectedType =
        info.struct.fields[FieldIndex.typeTypeArguments].type.unpacked;
    b.i32_const(info.classId);
    b.i32_const(initialIdentityHash);
    b.i64_const(typeInfo.classId);
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
    return info.nullableType;
  }

  /// Test value against a Dart type. Expects the value on the stack as a
  /// (ref null #Top) and leaves the result on the stack as an i32.
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
    bool isNullable = operandType.isPotentiallyNullable;
    w.Label? resultLabel;
    if (isNullable) {
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
    List<Class> concrete = _getConcreteSubtypes(type.classNode);
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
    if (isNullable) {
      b.br(resultLabel!);
      b.end(); // nullLabel
      b.i32_const(type.declaredNullability == Nullability.nullable ? 1 : 0);
      b.end(); // resultLabel
    }
  }
}
