// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import 'entity_data.dart';

import '../common.dart';
import '../common/elements.dart' show CommonElements, KElementEnvironment;
import '../compiler.dart' show Compiler;
import '../constants/values.dart'
    show ConstantValue, ConstructedConstantValue, InstantiationConstantValue;
import '../elements/types.dart';
import '../elements/entities.dart';
import '../ir/util.dart';
import '../kernel/kelements.dart' show KLocalFunction;
import '../kernel/element_map.dart';
import '../universe/use.dart';
import '../universe/world_impact.dart' show WorldImpact, WorldImpactVisitorImpl;
import '../world.dart' show KClosedWorld;

/// [EntityDataInfo] is meta data about [EntityData] for a given compilation
/// [Entity].
class EntityDataInfo {
  /// The deferred [EntityData] roots collected by the collector.
  final Map<EntityData, List<ImportEntity>> deferredRoots = {};

  /// The direct [EntityData] collected by the collector.
  final Set<EntityData> directDependencies = {};

  /// Various [add] methods for various types of direct dependencies.
  void add(EntityData entityData, {ImportEntity import}) {
    // If we already have a direct dependency on [entityData] then we have
    // nothing left to do.
    if (directDependencies.contains(entityData)) return;

    // If [import] is null, then create a direct dependency on [entityData] and
    // remove any deferred roots. Otherwise, add [import] to [deferredRoots] for
    // [entityData].
    if (import == null) {
      deferredRoots.remove(entityData);
      directDependencies.add(entityData);
    } else {
      (deferredRoots[entityData] ??= []).add(import);
    }
  }
}

/// Builds [EntityDataInfo] to help update dependencies of [EntityData] in the
/// deferred_load algorithm.
class EntityDataInfoBuilder {
  final EntityDataInfo info = EntityDataInfo();
  final KClosedWorld closedWorld;
  final KernelToElementMap elementMap;
  final Compiler compiler;
  final EntityDataRegistry registry;

  EntityDataInfoBuilder(
      this.closedWorld, this.elementMap, this.compiler, this.registry);

  Map<Entity, WorldImpact> get impactCache => compiler.impactCache;
  KElementEnvironment get elementEnvironment =>
      compiler.frontendStrategy.elementEnvironment;
  CommonElements get commonElements => compiler.frontendStrategy.commonElements;

  void add(EntityData data, {ImportEntity import}) {
    info.add(data, import: import);
  }

  void addClass(ClassEntity cls, {ImportEntity import}) {
    add(registry.createClassEntityData(cls), import: import);

    // Add a classType entityData as well just in case we optimize out
    // the class later.
    addClassType(cls, import: import);
  }

  void addClassType(ClassEntity cls, {ImportEntity import}) {
    add(registry.createClassTypeEntityData(cls), import: import);
  }

  void addMember(MemberEntity m, {ImportEntity import}) {
    add(registry.createMemberEntityData(m), import: import);
  }

  void addConstant(ConstantValue c, {ImportEntity import}) {
    add(registry.createConstantEntityData(c), import: import);
  }

  void addLocalFunction(Local localFunction) {
    add(registry.createLocalFunctionEntityData(localFunction));
  }

  /// Recursively collects all the dependencies of [type].
  void addTypeDependencies(DartType type, [ImportEntity import]) {
    TypeEntityDataVisitor(this, import, commonElements).visit(type);
  }

  /// Recursively collects all the dependencies of [types].
  void addTypeListDependencies(Iterable<DartType> types,
      [ImportEntity import]) {
    if (types == null) return;
    TypeEntityDataVisitor(this, import, commonElements).visitList(types);
  }

  /// Collects all direct dependencies of [element].
  ///
  /// The collected dependent elements and constants are are added to
  /// [elements] and [constants] respectively.
  void addDirectMemberDependencies(MemberEntity element) {
    // TODO(sigurdm): We want to be more specific about this - need a better
    // way to query "liveness".
    if (!closedWorld.isMemberUsed(element)) {
      return;
    }
    _addDependenciesFromImpact(element);
    ConstantCollector.collect(elementMap, element, this);
  }

