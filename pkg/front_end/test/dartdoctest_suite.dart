// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:testing/testing.dart'
    show Chain, ChainContext, Result, Step, TestDescription, runMe;

import '../tool/dart_doctest_impl.dart';

void main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, configurationPath: "../testing.json");

Future<Context> createContext(
    Chain suite, Map<String, String> environment) async {
  return new Context(suite.name);
}

class Context extends ChainContext {
  final String suiteName;

  Context(this.suiteName);

  @override
  final List<Step> steps = const <Step>[
    const DartDocTestStep(),
  ];

  // Override special handling of negative tests.
  @override
  Result processTestResult(
      TestDescription description, Result result, bool last) {
    return result;
  }

  @override
  Stream<DartDocTestTestDescription> list(Chain suite) async* {
    await for (TestDescription entry in super.list(suite)) {
      List<Test> tests = await dartDocTest.extractTestsFromUri(entry.uri);
      if (tests.isEmpty) continue;
      yield new DartDocTestTestDescription(entry.shortName, entry.uri, tests);
    }
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
