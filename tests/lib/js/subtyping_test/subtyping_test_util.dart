// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests subtyping relationships between JS and anonymous classes.

@JS()
library subtyping_test_util;

import 'package:js/js.dart';
import 'package:expect/expect.dart' show hasUnsoundNullSafety;
import 'package:expect/minitest.dart';

@JS()
class JSClassA {}

@JS()
class JSClassB {}

@JS()
@anonymous
class AnonymousClassA {}

@JS()
@anonymous
class AnonymousClassB {}

class DartClass {}

JSClassA returnJS() => throw '';
JSClassA? returnNullableJS() => throw '';

AnonymousClassA returnAnon() => throw '';
AnonymousClassA? returnNullableAnon() => throw '';

DartClass returnDartClass() => throw '';

// Avoid static type optimization by running all tests using this.
@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;

void testSubtyping() {
  // Checks subtyping with the same type and nullability subtyping.
  expect(returnJS is JSClassA Function(), true);
  expect(returnAnon is AnonymousClassA Function(), true);
  expect(returnJS is JSClassA? Function(), true);
  expect(returnAnon is AnonymousClassA? Function(), true);
  expect(returnNullableJS is JSClassA? Function(), true);
  expect(returnNullableAnon is AnonymousClassA? Function(), true);
  expect(returnNullableJS is JSClassA Function(), hasUnsoundNullSafety);
  expect(
      returnNullableAnon is AnonymousClassA Function(), hasUnsoundNullSafety);

  // Subtyping between JS and anonymous classes.
  expect(returnJS is AnonymousClassA Function(), true);
  expect(returnAnon is JSClassA Function(), true);

  // Subtyping between same type of package:js classes.
  expect(returnJS is JSClassB Function(), true);
  expect(returnAnon is AnonymousClassB Function(), true);

  // No subtyping between JS/anonymous classes and Dart classes.
  expect(returnJS is DartClass Function(), false);
  expect(returnDartClass is JSClassA Function(), false);
  expect(returnAnon is DartClass Function(), false);
  expect(returnDartClass is AnonymousClassA Function(), false);

  // Repeat the checks but using `confuse` to coerce runtime checks instead of
  // compile-time like above.
  expect(confuse(returnJS) is JSClassA Function(), true);
  expect(confuse(returnAnon) is AnonymousClassA Function(), true);
  expect(confuse(returnJS) is JSClassA? Function(), true);
  expect(confuse(returnAnon) is AnonymousClassA? Function(), true);
  expect(confuse(returnNullableJS) is JSClassA? Function(), true);
  expect(confuse(returnNullableAnon) is AnonymousClassA? Function(), true);
  expect(
      confuse(returnNullableJS) is JSClassA Function(), hasUnsoundNullSafety);
  expect(confuse(returnNullableAnon) is AnonymousClassA Function(),
      hasUnsoundNullSafety);

  expect(confuse(returnJS) is AnonymousClassA Function(), true);
  expect(confuse(returnAnon) is JSClassA Function(), true);

  expect(confuse(returnJS) is JSClassB Function(), true);
  expect(confuse(returnAnon) is AnonymousClassB Function(), true);

  expect(confuse(returnJS) is DartClass Function(), false);
  expect(confuse(returnDartClass) is JSClassA Function(), false);
  expect(confuse(returnAnon) is DartClass Function(), false);
  expect(confuse(returnDartClass) is AnonymousClassA Function(), false);
}
