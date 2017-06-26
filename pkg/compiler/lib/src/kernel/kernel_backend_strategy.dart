// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.backend_strategy;

import 'package:kernel/ast.dart' as ir;

import '../backend_strategy.dart';
import '../closure.dart';
import '../common.dart';
import '../common/codegen.dart' show CodegenRegistry, CodegenWorkItem;
import '../common/tasks.dart';
import '../compiler.dart';
import '../elements/entities.dart';
import '../elements/entity_utils.dart' as utils;
import '../elements/jumps.dart';
import '../enqueue.dart';
import '../io/source_information.dart';
import '../js/js_source_mapping.dart';
import '../js_backend/backend.dart';
import '../js_backend/native_data.dart';
import '../js_emitter/sorter.dart';
import '../kernel/element_map.dart';
import '../kernel/element_map_impl.dart';
import '../native/behavior.dart';
import '../options.dart';
import '../ssa/builder_kernel.dart';
import '../ssa/nodes.dart';
import '../ssa/ssa.dart';
import '../ssa/types.dart';
import '../types/types.dart';
import '../universe/selector.dart';
import '../universe/world_builder.dart';
import '../universe/world_impact.dart';
import '../world.dart';
import 'closure.dart';
import 'element_map_impl.dart';
import 'kernel_strategy.dart';

/// A backend strategy based on Kernel IR nodes.
abstract class KernelBackendStrategy implements BackendStrategy {
  KernelToElementMap get elementMap;
  GlobalLocalsMap get globalLocalsMapForTesting;
}

/// Backend strategy that uses the kernel elements as the backend model.
// TODO(redemption): Replace this with a strategy based on the J-element
// model.
class KernelBackendStrategyImpl implements KernelBackendStrategy {
  final Compiler _compiler;
  Sorter _sorter;
  ClosureConversionTask _closureDataLookup;
  final GlobalLocalsMap _globalLocalsMap = new GlobalLocalsMap();

  KernelBackendStrategyImpl(this._compiler);

  KernelToElementMap get elementMap {
    KernelFrontEndStrategy frontendStrategy = _compiler.frontendStrategy;
    return frontendStrategy.elementMap;
  }

  GlobalLocalsMap get globalLocalsMapForTesting => _globalLocalsMap;

  @override
  ClosedWorldRefiner createClosedWorldRefiner(
      covariant KernelClosedWorld closedWorld) {
    return closedWorld;
  }

  @override
  Sorter get sorter {
    if (_sorter == null) {
      _sorter = new KernelSorter(elementMap);
    }
    return _sorter;
  }

  @override
  ClosureConversionTask get closureDataLookup =>
      _closureDataLookup ??= new KernelClosureConversionTask(
          _compiler.measurer, elementMap, _globalLocalsMap);

  @override
  WorkItemBuilder createCodegenWorkItemBuilder(ClosedWorld closedWorld) {
    return new KernelCodegenWorkItemBuilder(_compiler.backend, closedWorld);
  }

  @override
  CodegenWorldBuilder createCodegenWorldBuilder(
      NativeBasicData nativeBasicData,
      ClosedWorld closedWorld,
      SelectorConstraintsStrategy selectorConstraintsStrategy) {
    return new KernelCodegenWorldBuilder(
        elementMap,
        closedWorld.elementEnvironment,
        nativeBasicData,
        closedWorld,
        selectorConstraintsStrategy);
  }

  @override
  SsaBuilder createSsaBuilder(CompilerTask task, JavaScriptBackend backend,
      SourceInformationStrategy sourceInformationStrategy) {
    return new KernelSsaBuilder(
        task, backend.compiler, elementMap, _globalLocalsMap);
  }

  @override
  SourceInformationStrategy get sourceInformationStrategy =>
      const JavaScriptSourceInformationStrategy();
}

class KernelCodegenWorkItemBuilder implements WorkItemBuilder {
  final JavaScriptBackend _backend;
  final ClosedWorld _closedWorld;

  KernelCodegenWorkItemBuilder(this._backend, this._closedWorld);

  CompilerOptions get _options => _backend.compiler.options;

  @override
  CodegenWorkItem createWorkItem(MemberEntity entity) {
    // Codegen inlines field initializers. It only needs to generate
    // code for checked setters.
    if (entity.isField && entity.isInstanceMember) {
      if (!_options.enableTypeAssertions || entity.enclosingClass.isClosure) {
        return null;
      }
    }

    return new KernelCodegenWorkItem(_backend, _closedWorld, entity);
  }
}

