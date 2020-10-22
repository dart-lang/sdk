// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;
import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart'
    show DataInterpreter, runTests;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart'
    show ExperimentalFlag;
import 'package:front_end/src/base/nnbd_mode.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/src/printer.dart';

const String normalMarker = 'normal';
const String verboseMarker = 'verbose';
const String limitedMarker = 'limited';

const String statementMarker = 'stmt';
const String expressionMarker = 'expr';

const AstTextStrategy normalStrategy = const AstTextStrategy(
    includeLibraryNamesInMembers: false,
    includeLibraryNamesInTypes: false,
    includeAuxiliaryProperties: false,
    useMultiline: true,
    maxExpressionDepth: null,
    maxExpressionsLength: null,
    maxStatementDepth: null,
    maxStatementsLength: null);

const AstTextStrategy verboseStrategy = const AstTextStrategy(
    includeLibraryNamesInMembers: true,
    includeLibraryNamesInTypes: true,
    includeAuxiliaryProperties: true,
    useMultiline: true,
    maxExpressionDepth: null,
    maxExpressionsLength: null,
    maxStatementDepth: null,
    maxStatementsLength: null);

const AstTextStrategy limitedStrategy = const AstTextStrategy(
    includeLibraryNamesInMembers: false,
    includeLibraryNamesInTypes: false,
    includeAuxiliaryProperties: false,
    useMultiline: false,
    maxExpressionDepth: 5,
    maxExpressionsLength: 4,
    maxStatementDepth: 5,
    maxStatementsLength: 4);

AstTextStrategy getStrategy(String marker) {
  switch (marker) {
    case normalMarker:
      return normalStrategy;
    case verboseMarker:
      return verboseStrategy;
    case limitedMarker:
      return limitedStrategy;
  }
  throw new UnsupportedError("Unexpected marker '${marker}'.");
}

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
  await runTests<String>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      preserveWhitespaceInAnnotations: true,
      runTest: runTestFor(const TextRepresentationDataComputer(), [
        const TextRepresentationConfig(normalMarker, 'normal'),
        const TextRepresentationConfig(verboseMarker, 'verbose'),
        const TextRepresentationConfig(limitedMarker, 'limited'),
      ]));
}

class TextRepresentationConfig extends TestConfig {
  const TextRepresentationConfig(String marker, String name)
      : super(marker, name,
            explicitExperimentalFlags: const {
              ExperimentalFlag.nonNullable: true
            },
            nnbdMode: NnbdMode.Strong);

  void customizeCompilerOptions(CompilerOptions options, TestData testData) {
    if (testData.name.endsWith('_opt_out.dart')) {
      options.nnbdMode = NnbdMode.Weak;
    }
  }
}

class TextRepresentationDataComputer extends DataComputer<String> {
  const TextRepresentationDataComputer();

  void computeLibraryData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Library library,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    new TextRepresentationDataExtractor(
            compilerResult, actualMap, getStrategy(config.marker))
        .computeForLibrary(library);
  }

  @override
  void computeMemberData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Member member,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    member.accept(new TextRepresentationDataExtractor(
        compilerResult, actualMap, getStrategy(config.marker)));
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

class TextRepresentationDataExtractor extends CfeDataExtractor<String> {
  final AstTextStrategy strategy;

  TextRepresentationDataExtractor(InternalCompilerResult compilerResult,
      Map<Id, ActualData<String>> actualMap, this.strategy)
      : super(compilerResult, actualMap);

  @override
  String computeLibraryValue(Id id, Library node) {
    return 'nnbd=${node.isNonNullableByDefault}';
  }

  @override
  visitProcedure(Procedure node) {
    if (!node.name.text.startsWith(expressionMarker) &&
        !node.name.text.startsWith(statementMarker)) {
      node.function.accept(this);
    }
    computeForMember(node);
  }

  @override
  visitField(Field node) {
    if (!node.name.text.startsWith(expressionMarker) &&
        !node.name.text.startsWith(statementMarker)) {
      node.initializer?.accept(this);
    }
    computeForMember(node);
  }

  @override
  String computeMemberValue(Id id, Member node) {
    if (node.name.text == 'stmtVariableDeclarationMulti') {
      print(node);
    }
    if (node.name.text.startsWith(expressionMarker)) {
      if (node is Procedure) {
        Statement body = node.function.body;
        if (body is ReturnStatement) {
          return body.expression.toText(strategy);
        }
      } else if (node is Field && node.initializer != null) {
        return node.initializer.toText(strategy);
      }
    } else if (node.name.text.startsWith(statementMarker)) {
      if (node is Procedure) {
        Statement body = node.function.body;
        if (body is Block && body.statements.length == 1) {
          // Prefix with newline to make multiline text representations more
          // readable.
          return '\n${body.statements.single.toText(strategy)}';
        }
      }
    }
    return null;
  }

  @override
  String computeNodeValue(Id id, TreeNode node) {
    if (node is ConstantExpression) {
      return node.constant.toText(strategy);
    } else if (node is VariableDeclaration) {
      DartType type = node.type;
      if (type is FunctionType && type.typedefType != null) {
        return type.typedefType.toText(strategy);
      } else {
        return type.toText(strategy);
      }
    }
    return null;
  }
}
