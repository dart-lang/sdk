// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/dart2js.dart'
    show operatorFromString;

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import '../common.dart';
import 'constants.dart';
import 'impact_data.dart';
import 'runtime_type_analysis.dart';
import 'scope.dart';
import 'static_type.dart';
import 'static_type_cache.dart';
import 'util.dart';

/// Interface for collecting world impact data.
///
/// This is used both for direct world impact computation through the
/// [KernelImpactBuilder] and for serialization through the [ImpactBuilder]
/// and [ImpactLoader].
abstract class ImpactRegistry {
  void registerIntLiteral(int value);

  void registerDoubleLiteral(double value);

  void registerBoolLiteral(bool value);

  void registerStringLiteral(String value);

  void registerSymbolLiteral(String value);

  void registerNullLiteral();

  void registerListLiteral(ir.DartType elementType,
      {bool isConst, bool isEmpty});

  void registerSetLiteral(ir.DartType elementType,
      {bool isConst, bool isEmpty});

  void registerMapLiteral(ir.DartType keyType, ir.DartType valueType,
      {bool isConst, bool isEmpty});

  void registerStaticTearOff(
      ir.Procedure procedure, ir.LibraryDependency import);

  void registerStaticGet(ir.Member member, ir.LibraryDependency import);

  void registerStaticSet(ir.Member member, ir.LibraryDependency import);

  void registerAssert({bool withMessage});

  void registerGenericInstantiation(
      ir.FunctionType expressionType, List<ir.DartType> typeArguments);

  void registerSyncStar(ir.DartType elementType);

  void registerAsync(ir.DartType elementType);

  void registerAsyncStar(ir.DartType elementType);

  void registerStringConcatenation();

  void registerLocalFunction(ir.TreeNode node);

  void registerLocalWithoutInitializer();

  void registerIsCheck(ir.DartType type);

  void registerImplicitCast(ir.DartType type);

  void registerAsCast(ir.DartType type);

  void registerThrow();

  void registerSyncForIn(ir.DartType iterableType, ir.DartType iteratorType,
      ClassRelation iteratorClassRelation);

  void registerAsyncForIn(ir.DartType iterableType, ir.DartType iteratorType,
      ClassRelation iteratorClassRelation);

  void registerCatch();

  void registerStackTrace();

  void registerCatchType(ir.DartType type);

  void registerTypeLiteral(ir.DartType type, ir.LibraryDependency import);

  void registerFieldInitialization(ir.Field node);

  void registerFieldConstantInitialization(
      ir.Field node, ConstantReference constant);

  void registerLoadLibrary();

  void registerRedirectingInitializer(
      ir.Constructor constructor,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments);

  void registerParameterCheck(ir.DartType type);

  void registerLazyField();

  void registerNew(
      ir.Member constructor,
      ir.InterfaceType type,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments,
      ir.LibraryDependency import,
      {bool isConst});

  void registerConstInstantiation(ir.Class cls, List<ir.DartType> typeArguments,
      ir.LibraryDependency import);

  void registerStaticInvocation(
      ir.Procedure target,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments,
      ir.LibraryDependency import);

  void registerLocalFunctionInvocation(
      ir.FunctionDeclaration localFunction,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments);

  void registerDynamicInvocation(
      ir.DartType receiverType,
      ClassRelation relation,
      ir.Name name,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments);

  void registerInstanceInvocation(
      ir.DartType receiverType,
      ClassRelation relation,
      ir.Member target,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments);

  void registerFunctionInvocation(
      ir.DartType receiverType,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments);

  void registerDynamicGet(
      ir.DartType receiverType, ClassRelation relation, ir.Name name);

  void registerInstanceGet(
      ir.DartType receiverType, ClassRelation relation, ir.Member target);

  void registerDynamicSet(
      ir.DartType receiverType, ClassRelation relation, ir.Name name);

  void registerInstanceSet(
      ir.DartType receiverType, ClassRelation relation, ir.Member target);

  void registerSuperInvocation(ir.Name name, int positionalArguments,
      List<String> namedArguments, List<ir.DartType> typeArguments);

