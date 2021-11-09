// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that compare results works as expected.

// @dart = 2.9

import 'package:expect/expect.dart';
import 'package:test_runner/bot_results.dart';
import '../../bin/compare_results.dart';

void main() {
  testEvent();
}

void testEvent() {
  var passingResult = _result();
  var sameResult = Event(passingResult, passingResult);
  _expectEvent(sameResult,
      isNew: false,
      isNewPassing: false,
      isNewFailing: false,
      changed: false,
      unchanged: true,
      remainedPassing: true,
      remainedFailing: false,
      fixed: false,
      broke: false,
      description: 'succeeded again');

  var failingResult =
      _result(matches: false, outcome: 'Fail', previousOutcome: 'Fail');
  var sameFailingResult = Event(failingResult, failingResult);
  _expectEvent(sameFailingResult,
      isNew: false,
      isNewPassing: false,
      isNewFailing: false,
      changed: false,
      unchanged: true,
      remainedPassing: false,
      remainedFailing: true,
      fixed: false,
      broke: false,
      description: 'failed again');

  var regression = Event(passingResult, failingResult);
  _expectEvent(regression,
      isNew: false,
      isNewPassing: false,
      isNewFailing: false,
      changed: true,
      unchanged: false,
      remainedPassing: false,
      remainedFailing: false,
      fixed: false,
      broke: true,
      description: 'broke');

  var differentFailingResult =
      _result(matches: false, outcome: 'Error', previousOutcome: 'Error');
  var differentFailure = Event(failingResult, differentFailingResult);
  _expectEvent(differentFailure,
      isNew: false,
      isNewPassing: false,
      isNewFailing: false,
      changed: true,
      unchanged: false,
      remainedPassing: false,
      remainedFailing: true,
      fixed: false,
      broke: false,
      description: 'failed again');

  var fixed = Event(failingResult, passingResult);
  _expectEvent(fixed,
      isNew: false,
      isNewPassing: false,
      isNewFailing: false,
      changed: true,
      unchanged: false,
      remainedPassing: false,
      remainedFailing: false,
      fixed: true,
      broke: false,
      description: 'was fixed');

  var newPass = Event(null, passingResult);
  _expectEvent(newPass,
      isNew: true,
      isNewPassing: true,
      isNewFailing: false,
      changed: true,
      unchanged: false,
      description: 'is new and succeeded');

  var newFailure = Event(null, failingResult);
  _expectEvent(newFailure,
      isNew: true,
      isNewPassing: false,
      isNewFailing: true,
      changed: true,
      unchanged: false,
      description: 'is new and failed');

  var flakyResult = _result(flaked: true);
  var becameFlaky = Event(passingResult, flakyResult);
  _expectEvent(becameFlaky, flaked: true);

  var noLongerFlaky = Event(flakyResult, passingResult);
  _expectEvent(noLongerFlaky, flaked: false);

  var failingExpectedToFailResult = _result(
      matches: true,
      outcome: 'Fail',
      previousOutcome: 'Fail',
      expectation: 'Fail');
  var nowMeetingExpectation = Event(failingResult, failingExpectedToFailResult);
  _expectEvent(nowMeetingExpectation,
      changed: true,
      unchanged: false,
      remainedPassing: false,
      remainedFailing: false,
      broke: false,
      description: 'was fixed');

  var passingExpectedToFailResult = _result(
      matches: false,
      outcome: 'Pass',
      previousOutcome: 'Pass',
      expectation: 'Fail');
  var noLongerMeetingExpectation =
      Event(passingResult, passingExpectedToFailResult);
  _expectEvent(noLongerMeetingExpectation,
      changed: true,
      unchanged: false,
      remainedPassing: false,
      remainedFailing: false,
      broke: true,
      description: 'broke');
}

void _expectEvent(Event actual,
    {bool isNew,
    bool isNewPassing,
    bool isNewFailing,
    bool changed,
    bool unchanged,
    bool remainedPassing,
    bool remainedFailing,
    bool flaked,
    bool fixed,
    bool broke,
    String description}) {
  if (isNew != null) {
    Expect.equals(isNew, actual.isNew, 'isNew mismatch');
  }
  if (isNewPassing != null) {
    Expect.equals(isNewPassing, actual.isNewPassing, 'isNewPassing mismatch');
  }
  if (isNewFailing != null) {
    Expect.equals(isNewFailing, actual.isNewFailing, 'isNewFailing mismatch');
  }
  if (changed != null) {
    Expect.equals(changed, actual.changed, 'changed mismatch');
  }
  if (unchanged != null) {
    Expect.equals(unchanged, actual.unchanged, 'unchanged mismatch');
  }
  if (remainedPassing != null) {
    Expect.equals(
        remainedPassing, actual.remainedPassing, 'remainedPassing mismatch');
  }
  if (remainedFailing != null) {
    Expect.equals(
        remainedFailing, actual.remainedFailing, 'remainedFailing mismatch');
  }
  if (flaked != null) {
    Expect.equals(flaked, actual.flaked, 'flaked mismatch');
  }
  if (fixed != null) {
    Expect.equals(fixed, actual.fixed, 'fixed mismatch');
  }
  if (broke != null) {
    Expect.equals(broke, actual.broke, 'broke mismatch');
  }
  if (description != null) {
    Expect.equals(description, actual.description, 'description mismatch');
  }
}

Result _result(
    {String configuration = 'config',
    String expectation = 'Pass',
    bool matches = true,
    String name = 'test1',
    String outcome = 'Pass',
    bool changed = false,
    String commitHash = 'abcdabcd',
    bool flaked = false,
    bool isFlaky = false,
    String previousOutcome = 'Pass'}) {
  return Result(configuration, name, outcome, expectation, matches, changed,
      commitHash, isFlaky, previousOutcome, flaked);
}
