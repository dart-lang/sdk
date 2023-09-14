// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/type_environment.dart';
import 'package:kernel/type_algebra.dart';

import 'package:dart2wasm/list_factory_specializer.dart';

void transformLibraries(List<Library> libraries, CoreTypes coreTypes,
    ClassHierarchy hierarchy, DiagnosticReporter diagnosticReporter) {
  final transformer =
      _WasmTransformer(coreTypes, hierarchy, diagnosticReporter);
  libraries.forEach(transformer.visitLibrary);
}

void transformProcedure(
    Procedure procedure, CoreTypes coreTypes, ClassHierarchy hierarchy) {
  final transformer = _WasmTransformer(coreTypes, hierarchy, null);
  procedure.accept(transformer);
}

class _WasmTransformer extends Transformer {
  final TypeEnvironment env;
  final DiagnosticReporter? diagnosticReporter;

  Member? _currentMember;
  StaticTypeContext? _cachedTypeContext;
  final Library _coreLibrary;
  final InterfaceType _nonNullableTypeType;
  final Class _wasmBaseClass;
  final List<_AsyncStarFrame> _asyncStarFrames = [];
  bool _enclosingIsAsyncStar = false;
  late final controllerNullableObjectType = InterfaceType(
      coreTypes.index.getClass('dart:async', 'StreamController'),
      Nullability.nonNullable,
      [coreTypes.objectNullableRawType]);
  late final completerBoolType = InterfaceType(
      coreTypes.index.getClass('dart:async', 'Completer'),
      Nullability.nonNullable,
      [coreTypes.boolNonNullableRawType]);

  final ListFactorySpecializer _listFactorySpecializer;

  StaticTypeContext get typeContext =>
      _cachedTypeContext ??= StaticTypeContext(_currentMember!, env);

  CoreTypes get coreTypes => env.coreTypes;