class KernelCodegenWorkItem extends CodegenWorkItem {
  final JavaScriptBackend _backend;
  final ClosedWorld _closedWorld;
  final MemberEntity element;
  final CodegenRegistry registry;

  KernelCodegenWorkItem(this._backend, this._closedWorld, this.element)
      : registry =
            new CodegenRegistry(_closedWorld.elementEnvironment, element);

  @override
  WorldImpact run() {
    return _backend.codegen(this, _closedWorld);
  }
}

/// Task for building SSA from kernel IR loaded from .dill.
class KernelSsaBuilder implements SsaBuilder {
  final CompilerTask task;
  final Compiler _compiler;
  final KernelToElementMap _elementMap;
  final GlobalLocalsMap _globalLocalsMap;

  KernelSsaBuilder(
      this.task, this._compiler, this._elementMap, this._globalLocalsMap);

  @override
  HGraph build(CodegenWorkItem work, ClosedWorld closedWorld) {
    KernelToLocalsMap localsMap = _globalLocalsMap.getLocalsMap(work.element);
    KernelSsaGraphBuilder builder = new KernelSsaGraphBuilder(
        work.element,
        work.element.enclosingClass,
        _elementMap.getMemberNode(work.element),
        _compiler,
        _elementMap,
        new KernelToTypeInferenceMapImpl(closedWorld),
        localsMap,
        closedWorld,
        _compiler.codegenWorldBuilder,
        work.registry,
        _compiler.backendStrategy.closureDataLookup,
        // TODO(redemption): Support these:
        const SourceInformationBuilder(),
        null, // Function node used as capture scope id.
        targetIsConstructorBody: false);
    return builder.build();
  }
}

class KernelToTypeInferenceMapImpl implements KernelToTypeInferenceMap {
  final ClosedWorld _closedWorld;

  KernelToTypeInferenceMapImpl(this._closedWorld);

  @override
  TypeMask typeFromNativeBehavior(
      NativeBehavior nativeBehavior, ClosedWorld closedWorld) {
    return TypeMaskFactory.fromNativeBehavior(nativeBehavior, closedWorld);
  }

  @override
  TypeMask selectorTypeOf(Selector selector, TypeMask mask) {
    return _closedWorld.commonMasks.dynamicType;
  }

  @override
  TypeMask getInferredTypeOf(MemberEntity member) {
    return _closedWorld.commonMasks.dynamicType;
  }

  @override
  TypeMask getInferredTypeOfParameter(Local parameter) {
    return _closedWorld.commonMasks.dynamicType;
  }

  @override
  TypeMask inferredIndexType(ir.ForInStatement forInStatement) {
    return _closedWorld.commonMasks.dynamicType;
  }

  @override
  bool isJsIndexableIterator(
      ir.ForInStatement forInStatement, ClosedWorld closedWorld) {
    return false;
  }

  @override
  bool isFixedLength(TypeMask mask, ClosedWorld closedWorld) {
    return false;
  }

  @override
  TypeMask typeOfIteratorMoveNext(ir.ForInStatement forInStatement) {
    return _closedWorld.commonMasks.dynamicType;
  }

  @override
  TypeMask typeOfIteratorCurrent(ir.ForInStatement forInStatement) {
    return _closedWorld.commonMasks.dynamicType;
  }

  @override
  TypeMask typeOfIterator(ir.ForInStatement forInStatement) {
    return _closedWorld.commonMasks.dynamicType;
  }

  @override
  TypeMask typeOfListLiteral(
      MemberEntity owner, ir.ListLiteral listLiteral, ClosedWorld closedWorld) {
    return _closedWorld.commonMasks.dynamicType;
  }

  @override
  TypeMask typeOfSet(ir.PropertySet write, ClosedWorld closedWorld) {
    return _closedWorld.commonMasks.dynamicType;
  }

  @override
  TypeMask typeOfGet(ir.PropertyGet read) {
    return _closedWorld.commonMasks.dynamicType;
  }

  @override
  TypeMask typeOfInvocation(
      ir.MethodInvocation invocation, ClosedWorld closedWorld) {
    return _closedWorld.commonMasks.dynamicType;
  }

  @override
  TypeMask getReturnTypeOf(FunctionEntity function) {
    return _closedWorld.commonMasks.dynamicType;
  }
}

class GlobalLocalsMap {
  Map<MemberEntity, KernelToLocalsMap> _localsMaps =
      <MemberEntity, KernelToLocalsMap>{};

  KernelToLocalsMap getLocalsMap(MemberEntity member) {
    return _localsMaps.putIfAbsent(
        member, () => new KernelToLocalsMapImpl(member));
  }
}