  void _addFromStaticUse(MemberEntity parent, StaticUse staticUse) {
    void processEntity() {
      Entity usedEntity = staticUse.element;
      if (usedEntity is MemberEntity) {
        addMember(usedEntity, import: staticUse.deferredImport);
      } else {
        assert(usedEntity is KLocalFunction,
            failedAt(usedEntity, "Unexpected static use $staticUse."));
        KLocalFunction localFunction = usedEntity;
        // TODO(sra): Consult KClosedWorld to see if signature is needed.
        addTypeDependencies(localFunction.functionType);
        addLocalFunction(localFunction);
      }
    }

    switch (staticUse.kind) {
      case StaticUseKind.CONSTRUCTOR_INVOKE:
      case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
        // The receiver type of generative constructors is a entityData of
        // the constructor (handled by `addMember` above) and not a
        // entityData at the call site.
        // Factory methods, on the other hand, are like static methods so
        // the target type is not relevant.
        // TODO(johnniwinther): Use rti need data to skip unneeded type
        // arguments.
        addTypeListDependencies(staticUse.type.typeArguments);
        processEntity();
        break;
      case StaticUseKind.STATIC_INVOKE:
      case StaticUseKind.CLOSURE_CALL:
      case StaticUseKind.DIRECT_INVOKE:
        // TODO(johnniwinther): Use rti need data to skip unneeded type
        // arguments.
        addTypeListDependencies(staticUse.typeArguments);
        processEntity();
        break;
      case StaticUseKind.STATIC_TEAR_OFF:
      case StaticUseKind.CLOSURE:
      case StaticUseKind.STATIC_GET:
      case StaticUseKind.STATIC_SET:
        processEntity();
        break;
      case StaticUseKind.SUPER_TEAR_OFF:
      case StaticUseKind.SUPER_FIELD_SET:
      case StaticUseKind.SUPER_GET:
      case StaticUseKind.SUPER_SETTER_SET:
      case StaticUseKind.SUPER_INVOKE:
      case StaticUseKind.INSTANCE_FIELD_GET:
      case StaticUseKind.INSTANCE_FIELD_SET:
      case StaticUseKind.FIELD_INIT:
      case StaticUseKind.FIELD_CONSTANT_INIT:
        // These static uses are not relevant for this algorithm.
        break;
      case StaticUseKind.CALL_METHOD:
      case StaticUseKind.INLINING:
        failedAt(parent, "Unexpected static use: $staticUse.");
        break;
    }
  }

  void _addFromTypeUse(MemberEntity parent, TypeUse typeUse) {
    void addClassIfInterfaceType(DartType t, [ImportEntity import]) {
      var typeWithoutNullability = t.withoutNullability;
      if (typeWithoutNullability is InterfaceType) {
        addClass(typeWithoutNullability.element, import: import);
      }
    }

    DartType type = typeUse.type;
    switch (typeUse.kind) {
      case TypeUseKind.TYPE_LITERAL:
        addTypeDependencies(type, typeUse.deferredImport);
        break;
      case TypeUseKind.CONST_INSTANTIATION:
        addClassIfInterfaceType(type, typeUse.deferredImport);
        addTypeDependencies(type, typeUse.deferredImport);
        break;
      case TypeUseKind.INSTANTIATION:
      case TypeUseKind.NATIVE_INSTANTIATION:
        addClassIfInterfaceType(type);
        addTypeDependencies(type);
        break;
      case TypeUseKind.IS_CHECK:
      case TypeUseKind.CATCH_TYPE:
        addTypeDependencies(type);
        break;
      case TypeUseKind.AS_CAST:
        if (closedWorld.annotationsData
            .getExplicitCastCheckPolicy(parent)
            .isEmitted) {
          addTypeDependencies(type);
        }
        break;
      case TypeUseKind.IMPLICIT_CAST:
        if (closedWorld.annotationsData
            .getImplicitDowncastCheckPolicy(parent)
            .isEmitted) {
          addTypeDependencies(type);
        }
        break;
      case TypeUseKind.PARAMETER_CHECK:
      case TypeUseKind.TYPE_VARIABLE_BOUND_CHECK:
        if (closedWorld.annotationsData
            .getParameterCheckPolicy(parent)
            .isEmitted) {
          addTypeDependencies(type);
        }
        break;
      case TypeUseKind.RTI_VALUE:
      case TypeUseKind.TYPE_ARGUMENT:
      case TypeUseKind.NAMED_TYPE_VARIABLE_NEW_RTI:
      case TypeUseKind.CONSTRUCTOR_REFERENCE:
        failedAt(parent, "Unexpected type use: $typeUse.");
        break;
    }
  }

  /// Extract any dependencies that are known from the impact of [element].
  void _addDependenciesFromImpact(MemberEntity element) {
    WorldImpact worldImpact = impactCache[element];
    worldImpact.apply(WorldImpactVisitorImpl(
        visitStaticUse: (MemberEntity member, StaticUse staticUse) {
      _addFromStaticUse(element, staticUse);
    }, visitTypeUse: (MemberEntity member, TypeUse typeUse) {
      _addFromTypeUse(element, typeUse);
    }, visitDynamicUse: (MemberEntity member, DynamicUse dynamicUse) {
      // TODO(johnniwinther): Use rti need data to skip unneeded type
      // arguments.
      addTypeListDependencies(dynamicUse.typeArguments);
    }));
  }
}

