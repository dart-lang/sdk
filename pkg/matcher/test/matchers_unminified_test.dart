// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file is for matcher tests that rely on the names of various Dart types.
// These tests will fail when run in minified dart2js, since the names will be
// mangled. A version of this file that works in minified dart2js is in
// matchers_minified_test.dart.

import 'package:matcher/matcher.dart';
import 'package:unittest/unittest.dart' as ut;

import 'test_common.dart';
import 'test_utils.dart';

void main() {
  initUtils();

  ut.group('Core matchers', () {
    ut.test('throwsFormatException', () {
      shouldPass(() { throw new FormatException(''); },
          throwsFormatException);
      shouldFail(() { throw new Exception(); },
          throwsFormatException,
          matches(
              r"Expected: throws FormatException +"
              r"Actual: <Closure(: \(\) => dynamic)?> +"
              r"Which: threw \?:<Exception>"));

    });

    ut.test('throwsArgumentError', () {
      shouldPass(() { throw new ArgumentError(''); },
          throwsArgumentError);
      shouldFail(() { throw new Exception(); },
          throwsArgumentError,
          matches(
              r"Expected: throws ArgumentError +"
              r"Actual: <Closure(: \(\) => dynamic)?> +"
              r"Which: threw \?:<Exception>"));
    });

    ut.test('throwsRangeError', () {
      shouldPass(() { throw new RangeError(0); },
          throwsRangeError);
      shouldFail(() { throw new Exception(); },
          throwsRangeError,
          matches(
              r"Expected: throws RangeError +"
              r"Actual: <Closure(: \(\) => dynamic)?> +"
              r"Which: threw \?:<Exception>"));
    });

    ut.test('throwsNoSuchMethodError', () {
      shouldPass(() {
          throw new NoSuchMethodError(null, const Symbol(''), null, null);
      }, throwsNoSuchMethodError);
      shouldFail(() { throw new Exception(); },
          throwsNoSuchMethodError,
          matches(
              r"Expected: throws NoSuchMethodError +"
              r"Actual: <Closure(: \(\) => dynamic)?> +"
              r"Which: threw \?:<Exception>"));
    });

    ut.test('throwsUnimplementedError', () {
      shouldPass(() { throw new UnimplementedError(''); },
          throwsUnimplementedError);
      shouldFail(() { throw new Exception(); },
          throwsUnimplementedError,
          matches(
              r"Expected: throws UnimplementedError +"
              r"Actual: <Closure(: \(\) => dynamic)?> +"
              r"Which: threw \?:<Exception>"));
    });

    ut.test('throwsUnsupportedError', () {
      shouldPass(() { throw new UnsupportedError(''); },
          throwsUnsupportedError);
      shouldFail(() { throw new Exception(); },
          throwsUnsupportedError,
          matches(
              r"Expected: throws UnsupportedError +"
              r"Actual: <Closure(: \(\) => dynamic)?> +"
              r"Which: threw \?:<Exception>"));
    });

    ut.test('throwsStateError', () {
      shouldPass(() { throw new StateError(''); },
          throwsStateError);
      shouldFail(() { throw new Exception(); },
          throwsStateError,
          matches(
              r"Expected: throws StateError +"
              r"Actual: <Closure(: \(\) => dynamic)?> +"
              r"Which: threw \?:<Exception>"));
    });
  });

  ut.group('Iterable Matchers', () {
    ut.test('isEmpty', () {
      var d = new SimpleIterable(0);
      var e = new SimpleIterable(1);
      shouldPass(d, isEmpty);
      shouldFail(e, isEmpty, "Expected: empty "
          "Actual: SimpleIterable:[1]");
    });

    ut.test('contains', () {
      var d = new SimpleIterable(3);
      shouldPass(d, contains(2));
      shouldFail(d, contains(5),
          "Expected: contains <5> "
          "Actual: SimpleIterable:[3, 2, 1]");
    });
  });

  ut.group('Feature Matchers', () {
    ut.test("Feature Matcher", () {
      var w = new Widget();
      w.price = 10;
      shouldPass(w, new HasPrice(10));
      shouldPass(w, new HasPrice(greaterThan(0)));
      shouldFail(w, new HasPrice(greaterThan(10)),
          "Expected: Widget with a price that is a value greater than <10> "
          "Actual: <Instance of 'Widget'> "
          "Which: has price with value <10> which is not "
          "a value greater than <10>");
    });
  });
}
