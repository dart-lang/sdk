// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/dart2js.dart'
    show operatorFromString;

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import '../common.dart';
import 'scope.dart';
import 'static_type.dart';
import 'static_type_base.dart';
import 'util.dart';

abstract class ImpactBuilder extends StaticTypeVisitor {
  final VariableScopeModel variableScopeModel;

  ImpactBuilder(ir.TypeEnvironment typeEnvironment,
      ir.ClassHierarchy classHierarchy, this.variableScopeModel)
      : super(typeEnvironment, classHierarchy);

  ClassRelation _computeClassRelationFromType(ir.DartType type) {
    if (type is ThisInterfaceType) {
      return ClassRelation.thisExpression;
    } else if (type is ExactInterfaceType) {
      return ClassRelation.exact;
    } else {
      return ClassRelation.subtype;
    }
  }

  void registerIntLiteral(int value);

  @override
  void handleIntLiteral(ir.IntLiteral node) {
    registerIntLiteral(node.value);
  }

  void registerDoubleLiteral(double value);

  @override
  void handleDoubleLiteral(ir.DoubleLiteral node) {
    registerDoubleLiteral(node.value);
  }

  void registerBoolLiteral(bool value);

  @override
  void handleBoolLiteral(ir.BoolLiteral node) {
    registerBoolLiteral(node.value);
  }

  void registerStringLiteral(String value);

  @override
  void handleStringLiteral(ir.StringLiteral node) {
    registerStringLiteral(node.value);
  }

  void registerSymbolLiteral(String value);

  @override
  void handleSymbolLiteral(ir.SymbolLiteral node) {
    registerSymbolLiteral(node.value);
  }

  void registerNullLiteral();

  @override
  void handleNullLiteral(ir.NullLiteral node) {
    registerNullLiteral();
  }

  void registerListLiteral(ir.DartType elementType,
      {bool isConstant, bool isEmpty});

  @override
  void handleListLiteral(ir.ListLiteral node) {
    registerListLiteral(node.typeArgument,
        isConstant: node.isConst, isEmpty: node.expressions.isEmpty);
  }

  void registerMapLiteral(ir.DartType keyType, ir.DartType valueType,
      {bool isConstant, bool isEmpty});

  @override
  void handleMapLiteral(ir.MapLiteral node) {
    registerMapLiteral(node.keyType, node.valueType,
        isConstant: node.isConst, isEmpty: node.entries.isEmpty);
  }

  void registerStaticTearOff(
      ir.Procedure procedure, ir.LibraryDependency import);

  void registerStaticGet(ir.Member member, ir.LibraryDependency import);

  @override
  void handleStaticGet(ir.StaticGet node, ir.DartType resultType) {
    ir.Member target = node.target;
    if (target is ir.Procedure && target.kind == ir.ProcedureKind.Method) {
      registerStaticTearOff(target, getDeferredImport(node));
    } else {
      registerStaticGet(target, getDeferredImport(node));
    }
  }

  void registerStaticSet(ir.Member member, ir.LibraryDependency import);

  @override
  void handleStaticSet(ir.StaticSet node, ir.DartType valueType) {
    registerStaticSet(node.target, getDeferredImport(node));
  }

  void registerAssert({bool withMessage});

  @override
  void handleAssertStatement(ir.AssertStatement node) {
    registerAssert(withMessage: node.message != null);
  }

  void registerGenericInstantiation(
      ir.FunctionType expressionType, List<ir.DartType> typeArguments);

  @override
  void handleInstantiation(ir.Instantiation node,
      ir.FunctionType expressionType, ir.DartType resultType) {
    registerGenericInstantiation(expressionType, node.typeArguments);
  }

  void registerSyncStar(ir.DartType elementType);

  void registerAsync(ir.DartType elementType);

  void registerAsyncStar(ir.DartType elementType);

