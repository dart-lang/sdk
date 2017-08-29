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
        node.accept(translator);
      } else {
        assert(entity.isInstanceMember);
        model.scopeInfo = new KernelScopeInfo(true);
      }
    } else {
      assert(node is ir.Procedure || node is ir.Constructor);
      node.accept(translator);
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
  Map<MemberEntity, ScopeInfo> _scopeMap = <MemberEntity, ScopeInfo>{};
  Map<ir.Node, CapturedScope> _capturedScopesMap = <ir.Node, CapturedScope>{};

  Map<MemberEntity, ClosureRepresentationInfo> _memberClosureRepresentationMap =
      <MemberEntity, ClosureRepresentationInfo>{};

  // The key is either a [ir.FunctionDeclaration] or [ir.FunctionExpression].
  Map<ir.TreeNode, ClosureRepresentationInfo> _localClosureRepresentationMap =
      <ir.TreeNode, ClosureRepresentationInfo>{};

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

      Map<ir.TreeNode, KernelScopeInfo> closuresToGenerate =
          model.closuresToGenerate;
      for (ir.TreeNode node in closuresToGenerate.keys) {
        ir.FunctionNode functionNode;
        if (node is ir.FunctionDeclaration) {
          functionNode = node.function;
        } else if (node is ir.FunctionExpression) {
          functionNode = node.function;
        } else {
          failedAt(member, "Unexpected closure node ${node}");
        }
        KernelClosureClass closureClass = _produceSyntheticElements(
            member, functionNode, closuresToGenerate[node], closedWorldRefiner);
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
    _memberClosureRepresentationMap[closureClass.callMethod] = closureClass;
    _globalLocalsMap.setLocalsMap(closureClass.callMethod, localsMap);
    if (node.parent is ir.Member) {
      assert(_elementMap.getMember(node.parent) == member);
      _memberClosureRepresentationMap[member] = closureClass;
    } else {
      assert(node.parent is ir.FunctionExpression ||
          node.parent is ir.FunctionDeclaration);
      _localClosureRepresentationMap[node.parent] = closureClass;
    }
    return closureClass;
  }

  @override
  ScopeInfo getScopeInfo(MemberEntity entity) {
    // TODO(johnniwinther): Remove this check when constructor bodies a created
    // eagerly with the J-model; a constructor body should have it's own
    // [ClosureRepresentationInfo].
    if (entity is ConstructorBodyEntity) {
      ConstructorBodyEntity constructorBody = entity;
      entity = constructorBody.constructor;
    }

    ScopeInfo scopeInfo = _scopeMap[entity];
    assert(
        scopeInfo != null, failedAt(entity, "Missing scope info for $entity."));
    return scopeInfo;
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
  ClosureRepresentationInfo getClosureInfoForMember(MemberEntity entity) {
    var closure = _memberClosureRepresentationMap[entity];
    // TODO(johnniwinther): Re-insert assertion or remove
    // [getClosureInfoForMember].
    /*assert(
        closure != null,
        "Corresponding closure class not found for $entity. "
        "Closures found for ${_memberClosureRepresentationMap.keys}");*/
    return closure ?? const ClosureRepresentationInfo();
  }

  @override
  ClosureRepresentationInfo getClosureInfo(ir.Node node) {
    assert(node is ir.FunctionExpression || node is ir.FunctionDeclaration);
    var closure = _localClosureRepresentationMap[node];
    assert(
        closure != null,
        "Corresponding closure class not found for $node. "
        "Closures found for ${_localClosureRepresentationMap.keys}");
    return closure;
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
      KernelToLocalsMap localsMap,
      this.closureEntity,
      this.thisLocal)
      : super.from(info, localsMap);

  List<Local> get createdFieldEntities => localToFieldMap.keys.toList();

  FieldEntity get thisFieldEntity => localToFieldMap[thisLocal];

  void forEachCapturedVariable(f(Local from, JField to)) {
    localToFieldMap.forEach(f);
  }

  @override
  void forEachBoxedVariable(f(Local local, JField field)) {
    for (Local l in localToFieldMap.keys) {
      if (localToFieldMap[l] is JRecordField) f(l, localToFieldMap[l]);
    }
  }

  void forEachFreeVariable(f(Local variable, JField field)) {
    for (Local l in localToFieldMap.keys) {
      var jField = localToFieldMap[l];
      if (jField is! JRecordField && jField is! BoxLocal) f(l, jField);
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
  JClosureClass(JLibrary library, int classIndex, String name)
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

/// A container for variables declared in a particular scope that are accessed
/// elsewhere.
// TODO(efortuna, johnniwinther): Don't implement JClass. This isn't actually a
// class.
class JRecord implements JClass {
  final JLibrary library;
  final String name;

  /// Index into the classData, classList and classEnvironment lists where this
  /// entity is stored in [JsToFrontendMapImpl].
  final int classIndex;

  JRecord(this.library, this.classIndex, this.name);

  bool get isAbstract => false;

  bool get isClosure => false;

  String toString() => '${jsElementPrefix}record_container($name)';
}

/// A variable that has been "boxed" to prevent name shadowing with the
/// original variable and ensure that this variable is updated/read with the
/// most recent value.
/// This corresponds to BoxFieldElement; we reuse BoxLocal from the original
/// algorithm to correspond to the actual name of the variable.
class JRecordField extends JField {
  final BoxLocal box;
  JRecordField(String name, int memberIndex, this.box, JClass containingClass,
      bool isConst)
      : super(memberIndex, containingClass.library, containingClass,
            new Name(name, containingClass.library),
            isStatic: false, isAssignable: true, isConst: isConst);
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
  ConstantExpression getFieldConstantExpression(KernelToElementMap elementMap) {
    failedAt(
        definition.member,
        "Unexpected field ${definition.member} in "
        "ClosureFieldData.getFieldConstantExpression");
    return null;
  }

  @override
  ConstantValue getConstantFieldInitializer(KernelToElementMap elementMap) {
    failedAt(
        definition.member,
        "Unexpected field ${definition.member} in "
        "ClosureFieldData.getConstantFieldInitializer");
    return null;
  }

  @override
  bool hasConstantFieldInitializer(KernelToElementMap elementMap) {
    return false;
  }

  @override
  ConstantValue getFieldConstantValue(KernelToElementMap elementMap) {
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

class RecordContainerDefinition implements ClassDefinition {
  final ClassEntity cls;
  final SourceSpan location;

  RecordContainerDefinition(this.cls, this.location);

  ClassKind get kind => ClassKind.record;

  ir.Node get node =>
      throw new UnsupportedError('RecordContainerDefinition.node for $cls');

  String toString() =>
      'RecordContainerDefinition(kind:$kind,cls:$cls,location:$location)';
}

/// Collection of scope data collected for a single member.
class ScopeModel {
  /// Collection [ScopeInfo] data for the member.
  KernelScopeInfo scopeInfo;

  /// Collected [CapturedScope] data for nodes.
  Map<ir.Node, KernelCapturedScope> capturedScopesMap =
      <ir.Node, KernelCapturedScope>{};

  /// Collected [ScopeInfo] data for nodes.
  Map<ir.TreeNode, KernelScopeInfo> closuresToGenerate =
      <ir.TreeNode, KernelScopeInfo>{};
}
