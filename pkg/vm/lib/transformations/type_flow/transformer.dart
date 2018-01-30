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

const bool kDumpAllSummaries =
    const bool.fromEnvironment('global.type.flow.dump.all.summaries');

/// Whole-program type flow analysis and transformation.
/// Assumes strong mode and closed world.
Program transformProgram(CoreTypes coreTypes, Program program,
    // TODO(alexmarkov): Pass entry points descriptors from command line.
    {List<String> entryPointsJSONFiles: const [
      'pkg/vm/lib/transformations/type_flow/entry_points.json',
      'pkg/vm/lib/transformations/type_flow/entry_points_extra.json',
    ]}) {
  void ignoreAmbiguousSupertypes(Class cls, Supertype a, Supertype b) {}
  final hierarchy = new ClassHierarchy(program,
      onAmbiguousSupertypes: ignoreAmbiguousSupertypes);
  final types = new TypeEnvironment(coreTypes, hierarchy, strongMode: true);
  final libraryIndex = new LibraryIndex.all(program);

  if (kDumpAllSummaries) {
    Statistics.reset();
    new CreateAllSummariesVisitor(types).visitProgram(program);
    Statistics.print("All summaries statistics");
  }

  Statistics.reset();
  final analysisStopWatch = new Stopwatch()..start();

  final typeFlowAnalysis = new TypeFlowAnalysis(hierarchy, types, libraryIndex,
      entryPointsJSONFiles: entryPointsJSONFiles);

  Procedure main = program.mainMethod;
  final Selector mainSelector = new DirectSelector(main);
  typeFlowAnalysis.addRawCall(mainSelector);
  typeFlowAnalysis.process();

  analysisStopWatch.stop();

  final transformsStopWatch = new Stopwatch()..start();

  new DropMethodBodiesVisitor(typeFlowAnalysis).visitProgram(program);

  new TFADevirtualization(program, typeFlowAnalysis).visitProgram(program);

  new AnnotateWithInferredTypes(program, typeFlowAnalysis)
      .visitProgram(program);

  transformsStopWatch.stop();

  statPrint("TF analysis took ${analysisStopWatch.elapsedMilliseconds}ms");
  statPrint("TF transforms took ${transformsStopWatch.elapsedMilliseconds}ms");

  Statistics.print("TFA statistics");

  return program;
}

/// Devirtualization based on results of type flow analysis.
class TFADevirtualization extends Devirtualization {
  final TypeFlowAnalysis _typeFlowAnalysis;

  TFADevirtualization(Program program, this._typeFlowAnalysis)
      : super(_typeFlowAnalysis.environment.coreTypes, program,
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

/// Annotates kernel AST with types inferred by type flow analysis.
class AnnotateWithInferredTypes extends RecursiveVisitor<Null> {
  final TypeFlowAnalysis _typeFlowAnalysis;
  final InferredTypeMetadataRepository _metadata;

  AnnotateWithInferredTypes(Program program, this._typeFlowAnalysis)
      : _metadata = new InferredTypeMetadataRepository() {
    program.addMetadataRepository(_metadata);
  }

  void _annotateNode(TreeNode node) {
    final callSite = _typeFlowAnalysis.callSite(node);
    if ((callSite != null) && callSite.isResultUsed && callSite.isReachable) {
      final resultType = callSite.resultType;
      assertx(resultType != null);

      Class concreteClass;

      final nullable = resultType is NullableType;
      if (nullable) {
        final baseType = (resultType as NullableType).baseType;

        if (baseType == const EmptyType()) {
          concreteClass = _typeFlowAnalysis.environment.coreTypes.nullClass;
        } else {
          concreteClass =
              baseType.getConcreteClass(_typeFlowAnalysis.hierarchyCache);
        }
      } else {
        concreteClass =
            resultType.getConcreteClass(_typeFlowAnalysis.hierarchyCache);
      }

      if ((concreteClass != null) || !nullable) {
        _metadata.mapping[node] = new InferredType(concreteClass, nullable);
      }
    }
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    _annotateNode(node);
    super.visitMethodInvocation(node);
  }

  @override
  visitPropertyGet(PropertyGet node) {
    _annotateNode(node);
    super.visitPropertyGet(node);
  }

  @override
  visitDirectMethodInvocation(DirectMethodInvocation node) {
    _annotateNode(node);
    super.visitDirectMethodInvocation(node);
  }

  @override
  visitDirectPropertyGet(DirectPropertyGet node) {
    _annotateNode(node);
    super.visitDirectPropertyGet(node);
  }

  @override
  visitSuperMethodInvocation(SuperMethodInvocation node) {
    _annotateNode(node);
    super.visitSuperMethodInvocation(node);
  }

  @override
  visitSuperPropertyGet(SuperPropertyGet node) {
    _annotateNode(node);
    super.visitSuperPropertyGet(node);
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    _annotateNode(node);
    super.visitStaticInvocation(node);
  }

  @override
  visitStaticGet(StaticGet node) {
    _annotateNode(node);
    super.visitStaticGet(node);
  }
}