  void handleAsyncMarker(ir.FunctionNode function) {
    ir.AsyncMarker asyncMarker = function.asyncMarker;
    ir.DartType returnType = function.returnType;

    switch (asyncMarker) {
      case ir.AsyncMarker.Sync:
        break;
      case ir.AsyncMarker.SyncStar:
        ir.DartType elementType = const ir.DynamicType();
        if (returnType is ir.InterfaceType) {
          if (returnType.classNode == typeEnvironment.coreTypes.iterableClass) {
            elementType = returnType.typeArguments.first;
          }
        }
        registerSyncStar(elementType);
        break;

      case ir.AsyncMarker.Async:
        ir.DartType elementType = const ir.DynamicType();
        if (returnType is ir.InterfaceType) {
          if (returnType.classNode == typeEnvironment.coreTypes.futureOrClass) {
            elementType = returnType.typeArguments.first;
          } else if (returnType.classNode ==
              typeEnvironment.coreTypes.futureClass) {
            elementType = returnType.typeArguments.first;
          }
        }
        registerAsync(elementType);
        break;

      case ir.AsyncMarker.AsyncStar:
        ir.DartType elementType = const ir.DynamicType();
        if (returnType is ir.InterfaceType) {
          if (returnType.classNode == typeEnvironment.coreTypes.streamClass) {
            elementType = returnType.typeArguments.first;
          }
        }
        registerAsyncStar(elementType);
        break;

      case ir.AsyncMarker.SyncYielding:
        failedAt(CURRENT_ELEMENT_SPANNABLE,
            "Unexpected async marker: ${asyncMarker}");
    }
  }

  void registerStringConcatenation();

  @override
  void handleStringConcatenation(ir.StringConcatenation node) {
    registerStringConcatenation();
  }

  void registerLocalFunction(ir.TreeNode node);

  @override
  Null handleFunctionDeclaration(ir.FunctionDeclaration node) {
    registerLocalFunction(node);
    handleAsyncMarker(node.function);
  }

  @override
  void handleFunctionExpression(ir.FunctionExpression node) {
    registerLocalFunction(node);
    handleAsyncMarker(node.function);
  }

  void registerLocalWithoutInitializer();

  @override
  void handleVariableDeclaration(ir.VariableDeclaration node) {
    if (node.initializer == null) {
      registerLocalWithoutInitializer();
    }
  }

  void registerIsCheck(ir.DartType type);

  @override
  void handleIsExpression(ir.IsExpression node) {
    registerIsCheck(node.type);
  }

  void registerImplicitCast(ir.DartType type);

  void registerAsCast(ir.DartType type);

  @override
  void handleAsExpression(ir.AsExpression node, ir.DartType operandType) {
    if (typeEnvironment.isSubtypeOf(operandType, node.type)) {
      // Skip unneeded casts.
      return;
    }
    if (node.isTypeError) {
      registerImplicitCast(node.type);
    } else {
      registerAsCast(node.type);
    }
  }

  void registerThrow();

  @override
  void handleThrow(ir.Throw node) {
    registerThrow();
  }

  void registerSyncForIn(ir.DartType iterableType);

  void registerAsyncForIn(ir.DartType iterableType);

  @override
  void handleForInStatement(ir.ForInStatement node, ir.DartType iterableType) {
    if (node.isAsync) {
      registerAsyncForIn(iterableType);
    } else {
      registerSyncForIn(iterableType);
    }
  }

  void registerCatch();

  void registerStackTrace();

  void registerCatchType(ir.DartType type);

  @override
  void handleCatch(ir.Catch node) {
    registerCatch();
    if (node.stackTrace != null) {
      registerStackTrace();
    }
    if (node.guard is! ir.DynamicType) {
      registerCatchType(node.guard);
    }
  }

  void registerTypeLiteral(ir.DartType type, ir.LibraryDependency import);

  @override
  void handleTypeLiteral(ir.TypeLiteral node) {
    registerTypeLiteral(node.type, getDeferredImport(node));
  }

  void registerFieldInitializer(ir.Field node);

  @override
  void handleFieldInitializer(ir.FieldInitializer node) {
    registerFieldInitializer(node.field);
  }

  void registerLoadLibrary();

