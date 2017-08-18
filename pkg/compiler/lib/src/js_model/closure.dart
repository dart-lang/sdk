// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../common.dart';
import '../common/tasks.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/names.dart' show Name;
import '../elements/types.dart';
import '../kernel/element_map.dart';
import '../kernel/env.dart';
import '../world.dart';
import 'elements.dart';
import 'closure_visitors.dart';
import 'locals.dart';
import 'js_strategy.dart' show JsClosedWorld;

class KernelClosureAnalysis {
  /// Inspect members and mark if those members capture any state that needs to
  /// be marked as free variables.
  static ScopeModel computeScopeModel(MemberEntity entity, ir.Member node) {
    if (entity.isAbstract) return null;
    if (entity.isField && !entity.isInstanceMember) {
      ir.Field field = node;
      // Skip top-level/static fields without an initializer.
      if (field.initializer == null) return null;
    }

    ScopeModel model = new ScopeModel();
    CapturedScopeBuilder translator = new CapturedScopeBuilder(model,
        hasThisLocal: entity.isInstanceMember || entity.isConstructor);
    if (entity.isField) {
      if (node is ir.Field && node.initializer != null) {
        translator.translateLazyInitializer(node);
      } else {
        assert(entity.isInstanceMember);
        model.scopeInfo = new KernelScopeInfo(true);
      }
    } else {
      assert(node is ir.Procedure || node is ir.Constructor);
      translator.translateConstructorOrProcedure(node);
    }
    return model;
  }
}

/// Closure conversion code using our new Entity model. Closure conversion is
/// necessary because the semantics of closures are slightly different in Dart
/// than JavaScript. Closure conversion is separated out into two phases:
/// generation of a new (temporary) representation to store where variables need
/// to be hoisted/captured up at another level to re-write the closure, and then
/// the code generation phase where we generate elements and/or instructions to
/// represent this new code path.
///
/// For a general explanation of how closure conversion works at a high level,
/// check out:
/// http://siek.blogspot.com/2012/07/essence-of-closure-conversion.html or
/// http://matt.might.net/articles/closure-conversion/.
// TODO(efortuna): Change inheritance hierarchy so that the
// ClosureConversionTask doesn't inherit from ClosureTask because it's just a
// glorified timer.
class KernelClosureConversionTask extends ClosureConversionTask<ir.Node> {
  final KernelToElementMapForBuilding _elementMap;
  final GlobalLocalsMap _globalLocalsMap;
  final Map<MemberEntity, ScopeModel> _closureModels;

  /// Map of the scoping information that corresponds to a particular entity.
  Map<Entity, ScopeInfo> _scopeMap = <Entity, ScopeInfo>{};
  Map<ir.Node, CapturedScope> _capturedScopesMap = <ir.Node, CapturedScope>{};

  Map<Entity, ClosureRepresentationInfo> _closureRepresentationMap =
      <Entity, ClosureRepresentationInfo>{};

  KernelClosureConversionTask(Measurer measurer, this._elementMap,
      this._globalLocalsMap, this._closureModels)
      : super(measurer);

  /// The combined steps of generating our intermediate representation of
  /// closures that need to be rewritten and generating the element model.
  /// Ultimately these two steps will be split apart with the second step
  /// happening later in compilation just before codegen. These steps are
  /// combined here currently to provide a consistent interface to the rest of
  /// the compiler until we are ready to separate these phases.
  @override
  void convertClosures(Iterable<MemberEntity> processedEntities,
      ClosedWorldRefiner closedWorldRefiner) {
    _createClosureEntities(_closureModels, closedWorldRefiner);
  }

