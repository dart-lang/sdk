// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:io';
import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_backend/annotations.dart';
import 'package:compiler/src/js_model/element_map.dart';
import 'package:compiler/src/js_model/js_world.dart';
import 'package:compiler/src/util/enumset.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(dataDir, const AnnotationDataComputer(),
        args: args, testedConfigs: allSpecConfigs);
  });
}

class AnnotationDataComputer extends DataComputer<String> {
  const AnnotationDataComputer();

  /// Compute type inference data for [member] from kernel based inference.
  ///
  /// Fills [actualMap] with the data.
  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose: false}) {
    JsClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    JsToElementMap elementMap = closedWorld.elementMap;
    MemberDefinition definition = elementMap.getMemberDefinition(member);
    new AnnotationIrComputer(compiler.reporter, actualMap, elementMap, member,
            closedWorld.closureDataLookup, closedWorld.annotationsData)
        .run(definition.node);
  }

  @override
  bool get supportsErrors => true;

  @override
  String computeErrorData(
      Compiler compiler, Id id, List<CollectedMessage> errors) {
    return '[${errors.map((error) => error.message.message).join(',')}]';
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

/// AST visitor for computing inference data for a member.
class AnnotationIrComputer extends IrDataExtractor<String> {
  final JsToElementMap _elementMap;
  final ClosureData _closureDataLookup;
  final AnnotationsDataImpl _annotationData;

  AnnotationIrComputer(
      DiagnosticReporter reporter,
      Map<Id, ActualData<String>> actualMap,
      this._elementMap,
      MemberEntity member,
      this._closureDataLookup,
      this._annotationData)
      : super(reporter, actualMap);

  String getMemberValue(MemberEntity member) {
    EnumSet<PragmaAnnotation> pragmas =
        _annotationData.pragmaAnnotations[member];
    if (pragmas != null) {
      Features features = new Features();
      for (PragmaAnnotation pragma
          in pragmas.iterable(PragmaAnnotation.values)) {
        features.add(pragma.name);
      }
      return features.getText();
    }
    return null;
  }

  @override
  String computeMemberValue(Id id, ir.Member node) {
    return getMemberValue(_elementMap.getMember(node));
  }

  @override
  String computeNodeValue(Id id, ir.TreeNode node) {
    if (node is ir.FunctionExpression || node is ir.FunctionDeclaration) {
      ClosureRepresentationInfo info = _closureDataLookup.getClosureInfo(node);
      return getMemberValue(info.callMethod);
    }
    return null;
  }
}
