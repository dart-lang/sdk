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
import 'utils.dart';
import '../devirtualization.dart' show Devirtualization;
import '../../metadata/direct_call.dart';

const bool kDumpAllSummaries =
    const bool.fromEnvironment('global.type.flow.dump.all.summaries');

/// Whole-program type flow analysis and transformation.
/// Assumes strong mode and closed world.
Program transformProgram(CoreTypes coreTypes, Program program) {
  final hierarchy = new ClassHierarchy(program);
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
      // TODO(alexmarkov): Pass entry points descriptors from command line.
      entryPointsJSONFiles: [
        'pkg/vm/lib/transformations/type_flow/entry_points.json',
        'pkg/vm/lib/transformations/type_flow/entry_points_extra.json',
      ]);

  Procedure main = program.mainMethod;
  final Selector mainSelector = new DirectSelector(main);
  typeFlowAnalysis.addRawCall(mainSelector);
  typeFlowAnalysis.process();

  analysisStopWatch.stop();

  final transformsStopWatch = new Stopwatch()..start();

  new DropMethodBodiesVisitor(typeFlowAnalysis).visitProgram(program);

  new TFADevirtualization(program, typeFlowAnalysis).visitProgram(program);

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