  void _createClosureEntities(Map<MemberEntity, ScopeModel> closureModels,
      JsClosedWorld closedWorldRefiner) {
    closureModels.forEach((MemberEntity member, ScopeModel model) {
      KernelToLocalsMap localsMap = _globalLocalsMap.getLocalsMap(member);
      if (model.scopeInfo != null) {
        _scopeMap[member] = new JsScopeInfo.from(model.scopeInfo, localsMap);
      }

      model.capturedScopesMap
          .forEach((ir.Node node, KernelCapturedScope scope) {
        if (scope is KernelCapturedLoopScope) {
          _capturedScopesMap[node] =
              new JsCapturedLoopScope.from(scope, localsMap);
        } else {
          _capturedScopesMap[node] = new JsCapturedScope.from(scope, localsMap);
        }
      });

      Map<ir.FunctionNode, KernelScopeInfo> closuresToGenerate =
          model.closuresToGenerate;
      for (ir.FunctionNode node in closuresToGenerate.keys) {
        KernelClosureClass closureClass = _produceSyntheticElements(
            member, node, closuresToGenerate[node], closedWorldRefiner);
        // Add also for the call method.
        _scopeMap[closureClass.callMethod] = closureClass;
      }
    });
  }

  /// Given what variables are captured at each point, construct closure classes
  /// with fields containing the captured variables to replicate the Dart
  /// closure semantics in JS. If this closure captures any variables (meaning
  /// the closure accesses a variable that gets accessed at some point), then
  /// boxForCapturedVariables stores the local context for those variables.
  /// If no variables are captured, this parameter is null.
  KernelClosureClass _produceSyntheticElements(
      MemberEntity member,
      ir.FunctionNode node,
      KernelScopeInfo info,
      JsClosedWorld closedWorldRefiner) {
    KernelToLocalsMap localsMap = _globalLocalsMap.getLocalsMap(member);
    KernelClosureClass closureClass = closedWorldRefiner.buildClosureClass(
        member, node, member.library, info, node.location, localsMap);

    // We want the original declaration where that function is used to point
    // to the correct closure class.
    _closureRepresentationMap[closureClass.callMethod] = closureClass;
    Entity entity;
    if (node.parent is ir.Member) {
      entity = _elementMap.getMember(node.parent);
    } else {
      entity = localsMap.getLocalFunction(node.parent);
    }
    assert(entity != null);
    _closureRepresentationMap[entity] = closureClass;
    return closureClass;
  }

  @override
  ScopeInfo getScopeInfo(Entity entity) {
    // TODO(johnniwinther): Remove this check when constructor bodies a created
    // eagerly with the J-model; a constructor body should have it's own
    // [ClosureRepresentationInfo].
    if (entity is ConstructorBodyEntity) {
      ConstructorBodyEntity constructorBody = entity;
      entity = constructorBody.constructor;
    }

    return _scopeMap[entity] ?? getClosureRepresentationInfo(entity);
  }

  // TODO(efortuna): Eventually capturedScopesMap[node] should always
  // be non-null, and we should just test that with an assert.
  @override
  CapturedScope getCapturedScope(MemberEntity entity) {
    MemberDefinition definition = _elementMap.getMemberDefinition(entity);
    switch (definition.kind) {
      case MemberKind.regular:
      case MemberKind.constructor:
      case MemberKind.constructorBody:
      case MemberKind.closureCall:
        return _capturedScopesMap[definition.node] ?? const CapturedScope();
      default:
        throw failedAt(entity, "Unexpected member definition $definition");
    }
  }

  @override
  // TODO(efortuna): Eventually capturedScopesMap[node] should always
  // be non-null, and we should just test that with an assert.
  CapturedLoopScope getCapturedLoopScope(ir.Node loopNode) =>
      _capturedScopesMap[loopNode] ?? const CapturedLoopScope();

  @override
  ClosureRepresentationInfo getClosureRepresentationInfo(Entity entity) {
    var closure = _closureRepresentationMap[entity];
    assert(
        closure != null,
        "Corresponding closure class not found for $entity. "
        "Closures found for ${_closureRepresentationMap.keys}");
    return closure;
  }

  @override
  ClosureRepresentationInfo getClosureRepresentationInfoForTesting(
      Entity member) {
    return _closureRepresentationMap[member];
  }
}