  @override
  void handleLoadLibrary(ir.LoadLibrary node) {
    registerLoadLibrary();
  }

  void registerRedirectingInitializer(
      ir.Constructor constructor, ir.Arguments arguments);

  void handleRedirectingInitializer(
      ir.RedirectingInitializer node, ArgumentTypes argumentTypes) {
    registerRedirectingInitializer(node.target, node.arguments);
  }

  void registerParameterCheck(ir.DartType type);

  @override
  void handleParameter(ir.VariableDeclaration parameter) {
    registerParameterCheck(parameter.type);
  }

  @override
  void handleSignature(ir.FunctionNode node) {
    for (ir.TypeParameter parameter in node.typeParameters) {
      registerParameterCheck(parameter.bound);
    }
  }

  void registerLazyField();

  @override
  void handleField(ir.Field field) {
    registerParameterCheck(field.type);
    if (field.initializer != null) {
      if (!field.isInstanceMember &&
          !field.isConst &&
          field.initializer is! ir.NullLiteral) {
        registerLazyField();
      }
    } else {
      registerNullLiteral();
    }
  }

  @override
  void handleProcedure(ir.Procedure procedure) {
    handleAsyncMarker(procedure.function);
  }

  void registerNew(ir.Member constructor, ir.InterfaceType type,
      ir.Arguments arguments, ir.LibraryDependency import,
      {bool isConst});

  @override
  void handleConstructorInvocation(ir.ConstructorInvocation node,
      ArgumentTypes argumentTypes, ir.DartType resultType) {
    registerNew(node.target, node.constructedType, node.arguments,
        getDeferredImport(node),
        isConst: node.isConst);
  }

  void registerStaticInvocation(
      ir.Procedure target, ir.Arguments arguments, ir.LibraryDependency import);

  @override
  void handleStaticInvocation(ir.StaticInvocation node,
      ArgumentTypes argumentTypes, ir.DartType returnType) {
    if (node.target.kind == ir.ProcedureKind.Factory) {
      // TODO(johnniwinther): We should not mark the type as instantiated but
      // rather follow the type arguments directly.
      //
      // Consider this:
      //
      //    abstract class A<T> {
      //      factory A.regular() => new B<T>();
      //      factory A.redirect() = B<T>;
      //    }
      //
      //    class B<T> implements A<T> {}
      //
      //    main() {
      //      print(new A<int>.regular() is B<int>);
      //      print(new A<String>.redirect() is B<String>);
      //    }
      //
      // To track that B is actually instantiated as B<int> and B<String> we
      // need to follow the type arguments passed to A.regular and A.redirect
      // to B. Currently, we only do this soundly if we register A<int> and
      // A<String> as instantiated. We should instead register that A.T is
      // instantiated as int and String.
      registerNew(
          node.target,
          new ir.InterfaceType(
              node.target.enclosingClass, node.arguments.types),
          node.arguments,
          getDeferredImport(node),
          isConst: node.isConst);
    } else {
      registerStaticInvocation(
          node.target, node.arguments, getDeferredImport(node));
    }
  }

  void registerLocalFunctionInvocation(
      ir.FunctionDeclaration localFunction, ir.Arguments arguments);

  void registerDynamicInvocation(ir.DartType receiverType,
      ClassRelation relation, ir.Name name, ir.Arguments arguments);

  void registerInstanceInvocation(ir.DartType receiverType,
      ClassRelation relation, ir.Member target, ir.Arguments arguments);

  void registerFunctionInvocation(
      ir.DartType receiverType, ir.Arguments arguments);

