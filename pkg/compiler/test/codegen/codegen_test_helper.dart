// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_model/element_map.dart';
import 'package:compiler/src/js_model/js_strategy.dart';
import 'package:compiler/src/js_model/js_world.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

const List<String> skip = [];
const List<String> skip2 = [];

main(List<String> args) {
  runTests(args);
  runTests2(args);
}

runTests(List<String> args, [int shardIndex]) {
  runTestsCommon(args,
      shardIndex: shardIndex,
      shards: 2,
      directory: 'data',
      skip: skip,
      options: ['--enable-experiment=non-nullable', Flags.soundNullSafety]);
}

runTests2(List<String> args, [int shardIndex]) {
  runTestsCommon(args,
      shardIndex: shardIndex,
      shards: 2,
      directory: 'data_2',
      skip: skip2,
      options: []);
}

runTestsCommon(List<String> args,
    {int shardIndex,
    int shards,
    String directory,
    List<String> options,
    List<String> skip}) {
  asyncTest(() async {
    Directory dataDir = Directory.fromUri(Platform.script.resolve(directory));
    await checkTests(dataDir, const CodegenDataComputer(),
        forUserLibrariesOnly: true,
        args: args,
        options: options,
        testedConfigs: allInternalConfigs,
        skip: skip,
        shardIndex: shardIndex ?? 0,
        shards: shardIndex == null ? 1 : shards);
  });
}

class CodegenDataComputer extends DataComputer<String> {
  const CodegenDataComputer();

  /// Compute generated code for [member].
  ///
  /// Fills [actualMap] with the data.
  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose: false}) {
    JsClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    JsToElementMap elementMap = closedWorld.elementMap;
    MemberDefinition definition = elementMap.getMemberDefinition(member);
    CodegenIrComputer(compiler.reporter, actualMap, elementMap, member,
            compiler.backendStrategy, closedWorld.closureDataLookup)
        .run(definition.node);
  }

  @override
  DataInterpreter<String> get dataValidator => const CodeDataInterpreter();
}

/// AST visitor for computing codegen data for a member.
class CodegenIrComputer extends IrDataExtractor<String> {
  final JsBackendStrategy _backendStrategy;
  final JsToElementMap _elementMap;
  final ClosureData _closureDataLookup;

  CodegenIrComputer(
      DiagnosticReporter reporter,
      Map<Id, ActualData<String>> actualMap,
      this._elementMap,
      MemberEntity member,
      this._backendStrategy,
      this._closureDataLookup)
      : super(reporter, actualMap);

  String getMemberValue(MemberEntity member) {
    if (member is FunctionEntity) {
      return _backendStrategy.getGeneratedCodeForTesting(member);
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

/// Default data interpreter for string data representing compiled JavaScript
/// code.
///
/// The data annotation reader strips out newlines and indentation so the
/// comparison needs to compensate.
///
/// The special data annotation `ignore` always passes, so we don't have to
/// track uninteresting code like a 'main' program.
class CodeDataInterpreter implements DataInterpreter<String> {
  const CodeDataInterpreter();

  String _clean(String code) => code.replaceAll(_re, '');
  static RegExp _re = RegExp(r'[\n\r]\s*');

  @override
  String isAsExpected(String actualData, String expectedData) {
    actualData ??= '';
    expectedData ??= '';
    if (expectedData == 'ignore') return null;
    if (_clean(actualData) != _clean(expectedData)) {
      return 'Expected $expectedData, found $actualData';
    }
    return null;
  }

  @override
  bool isEmpty(String actualData) {
    return _clean(actualData) == '';
  }

  @override
  String getText(String actualData, [String indentation]) {
    return actualData;
  }
}