class KernelScopeInfo {
  final Set<ir.VariableDeclaration> localsUsedInTryOrSync;
  final bool hasThisLocal;
  final Set<ir.VariableDeclaration> boxedVariables;
  // If boxedVariables is empty, this will be null, because no variables will
  // need to be boxed.
  final NodeBox capturedVariablesAccessor;

  /// The set of variables that were defined in another scope, but are used in
  /// this scope.
  Set<ir.VariableDeclaration> freeVariables = new Set<ir.VariableDeclaration>();

  KernelScopeInfo(this.hasThisLocal)
      : localsUsedInTryOrSync = new Set<ir.VariableDeclaration>(),
        boxedVariables = new Set<ir.VariableDeclaration>(),
        capturedVariablesAccessor = null;

  KernelScopeInfo.from(this.hasThisLocal, KernelScopeInfo info)
      : localsUsedInTryOrSync = info.localsUsedInTryOrSync,
        boxedVariables = info.boxedVariables,
        capturedVariablesAccessor = null;

  KernelScopeInfo.withBoxedVariables(
      this.boxedVariables,
      this.capturedVariablesAccessor,
      this.localsUsedInTryOrSync,
      this.freeVariables,
      this.hasThisLocal);

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('this=$hasThisLocal,');
    sb.write('localsUsedInTryOrSync={${localsUsedInTryOrSync.join(', ')}}');
    return sb.toString();
  }
}

class JsScopeInfo extends ScopeInfo {
  final Set<Local> localsUsedInTryOrSync;
  final Local thisLocal;
  final Set<Local> boxedVariables;

  /// The set of variables that were defined in another scope, but are used in
  /// this scope.
  final Set<Local> freeVariables;

  JsScopeInfo(this.thisLocal, this.localsUsedInTryOrSync, this.boxedVariables,
      this.freeVariables);

  JsScopeInfo.from(KernelScopeInfo info, KernelToLocalsMap localsMap)
      : this.thisLocal =
            info.hasThisLocal ? new ThisLocal(localsMap.currentMember) : null,
        this.localsUsedInTryOrSync =
            info.localsUsedInTryOrSync.map(localsMap.getLocalVariable).toSet(),
        this.boxedVariables =
            info.boxedVariables.map(localsMap.getLocalVariable).toSet(),
        this.freeVariables =
            info.freeVariables.map(localsMap.getLocalVariable).toSet();

  void forEachBoxedVariable(f(Local local, FieldEntity field)) {
    boxedVariables.forEach((Local l) {
      // TODO(efortuna): add FieldEntities as created.
      f(l, null);
    });
  }

  bool localIsUsedInTryOrSync(Local variable) =>
      localsUsedInTryOrSync.contains(variable);

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('this=$thisLocal,');
    sb.write('localsUsedInTryOrSync={${localsUsedInTryOrSync.join(', ')}}');
    return sb.toString();
  }

  bool isBoxed(Local variable) => boxedVariables.contains(variable);
}

class KernelCapturedScope extends KernelScopeInfo {
  final ir.TreeNode context;

  KernelCapturedScope(
      Set<ir.VariableDeclaration> boxedVariables,
      NodeBox capturedVariablesAccessor,
      this.context,
      Set<ir.VariableDeclaration> localsUsedInTryOrSync,
      Set<ir.VariableDeclaration> freeVariables,
      bool hasThisLocal)
      : super.withBoxedVariables(boxedVariables, capturedVariablesAccessor,
            localsUsedInTryOrSync, freeVariables, hasThisLocal);

  bool get requiresContextBox => boxedVariables.isNotEmpty;
}

class JsCapturedScope extends JsScopeInfo implements CapturedScope {
  final Local context;

  JsCapturedScope.from(
      KernelCapturedScope capturedScope, KernelToLocalsMap localsMap)
      : this.context = localsMap.getLocalVariable(capturedScope.context),
        super.from(capturedScope, localsMap);

  bool get requiresContextBox => boxedVariables.isNotEmpty;
}

class KernelCapturedLoopScope extends KernelCapturedScope {
  final List<ir.VariableDeclaration> boxedLoopVariables;

