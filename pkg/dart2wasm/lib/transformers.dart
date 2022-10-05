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
  final Library _coreLibrary;
  final InterfaceType _nonNullableTypeType;

  StaticTypeContext get typeContext =>
      _cachedTypeContext ??= StaticTypeContext(_currentMember!, env);

  CoreTypes get coreTypes => env.coreTypes;

  _WasmTransformer(CoreTypes coreTypes, ClassHierarchy hierarchy)
      : env = TypeEnvironment(coreTypes, hierarchy),
        _nonNullableTypeType = coreTypes.index
            .getClass('dart:core', '_Type')
            .getThisType(coreTypes, Nullability.nonNullable),
        _coreLibrary = coreTypes.index.getLibrary('dart:core');

  @override
  defaultMember(Member node) {
    _currentMember = node;
    _cachedTypeContext = null;

    final result = super.defaultMember(node);

    _currentMember = null;
    _cachedTypeContext = null;
    return result;
  }

  /// Checks to see if it is safe to reuse `super._typeArguments`.
  bool canReuseSuperMethod(Class cls) {
    // We search for the first non-abstract super in [cls]'s inheritance chain
    // to see if we can reuse its `_typeArguments` method.
    Class classIter = cls;
    late Supertype supertype;
    while (classIter.supertype != null) {
      Supertype supertypeIter = classIter.supertype!;
      Class superclass = supertypeIter.classNode;
      if (!superclass.isAbstract) {
        supertype = supertypeIter;
        break;
      }
      classIter = classIter.supertype!.classNode;
    }

    // We can reuse a superclass' `_typeArguments` method if the subclass and
    // the superclass have the exact same type parameters in the exact same
    // order.
    if (cls.typeParameters.length != supertype.typeArguments.length) {
      return false;
    }
    for (int i = 0; i < cls.typeParameters.length; i++) {
      TypeParameter parameter = cls.typeParameters[i];
      DartType arg = supertype.typeArguments[i];
      if (arg is! TypeParameterType || arg.parameter != parameter) {
        return false;
      }
    }
    return true;
  }

  @override
  TreeNode visitClass(Class cls) {
    // For every concrete class whose type parameters do not match the type
    // parameters of it's super class we embed a special virtual function
    // `_getTypeArguments`.  When generating code for `_getTypeArguments`, we
    // read the `TypeParameter`s off the instantiated object and generate a
    // `List<Type>` to pass to `_getRuntimeType` which then returns a reified
    // `Type` object.
    if (!cls.isAbstract &&
        cls != coreTypes.objectClass &&
        !canReuseSuperMethod(cls)) {
      Procedure getTypeArguments = Procedure(
          Name("_typeArguments", _coreLibrary),
          ProcedureKind.Getter,
          FunctionNode(
            null,
            returnType: InterfaceType(coreTypes.listClass,
                Nullability.nonNullable, [_nonNullableTypeType]),
          ),
          isExternal: true,
          fileUri: cls.fileUri)
        ..isNonNullableByDefault = true;
      cls.addProcedure(getTypeArguments);
    }
    return super.visitClass(cls);
  }

  TreeNode _lowerForIn(ForInStatement stmt) {
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
    //
    // and:
    //
    //   await for ({var/final} T <variable> in <stream>) { ... }
    //
    // Into
    //
    //  {
    //    final StreamIterator<T> #forIterator = StreamIterator(<stream>);
    //    bool #jumpSentinel = false;
    //    try {
    //      for (; jumpSentinel = await #forIterator.moveNext() ;) {
    //        {var/final} T variable = #forIterator.current;
    //        ...
    //      }
    //    } finally {
    //      if (#jumpSentinel) {
    //        await #forIterator.cancel();
    //      }
    //    }
    //  }

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

    final isAsync = stmt.isAsync;
    late final Class iteratorClass;
    late final Procedure iteratorMoveNext;
    late final Member iteratorCurrent;
    if (isAsync) {
      iteratorClass = coreTypes.streamIteratorClass;
      iteratorMoveNext = coreTypes.streamIteratorMoveNext;
      iteratorCurrent = coreTypes.streamIteratorCurrent;
    } else {
      iteratorClass = coreTypes.iteratorClass;
      iteratorMoveNext = coreTypes.iteratorMoveNext;
      iteratorCurrent = coreTypes.iteratorGetCurrent;
    }

    final DartType elementType = stmt.getElementType(typeContext);
    final iteratorType =
        InterfaceType(iteratorClass, Nullability.nonNullable, [elementType]);

    late final Expression iteratorInitializer;
    if (isAsync) {
      iteratorInitializer = ConstructorInvocation(
          coreTypes.streamIteratorDefaultConstructor,
          Arguments([iterable], types: [elementType]));
    } else {
      iteratorInitializer = InstanceGet(
          InstanceAccessKind.Instance, iterable, Name('iterator'),
          interfaceTarget: coreTypes.iterableGetIterator,
          resultType: iteratorType);
    }

    final iterator = VariableDeclaration("#forIterator",
        initializer: iteratorInitializer..fileOffset = iterable.fileOffset,
        type: iteratorType)
      ..fileOffset = iterable.fileOffset;

    // Only used when `isAsync` is true.
    final jumpSentinel = VariableDeclaration("#jumpSentinel",
        initializer: ConstantExpression(BoolConstant(false)),
        type: InterfaceType(coreTypes.boolClass, Nullability.nonNullable));

    final condition = InstanceInvocation(InstanceAccessKind.Instance,
        VariableGet(iterator), Name('moveNext'), Arguments(const []),
        interfaceTarget: iteratorMoveNext,
        functionType: iteratorMoveNext.getterType as FunctionType)
      ..fileOffset = iterable.fileOffset;

    final variable = stmt.variable
      ..initializer = (InstanceGet(
          InstanceAccessKind.Instance, VariableGet(iterator), Name('current'),
          interfaceTarget: iteratorCurrent, resultType: elementType)
        ..fileOffset = stmt.bodyOffset);

    Block body = Block([variable, stmt.body])..fileOffset = stmt.fileOffset;

    Statement forStatement = ForStatement(
        const [],
        isAsync
            ? VariableSet(jumpSentinel, AwaitExpression(condition))
            : condition,
        const [],
        body);

    // Wrap the body with a try / finally to cancel the stream on breaking out
    // of the loop.
    if (isAsync) {
      forStatement = TryFinally(
        Block([forStatement]),
        Block([
          IfStatement(
              VariableGet(jumpSentinel),
              ExpressionStatement(AwaitExpression(InstanceInvocation(
                  InstanceAccessKind.Instance,
                  VariableGet(iterator),
                  Name('cancel'),
                  Arguments(const []),
                  interfaceTarget: coreTypes.streamIteratorCancel,
                  functionType: coreTypes.streamIteratorCancel.getterType
                      as FunctionType))),
              null)
        ]),
      );
    }

    return Block([iterator, if (isAsync) jumpSentinel, forStatement])
        .accept<TreeNode>(this);
  }

  @override
  TreeNode visitForInStatement(ForInStatement stmt) {
    return _lowerForIn(stmt);
  }
}
