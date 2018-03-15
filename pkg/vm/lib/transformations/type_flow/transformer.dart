// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Transformations based on type flow analysis.
library vm.transformations.type_flow.transformer;

import 'dart:core' hide Type;

import 'package:kernel/ast.dart' hide Statement, StatementVisitor;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/type_environment.dart';

import 'analysis.dart';
import 'calls.dart';
import 'summary_collector.dart';
import 'types.dart';
import 'utils.dart';
import '../devirtualization.dart' show Devirtualization;
import '../../metadata/direct_call.dart';
import '../../metadata/inferred_type.dart';
import '../../metadata/unreachable.dart';

const bool kDumpAllSummaries =
    const bool.fromEnvironment('global.type.flow.dump.all.summaries');
const bool kDumpClassHierarchy =
    const bool.fromEnvironment('global.type.flow.dump.class.hierarchy');

/// Whole-program type flow analysis and transformation.
/// Assumes strong mode and closed world.
Component transformComponent(
    CoreTypes coreTypes, Component component, List<String> entryPoints) {
  if ((entryPoints == null) || entryPoints.isEmpty) {
    throw 'Error: unable to perform global type flow analysis without entry points.';
  }

  void ignoreAmbiguousSupertypes(Class cls, Supertype a, Supertype b) {}
  final hierarchy = new ClassHierarchy(component,
      onAmbiguousSupertypes: ignoreAmbiguousSupertypes);
  final types = new TypeEnvironment(coreTypes, hierarchy, strongMode: true);
  final libraryIndex = new LibraryIndex.all(component);

  if (kDumpAllSummaries) {
    Statistics.reset();
    new CreateAllSummariesVisitor(types).visitComponent(component);
    Statistics.print("All summaries statistics");
  }

  Statistics.reset();
  final analysisStopWatch = new Stopwatch()..start();

  final typeFlowAnalysis = new TypeFlowAnalysis(hierarchy, types, libraryIndex,
      entryPointsJSONFiles: entryPoints);

  Procedure main = component.mainMethod;
  final Selector mainSelector = new DirectSelector(main);
  typeFlowAnalysis.addRawCall(mainSelector);
  typeFlowAnalysis.process();

  analysisStopWatch.stop();

  if (kDumpClassHierarchy) {
    debugPrint(typeFlowAnalysis.hierarchyCache);
  }

  final transformsStopWatch = new Stopwatch()..start();

  new DropMethodBodiesVisitor(typeFlowAnalysis).visitComponent(component);

  new TFADevirtualization(component, typeFlowAnalysis)
      .visitComponent(component);

  new AnnotateKernel(component, typeFlowAnalysis).visitComponent(component);

  transformsStopWatch.stop();

  statPrint("TF analysis took ${analysisStopWatch.elapsedMilliseconds}ms");
  statPrint("TF transforms took ${transformsStopWatch.elapsedMilliseconds}ms");

  Statistics.print("TFA statistics");

  return component;
}

/// Devirtualization based on results of type flow analysis.
class TFADevirtualization extends Devirtualization {
  final TypeFlowAnalysis _typeFlowAnalysis;

  TFADevirtualization(Component component, this._typeFlowAnalysis)
      : super(_typeFlowAnalysis.environment.coreTypes, component,
            _typeFlowAnalysis.environment.hierarchy);

  @override
  DirectCallMetadata getDirectCall(TreeNode node, Member target,
      {bool setter = false}) {
    final callSite = _typeFlowAnalysis.callSite(node);
    if (callSite != null) {
      final Member singleTarget = callSite.monomorphicTarget;
      if (singleTarget != null) {
        return new DirectCallMetadata(
            singleTarget, callSite.isNullableReceiver);
      }
    }
    return null;
  }
}

/// Drop method bodies using results of type flow analysis.
class DropMethodBodiesVisitor extends RecursiveVisitor<Null> {
  final TypeFlowAnalysis _typeFlowAnalysis;

  DropMethodBodiesVisitor(this._typeFlowAnalysis);

  @override
  defaultMember(Member m) {
    if (!m.isAbstract && !_typeFlowAnalysis.isMemberUsed(m)) {
      if (m.function != null && m.function.body != null) {
        m.function.body = new ExpressionStatement(
            new Throw(new StringLiteral("TFA Error: $m")))
          ..parent = m.function;
        debugPrint("Dropped $m");
      } else if ((m is Field) &&
          (m.initializer != null) &&
          (m.initializer is! NullLiteral)) {
        m.isConst = false;
        m.initializer = new Throw(new StringLiteral("TFA Error: $m"))
          ..parent = m;
        debugPrint("Dropped $m");
      }
    }
  }
}

