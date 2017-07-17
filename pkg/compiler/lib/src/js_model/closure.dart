// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../common/tasks.dart';
import '../elements/entities.dart';
import '../kernel/element_map.dart';
import '../world.dart';
import 'elements.dart';
import 'closure_visitors.dart';
import 'locals.dart';

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

  /// Map of the scoping information that corresponds to a particular entity.
  Map<Entity, ScopeInfo> _scopeMap = <Entity, ScopeInfo>{};
  Map<ir.Node, CapturedScope> _scopesCapturedInClosureMap =
      <ir.Node, CapturedScope>{};

  Map<Entity, ClosureRepresentationInfo> _closureRepresentationMap =
      <Entity, ClosureRepresentationInfo>{};

  /// Should only be used at the very beginning to ensure we are looking at the
  /// right kind of elements.
  // TODO(efortuna): Remove this map once we have one kernel backend strategy.
  final JsToFrontendMap _kToJElementMap;

  KernelClosureConversionTask(Measurer measurer, this._elementMap,
      this._kToJElementMap, this._globalLocalsMap)
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
    var closuresToGenerate = <ir.TreeNode, ScopeInfo>{};
    processedEntities.forEach((MemberEntity kEntity) {
      MemberEntity entity = kEntity;
      if (_kToJElementMap != null) {
        entity = _kToJElementMap.toBackendMember(kEntity);
      }
      if (entity.isAbstract) return;
      if (entity.isField && !entity.isInstanceMember) {
        ir.Field field = _elementMap.getMemberNode(entity);
        // Skip top-level/static fields without an initializer.
        if (field.initializer == null) return;
      }
      _buildClosureModel(entity, closuresToGenerate, closedWorldRefiner);
    });

    for (ir.TreeNode node in closuresToGenerate.keys) {
      _produceSyntheticElements(
          node, closuresToGenerate[node], closedWorldRefiner);
    }
  }

  /// Inspect members and mark if those members capture any state that needs to
  /// be marked as free variables.
  void _buildClosureModel(
      MemberEntity entity,
      Map<ir.TreeNode, ScopeInfo> closuresToGenerate,
      ClosedWorldRefiner closedWorldRefiner) {
    if (_scopeMap.keys.contains(entity)) return;
    ir.Node node = _elementMap.getMemberNode(entity);
    if (_scopesCapturedInClosureMap.keys.contains(node)) return;
    CapturedScopeBuilder translator = new CapturedScopeBuilder(
        _scopesCapturedInClosureMap,
        _scopeMap,
        entity,
        closuresToGenerate,
        _globalLocalsMap.getLocalsMap(entity),
        _elementMap);
    if (entity.isField) {
      if (node is ir.Field && node.initializer != null) {
        translator.translateLazyInitializer(node);
      }
    } else {
      assert(node is ir.Procedure || node is ir.Constructor);
      translator.translateConstructorOrProcedure(node);
    }
  }

  /// Given what variables are captured at each point, construct closure classes
  /// with fields containing the captured variables to replicate the Dart
  /// closure semantics in JS.
  void _produceSyntheticElements(
      ir.TreeNode /* ir.Field | ir.FunctionNode */ node,
      ScopeInfo info,
      ClosedWorldRefiner closedWorldRefiner) {
    Entity entity;
    KernelClosureClass closureClass =
        new KernelClosureClass.fromScopeInfo(info);
    if (node is ir.FunctionNode) {
      // We want the original declaration where that function is used to point
      // to the correct closure class.
      // TODO(efortuna): entity equivalent of element.declaration?
      node = (node as ir.FunctionNode).parent;
      _closureRepresentationMap[closureClass.callMethod] = closureClass;
    }

    if (node is ir.Member) {
      entity = _elementMap.getMember(node);
    } else {
      entity = _elementMap.getLocalFunction(node);
    }
    assert(entity != null);

    _closureRepresentationMap[entity] = closureClass;

    // Register that a new class has been created.
    closedWorldRefiner.registerClosureClass(
        closureClass, node is ir.Member && node.isInstanceMember);
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

  // TODO(efortuna): Eventually scopesCapturedInClosureMap[node] should always
  // be non-null, and we should just test that with an assert.
  @override
  CapturedScope getCapturedScope(MemberEntity entity) =>
      _scopesCapturedInClosureMap[_elementMap.getMemberNode(entity)] ??
      const CapturedScope();

  @override
  // TODO(efortuna): Eventually scopesCapturedInClosureMap[node] should always
  // be non-null, and we should just test that with an assert.
  CapturedLoopScope getCapturedLoopScope(ir.Node loopNode) =>
      _scopesCapturedInClosureMap[loopNode] ?? const CapturedLoopScope();

  @override
  // TODO(efortuna): Eventually closureRepresentationMap[node] should always be
  // non-null, and we should just test that with an assert.
  ClosureRepresentationInfo getClosureRepresentationInfo(Entity entity) {
    return _closureRepresentationMap[entity] ??
        const ClosureRepresentationInfo();
  }
}