  @override
  void handleMethodInvocation(
      ir.MethodInvocation node,
      ir.DartType receiverType,
      ArgumentTypes argumentTypes,
      ir.DartType returnType) {
    ir.Expression receiver = node.receiver;
    if (receiver is ir.VariableGet &&
        receiver.variable.isFinal &&
        receiver.variable.parent is ir.FunctionDeclaration) {
      registerLocalFunctionInvocation(receiver.variable.parent, node.arguments);
    } else {
      ClassRelation relation = _computeClassRelationFromType(receiverType);

      ir.Member interfaceTarget = node.interfaceTarget;
      if (interfaceTarget == null) {
        registerDynamicInvocation(
            receiverType, relation, node.name, node.arguments);
        // TODO(johnniwinther): Avoid treating a known function call as a
        // dynamic call when CFE provides a way to distinguish the two.
        if (operatorFromString(node.name.name) == null &&
            receiverType is ir.DynamicType) {
          // We might implicitly call a getter that returns a function.
          registerFunctionInvocation(const ir.DynamicType(), node.arguments);
        }
      } else {
        if (interfaceTarget is ir.Field ||
            interfaceTarget is ir.Procedure &&
                interfaceTarget.kind == ir.ProcedureKind.Getter) {
          registerInstanceInvocation(
              receiverType, relation, interfaceTarget, node.arguments);
          registerFunctionInvocation(
              interfaceTarget.getterType, node.arguments);
        } else {
          registerInstanceInvocation(
              receiverType, relation, interfaceTarget, node.arguments);
        }
      }
    }
  }

  @override
  void handleDirectMethodInvocation(
      ir.DirectMethodInvocation node,
      ir.DartType receiverType,
      ArgumentTypes argumentTypes,
      ir.DartType returnType) {
    registerInstanceInvocation(
        receiverType, ClassRelation.exact, node.target, node.arguments);
  }

  void registerDynamicGet(
      ir.DartType receiverType, ClassRelation relation, ir.Name name);

  void registerInstanceGet(
      ir.DartType receiverType, ClassRelation relation, ir.Member target);

  @override
  void handlePropertyGet(
      ir.PropertyGet node, ir.DartType receiverType, ir.DartType resultType) {
    ClassRelation relation = _computeClassRelationFromType(receiverType);
    if (node.interfaceTarget != null) {
      registerInstanceGet(receiverType, relation, node.interfaceTarget);
    } else {
      registerDynamicGet(receiverType, relation, node.name);
    }
  }

  @override
  void handleDirectPropertyGet(ir.DirectPropertyGet node,
      ir.DartType receiverType, ir.DartType resultType) {
    registerInstanceGet(receiverType, ClassRelation.exact, node.target);
  }

  void registerDynamicSet(
      ir.DartType receiverType, ClassRelation relation, ir.Name name);

  void registerInstanceSet(
      ir.DartType receiverType, ClassRelation relation, ir.Member target);

  @override
  void handlePropertySet(
      ir.PropertySet node, ir.DartType receiverType, ir.DartType valueType) {
    ClassRelation relation = _computeClassRelationFromType(receiverType);
    if (node.interfaceTarget != null) {
      registerInstanceSet(receiverType, relation, node.interfaceTarget);
    } else {
      registerDynamicSet(receiverType, relation, node.name);
    }
  }

  @override
  void handleDirectPropertySet(ir.DirectPropertySet node,
      ir.DartType receiverType, ir.DartType valueType) {
    registerInstanceSet(receiverType, ClassRelation.exact, node.target);
  }

  void registerSuperInvocation(ir.Name name, ir.Arguments arguments);

  @override
  void handleSuperMethodInvocation(ir.SuperMethodInvocation node,
      ArgumentTypes argumentTypes, ir.DartType returnType) {
    registerSuperInvocation(node.name, node.arguments);
  }

  void registerSuperGet(ir.Name name);

  @override
  void handleSuperPropertyGet(
      ir.SuperPropertyGet node, ir.DartType resultType) {
    registerSuperGet(node.name);
  }

  void registerSuperSet(ir.Name name);

  @override
  void handleSuperPropertySet(ir.SuperPropertySet node, ir.DartType valueType) {
    registerSuperSet(node.name);
  }

  void registerSuperInitializer(
      ir.Constructor source, ir.Constructor target, ir.Arguments arguments);

  @override
  void handleSuperInitializer(
      ir.SuperInitializer node, ArgumentTypes argumentTypes) {
    registerSuperInitializer(node.parent, node.target, node.arguments);
  }
}
