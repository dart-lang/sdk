// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_utilities/check/check.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart' as test_package;

extension IterableExtension<T> on CheckTarget<Iterable<T>> {
  void get isEmpty {
    if (value.isNotEmpty) {
      fail('is not empty');
    }
  }

  void get isNotEmpty {
    if (value.isEmpty) {
      fail('is empty');
    }
  }

  /// Succeeds if there is an element that matches the [matcher],
  void containsMatch(void Function(CheckTarget<T> element) matcher) {
    var elementList = value.toList();
    for (var elementIndex = 0;
        elementIndex < elementList.length;
        elementIndex++) {
      var element = elementList[elementIndex];
      var elementTarget = nest(
        element,
        (element) =>
            'element ${valueStr(element)} at ${valueStr(elementIndex)}',
      );
      try {
        matcher(elementTarget);
        return;
      } on test_package.TestFailure {
        continue;
      }
    }
    fail('Does not contain at least one element that matches');
  }

  @UseResult.unless(parameterDefined: 'expected')
  CheckTarget<int> hasLength([int? expected]) {
    var actual = value.length;

    if (expected != null && actual != expected) {
      fail('does not have length ${valueStr(expected)}');
    }

    return nest(actual, (length) => 'has length $length');
  }

  /// Succeeds if the number of [matchers] is exactly the same as the number
  /// of elements in [value], and for each matcher there is exactly one element
  /// that matches.
  void matchesInAnyOrder(
    Iterable<void Function(CheckTarget<T> element)> matchers,
  ) {
    var elementList = value.toList();
    var matcherList = matchers.toList();
    if (elementList.length != matcherList.length) {
      fail('Expected ${valueStr(matcherList.length)} elements, '
          'actually ${valueStr(elementList.length)}');
    }

    for (var matcherIndex = 0;
        matcherIndex < matcherList.length;
        matcherIndex++) {
      var matcher = matcherList[matcherIndex];
      T? matchedElement;
      for (var elementIndex = 0;
          elementIndex < elementList.length;
          elementIndex++) {
        var element = elementList[elementIndex];
        var elementTarget = nest(
          element,
          (element) =>
              'element ${valueStr(element)} at ${valueStr(elementIndex)}',
        );
        // Jump to the next element if does not match.
        try {
          matcher(elementTarget);
        } on test_package.TestFailure {
          continue;
        }
        // The element matches, check that it is unique.
        if (matchedElement == null) {
          matchedElement = element;
        } else {
          fail('Already matched ${valueStr(matchedElement)}, '
              'found ${valueStr(element)}');
        }
      }
      if (matchedElement == null) {
        fail('No match at ${valueStr(matcherIndex)}');
      }
    }
  }
}