  void registerSuperGet(ir.Name name);

  void registerSuperSet(ir.Name name);

  void registerSuperInitializer(
      ir.Constructor source,
      ir.Constructor target,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments);

  void registerRuntimeTypeUse(ir.PropertyGet node, RuntimeTypeUseKind kind,
      ir.DartType receiverType, ir.DartType argumentType);

  // TODO(johnniwinther): Remove these when CFE provides constants.
  void registerConstructorNode(ir.Constructor node);
  void registerFieldNode(ir.Field node);
  void registerProcedureNode(ir.Procedure node);
  void registerStaticInvocationNode(ir.StaticInvocation node);
  void registerSwitchStatementNode(ir.SwitchStatement node);
  void registerConstConstructorInvocationNode(ir.ConstructorInvocation node);
}

abstract class ImpactBuilderBase extends StaticTypeVisitor
    implements ImpactRegistry {
  @override
  final VariableScopeModel variableScopeModel;

  @override
  final ir.StaticTypeContext staticTypeContext;

  ImpactBuilderBase(this.staticTypeContext, StaticTypeCacheImpl staticTypeCache,
      ir.ClassHierarchy classHierarchy, this.variableScopeModel)
      : super(
            staticTypeContext.typeEnvironment, classHierarchy, staticTypeCache);

  @override
  void handleIntLiteral(ir.IntLiteral node) {
    registerIntLiteral(node.value);
  }

  @override
  void handleDoubleLiteral(ir.DoubleLiteral node) {
    registerDoubleLiteral(node.value);
  }

  @override
  void handleBoolLiteral(ir.BoolLiteral node) {
    registerBoolLiteral(node.value);
  }

  @override
  void handleStringLiteral(ir.StringLiteral node) {
    registerStringLiteral(node.value);
  }

  @override
  void handleSymbolLiteral(ir.SymbolLiteral node) {
    registerSymbolLiteral(node.value);
  }

  @override
  void handleNullLiteral(ir.NullLiteral node) {
    registerNullLiteral();
  }

  @override
  void handleListLiteral(ir.ListLiteral node) {
    registerListLiteral(node.typeArgument,
        isConst: node.isConst, isEmpty: node.expressions.isEmpty);
  }

  @override
  void handleSetLiteral(ir.SetLiteral node) {
    registerSetLiteral(node.typeArgument,
        isConst: node.isConst, isEmpty: node.expressions.isEmpty);
  }

  @override
  void handleMapLiteral(ir.MapLiteral node) {
    registerMapLiteral(node.keyType, node.valueType,
        isConst: node.isConst, isEmpty: node.entries.isEmpty);
  }

  @override
  void handleStaticGet(ir.StaticGet node, ir.DartType resultType) {
    ir.Member target = node.target;
    if (target is ir.Procedure && target.kind == ir.ProcedureKind.Method) {
      registerStaticTearOff(target, getDeferredImport(node));
    } else {
      registerStaticGet(target, getDeferredImport(node));
    }
  }

  @override
  void handleStaticSet(ir.StaticSet node, ir.DartType valueType) {
    registerStaticSet(node.target, getDeferredImport(node));
  }

  @override
  void handleAssertStatement(ir.AssertStatement node) {
    registerAssert(withMessage: node.message != null);
  }

  @override
  void handleInstantiation(ir.Instantiation node,
      ir.FunctionType expressionType, ir.DartType resultType) {
    registerGenericInstantiation(expressionType, node.typeArguments);
  }

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
        if (returnType is ir.InterfaceType &&
            returnType.classNode == typeEnvironment.coreTypes.futureClass) {
          elementType = returnType.typeArguments.first;
        } else if (returnType is ir.FutureOrType) {
          elementType = returnType.typeArgument;
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

  @override
  void handleStringConcatenation(ir.StringConcatenation node) {
    registerStringConcatenation();
  }

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

  @override
  void handleVariableDeclaration(ir.VariableDeclaration node) {
    if (node.initializer == null) {
      registerLocalWithoutInitializer();
    }
  }

  @override
  void handleIsExpression(ir.IsExpression node) {
    registerIsCheck(node.type);
  }

  @override
  void handleAsExpression(ir.AsExpression node, ir.DartType operandType) {
    if (typeEnvironment.isSubtypeOf(
        operandType, node.type, ir.SubtypeCheckMode.ignoringNullabilities)) {
      // Skip unneeded casts.
      return;
    }
    if (node.isTypeError) {
      registerImplicitCast(node.type);
    } else {
      registerAsCast(node.type);
    }
  }

  @override
  void handleThrow(ir.Throw node) {
    registerThrow();
  }

  @override
  void handleForInStatement(ir.ForInStatement node, ir.DartType iterableType,
      ir.DartType iteratorType) {
    if (node.isAsync) {
      registerAsyncForIn(iterableType, iteratorType,
          computeClassRelationFromType(iteratorType));
    } else {
      registerSyncForIn(iterableType, iteratorType,
          computeClassRelationFromType(iteratorType));
    }
  }

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

  @override
  void handleTypeLiteral(ir.TypeLiteral node) {
    registerTypeLiteral(node.type, getDeferredImport(node));
  }

  @override
  void handleFieldInitializer(ir.FieldInitializer node) {
    registerFieldInitialization(node.field);
  }

  @override
  void handleLoadLibrary(ir.LoadLibrary node) {
    registerLoadLibrary();
  }

  @override
  void handleRedirectingInitializer(
      ir.RedirectingInitializer node, ArgumentTypes argumentTypes) {
    registerRedirectingInitializer(
        node.target,
        node.arguments.positional.length,
        _getNamedArguments(node.arguments),
        node.arguments.types);
  }

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

  @override
  void handleConstructor(ir.Constructor node) {
    registerConstructorNode(node);
  }

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
    registerFieldNode(field);
  }

  @override
  void handleProcedure(ir.Procedure procedure) {
    handleAsyncMarker(procedure.function);
    registerProcedureNode(procedure);
  }

  @override
  void handleConstructorInvocation(ir.ConstructorInvocation node,
      ArgumentTypes argumentTypes, ir.DartType resultType) {
    registerNew(
        node.target,
        node.constructedType,
        node.arguments.positional.length,
        _getNamedArguments(node.arguments),
        node.arguments.types,
        getDeferredImport(node),
        isConst: node.isConst);
    if (node.isConst) {
      registerConstConstructorInvocationNode(node);
    }
  }

  @override
  void handleStaticInvocation(ir.StaticInvocation node,
      ArgumentTypes argumentTypes, ir.DartType returnType) {
    int positionArguments = node.arguments.positional.length;
    List<String> namedArguments = _getNamedArguments(node.arguments);
    List<ir.DartType> typeArguments = node.arguments.types;
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
          new ir.InterfaceType(node.target.enclosingClass,
              node.target.enclosingLibrary.nonNullable, typeArguments),
          positionArguments,
          namedArguments,
          node.arguments.types,
          getDeferredImport(node),
          isConst: node.isConst);
    } else {
      registerStaticInvocation(node.target, positionArguments, namedArguments,
          typeArguments, getDeferredImport(node));
    }
    registerStaticInvocationNode(node);
  }

  @override
  void handleMethodInvocation(
      ir.MethodInvocation node,
      ir.DartType receiverType,
      ArgumentTypes argumentTypes,
      ir.DartType returnType) {
    int positionArguments = node.arguments.positional.length;
    List<String> namedArguments = _getNamedArguments(node.arguments);
    List<ir.DartType> typeArguments = node.arguments.types;
    ir.Expression receiver = node.receiver;
    if (receiver is ir.VariableGet &&
        receiver.variable.isFinal &&
        receiver.variable.parent is ir.FunctionDeclaration) {
      registerLocalFunctionInvocation(receiver.variable.parent,
          positionArguments, namedArguments, typeArguments);
    } else {
      ClassRelation relation = computeClassRelationFromType(receiverType);

      ir.Member interfaceTarget = node.interfaceTarget;
      if (interfaceTarget == null) {
        registerDynamicInvocation(receiverType, relation, node.name,
            positionArguments, namedArguments, typeArguments);
        // TODO(johnniwinther): Avoid treating a known function call as a
        // dynamic call when CFE provides a way to distinguish the two.
        if (operatorFromString(node.name.text) == null &&
            receiverType is ir.DynamicType) {
          // We might implicitly call a getter that returns a function.
          registerFunctionInvocation(const ir.DynamicType(), positionArguments,
              namedArguments, typeArguments);
        }
      } else {
        if (interfaceTarget is ir.Field ||
            interfaceTarget is ir.Procedure &&
                interfaceTarget.kind == ir.ProcedureKind.Getter) {
          registerInstanceInvocation(receiverType, relation, interfaceTarget,
              positionArguments, namedArguments, typeArguments);
          registerFunctionInvocation(interfaceTarget.getterType,
              positionArguments, namedArguments, typeArguments);
        } else {
          registerInstanceInvocation(receiverType, relation, interfaceTarget,
              positionArguments, namedArguments, typeArguments);
        }
      }
    }
  }

  @override
  void handlePropertyGet(
      ir.PropertyGet node, ir.DartType receiverType, ir.DartType resultType) {
    ClassRelation relation = computeClassRelationFromType(receiverType);
    if (node.interfaceTarget != null) {
      registerInstanceGet(receiverType, relation, node.interfaceTarget);
    } else {
      registerDynamicGet(receiverType, relation, node.name);
    }
  }

  @override
  void handlePropertySet(
      ir.PropertySet node, ir.DartType receiverType, ir.DartType valueType) {
    ClassRelation relation = computeClassRelationFromType(receiverType);
    if (node.interfaceTarget != null) {
      registerInstanceSet(receiverType, relation, node.interfaceTarget);
    } else {
      registerDynamicSet(receiverType, relation, node.name);
    }
  }

  @override
  void handleSuperMethodInvocation(ir.SuperMethodInvocation node,
      ArgumentTypes argumentTypes, ir.DartType returnType) {
    registerSuperInvocation(node.name, node.arguments.positional.length,
        _getNamedArguments(node.arguments), node.arguments.types);
  }

  @override
  void handleSuperPropertyGet(
      ir.SuperPropertyGet node, ir.DartType resultType) {
    registerSuperGet(node.name);
  }

  @override
  void handleSuperPropertySet(ir.SuperPropertySet node, ir.DartType valueType) {
    registerSuperSet(node.name);
  }

  @override
  void handleSuperInitializer(
      ir.SuperInitializer node, ArgumentTypes argumentTypes) {
    registerSuperInitializer(
        node.parent,
        node.target,
        node.arguments.positional.length,
        _getNamedArguments(node.arguments),
        node.arguments.types);
  }

  @override
  Null visitSwitchStatement(ir.SwitchStatement node) {
    registerSwitchStatementNode(node);
    return super.visitSwitchStatement(node);
  }

  @override
  void handleRuntimeTypeUse(ir.PropertyGet node, RuntimeTypeUseKind kind,
      ir.DartType receiverType, ir.DartType argumentType) {
    registerRuntimeTypeUse(node, kind, receiverType, argumentType);
  }

  @override
  void handleConstantExpression(ir.ConstantExpression node) {
    ir.LibraryDependency import = getDeferredImport(node);
    new ConstantImpactVisitor(this, import, node).visitConstant(node.constant);
  }
}