/// Collects the necessary [EntityDataInfo] for a given [EntityData].
class EntityDataInfoVisitor extends EntityDataVisitor {
  final EntityDataInfoBuilder infoBuilder;

  EntityDataInfoVisitor(this.infoBuilder);

  KClosedWorld get closedWorld => infoBuilder.closedWorld;
  KElementEnvironment get elementEnvironment =>
      infoBuilder.compiler.frontendStrategy.elementEnvironment;

  /// Finds all elements and constants that [element] depends directly on.
  /// (not the transitive closure.)
  ///
  /// Adds the results to [elements] and [constants].
  @override
  void visitClassEntityData(ClassEntity element) {
    // If we see a class, add everything its live instance members refer
    // to.  Static members are not relevant, unless we are processing
    // extra dependencies due to mirrors.
    void addLiveInstanceMember(MemberEntity member) {
      if (!closedWorld.isMemberUsed(member)) return;
      if (!member.isInstanceMember) return;
      infoBuilder.addMember(member);
      infoBuilder.addDirectMemberDependencies(member);
    }

    void addClassAndMaybeAddEffectiveMixinClass(ClassEntity cls) {
      infoBuilder.addClass(cls);
      if (elementEnvironment.isMixinApplication(cls)) {
        infoBuilder.addClass(elementEnvironment.getEffectiveMixinClass(cls));
      }
    }

    ClassEntity cls = element;
    elementEnvironment.forEachLocalClassMember(cls, addLiveInstanceMember);
    elementEnvironment.forEachSupertype(cls, (InterfaceType type) {
      infoBuilder.addTypeDependencies(type);
    });
    elementEnvironment.forEachSuperClass(cls, (superClass) {
      addClassAndMaybeAddEffectiveMixinClass(superClass);
      infoBuilder
          .addTypeDependencies(elementEnvironment.getThisType(superClass));
    });
    addClassAndMaybeAddEffectiveMixinClass(cls);
  }

  @override
  void visitClassTypeEntityData(ClassEntity element) {
    infoBuilder.addClassType(element);
  }

  /// Finds all elements and constants that [element] depends directly on.
  /// (not the transitive closure.)
  ///
  /// Adds the results to [elements] and [constants].
  @override
  void visitMemberEntityData(MemberEntity element) {
    if (element is FunctionEntity) {
      infoBuilder
          .addTypeDependencies(elementEnvironment.getFunctionType(element));
    }
    if (element.isStatic || element.isTopLevel || element.isConstructor) {
      infoBuilder.addMember(element);
      infoBuilder.addDirectMemberDependencies(element);
    }
    if (element is ConstructorEntity && element.isGenerativeConstructor) {
      // When instantiating a class, we record a reference to the
      // constructor, not the class itself.  We must add all the
      // instance members of the constructor's class.
      ClassEntity cls = element.enclosingClass;
      visitClassEntityData(cls);
    }

    // Other elements, in particular instance members, are ignored as
    // they are processed as part of the class.
  }

  @override
  void visitConstantEntityData(ConstantValue constant) {
    if (constant is ConstructedConstantValue) {
      infoBuilder.addClass(constant.type.element);
    }
    if (constant is InstantiationConstantValue) {
      for (DartType type in constant.typeArguments) {
        type = type.withoutNullability;
        if (type is InterfaceType) {
          infoBuilder.addClass(type.element);
        }
      }
    }

    // Constants are not allowed to refer to deferred constants, so
    // no need to check for a deferred type literal here.
    constant.getDependencies().forEach(infoBuilder.addConstant);
  }
}

class TypeEntityDataVisitor implements DartTypeVisitor<void, Null> {
  final EntityDataInfoBuilder _infoBuilder;
  final ImportEntity _import;
  final CommonElements _commonElements;

  TypeEntityDataVisitor(this._infoBuilder, this._import, this._commonElements);

  @override
  void visit(DartType type, [_]) {
    type.accept(this, null);
  }

  void visitList(List<DartType> types) {
    types.forEach(visit);
  }

  @override
  void visitLegacyType(LegacyType type, Null argument) {
    visit(type.baseType);
  }

  @override
  void visitNullableType(NullableType type, Null argument) {
    visit(type.baseType);
  }

  @override
  void visitFutureOrType(FutureOrType type, Null argument) {
    _infoBuilder.addClassType(_commonElements.futureClass);
    visit(type.typeArgument);
  }

  @override
  void visitNeverType(NeverType type, Null argument) {
    // Nothing to add.
  }

  @override
  void visitDynamicType(DynamicType type, Null argument) {
    // Nothing to add.
  }

