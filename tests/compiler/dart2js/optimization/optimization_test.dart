// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_backend/backend.dart';
import 'package:compiler/src/js_model/element_map.dart';
import 'package:compiler/src/js_model/js_world.dart';
import 'package:compiler/src/ssa/logging.dart';
import 'package:compiler/src/ssa/ssa.dart';
import 'package:compiler/src/util/features.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(dataDir, const OptimizationDataComputer(), args: args);
  });
}

class OptimizationDataValidator implements DataInterpreter<OptimizationLog> {
  const OptimizationDataValidator();

  @override
  String getText(OptimizationLog actualData) {
    Features features = new Features();
    for (OptimizationLogEntry entry in actualData.entries) {
      features.addElement(entry.tag, entry.features.getText());
    }
    return features.getText();
  }

  @override
  bool isEmpty(OptimizationLog actualData) {
    return actualData == null || actualData.entries.isEmpty;
  }

  @override
  String isAsExpected(OptimizationLog actualLog, String expectedLog) {
    expectedLog ??= '';
    if (expectedLog == '') {
      return actualLog.entries.isEmpty
          ? null
          : "Expected empty optimization log.";
    }
    if (expectedLog == '*') {
      return null;
    }
    List<OptimizationLogEntry> actualDataEntries = actualLog.entries.toList();
    Features expectedLogEntries = Features.fromText(expectedLog);
    List<String> errorsFound = <String>[];
    expectedLogEntries.forEach((String tag, dynamic expectedEntryData) {
      List<OptimizationLogEntry> actualDataForTag =
          actualDataEntries.where((data) => data.tag == tag).toList();
      if (expectedEntryData == '' ||
          expectedEntryData is List && expectedEntryData.isEmpty) {
        if (actualDataForTag.isNotEmpty) {
          errorsFound.add('Non-empty log found for tag $tag');
        }
      } else if (expectedEntryData == '*') {
        // Anything allowed.
      } else if (expectedEntryData is List) {
        for (Object object in expectedEntryData) {
          Features expectedLogEntry = Features.fromText('$object');
          bool matchFound = false;
          for (OptimizationLogEntry actualLogEntry in actualDataForTag) {
            bool validData = true;
            expectedLogEntry.forEach((String key, Object expectedValue) {
              Object actualValue = actualLogEntry.features[key];
              if ('$actualValue' != '$expectedValue') {
                validData = false;
              }
            });
            if (validData) {
              actualDataForTag.remove(actualLogEntry);
              matchFound = true;
              break;
            }
          }
          if (!matchFound) {
            errorsFound.add("No match found for $tag=[$object]");
          }
        }
      } else {
        errorsFound.add("Unknown expected entry '$expectedEntryData'");
      }
    });
    return errorsFound.isNotEmpty ? errorsFound.join(', ') : null;
  }
}

class OptimizationDataComputer extends DataComputer<OptimizationLog> {
  const OptimizationDataComputer();

  /// Compute type inference data for [member] from kernel based inference.
  ///
  /// Fills [actualMap] with the data.
  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<OptimizationLog>> actualMap,
      {bool verbose: false}) {
    JsClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    JsToElementMap elementMap = closedWorld.elementMap;
    MemberDefinition definition = elementMap.getMemberDefinition(member);
    new OptimizationIrComputer(compiler.reporter, actualMap, elementMap, member,
            compiler.backend, closedWorld.closureDataLookup)
        .run(definition.node);
  }

  @override
  DataInterpreter<OptimizationLog> get dataValidator =>
      const OptimizationDataValidator();
}

/// AST visitor for computing inference data for a member.
class OptimizationIrComputer extends IrDataExtractor<OptimizationLog> {
  final JavaScriptBackend backend;
  final JsToElementMap _elementMap;
  final ClosureData _closureDataLookup;

  OptimizationIrComputer(
      DiagnosticReporter reporter,
      Map<Id, ActualData<OptimizationLog>> actualMap,
      this._elementMap,
      MemberEntity member,
      this.backend,
      this._closureDataLookup)
      : super(reporter, actualMap);

  OptimizationLog getLog(MemberEntity member) {
    SsaFunctionCompiler functionCompiler = backend.functionCompiler;
    return functionCompiler.optimizer.loggersForTesting[member];
  }

  OptimizationLog getMemberValue(MemberEntity member) {
    if (member is FunctionEntity) {
      return getLog(member);
    }
    return null;
  }

  @override
  OptimizationLog computeMemberValue(Id id, ir.Member node) {
    return getMemberValue(_elementMap.getMember(node));
  }

  @override
  OptimizationLog computeNodeValue(Id id, ir.TreeNode node) {
    if (node is ir.FunctionExpression || node is ir.FunctionDeclaration) {
      ClosureRepresentationInfo info = _closureDataLookup.getClosureInfo(node);
      return getMemberValue(info.callMethod);
    }
    return null;
  }
}
