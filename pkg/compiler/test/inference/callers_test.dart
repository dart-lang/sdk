// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/inferrer/type_graph_inferrer.dart';
import 'package:compiler/src/js_model/element_map.dart';
import 'package:compiler/src/js_model/js_world.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir =
        new Directory.fromUri(Platform.script.resolve('callers'));
    await checkTests(dataDir, const CallersDataComputer(),
        args: args, options: [stopAfterTypeInference]);
  });
}

class CallersDataComputer extends DataComputer<String> {
  const CallersDataComputer();

  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose: false}) {
    JsClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    JsToElementMap elementMap = closedWorld.elementMap;
    MemberDefinition definition = elementMap.getMemberDefinition(member);
    new CallersIrComputer(
            compiler.reporter,
            actualMap,
            elementMap,
            compiler.globalInference.typesInferrerInternal,
            closedWorld.closureDataLookup)
        .run(definition.node);
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

/// AST visitor for computing side effects data for a member.
class CallersIrComputer extends IrDataExtractor<String> {
  final TypeGraphInferrer inferrer;
  final JsToElementMap _elementMap;
  final ClosureData _closureDataLookup;

  CallersIrComputer(
      DiagnosticReporter reporter,
      Map<Id, ActualData<String>> actualMap,
      this._elementMap,
      this.inferrer,
      this._closureDataLookup)
      : super(reporter, actualMap);

  String getMemberValue(MemberEntity member) {
    Iterable<MemberEntity> callers = inferrer.getCallersOfForTesting(member);
    if (callers != null) {
      List<String> names = callers.map((MemberEntity member) {
        StringBuffer sb = new StringBuffer();
        if (member.enclosingClass != null) {
          sb.write(member.enclosingClass.name);
          sb.write('.');
        }
        sb.write(member.name);
        if (member.isSetter) {
          sb.write('=');
        }
        return sb.toString();
      }).toList()
        ..sort();
      return '[${names.join(',')}]';
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