  _WasmTransformer(
      CoreTypes coreTypes, ClassHierarchy hierarchy, this.diagnosticReporter)
      : env = TypeEnvironment(coreTypes, hierarchy),
        _nonNullableTypeType = coreTypes.index
            .getClass('dart:core', '_Type')
            .getThisType(coreTypes, Nullability.nonNullable),
        _wasmBaseClass = coreTypes.index.getClass('dart:_wasm', '_WasmBase'),
        _coreLibrary = coreTypes.index.getLibrary('dart:core'),
        _listFactorySpecializer = ListFactorySpecializer(coreTypes);

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
        !env.hierarchy.isSubclassOf(cls, _wasmBaseClass) &&
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
          isSynthetic: true,
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
        type: iteratorType,
        isSynthesized: true)
      ..fileOffset = iterable.fileOffset;

    // Only used when `isAsync` is true.
    final jumpSentinel = VariableDeclaration("#jumpSentinel",
        initializer: ConstantExpression(BoolConstant(false)),
        type: InterfaceType(coreTypes.boolClass, Nullability.nonNullable),
        isSynthesized: true);

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

  StaticInvocation _completerBoolInitializer() => StaticInvocation(
      coreTypes.index.getProcedure('dart:async', 'Completer', ''),
      Arguments([], types: [coreTypes.boolNonNullableRawType]));

  InstanceInvocation _addToController(
      VariableDeclaration controller, Expression expression, int fileOffset) {
    Procedure controllerAdd =
        coreTypes.index.getProcedure('dart:async', 'StreamController', 'add');
    FunctionType controllerAddType =
        Substitution.fromInterfaceType(controllerNullableObjectType)
                .substituteType(controllerAdd.function
                    .computeThisFunctionType(Nullability.nonNullable))
            as FunctionType;
    return InstanceInvocation(InstanceAccessKind.Instance,
        VariableGet(controller), Name('add'), Arguments([expression]),
        interfaceTarget: controllerAdd, functionType: controllerAddType)
      ..fileOffset = fileOffset;
  }

  InstanceInvocation _addCompleterToController(VariableDeclaration controller,
          VariableDeclaration completer, int fileOffset) =>
      _addToController(controller, VariableGet(completer), fileOffset);

  AwaitExpression _awaitCompleterFuture(
      VariableDeclaration completer, int fileOffset) {
    Procedure completerFuture =
        coreTypes.index.getProcedure('dart:async', 'Completer', 'get:future');
    // Future<bool>
    DartType completerFutureType = InterfaceType(coreTypes.futureClass,
        Nullability.nonNullable, [coreTypes.boolNonNullableRawType]);
    return AwaitExpression(InstanceGet(
        InstanceAccessKind.Instance, VariableGet(completer), Name('future'),
        interfaceTarget: completerFuture, resultType: completerFutureType)
      ..fileOffset = fileOffset);
  }

  TreeNode _lowerAsyncStar(FunctionNode functionNode) {
    // TODO(joshualitt): This lowering is mostly reasonable, but if possible we
    // should try and figure out a way to remove the even / odd dance. That
    // said, this will be replaced by an intrinsic implementation ASAP so it may
    // not be worth spending anymore time on this(aside from bug fixes).
    //
    // Transform
    //
    //   Stream<T> foo() async* {
    //     ...
    //     yield i;
    //     ...
    //     yield* bar;
    //     ...
    //   }
    //
    // Into
    //
    //   Stream<T> foo() {
    //     StreamController<Object?> #controller = StreamController<Object?>();
    //     Future<void> Function() #body = () async {
    //       Completer<bool> #completer = Completer<bool>();
    //       #controller.add(#completer);
    //       try {
    //         await #completer.future;
    //         ...
    //         #controller.add(i);
    //         #completer = Completer<bool>();
    //         #controller.add(#completer)
    //         await #completer.future;
    //         ...
    //         await for (var i in bar) {
    //           #controller.add(i);
    //           #completer = Completer<bool>();
    //           #controller.add(#completer)
    //           await #completer.future;
    //         }
    //         ...
    //       } catch (e) {
    //         #controller.addError(e);
    //       } finally {
    //         #controller.close();
    //       }
    //     };
    //     bool isEven = false;
    //     bool isFirst = true;
    //     #controller.add(null);
    //     return #controller.stream.asyncMap((value) async {
    //       if (isFirst) {
    //         #body();
    //         return null;
    //       }
    //       if (value is Completer<Bool>) {
    //         value.complete(true);
    //       }
    //       return value;
    //     }).where((value) {
    //       if (isFirst) {
    //         isFirst = false;
    //         return false;
    //       }
    //       bool keep = isEven;
    //       isEven = !isEven;
    //       return keep;
    //     }).cast<T>();
    //   }
    int fileOffset = functionNode.fileOffset;

    // Initialize `#controller`.
    final controllerInitializer = StaticInvocation(
        coreTypes.index.getProcedure('dart:async', 'StreamController', ''),
        Arguments([], types: [coreTypes.objectNullableRawType]));
    final controller = VariableDeclaration('#controller',
        initializer: controllerInitializer..fileOffset = fileOffset,
        type: controllerNullableObjectType,
        isSynthesized: true)
      ..fileOffset = fileOffset;

    // Initialize `#completer`.
    final completer = VariableDeclaration('#completer',
        initializer: _completerBoolInitializer()..fileOffset = fileOffset,
        type: completerBoolType,
        isSynthesized: true)
      ..fileOffset = fileOffset;

    // Close `#controller`.
    Procedure controllerCloseProc =
        coreTypes.index.getProcedure('dart:async', 'StreamController', 'close');
    FunctionType controllerCloseType =
        Substitution.fromInterfaceType(controllerNullableObjectType)
                .substituteType(controllerCloseProc.function
                    .computeThisFunctionType(Nullability.nonNullable))
            as FunctionType;
    final callControllerClose = InstanceInvocation(InstanceAccessKind.Instance,
        VariableGet(controller), Name('close'), Arguments([]),
        interfaceTarget: controllerCloseProc,
        functionType: controllerCloseType);

    // Create a frame so yield statements within the body can access the right
    // controller / completer.
    _asyncStarFrames.add(_AsyncStarFrame(controller, completer));

    // Visit the body to transform any yields. We will re-visit after
    // transformation just to ensure everything we've added will also be
    // lowered.
    Statement? transformedBody =
        functionNode.body?.accept<TreeNode>(this) as Statement?;
    _asyncStarFrames.removeLast();

    // Try-catch-finally around the body to call `controller.addError` and
    // `controller.close`.
    final exceptionVar = VariableDeclaration(null, isSynthesized: true);
    final Procedure controllerAddErrorProc = coreTypes.index
        .getProcedure('dart:async', 'StreamController', 'addError');
    final FunctionType controllerAddErrorType =
        Substitution.fromInterfaceType(controllerNullableObjectType)
                .substituteType(controllerAddErrorProc.function
                    .computeThisFunctionType(Nullability.nonNullable))
            as FunctionType;
    final tryCatch = TryCatch(
      Block([
        ExpressionStatement(_awaitCompleterFuture(completer, fileOffset)),
        if (transformedBody != null) transformedBody,
      ]),
      [
        Catch(
          exceptionVar,
          ExpressionStatement(InstanceInvocation(
            InstanceAccessKind.Instance,
            VariableGet(controller),
            Name('addError'),
            Arguments([VariableGet(exceptionVar)]),
            interfaceTarget: controllerAddErrorProc,
            functionType: controllerAddErrorType,
          )),
        )
      ],
    );
    final tryFinally =
        TryFinally(tryCatch, ExpressionStatement(callControllerClose));

    // Locally declare body function.
    final bodyFunction = FunctionNode(
        Block([
          completer,
          ExpressionStatement(
              _addCompleterToController(controller, completer, fileOffset)),
          tryFinally,
        ]),
        futureValueType: const VoidType(),
        returnType: InterfaceType(
            coreTypes.futureClass, Nullability.nonNullable, [const VoidType()]),
        asyncMarker: AsyncMarker.Async,
        dartAsyncMarker: AsyncMarker.Async);
    final bodyInitializer = FunctionExpression(bodyFunction);
    FunctionType bodyFunctionType =
        bodyFunction.computeThisFunctionType(Nullability.nonNullable);
    final body = VariableDeclaration('#body',
        initializer: bodyInitializer..fileOffset = fileOffset,
        type: bodyFunctionType,
        isSynthesized: true)
      ..fileOffset = fileOffset;

    // Invoke body.
    final invokeBody = FunctionInvocation(
        FunctionAccessKind.FunctionType, VariableGet(body), Arguments([]),
        functionType: bodyFunctionType);

    // Create a 'counting' sentinel to let us know which values to filter.
    final isEven = VariableDeclaration('#isEven',
        initializer: ConstantExpression(BoolConstant(false))
          ..fileOffset = fileOffset,
        type: coreTypes.boolNonNullableRawType,
        isSynthesized: true)
      ..fileOffset = fileOffset;
    final isFirst = VariableDeclaration('#isFirst',
        initializer: ConstantExpression(BoolConstant(true))
          ..fileOffset = fileOffset,
        type: coreTypes.boolNonNullableRawType,
        isSynthesized: true)
      ..fileOffset = fileOffset;

    // Get `controller.stream`
    Procedure controllerStream = coreTypes.index
        .getProcedure('dart:async', 'StreamController', 'get:stream');
    FunctionType controllerStreamType =
        Substitution.fromInterfaceType(controllerNullableObjectType)
                .substituteType(controllerStream.function
                    .computeThisFunctionType(Nullability.nonNullable))
            as FunctionType;
    final getControllerStream = InstanceGet(
        InstanceAccessKind.Instance, VariableGet(controller), Name('stream'),
        interfaceTarget: controllerStream, resultType: controllerStreamType);

    // Prepare `completerPrePass` to issue a round of completions to our hidden
    // completers.
    Procedure completerComplete =
        coreTypes.index.getProcedure('dart:async', 'Completer', 'complete');
    FunctionType completerCompleteType =
        Substitution.fromInterfaceType(completerBoolType).substituteType(
                completerComplete.function
                    .computeThisFunctionType(Nullability.nonNullable))
            as FunctionType;
    final completerPrePassArg = VariableDeclaration('value',
        type: coreTypes.objectNullableRawType, isSynthesized: true);
    final completerPrePass = FunctionExpression(FunctionNode(
      Block([
        IfStatement(
            VariableGet(isFirst),
            Block([
              ExpressionStatement(invokeBody),
              ReturnStatement(ConstantExpression(NullConstant())),
            ]),
            null),
        IfStatement(
            Not(VariableGet(isEven)),
            ExpressionStatement(InstanceInvocation(
                InstanceAccessKind.Instance,
                VariableGet(completerPrePassArg),
                Name('complete'),
                Arguments([ConstantExpression(BoolConstant(true))]),
                interfaceTarget: completerComplete,
                functionType: completerCompleteType)),
            null),
        ReturnStatement(VariableGet(completerPrePassArg)),
      ]),
      positionalParameters: [completerPrePassArg],
      returnType: FutureOrType(
          coreTypes.objectNullableRawType, Nullability.nonNullable),
      asyncMarker: AsyncMarker.Async,
      dartAsyncMarker: AsyncMarker.Async,
      futureValueType: coreTypes.objectNullableRawType,
    ));

    // Call `asyncMap`.
    Procedure asyncMap =
        coreTypes.index.getProcedure('dart:async', 'Stream', 'asyncMap');
    final streamType = InterfaceType(coreTypes.streamClass,
        Nullability.nonNullable, [coreTypes.objectNullableRawType]);
    final asyncMapType = FunctionType([
      FunctionType([
        coreTypes.objectNullableRawType
      ], FutureOrType(coreTypes.objectNullableRawType, Nullability.nonNullable),
          Nullability.nonNullable, requiredParameterCount: 1)
    ], streamType, Nullability.nonNullable, requiredParameterCount: 1);
    final callAsyncMap = InstanceInvocation(
        InstanceAccessKind.Instance,
        getControllerStream,
        Name('asyncMap'),
        Arguments([completerPrePass], types: [coreTypes.objectNullableRawType]),
        interfaceTarget: asyncMap,
        functionType: asyncMapType);

    // Call `where`.
    final whereFilterArg = VariableDeclaration('value',
        type: coreTypes.objectNullableRawType, isSynthesized: true);
    final whereKeep = VariableDeclaration('keep',
        initializer: VariableGet(isEven),
        type: coreTypes.boolNonNullableRawType,
        isSynthesized: true);

    final whereFilter = FunctionExpression(FunctionNode(
        Block([
          IfStatement(
              VariableGet(isFirst),
              Block([
                ExpressionStatement(VariableSet(
                    isFirst, ConstantExpression(BoolConstant(false)))),
                ReturnStatement(ConstantExpression(BoolConstant(false)))
              ]),
              null),
          whereKeep,
          ExpressionStatement(VariableSet(isEven, Not(VariableGet(isEven)))),
          ReturnStatement(VariableGet(whereKeep)),
        ]),
        positionalParameters: [whereFilterArg],
        returnType: coreTypes.objectNullableRawType));

    Procedure whereProc =
        coreTypes.index.getProcedure('dart:async', 'Stream', 'where');
    FunctionType whereProcType = Substitution.fromInterfaceType(streamType)
        .substituteType(whereProc.function
            .computeThisFunctionType(Nullability.nonNullable)) as FunctionType;
    final callWhere = InstanceInvocation(InstanceAccessKind.Instance,
        callAsyncMap, Name('where'), Arguments([whereFilter]),
        interfaceTarget: whereProc, functionType: whereProcType);

    // Finally call cast
    DartType typeArgument;
    if (functionNode.returnType is InterfaceType) {
      typeArgument =
          (functionNode.returnType as InterfaceType).typeArguments.single;
    } else {
      typeArgument = const DynamicType();
    }
    Procedure castProc =
        coreTypes.index.getProcedure('dart:async', 'Stream', 'cast');
    final returnStreamType = InterfaceType(
        coreTypes.streamClass, typeArgument.nullability, [typeArgument]);
    final castProcType = FunctionType(
        [], returnStreamType, Nullability.nonNullable,
        requiredParameterCount: 1);
    final castToExpectedType = InstanceInvocation(InstanceAccessKind.Instance,
        callWhere, Name('cast'), Arguments([], types: [typeArgument]),
        interfaceTarget: castProc, functionType: castProcType);
    return FunctionNode(
        Block([
          controller,
          body,
          isFirst,
          isEven,
          ExpressionStatement(_addToController(
              controller, ConstantExpression(NullConstant()), fileOffset)),
          ReturnStatement(castToExpectedType),
        ]),
        typeParameters: functionNode.typeParameters,
        positionalParameters: functionNode.positionalParameters,
        namedParameters: functionNode.namedParameters,
        requiredParameterCount: functionNode.requiredParameterCount,
        returnType: functionNode.returnType,
        asyncMarker: AsyncMarker.Sync,
        dartAsyncMarker: AsyncMarker.Sync);
  }

  @override
  TreeNode visitYieldStatement(YieldStatement yield) {
    // We currently ignore yields in 'sync*'.
    if (!_enclosingIsAsyncStar) {
      return super.visitYieldStatement(yield);
    }
    int fileOffset = yield.fileOffset;
    _AsyncStarFrame frame = _asyncStarFrames.last;
    VariableDeclaration controller = frame.controller;
    VariableDeclaration completer = frame.completer;
    bool isYieldStar = yield.isYieldStar;

    // If [isYieldStar] then we need to create an `await for` loop to wrap the
    // yields.
    DartType yieldExpressionType = yield.expression.getStaticType(typeContext);
    VariableDeclaration? awaitForVar;
    if (isYieldStar) {
      DartType awaitVarType = const DynamicType();
      if (yieldExpressionType is InterfaceType) {
        Class cls = yieldExpressionType.classReference.asClass;
        if (cls == coreTypes.streamClass) {
          awaitVarType = yieldExpressionType.typeArguments.single;
        }
      }
      awaitForVar = VariableDeclaration('#awaitForVar',
          type: awaitVarType, isSynthesized: true)
        ..fileOffset = fileOffset;
    }

    final yieldBody = Block([
      ExpressionStatement(_addToController(
          controller,
          isYieldStar ? VariableGet(awaitForVar!) : yield.expression,
          fileOffset)),
      ExpressionStatement(VariableSet(completer, _completerBoolInitializer())),
      ExpressionStatement(
          _addCompleterToController(controller, completer, fileOffset)),
      ExpressionStatement(_awaitCompleterFuture(completer, fileOffset)),
    ]);
    if (isYieldStar) {
      // If this is a yield* then wrap the yield in an `await for`.
      ForInStatement awaitForIn = ForInStatement(
          awaitForVar!, yield.expression, yieldBody,
          isAsync: true);
      return awaitForIn.accept<TreeNode>(this);
    } else {
      return yieldBody.accept<TreeNode>(this);
    }
  }

  @override
  TreeNode visitFunctionNode(FunctionNode functionNode) {
    if (functionNode.dartAsyncMarker == AsyncMarker.AsyncStar) {
      _enclosingIsAsyncStar = true;
      functionNode = _lowerAsyncStar(functionNode) as FunctionNode;
      _enclosingIsAsyncStar = false;
      return super.visitFunctionNode(functionNode);
    } else {
      bool previousEnclosing = _enclosingIsAsyncStar;
      TreeNode result = super.visitFunctionNode(functionNode);
      _enclosingIsAsyncStar = previousEnclosing;
      return result;
    }
  }

  @override
  TreeNode visitStaticInvocation(StaticInvocation node) {
    node.transformChildren(this);
    return _listFactorySpecializer.transformStaticInvocation(node);
  }
}

class _AsyncStarFrame {
  final VariableDeclaration controller;
  final VariableDeclaration completer;

  _AsyncStarFrame(this.controller, this.completer);
}
