// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:testing/testing.dart'
    show Chain, ChainContext, Result, Step, TestDescription;

import '../tool/dart_doctest_impl.dart';
import 'utils/suite_utils.dart';

void main([List<String> arguments = const []]) => internalMain(createContext,
    arguments: arguments,
    displayName: "dartdoctest suite",
    configurationPath: "../testing.json");

Future<Context> createContext(
    Chain suite, Map<String, String> environment) {
  return new Future.value(new Context(suite.name));
}

class Context extends ChainContext {
  final String suiteName;

  Context(this.suiteName);

  @override
  final List<Step> steps = const <Step>[
    const DartDocTestStep(),
  ];

  @override
  Future<List<DartDocTestTestDescription>> list(Chain suite) async {
    List<DartDocTestTestDescription> result = [];
    for (TestDescription entry in await super.list(suite)) {
      List<Test> tests = await dartDocTest.extractTestsFromUri(entry.uri);
      if (tests.isEmpty) continue;
      result.add(
          new DartDocTestTestDescription(entry.shortName, entry.uri, tests));
    }
    return result;
  }

  DartDocTest dartDocTest = new DartDocTest();
}

class DartDocTestTestDescription extends TestDescription {
  @override
  final String shortName;
  @override
  final Uri uri;
  final List<Test> tests;

  DartDocTestTestDescription(this.shortName, this.uri, this.tests);
}

class DartDocTestStep extends Step<DartDocTestTestDescription,
    DartDocTestTestDescription, Context> {
  const DartDocTestStep();

  @override
  String get name => "DartDocTest";

  @override
  Future<Result<DartDocTestTestDescription>> run(
      DartDocTestTestDescription description, Context context) async {
    List<TestResult> result = await context.dartDocTest
        .compileAndRun(description.uri, description.tests);
    bool boolResult = result
        .map((e) => e.outcome == TestOutcome.Pass)
        .fold(true, (previousValue, element) => previousValue && element);
    if (boolResult) {
      return new Result<DartDocTestTestDescription>.pass(description);
    } else {
      return new Result<DartDocTestTestDescription>.fail(description);
    }
  }
}
