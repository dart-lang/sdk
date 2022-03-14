// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_environment.dart';

void transformLibraries(
    List<Library> libraries, CoreTypes coreTypes, ClassHierarchy hierarchy) {
  final transformer = _WasmTransformer(coreTypes, hierarchy);
  libraries.forEach(transformer.visitLibrary);
}

void transformProcedure(
    Procedure procedure, CoreTypes coreTypes, ClassHierarchy hierarchy) {
  final transformer = _WasmTransformer(coreTypes, hierarchy);
  procedure.accept(transformer);
}

class _WasmTransformer extends Transformer {
  final TypeEnvironment env;

  Member? _currentMember;
  StaticTypeContext? _cachedTypeContext;

  StaticTypeContext get typeContext =>
      _cachedTypeContext ??= StaticTypeContext(_currentMember!, env);

  _WasmTransformer(CoreTypes coreTypes, ClassHierarchy hierarchy)
      : env = TypeEnvironment(coreTypes, hierarchy);

  @override
  defaultMember(Member node) {
    _currentMember = node;
    _cachedTypeContext = null;

    final result = super.defaultMember(node);

    _currentMember = null;
    _cachedTypeContext = null;
    return result;
  }

  @override
  TreeNode visitForInStatement(ForInStatement stmt) {
    // Transform
    //
    //   for ({var/final} T <variable> in <iterable>) { ... }
    //
    // Into
    //
    //  {
    //    final Iterator<T> #forIterator = <iterable>.iterator;
    //    for (; #forIterator.moveNext() ;) {
    //        {var/final} T variable = #forIterator.current;
    //        ...
    //      }
    //    }
    //  }
    final CoreTypes coreTypes = typeContext.typeEnvironment.coreTypes;

    // The CFE might invoke this transformation despite the program having
    // compile-time errors. So we will not transform this [stmt] if the
    // `stmt.iterable` is an invalid expression or has an invalid type and
    // instead eliminate the entire for-in and replace it with a invalid
    // expression statement.
    final iterable = stmt.iterable;
    final iterableType = iterable.getStaticType(typeContext);
    if (iterableType is InvalidType) {
      return ExpressionStatement(
          InvalidExpression('Invalid iterable type in for-in'));
    }

    final DartType elementType = stmt.getElementType(typeContext);
    final iteratorType = InterfaceType(
        coreTypes.iteratorClass, Nullability.nonNullable, [elementType]);

    final iterator = VariableDeclaration("#forIterator",
        initializer: InstanceGet(
            InstanceAccessKind.Instance, iterable, Name('iterator'),
            interfaceTarget: coreTypes.iterableGetIterator,
            resultType: coreTypes.iterableGetIterator.function.returnType)
          ..fileOffset = iterable.fileOffset,
        type: iteratorType)
      ..fileOffset = iterable.fileOffset;

    final condition = InstanceInvocation(InstanceAccessKind.Instance,
        VariableGet(iterator), Name('moveNext'), Arguments(const []),
        interfaceTarget: coreTypes.iteratorMoveNext,
        functionType: coreTypes.iteratorMoveNext.function
            .computeFunctionType(Nullability.nonNullable))
      ..fileOffset = iterable.fileOffset;

    final variable = stmt.variable
      ..initializer = (InstanceGet(
          InstanceAccessKind.Instance, VariableGet(iterator), Name('current'),
          interfaceTarget: coreTypes.iteratorGetCurrent,
          resultType: coreTypes.iteratorGetCurrent.function.returnType)
        ..fileOffset = stmt.bodyOffset);

    final Block body = Block([variable, stmt.body]);

    return Block([iterator, ForStatement(const [], condition, const [], body)])
        .accept<TreeNode>(this);
  }
}
