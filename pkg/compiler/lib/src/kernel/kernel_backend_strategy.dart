// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.backend_strategy;

import 'package:kernel/ast.dart' as ir;

import '../backend_strategy.dart';
import '../closure.dart';
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

  MemberEntity get currentMember => _members.last;

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
    throw new UnimplementedError('KernelToLocalsMapImpl.getJumpTargetForBreak');
  }

  @override
  JumpTarget getJumpTargetForContinueSwitch(ir.ContinueSwitchStatement node) {
    throw new UnimplementedError(
        'KernelToLocalsMapImpl.getJumpTargetForContinueSwitch');
  }

  @override
  JumpTarget getJumpTargetForSwitchCase(ir.SwitchCase node) {
    throw new UnimplementedError(
        'KernelToLocalsMapImpl.getJumpTargetForSwitchCase');
  }

  @override
  JumpTarget getJumpTargetForDo(ir.DoStatement node) {
    // TODO(redemption): Support do statement as jump target.
    return null;
  }

  @override
  JumpTarget getJumpTargetForLabel(ir.LabeledStatement node) {
    throw new UnimplementedError('KernelToLocalsMapImpl.getJumpTargetForLabel');
  }

  @override
  JumpTarget getJumpTargetForSwitch(ir.SwitchStatement node) {
    throw new UnimplementedError(
        'KernelToLocalsMapImpl.getJumpTargetForSwitch');
  }

  @override
  JumpTarget getJumpTargetForFor(ir.ForStatement node) {
    // TODO(redemption): Support for statement as jump target.
    return null;
  }

  @override
  JumpTarget getJumpTargetForForIn(ir.ForInStatement node) {
    // TODO(redemption): Support for-in statement as jump target.
    return null;
  }

  @override
  JumpTarget getJumpTargetForWhile(ir.WhileStatement node) {
    // TODO(redemption): Support while statement as jump target.
    return null;
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
