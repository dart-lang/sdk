// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:io';
import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_model/element_map.dart';
import 'package:compiler/src/js_model/js_strategy.dart';
import 'package:compiler/src/js_model/js_world.dart';
import 'package:compiler/src/ssa/logging.dart';
import 'package:compiler/src/ssa/ssa.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    bool strict = args.contains('-s');
    await checkTests(dataDir, new OptimizationDataComputer(strict: strict),
        options: [Flags.disableInlining], args: args);
  });
}

class OptimizationDataValidator
    implements DataInterpreter<OptimizationTestLog> {
  final bool strict;

  const OptimizationDataValidator({this.strict: false});

  @override
  String getText(OptimizationTestLog actualData, [String indentation]) {
    Features features = new Features();
    for (OptimizationLogEntry entry in actualData.entries) {
      features.addElement(
          entry.tag, entry.features.getText().replaceAll(',', '&'));
    }
    return features.getText();
  }

  @override
  bool isEmpty(OptimizationTestLog actualData) {
    return actualData == null || actualData.entries.isEmpty;
  }

  @override
  String isAsExpected(OptimizationTestLog actualLog, String expectedLog) {
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
      for (OptimizationLogEntry entry in actualDataForTag) {
        actualDataEntries.remove(entry);
      }
      if (expectedEntryData == '') {
        errorsFound.add("Unknown expected entry '$tag'");
      } else if (expectedEntryData is List && expectedEntryData.isEmpty) {
        if (actualDataForTag.isNotEmpty) {
          errorsFound.add('Non-empty log found for tag $tag');
        }
      } else if (expectedEntryData == '*') {
        // Anything allowed.
      } else if (expectedEntryData is List) {
        for (Object object in expectedEntryData) {
          String expectedLogEntryText = '$object';
          bool expectMatch = true;
          if (expectedLogEntryText.startsWith('!')) {
            expectedLogEntryText = expectedLogEntryText.substring(1);
            expectMatch = false;
          }
          expectedLogEntryText = expectedLogEntryText.replaceAll('&', ',');
          Features expectedLogEntry = Features.fromText(expectedLogEntryText);
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
          if (expectMatch) {
            if (!matchFound) {
              errorsFound.add("No match found for $tag=[$object]");
            }
          } else {
            if (matchFound) {
              errorsFound.add("Unexpected match found for $tag=[$object]");
            }
          }
        }
      } else {
        errorsFound.add("Unknown expected entry $tag=$expectedEntryData");
      }
    });
    if (strict) {
      for (OptimizationLogEntry entry in actualDataEntries) {
        errorsFound.add("Extra entry ${entry.tag}=${entry.features.getText()}");
      }
    }
    return errorsFound.isNotEmpty ? errorsFound.join(', ') : null;
  }
}

class OptimizationDataComputer extends DataComputer<OptimizationTestLog> {
  final bool strict;

  const OptimizationDataComputer({this.strict: false});

  /// Compute type inference data for [member] from kernel based inference.
  ///
  /// Fills [actualMap] with the data.
  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<OptimizationTestLog>> actualMap,
      {bool verbose: false}) {
    JsClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    JsToElementMap elementMap = closedWorld.elementMap;
    MemberDefinition definition = elementMap.getMemberDefinition(member);
    new OptimizationIrComputer(compiler.reporter, actualMap, elementMap, member,
            compiler.backendStrategy, closedWorld.closureDataLookup)
        .run(definition.node);
  }

  @override
  DataInterpreter<OptimizationTestLog> get dataValidator =>
      new OptimizationDataValidator(strict: strict);
}

/// AST visitor for computing inference data for a member.
class OptimizationIrComputer extends IrDataExtractor<OptimizationTestLog> {
  final JsBackendStrategy _backendStrategy;
  final JsToElementMap _elementMap;
  final ClosureData _closureDataLookup;

  OptimizationIrComputer(
      DiagnosticReporter reporter,
      Map<Id, ActualData<OptimizationTestLog>> actualMap,
      this._elementMap,
      MemberEntity member,
      this._backendStrategy,
      this._closureDataLookup)
      : super(reporter, actualMap);

  OptimizationTestLog getLog(MemberEntity member) {
    SsaFunctionCompiler functionCompiler = _backendStrategy.functionCompiler;
    return functionCompiler.optimizer.loggersForTesting[member];
  }

  OptimizationTestLog getMemberValue(MemberEntity member) {
    if (member is FunctionEntity) {
      return getLog(member);
    }
    return null;
  }

  @override
  OptimizationTestLog computeMemberValue(Id id, ir.Member node) {
    return getMemberValue(_elementMap.getMember(node));
  }

  @override
  OptimizationTestLog computeNodeValue(Id id, ir.TreeNode node) {
    if (node is ir.FunctionExpression || node is ir.FunctionDeclaration) {
      ClosureRepresentationInfo info = _closureDataLookup.getClosureInfo(node);
      return getMemberValue(info.callMethod);
    }
    return null;
  }
}