  @override
  void visitErasedType(ErasedType type, Null argument) {
    // Nothing to add.
  }

  @override
  void visitAnyType(AnyType type, Null argument) {
    // Nothing to add.
  }

  @override
  void visitInterfaceType(InterfaceType type, Null argument) {
    visitList(type.typeArguments);
    _infoBuilder.addClassType(type.element, import: _import);
  }

  @override
  void visitFunctionType(FunctionType type, Null argument) {
    for (FunctionTypeVariable typeVariable in type.typeVariables) {
      visit(typeVariable.bound);
    }
    visitList(type.parameterTypes);
    visitList(type.optionalParameterTypes);
    visitList(type.namedParameterTypes);
    visit(type.returnType);
  }

  @override
  void visitFunctionTypeVariable(FunctionTypeVariable type, Null argument) {
    // Nothing to add. Handled in [visitFunctionType].
  }

  @override
  void visitTypeVariableType(TypeVariableType type, Null argument) {
    // TODO(johnniwinther): Do we need to collect the bound?
  }

  @override
  void visitVoidType(VoidType type, Null argument) {
    // Nothing to add.
  }
}

class ConstantCollector extends ir.RecursiveVisitor {
  final KernelToElementMap elementMap;
  final EntityDataInfoBuilder infoBuilder;
  final ir.StaticTypeContext staticTypeContext;

  ConstantCollector(this.elementMap, this.staticTypeContext, this.infoBuilder);

  CommonElements get commonElements => elementMap.commonElements;

  /// Extract the set of constants that are used in the body of [member].
  static void collect(KernelToElementMap elementMap, MemberEntity member,
      EntityDataInfoBuilder infoBuilder) {
    ir.Member node = elementMap.getMemberNode(member);

    // Fetch the internal node in order to skip annotations on the member.
    // TODO(sigmund): replace this pattern when the kernel-ast provides a better
    // way to skip annotations (issue 31565).
    var visitor = ConstantCollector(
        elementMap, elementMap.getStaticTypeContext(member), infoBuilder);
    if (node is ir.Field) {
      node.initializer?.accept(visitor);
      return;
    }

    if (node is ir.Constructor) {
      node.initializers.forEach((i) => i.accept(visitor));
    }
    node.function?.accept(visitor);
  }

  void add(ir.Expression node, {bool required = true}) {
    ConstantValue constant = elementMap
        .getConstantValue(staticTypeContext, node, requireConstant: required);
    if (constant != null) {
      infoBuilder.addConstant(constant,
          import: elementMap.getImport(getDeferredImport(node)));
    }
  }

  @override
  void visitIntLiteral(ir.IntLiteral literal) {}

  @override
  void visitDoubleLiteral(ir.DoubleLiteral literal) {}

  @override
  void visitBoolLiteral(ir.BoolLiteral literal) {}

  @override
  void visitStringLiteral(ir.StringLiteral literal) {}

  @override
  void visitSymbolLiteral(ir.SymbolLiteral literal) => add(literal);

  @override
  void visitNullLiteral(ir.NullLiteral literal) {}

  @override
  void visitListLiteral(ir.ListLiteral literal) {
    if (literal.isConst) {
      add(literal);
    } else {
      super.visitListLiteral(literal);
    }
  }

  @override
  void visitSetLiteral(ir.SetLiteral literal) {
    if (literal.isConst) {
      add(literal);
    } else {
      super.visitSetLiteral(literal);
    }
  }

  @override
  void visitMapLiteral(ir.MapLiteral literal) {
    if (literal.isConst) {
      add(literal);
    } else {
      super.visitMapLiteral(literal);
    }
  }

  @override
  void visitConstructorInvocation(ir.ConstructorInvocation node) {
    if (node.isConst) {
      add(node);
    } else {
      super.visitConstructorInvocation(node);
    }
  }

  @override
  void visitTypeParameter(ir.TypeParameter node) {
    // We avoid visiting metadata on the type parameter declaration. The bound
    // cannot hold constants so we skip that as well.
  }

  @override
  void visitVariableDeclaration(ir.VariableDeclaration node) {
    // We avoid visiting metadata on the parameter declaration by only visiting
    // the initializer. The type cannot hold constants so can kan skip that
    // as well.
    node.initializer?.accept(this);
  }

  @override
  void visitTypeLiteral(ir.TypeLiteral node) {
    if (node.type is! ir.TypeParameterType) add(node);
  }

  @override
  void visitInstantiation(ir.Instantiation node) {
    // TODO(johnniwinther): The CFE should mark constant instantiations as
    // constant.
    add(node, required: false);
    super.visitInstantiation(node);
  }

  @override
  void visitConstantExpression(ir.ConstantExpression node) {
    add(node);
  }
}
