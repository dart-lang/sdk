#!/usr/bin/env dart
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("dunit");

typedef void Test();
typedef TestResult SynchTest();
typedef Future<TestResult> AsynchTest();

class TestSuite {
  TestSuite() : _tests = <SynchTest>[];

  void registerTestClass(TestClass tests) {
    tests.registerTests(this);
  }

  void _registerTest(SynchTest test) {
    _tests.add(test);
  }

  void run() {
    reportResults(runTests());
  }

  List<TestResult> runTests() {
    List<TestResult> results = <TestResult>[];
    for(Function test in _tests) {
      results.add(test());
    }
    return results;
  }

  void reportResults(List<TestResult> results) {
    if(results.every(bool _(TestResult r) => r is PassedTest)) {
      print("OK -- ALL TESTS PASS (${results.length} run)");
    } else {
      for(TestResult r in
          results.filter(bool _(TestResult r) => !(r is PassedTest))) {
        print(r);
      }
      int passedTests =
          results.filter(bool _(TestResult r) => r is PassedTest).length;
      int failures =
          results.filter(bool _(TestResult r) => r is FailedTest).length;
      int errors =
          results.filter(bool _(TestResult r) => r is TestError).length;
      print("FAIL -- TESTS RUN: ${results.length}");
      print("        PASSED: ${passedTests}");
      print("        FAILED: ${failures}");
      print("        ERRORS: ${errors}");
    }
  }

  List<SynchTest> _tests;
}

interface TestResult {
  String get testDescription;
}

class PassedTest implements TestResult {
  const PassedTest(String this._testDescription);
  String get testDescription => _testDescription;
  final String _testDescription;
  String toString() => _testDescription;
}

class _ExceptionResult {
  const _ExceptionResult(String this._testDescription, var this._exception);

  String get testDescription => _testDescription;
  final String _testDescription;

  Object get exception => _exception;
  final _exception;
}

class FailedTest extends _ExceptionResult implements TestResult {
  FailedTest(String testDescription, var exception) :
      super(testDescription, exception);

  String toString() => ">>> Test failure in ${_testDescription} " +
      "with:\n${exception}\n";
}

class TestError extends _ExceptionResult implements TestResult {
  TestError(String testDescription, var exception, var this.stacktrace) :
      super(testDescription, exception);

  String toString() => ">>> Test error caught in " +
      "${_testDescription} with:\n${exception}\n$stacktrace\n";

  var stacktrace;
}

class TestClass {
  void register(String description, Function test, TestSuite suite) {
    suite._registerTest(TestResult _() {
      setUp();
      try {
        test();
        tearDown();
        return new PassedTest(description);
      } on ExpectException catch (x) {
        tearDown();
        return new FailedTest(description, x);
      } catch (x, stacktrace) {
        tearDown();
        return new TestError(description, x, stacktrace);
      }
    });
  }

  abstract void registerTests(TestSuite suite);
  void setUp() {}
  void tearDown() {}
}