/// Visitor that builds an [ImpactData] object for the world impact.
class ImpactBuilder extends ImpactBuilderBase with ImpactRegistryMixin {
  @override
  final bool useAsserts;

  @override
  final inferEffectivelyFinalVariableTypes;

  ImpactBuilder(
      ir.StaticTypeContext staticTypeContext,
      StaticTypeCacheImpl staticTypeCache,
      ir.ClassHierarchy classHierarchy,
      VariableScopeModel variableScopeModel,
      {this.useAsserts: false,
      this.inferEffectivelyFinalVariableTypes: true})
      : super(staticTypeContext, staticTypeCache, classHierarchy,
            variableScopeModel);

  ImpactBuilderData computeImpact(ir.Member node) {
    if (retainDataForTesting) {
      typeMapsForTesting = {};
    }
    node.accept(this);
    return new ImpactBuilderData(
        impactData, typeMapsForTesting, getStaticTypeCache());
  }
}

/// Return the named arguments names as a list of strings.
List<String> _getNamedArguments(ir.Arguments arguments) =>
    arguments.named.map((n) => n.name).toList();

class ImpactBuilderData {
  final ImpactData impactData;
  final Map<ir.Expression, TypeMap> typeMapsForTesting;
  final StaticTypeCache cachedStaticTypes;