  KernelCapturedLoopScope(
      Set<ir.VariableDeclaration> boxedVariables,
      NodeBox capturedVariablesAccessor,
      this.boxedLoopVariables,
      ir.TreeNode context,
      Set<ir.VariableDeclaration> localsUsedInTryOrSync,
      Set<ir.VariableDeclaration> freeVariables,
      bool hasThisLocal)
      : super(boxedVariables, capturedVariablesAccessor, context,
            localsUsedInTryOrSync, freeVariables, hasThisLocal);

  bool get hasBoxedLoopVariables => boxedLoopVariables.isNotEmpty;
}

class JsCapturedLoopScope extends JsCapturedScope implements CapturedLoopScope {
  final List<Local> boxedLoopVariables;

  JsCapturedLoopScope.from(
      KernelCapturedLoopScope capturedScope, KernelToLocalsMap localsMap)
      : this.boxedLoopVariables = capturedScope.boxedLoopVariables
            .map(localsMap.getLocalVariable)
            .toList(),
        super.from(capturedScope, localsMap);

  bool get hasBoxedLoopVariables => boxedLoopVariables.isNotEmpty;
}

// TODO(johnniwinther): Add unittest for the computed [ClosureClass].
class KernelClosureClass extends JsScopeInfo
    implements ClosureRepresentationInfo {
  JFunction callMethod;
  final Local closureEntity;
  final Local thisLocal;
  final JClass closureClassEntity;

  final Map<Local, JField> localToFieldMap = new Map<Local, JField>();

  KernelClosureClass.fromScopeInfo(
      this.closureClassEntity,
      ir.FunctionNode closureSourceNode,
      KernelScopeInfo info,
      KernelToLocalsMap localsMap)
      : closureEntity = closureSourceNode.parent is ir.Member
            ? null
            : localsMap.getLocalFunction(closureSourceNode.parent),
        thisLocal =
            info.hasThisLocal ? new ThisLocal(localsMap.currentMember) : null,
        super.from(info, localsMap);

  List<Local> get createdFieldEntities => localToFieldMap.keys.toList();

  FieldEntity get thisFieldEntity => localToFieldMap[thisLocal];

  void forEachCapturedVariable(f(Local from, JField to)) {
    localToFieldMap.forEach(f);
  }

  @override
  void forEachBoxedVariable(f(Local local, JField field)) {
    for (Local l in localToFieldMap.keys) {
      if (localToFieldMap[l] is JBoxedField) f(l, localToFieldMap[l]);
    }
  }

  void forEachFreeVariable(f(Local variable, JField field)) {
    for (Local l in localToFieldMap.keys) {
      var jField = localToFieldMap[l];
      if (jField is! JBoxedField && jField is! BoxLocal) f(l, jField);
    }
  }

  bool isVariableBoxed(Local variable) =>
      localToFieldMap.keys.contains(variable);

  bool get isClosure => true;
}

/// A local variable to disambiguate between a variable that has been captured
/// from one scope to another. This is the ir.Node version that corresponds to
/// [BoxLocal].
class NodeBox {
  final String name;
  final ir.TreeNode executableContext;
  NodeBox(this.name, this.executableContext);
}

class JClosureClass extends JClass {
  // TODO(efortuna): Storing this map here is so horrible. Instead store this on
  // the ScopeModel (because all of the closures share that localsMap) and then
  // set populate the getLocalVariable lookup with this localsMap for all the
  // closures.
  final KernelToLocalsMap localsMap;

  JClosureClass(this.localsMap, JLibrary library, int classIndex, String name)
      : super(library, classIndex, name, isAbstract: false);

  @override
  bool get isClosure => true;

  String toString() => '${jsElementPrefix}closure_class($name)';
}

class JClosureField extends JField {
  JClosureField(String name, int memberIndex,
      KernelClosureClass containingClass, bool isConst, bool isAssignable)
      : super(
            memberIndex,
            containingClass.closureClassEntity.library,
            containingClass.closureClassEntity,
            new Name(name, containingClass.closureClassEntity.library),
            isAssignable: isAssignable,
            isConst: isConst,
            isStatic: false);
}