class KernelScopeInfo extends ScopeInfo {
  final Set<Local> localsUsedInTryOrSync;
  final Local thisLocal;
  final Set<Local> boxedVariables;

  /// The set of variables that were defined in another scope, but are used in
  /// this scope.
  Set<ir.VariableDeclaration> freeVariables = new Set<ir.VariableDeclaration>();

  KernelScopeInfo(this.thisLocal)
      : localsUsedInTryOrSync = new Set<Local>(),
        boxedVariables = new Set<Local>();

  KernelScopeInfo.from(this.thisLocal, KernelScopeInfo info)
      : localsUsedInTryOrSync = info.localsUsedInTryOrSync,
        boxedVariables = info.boxedVariables;

  KernelScopeInfo.withBoxedVariables(this.boxedVariables, this.thisLocal)
      : localsUsedInTryOrSync = new Set<Local>();

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

class KernelCapturedScope extends KernelScopeInfo implements CapturedScope {
  final Local context;

  KernelCapturedScope(Set<Local> boxedVariables, this.context, Local thisLocal)
      : super.withBoxedVariables(boxedVariables, thisLocal);

  bool get requiresContextBox => boxedVariables.isNotEmpty;
}

class KernelCapturedLoopScope extends KernelCapturedScope
    implements CapturedLoopScope {
  final List<Local> boxedLoopVariables;

  KernelCapturedLoopScope(Set<Local> boxedVariables, this.boxedLoopVariables,
      Local context, Local thisLocal)
      : super(boxedVariables, context, thisLocal);

  bool get hasBoxedLoopVariables => boxedLoopVariables.isNotEmpty;
}

// TODO(johnniwinther): Add unittest for the computed [ClosureClass].
class KernelClosureClass extends KernelScopeInfo
    implements ClosureRepresentationInfo, JClass {
  // TODO(efortuna): Generate unique name for each closure class.
  final String name = 'ClosureClass';

  /// Index into the classData, classList and classEnvironment lists where this
  /// entity is stored in [JsToFrontendMapImpl].
  int classIndex;

  final Map<Local, JField> localToFieldMap = new Map<Local, JField>();

  KernelClosureClass.fromScopeInfo(KernelScopeInfo info)
      : super.from(info.thisLocal, info);

  // TODO(efortuna): Implement.
  Local get closureEntity => null;

  ClassEntity get closureClassEntity => this;

  // TODO(efortuna): Implement.
  FunctionEntity get callMethod => null;

  // TODO(efortuna): Implement.
  List<Local> get createdFieldEntities => const <Local>[];

  // TODO(efortuna): Implement.
  FieldEntity get thisFieldEntity => null;

  // TODO(efortuna): Implement.
  void forEachCapturedVariable(f(Local from, FieldEntity to)) {}

  // TODO(efortuna): Implement.
  @override
  void forEachBoxedVariable(f(Local local, FieldEntity field)) {}

  // TODO(efortuna): Implement.
  void forEachFreeVariable(f(Local variable, FieldEntity field)) {}

  // TODO(efortuna): Implement.
  bool isVariableBoxed(Local variable) => false;

  // TODO(efortuna): Implement.
  // Why is this closure not actually a closure? Well, to properly call
  // ourselves a closure, we need to register the new closure class with the
  // ClosedWorldRefiner, which currently only takes elements. The change to
  // that (and the subsequent adjustment here) will follow soon.
  bool get isClosure => false;

  bool get isAbstract => false;

  // TODO(efortuna): Talk to Johnni.
  JLibrary get library => null;

  String toString() => '${jsElementPrefix}class($name)';
}