/// Annotates kernel AST with metadata using results of type flow analysis.
class AnnotateKernel extends RecursiveVisitor<Null> {
  final TypeFlowAnalysis _typeFlowAnalysis;
  final InferredTypeMetadataRepository _inferredTypeMetadata;
  final UnreachableNodeMetadataRepository _unreachableNodeMetadata;

  AnnotateKernel(Component component, this._typeFlowAnalysis)
      : _inferredTypeMetadata = new InferredTypeMetadataRepository(),
        _unreachableNodeMetadata = new UnreachableNodeMetadataRepository() {
    component.addMetadataRepository(_inferredTypeMetadata);
    component.addMetadataRepository(_unreachableNodeMetadata);
  }

  InferredType _convertType(Type type) {
    assertx(type != null);

    Class concreteClass;

    final nullable = type is NullableType;
    if (nullable) {
      final baseType = (type as NullableType).baseType;

      if (baseType == const EmptyType()) {
        concreteClass = _typeFlowAnalysis.environment.coreTypes.nullClass;
      } else {
        concreteClass =
            baseType.getConcreteClass(_typeFlowAnalysis.hierarchyCache);
      }
    } else {
      concreteClass = type.getConcreteClass(_typeFlowAnalysis.hierarchyCache);
    }

    if ((concreteClass != null) || !nullable) {
      return new InferredType(concreteClass, nullable);
    }

    return null;
  }

  void _setInferredType(TreeNode node, Type type) {
    final inferredType = _convertType(type);
    if (inferredType != null) {
      _inferredTypeMetadata.mapping[node] = inferredType;
    }
  }

  void _setUnreachable(TreeNode node) {
    _unreachableNodeMetadata.mapping[node] = const UnreachableNode();
  }

  void _annotateCallSite(TreeNode node) {
    final callSite = _typeFlowAnalysis.callSite(node);
    if (callSite != null) {
      if (callSite.isReachable) {
        if (callSite.isResultUsed) {
          _setInferredType(node, callSite.resultType);
        }
      } else {
        _setUnreachable(node);
      }
    }
  }

  void _annotateMember(Member member) {
    if (_typeFlowAnalysis.isMemberUsed(member)) {
      if (member is Field) {
        _setInferredType(member, _typeFlowAnalysis.fieldType(member));
      } else {
        Args<Type> argTypes = _typeFlowAnalysis.argumentTypes(member);
        assertx(argTypes != null);

        final int firstParamIndex = hasReceiverArg(member) ? 1 : 0;

        final positionalParams = member.function.positionalParameters;
        assertx(argTypes.positionalCount ==
            firstParamIndex + positionalParams.length);

        for (int i = 0; i < positionalParams.length; i++) {
          _setInferredType(
              positionalParams[i], argTypes.values[firstParamIndex + i]);
        }

        // TODO(dartbug.com/32292): make sure parameters are sorted in kernel
        // AST and iterate parameters in parallel, without lookup.
        final names = argTypes.names;
        for (int i = 0; i < names.length; i++) {
          final param = findNamedParameter(member.function, names[i]);
          assertx(param != null);
          _setInferredType(param,
              argTypes.values[firstParamIndex + positionalParams.length + i]);
        }

        // TODO(alexmarkov): figure out how to pass receiver type.
      }
    } else if (!member.isAbstract) {
      _setUnreachable(member);
    }
  }

  @override
  visitConstructor(Constructor node) {
    _annotateMember(node);
    super.visitConstructor(node);
  }

  @override
  visitProcedure(Procedure node) {
    _annotateMember(node);
    super.visitProcedure(node);
  }

  @override
  visitField(Field node) {
    _annotateMember(node);
    super.visitField(node);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    _annotateCallSite(node);
    super.visitMethodInvocation(node);
  }

  @override
  visitPropertyGet(PropertyGet node) {
    _annotateCallSite(node);
    super.visitPropertyGet(node);
  }

  @override
  visitDirectMethodInvocation(DirectMethodInvocation node) {
    _annotateCallSite(node);
    super.visitDirectMethodInvocation(node);
  }

  @override
  visitDirectPropertyGet(DirectPropertyGet node) {
    _annotateCallSite(node);
    super.visitDirectPropertyGet(node);
  }

  @override
  visitSuperMethodInvocation(SuperMethodInvocation node) {
    _annotateCallSite(node);
    super.visitSuperMethodInvocation(node);
  }

  @override
  visitSuperPropertyGet(SuperPropertyGet node) {
    _annotateCallSite(node);
    super.visitSuperPropertyGet(node);
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    _annotateCallSite(node);
    super.visitStaticInvocation(node);
  }

  @override
  visitStaticGet(StaticGet node) {
    _annotateCallSite(node);
    super.visitStaticGet(node);
  }
}