/// A ClosureField that has been "boxed" to prevent name shadowing with the
/// original variable and ensure that this variable is updated/read with the
/// most recent value.
/// This corresponds to BoxFieldElement; we reuse BoxLocal from the original
/// algorithm to correspond to the actual name of the variable.
class JBoxedField extends JField {
  final BoxLocal box;
  JBoxedField(String name, int memberIndex, this.box, JClass containingClass,
      bool isConst, bool isAssignable)
      : super(memberIndex, containingClass.library, containingClass,
            new Name(name, containingClass.library),
            isAssignable: isAssignable, isConst: isConst);
}

class ClosureClassDefinition implements ClassDefinition {
  final ClassEntity cls;
  final SourceSpan location;

  ClosureClassDefinition(this.cls, this.location);

  ClassKind get kind => ClassKind.closure;

  ir.Node get node =>
      throw new UnsupportedError('ClosureClassDefinition.node for $cls');

  String toString() =>
      'ClosureClassDefinition(kind:$kind,cls:$cls,location:$location)';
}

class ClosureMemberData implements MemberData {
  final MemberDefinition definition;

  ClosureMemberData(this.definition);

  @override
  Iterable<ConstantValue> getMetadata(KernelToElementMap elementMap) {
    return const <ConstantValue>[];
  }
}

class ClosureFunctionData extends ClosureMemberData implements FunctionData {
  final FunctionType functionType;
  final ir.FunctionNode functionNode;

  ClosureFunctionData(
      ClosureMemberDefinition definition, this.functionType, this.functionNode)
      : super(definition);

  void forEachParameter(KernelToElementMapForBuilding elementMap,
      void f(DartType type, String name, ConstantValue defaultValue)) {
    void handleParameter(ir.VariableDeclaration node, {bool isOptional: true}) {
      DartType type = elementMap.getDartType(node.type);
      String name = node.name;
      ConstantValue defaultValue;
      if (isOptional) {
        if (node.initializer != null) {
          defaultValue = elementMap.getConstantValue(node.initializer);
        } else {
          defaultValue = new NullConstantValue();
        }
      }
      f(type, name, defaultValue);
    }

    for (int i = 0; i < functionNode.positionalParameters.length; i++) {
      handleParameter(functionNode.positionalParameters[i],
          isOptional: i < functionNode.requiredParameterCount);
    }
    functionNode.namedParameters.toList()
      ..sort(namedOrdering)
      ..forEach(handleParameter);
  }

  @override
  FunctionType getFunctionType(KernelToElementMap elementMap) {
    return functionType;
  }
}

class ClosureFieldData extends ClosureMemberData implements FieldData {
  ClosureFieldData(MemberDefinition definition) : super(definition);

  @override
  DartType getFieldType(KernelToElementMap elementMap) {
    // A closure field doesn't have a Dart type.
    return null;
  }

  @override
  ConstantExpression getFieldConstant(
      KernelToElementMap elementMap, FieldEntity field) {
    failedAt(
        field,
        "Unexpected field $field in "
        "ClosureFieldData.getFieldConstant");
    return null;
  }
}

class ClosureMemberDefinition implements MemberDefinition {
  final MemberEntity member;
  final SourceSpan location;
  final MemberKind kind;
  final ir.Node node;

  ClosureMemberDefinition(this.member, this.location, this.kind, this.node);

  String toString() =>
      'ClosureMemberDefinition(kind:$kind,member:$member,location:$location)';
}

/// Collection of scope data collected for a single member.
class ScopeModel {
  /// Collection [ScopeInfo] data for the member.
  KernelScopeInfo scopeInfo;

  /// Collected [CapturedScope] data for nodes.
  Map<ir.Node, KernelCapturedScope> capturedScopesMap =
      <ir.Node, KernelCapturedScope>{};

  /// Collected [ScopeInfo] data for nodes.
  Map<ir.FunctionNode, KernelScopeInfo> closuresToGenerate =
      <ir.FunctionNode, KernelScopeInfo>{};
}