class KernelToLocalsMapImpl implements KernelToLocalsMap {
  final List<MemberEntity> _members = <MemberEntity>[];
  Map<ir.VariableDeclaration, KLocal> _map = <ir.VariableDeclaration, KLocal>{};
  Map<ir.TreeNode, KJumpTarget> _jumpTargetMap;
  Set<ir.BreakStatement> _breaksAsContinue;

  MemberEntity get currentMember => _members.last;

  // TODO(johnniwinther): Compute this eagerly from the root of the member.
  void _ensureJumpMap(ir.TreeNode node) {
    if (_jumpTargetMap == null) {
      JumpVisitor visitor = new JumpVisitor(currentMember);

      // Find the root node for the current member.
      while (node is! ir.Member) {
        node = node.parent;
      }

      node.accept(visitor);
      _jumpTargetMap = visitor.jumpTargetMap;
      _breaksAsContinue = visitor.breaksAsContinue;
    }
  }

  KernelToLocalsMapImpl(MemberEntity member) {
    _members.add(member);
  }

  @override
  void enterInlinedMember(MemberEntity member) {
    _members.add(member);
  }

  @override
  void leaveInlinedMember(MemberEntity member) {
    assert(member == currentMember);
    _members.removeLast();
  }

  @override
  JumpTarget getJumpTargetForBreak(ir.BreakStatement node) {
    _ensureJumpMap(node.target);
    JumpTarget target = _jumpTargetMap[node];
    assert(target != null, failedAt(currentMember, 'No target for $node.'));
    return target;
  }

  @override
  bool generateContinueForBreak(ir.BreakStatement node) {
    return _breaksAsContinue.contains(node);
  }

  @override
  JumpTarget getJumpTargetForContinueSwitch(ir.ContinueSwitchStatement node) {
    _ensureJumpMap(node.target);
    throw new UnimplementedError(
        'KernelToLocalsMapImpl.getJumpTargetForContinueSwitch');
  }

  @override
  JumpTarget getJumpTargetForSwitchCase(ir.SwitchCase node) {
    _ensureJumpMap(node);
    throw new UnimplementedError(
        'KernelToLocalsMapImpl.getJumpTargetForSwitchCase');
  }

  @override
  JumpTarget getJumpTargetForDo(ir.DoStatement node) {
    _ensureJumpMap(node);
    return _jumpTargetMap[node.parent];
  }

  @override
  JumpTarget getJumpTargetForLabel(ir.LabeledStatement node) {
    _ensureJumpMap(node);
    return _jumpTargetMap[node];
  }

  @override
  JumpTarget getJumpTargetForSwitch(ir.SwitchStatement node) {
    _ensureJumpMap(node);
    throw new UnimplementedError(
        'KernelToLocalsMapImpl.getJumpTargetForSwitch');
  }

  @override
  JumpTarget getJumpTargetForFor(ir.ForStatement node) {
    _ensureJumpMap(node);
    return _jumpTargetMap[node];
  }

  @override
  JumpTarget getJumpTargetForForIn(ir.ForInStatement node) {
    _ensureJumpMap(node);
    return _jumpTargetMap[node.parent];
  }

  @override
  JumpTarget getJumpTargetForWhile(ir.WhileStatement node) {
    _ensureJumpMap(node);
    return _jumpTargetMap[node.parent];
  }

  @override
  Local getLocal(ir.VariableDeclaration node) {
    return _map.putIfAbsent(node, () {
      return new KLocal(node.name, currentMember);
    });
  }

  @override
  LoopClosureRepresentationInfo getClosureRepresentationInfoForLoop(
      ClosureDataLookup closureLookup, ir.TreeNode node) {
    return closureLookup.getClosureRepresentationInfoForLoop(node);
  }
}

class JumpVisitor extends ir.Visitor {
  int index = 0;
  final MemberEntity member;
  final Map<ir.TreeNode, KJumpTarget> jumpTargetMap =
      <ir.TreeNode, KJumpTarget>{};
  final Set<ir.BreakStatement> breaksAsContinue = new Set<ir.BreakStatement>();

  JumpVisitor(this.member);

  KJumpTarget _getJumpTarget(ir.TreeNode node) {
    return jumpTargetMap.putIfAbsent(node, () {
      return new KJumpTarget(member, index++);
    });
  }

  @override
  defaultNode(ir.Node node) => node.visitChildren(this);

  bool _canBeBreakTarget(ir.TreeNode node) {
    // TODO(johnniwinther): Add more.
    return node is ir.ForStatement;
  }

