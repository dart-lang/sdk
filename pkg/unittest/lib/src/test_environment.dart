// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of unittest;

/// Class for encapsulating test environment state.
///
/// This is used by the [withTestEnvironment] method to support multiple
/// invocations of the unittest library within the same application
/// instance.
class _TestEnvironment {
  Configuration config;

  // We use a 'dummy' context for the top level to eliminate null
  // checks when querying the context. This allows us to easily
  //  support top-level [setUp]/[tearDown] functions as well.
  final rootContext = new _GroupContext();
  _GroupContext currentContext;

  /// The [currentTestCaseIndex] represents the index of the currently running
  /// test case.
  ///
  /// == -1 implies the test system is not running.
  /// == [number of test cases] is a short-lived state flagging that the last
  ///    test has completed.
  int currentTestCaseIndex = -1;

  /// The [initialized] variable specifies whether the framework
  /// has been initialized.
  bool initialized = false;

  /// The time since we last gave asynchronous code a chance to be scheduled.
  int lastBreath = new DateTime.now().millisecondsSinceEpoch;

  /// The set of tests to run can be restricted by using [solo_test] and
  /// [solo_group].
  ///
  /// As groups can be nested we use a counter to keep track of the nesting
  /// level of soloing, and a flag to tell if we have seen any solo tests.
  int soloNestingLevel = 0;
  bool soloTestSeen = false;

  /// The list of test cases to run.
  final List<TestCase> testCases = new List<TestCase>();

  /// The [uncaughtErrorMessage] holds the error messages that are printed
  /// in the test summary.
  String uncaughtErrorMessage;

  _TestEnvironment() {
    currentContext = rootContext;
  }
}
