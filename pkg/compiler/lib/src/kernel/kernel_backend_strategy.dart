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
import 'element_map_impl.dart';
import 'kernel_strategy.dart';

/// Backend strategy that uses the kernel elements as the backend model.
// TODO(johnniwinther): Replace this with a strategy based on the J-element
// model.
class KernelBackendStrategy implements BackendStrategy {
  final Compiler _compiler;
  Sorter _sorter;

  KernelBackendStrategy(this._compiler);

  @override
  ClosedWorldRefiner createClosedWorldRefiner(KernelClosedWorld closedWorld) {
    return closedWorld;
  }

  @override
  Sorter get sorter {
    if (_sorter == null) {
      KernelFrontEndStrategy frontendStrategy = _compiler.frontendStrategy;
      _sorter = new KernelSorter(frontendStrategy.elementMap);
    }
    return _sorter;
  }

  @override
  ClosureConversionTask createClosureConversionTask(Compiler compiler) =>
      new KernelClosureConversionTask(compiler.measurer);

  @override
  WorkItemBuilder createCodegenWorkItemBuilder(ClosedWorld closedWorld) {
    return new KernelCodegenWorkItemBuilder(_compiler.backend, closedWorld);
  }

  @override
  CodegenWorldBuilder createCodegenWorldBuilder(
      NativeBasicData nativeBasicData,
      ClosedWorld closedWorld,
      SelectorConstraintsStrategy selectorConstraintsStrategy) {
    KernelFrontEndStrategy frontendStrategy = _compiler.frontendStrategy;
    return new KernelCodegenWorldBuilder(
        frontendStrategy.elementMap,
        closedWorld.elementEnvironment,
        nativeBasicData,
        closedWorld,
        selectorConstraintsStrategy);
  }

  @override
  SsaBuilderTask createSsaBuilderTask(JavaScriptBackend backend,
      SourceInformationStrategy sourceInformationStrategy) {
    return new KernelSsaBuilderTask(backend.compiler);
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
class KernelSsaBuilderTask extends CompilerTask implements SsaBuilderTask {
  final Compiler _compiler;

  KernelSsaBuilderTask(this._compiler) : super(_compiler.measurer);

  KernelToElementMapImpl get _elementMap {
    KernelFrontEndStrategy frontendStrategy = _compiler.frontendStrategy;
    return frontendStrategy.elementMap;
  }

  @override
  HGraph build(CodegenWorkItem work, ClosedWorld closedWorld) {
    KernelSsaBuilder builder = new KernelSsaBuilder(
        work.element,
        work.element.enclosingClass,
        _elementMap.getMemberNode(work.element),
        _compiler,
        _elementMap,
        new KernelToTypeInferenceMapImpl(closedWorld),
        new KernelToLocalsMapImpl(work.element),
        closedWorld,
        _compiler.codegenWorldBuilder,
        work.registry,
        _compiler.closureDataLookup,
        // TODO(johnniwinther): Support these:
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
  JumpTarget getJumpTarget(ir.TreeNode node, {bool isContinueTarget: false}) {
    // TODO(johnniwinther): Support jump targets.
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
    return const LoopClosureRepresentationInfo();
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
class KernelClosureConversionTask extends ClosureConversionTask<ir.Node> {
  KernelClosureConversionTask(Measurer measurer) : super(measurer);

  /// The combined steps of generating our intermediate representation of
  /// closures that need to be rewritten and generating the element model.
  /// Ultimately these two steps will be split apart with the second step
  /// happening later in compilation just before codegen. These steps are
  /// combined here currently to provide a consistent interface to the rest of
  /// the compiler until we are ready to separate these phases.
  @override
  void convertClosures(Iterable<MemberEntity> processedEntities,
      ClosedWorldRefiner closedWorldRefiner) {
    // TODO(efortuna): implement.
  }

  @override
  ClosureAnalysisInfo getClosureAnalysisInfo(ir.Node node) {
    return const ClosureAnalysisInfo();
  }

  @override
  LoopClosureRepresentationInfo getClosureRepresentationInfoForLoop(
      ir.Node loopNode) {
    return const LoopClosureRepresentationInfo();
  }

  @override
  ClosureRepresentationInfo getClosureRepresentationInfo(Entity entity) {
    if (entity is MemberEntity) {
      ThisLocal thisLocal;
      if (entity.isInstanceMember) {
        thisLocal = new ThisLocal(entity);
      }
      return new ClosureClassMap(null, null, null, thisLocal);
    }
    return const ClosureRepresentationInfo();
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
