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
    for (var i = 0; i < elementList.length; i++) {
      if (_matches(elementList, i, matcher)) {
        return;
      }
    }
    fail('Does not contain at least one element that matches');
  }

  /// Fails if for any matcher there is an element that matches.
  void excludesAll(
    Iterable<void Function(CheckTarget<T> element)> matchers,
  ) {
    var elementList = value.toList();
    var matcherList = matchers.toList();
    var included = <int>[];
    for (var i = 0; i < matcherList.length; i++) {
      var matcher = matcherList[i];
      for (var j = 0; j < elementList.length; j++) {
        if (_matches(elementList, j, matcher)) {
          included.add(i);
          break;
        }
      }
    }
    if (included.isNotEmpty) {
      fail('Unexpectedly includes matchers at ${valueStr(included)}');
    }
  }

  @UseResult.unless(parameterDefined: 'expected')
  CheckTarget<int> hasLength([int? expected]) {
    var actual = value.length;

    if (expected != null && actual != expected) {
      fail('does not have length ${valueStr(expected)}');
    }

    return nest(actual, (length) => 'has length $length');
  }

  /// Succeeds if for each matcher in [matchers] there is at least one
  /// matching element.
  void includesAll(
    Iterable<void Function(CheckTarget<T> element)> matchers,
  ) {
    var elementList = value.toList();
    var matcherList = matchers.toList();
    var notIncluded = <int>[];
    for (var i = 0; i < matcherList.length; i++) {
      var matcher = matcherList[i];
      notIncluded.add(i);
      for (var j = 0; j < elementList.length; j++) {
        if (_matches(elementList, j, matcher)) {
          notIncluded.removeLast();
          break;
        }
      }
    }
    if (notIncluded.isNotEmpty) {
      fail('Does not include matchers at ${valueStr(notIncluded)}');
    }
  }

  /// Succeeds if for each matcher there is exactly one matching element,
  /// in the same relative order.
  void includesAllInOrder(
    Iterable<void Function(CheckTarget<T> element)> matchers,
  ) {
    var elementList = value.toList();
    var matcherList = matchers.toList();
    var elementIndex = 0;
    for (var i = 0; i < matcherList.length; i++) {
      var matcher = matcherList[i];
      var hasMatch = false;
      for (; elementIndex < elementList.length; elementIndex++) {
        if (_matches(elementList, elementIndex, matcher)) {
          hasMatch = true;
          for (var j = elementIndex + 1; j < elementList.length; j++) {
            if (_matches(elementList, j, matcher)) {
              fail(
                'Matcher at ${valueStr(i)} matches elements at '
                '${valueStr(elementIndex)} and ${valueStr(j)}',
              );
            }
          }
          break;
        } else {}
      }
      if (!hasMatch) {
        fail('Does not include matcher at ${valueStr(i)}');
      }
    }
  }

  /// Succeeds if the number of [matchers] is exactly the same as the number
  /// of elements in [value], and each matcher matches the element at the
  /// corresponding index.
  void matches(
    Iterable<void Function(CheckTarget<T> element)> matchers,
  ) {
    var elementList = value.toList();
    var matcherList = matchers.toList();
    if (elementList.length != matcherList.length) {
      fail('Expected ${valueStr(matcherList.length)} elements, '
          'actually ${valueStr(elementList.length)}');
    }

    for (var index = 0; index < matcherList.length; index++) {
      var element = elementList[index];
      var matcher = matcherList[index];
      matcher(
        nest(
          element,
          (element) => 'element ${valueStr(element)} at ${valueStr(index)}',
        ),
      );
    }
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
        if (!_matches(elementList, elementIndex, matcher)) {
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

  bool _matches(
    List<T> elementList,
    int index,
    void Function(CheckTarget<T> element) matcher,
  ) {
    var elementTarget = nest(
      elementList[index],
      (element) => 'element ${valueStr(element)} at ${valueStr(index)}',
    );
    try {
      matcher(elementTarget);
      return true;
    } on test_package.TestFailure {
      return false;
    }
  }
}