  ImpactBuilderData(
      this.impactData, this.typeMapsForTesting, this.cachedStaticTypes);
}

class ConstantImpactVisitor extends ir.VisitOnceConstantVisitor {
  final ImpactRegistry registry;
  final ir.LibraryDependency import;
  final ir.ConstantExpression expression;

  ConstantImpactVisitor(this.registry, this.import, this.expression);

  @override
  void defaultConstant(ir.Constant node) {
    throw new UnsupportedError(
        "Unexpected constant ${node} (${node.runtimeType}).");
  }

  @override
  void visitUnevaluatedConstant(ir.UnevaluatedConstant node) {
    // Do nothing. This occurs when the constant couldn't be evaluated because
    // of a compile-time error.
  }

  @override
  void visitTypeLiteralConstant(ir.TypeLiteralConstant node) {
    registry.registerTypeLiteral(node.type, import);
  }

  @override
  void visitTearOffConstant(ir.TearOffConstant node) {
    registry.registerStaticTearOff(node.procedure, import);
  }

  @override
  void visitPartialInstantiationConstant(ir.PartialInstantiationConstant node) {
    registry.registerGenericInstantiation(
        node.tearOffConstant.procedure.function.computeFunctionType(
            node.tearOffConstant.procedure.enclosingLibrary.nonNullable),
        node.types);
    visitConstant(node.tearOffConstant);
  }