  bool _canBeContinueTarget(ir.TreeNode node) {
    // TODO(johnniwinther): Add more.
    return node is ir.ForStatement;
  }

  @override
  visitBreakStatement(ir.BreakStatement node) {
    // TODO(johnniwinther): Add labels if the enclosing loop is not the implicit
    // break target.
    KJumpTarget target;
    ir.TreeNode body = node.target.body;
    ir.TreeNode parent = node.target.parent;
    if (_canBeBreakTarget(body)) {
      // We have code like
      //
      //     l1: for (int i = 0; i < 10; i++) {
      //        break l1:
      //     }
      //
      // and can therefore use the for loop as the break target.
      target = _getJumpTarget(body);
      target.isBreakTarget = true;
    } else if (_canBeContinueTarget(parent)) {
      // We have code like
      //
      //     for (int i = 0; i < 10; i++) l1: {
      //        break l1:
      //     }
      //
      // and can therefore use the for loop as a continue target.
      target = _getJumpTarget(parent);
      target.isContinueTarget = true;
      breaksAsContinue.add(node);
    } else {
      target = _getJumpTarget(node.target);
      target.isBreakTarget = true;
    }
    jumpTargetMap[node] = target;
    super.visitBreakStatement(node);
  }
}

class KJumpTarget extends JumpTarget<ir.Node> {
  final MemberEntity memberContext;
  final int nestingLevel;

  KJumpTarget(this.memberContext, this.nestingLevel);

  bool isBreakTarget = false;
  bool isContinueTarget = false;
  bool isSwitch = false;

  @override
  Entity get executableContext => memberContext;

  @override
  LabelDefinition<ir.Node> addLabel(ir.Node label, String labelName,
      {bool isBreakTarget: false}) {
    throw new UnimplementedError('KJumpTarget.addLabel');
  }

  @override
  List<LabelDefinition<ir.Node>> get labels {
    return const <LabelDefinition<ir.Node>>[];
  }

  @override
  ir.Node get statement {
    throw new UnimplementedError('KJumpTarget.statement');
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('KJumpTarget[');
    sb.write('memberContext=');
    sb.write(memberContext);
    sb.write(',nestingLevel=');
    sb.write(nestingLevel);
    sb.write(',isBreakTarget=');
    sb.write(isBreakTarget);
    sb.write(',isContinueTarget=');
    sb.write(isContinueTarget);
    sb.write(']');
    return sb.toString();
  }
}

class KLocal implements Local {
  final String name;
  final MemberEntity memberContext;

  KLocal(this.name, this.memberContext);

  @override
  Entity get executableContext => memberContext;

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('local(');
    if (memberContext.enclosingClass != null) {
      sb.write(memberContext.enclosingClass.name);
      sb.write('.');
    }
    sb.write(memberContext.name);
    sb.write('#');
    sb.write(name);
    sb.write(')');
    return sb.toString();
  }
}

class KernelSorter implements Sorter {
  final KernelToElementMapImpl elementMap;

  KernelSorter(this.elementMap);

  int _compareLibraries(LibraryEntity a, LibraryEntity b) {
    return utils.compareLibrariesUris(a.canonicalUri, b.canonicalUri);
  }

  int _compareNodes(
      Entity entity1, ir.TreeNode node1, Entity entity2, ir.TreeNode node2) {
    ir.Location location1 = node1.location;
    ir.Location location2 = node2.location;
    int r = utils.compareSourceUris(
        Uri.parse(location1.file), Uri.parse(location2.file));
    if (r != 0) return r;
    return utils.compareEntities(entity1, location1.line, location1.column,
        entity2, location2.line, location2.column);
  }

  @override
  Iterable<LibraryEntity> sortLibraries(Iterable<LibraryEntity> libraries) {
    return libraries.toList()..sort(_compareLibraries);
  }

  @override
  Iterable<MemberEntity> sortMembers(Iterable<MemberEntity> members) {
    return members.toList()
      ..sort((MemberEntity a, MemberEntity b) {
        int r = _compareLibraries(a.library, b.library);
        if (r != 0) return r;
        return _compareNodes(
            a, elementMap.getMemberNode(a), b, elementMap.getMemberNode(b));
      });
  }

  @override
  Iterable<ClassEntity> sortClasses(Iterable<ClassEntity> classes) {
    return classes.toList()
      ..sort((ClassEntity a, ClassEntity b) {
        int r = _compareLibraries(a.library, b.library);
        if (r != 0) return r;
        return _compareNodes(
            a, elementMap.getClassNode(a), b, elementMap.getClassNode(b));
      });
  }
}
