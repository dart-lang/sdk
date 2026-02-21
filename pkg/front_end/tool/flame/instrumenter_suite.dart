// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../../test/utils/kernel_chain.dart' show replacePathsInExpectText;

import 'package:kernel/ast.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:testing/testing.dart'
    show
        Chain,
        ChainContext,
        Result,
        Step,
        TestDescription,
        Expectation,
        ExpectationSet;

import '../../test/testing/environment_keys.dart';
import '../../test/utils/kernel_chain.dart' show MatchContext;
import '../../test/utils/suite_utils.dart';

import 'instrumenter.dart' as instrumenter;

void main([List<String> arguments = const []]) => internalMain(
  createContext,
  arguments: arguments,
  displayName: "Instrumenter suite",
  configurationPath: "../../testing.json",
);

const List<Map<String, String>> EXPECTATIONS = [
  {"name": "ExpectationFileMismatch", "group": "Fail"},
  {"name": "ExpectationFileMissing", "group": "Fail"},
];

Future<Context> createContext(Chain suite, Map<String, String> environment) {
  return new Future.value(new Context(suite.root, environment));
}

class Context extends ChainContext with MatchContext {
  @override
  final bool updateExpectations;

  @override
  final List<Step> steps = const <Step>[const InstrumenterStep()];

  @override
  final ExpectationSet expectationSet = new ExpectationSet.fromJsonList(
    EXPECTATIONS,
  );

  Context(Uri baseUri, Map<String, String> environment)
    : updateExpectations =
          environment[EnvironmentKeys.updateExpectations] == "true";

  @override
  bool get canBeFixWithUpdateExpectations => true;

  @override
  String get updateExpectationsOption =>
      '${EnvironmentKeys.updateExpectations}=true';
}

class InstrumenterStep extends Step<TestDescription, TestDescription, Context> {
  const InstrumenterStep();

  @override
  String get name => "Instrumenter";

  @override
  Future<Result<TestDescription>> run(
    TestDescription description,
    Context context,
  ) async {
    Component component;
    if (description.uri.path.endsWith(".count.dart")) {
      Directory tmpDir = Directory.systemTemp.createTempSync(
        "cfe_instrumenter",
      );
      try {
        component = await instrumenter.mainHelper([
          description.uri.toFilePath(),
          "--count",
          "--onlySome",
          "--omit-platform",
          "--delete",
        ], tmpDir);
      } finally {
        tmpDir.deleteSync(recursive: true);
      }
    } else if (description.uri.path.endsWith(".countCalls.dart")) {
      Directory tmpDir = Directory.systemTemp.createTempSync(
        "cfe_instrumenter",
      );
      try {
        component = await instrumenter.mainHelper([
          description.uri.toFilePath(),
          "--countCalls",
          "--onlySome",
          "--omit-platform",
          "--delete",
        ], tmpDir);
      } finally {
        tmpDir.deleteSync(recursive: true);
      }
    } else {
      throw "Don't know what to do with ${description.uri.path}";
    }

    StringBuffer buffer = new StringBuffer();
    Printer printer = new Printer(buffer);
    component.libraries.forEach((Library library) {
      if (library.fileUri == description.uri) {
        printer.writeLibraryFile(library);
        printer.endLine();
      }
    });
    printer.writeConstantTable(component);
    Result<TestDescription> expectMatch = await context.match<TestDescription>(
      ".expect",
      replacePathsInExpectText(
        buffer.toString(),
        description.uri.resolve(".."),
      ),
      description.uri,
      description,
    );
    if (expectMatch.outcome != Expectation.pass) return expectMatch;

    return new Result.pass(description);
  }
}