  @override
  void visitInstanceConstant(ir.InstanceConstant node) {
    registry.registerConstInstantiation(
        node.classNode, node.typeArguments, import);
    node.fieldValues.forEach((ir.Reference reference, ir.Constant value) {
      ir.Field field = reference.asField;
      registry.registerFieldConstantInitialization(
          field, new ConstantReference(expression, value));
      visitConstant(value);
    });
  }

  @override
  void visitSetConstant(ir.SetConstant node) {
    registry.registerSetLiteral(node.typeArgument,
        isConst: true, isEmpty: node.entries.isEmpty);
    for (ir.Constant element in node.entries) {
      visitConstant(element);
    }
  }

  @override
  void visitListConstant(ir.ListConstant node) {
    registry.registerListLiteral(node.typeArgument,
        isConst: true, isEmpty: node.entries.isEmpty);
    for (ir.Constant element in node.entries) {
      visitConstant(element);
    }
  }

  @override
  void visitMapConstant(ir.MapConstant node) {
    registry.registerMapLiteral(node.keyType, node.valueType,
        isConst: true, isEmpty: node.entries.isEmpty);
    for (ir.ConstantMapEntry entry in node.entries) {
      visitConstant(entry.key);
      visitConstant(entry.value);
    }
  }

  @override
  void visitSymbolConstant(ir.SymbolConstant node) {
    // TODO(johnniwinther): Handle the library reference.
    registry.registerSymbolLiteral(node.name);
  }

  @override
  void visitStringConstant(ir.StringConstant node) {
    registry.registerStringLiteral(node.value);
  }

  @override
  void visitDoubleConstant(ir.DoubleConstant node) {
    registry.registerDoubleLiteral(node.value);
  }

  @override
  void visitIntConstant(ir.IntConstant node) {
    registry.registerIntLiteral(node.value);
  }

  @override
  void visitBoolConstant(ir.BoolConstant node) {
    registry.registerBoolLiteral(node.value);
  }

  @override
  void visitNullConstant(ir.NullConstant node) {
    registry.registerNullLiteral();
  }
}
