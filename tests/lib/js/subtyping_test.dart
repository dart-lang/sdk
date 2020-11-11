// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests subtyping relationships between JS and anonymous classes.

@JS()
library subtyping_test;

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

void useJSClassA(JSClassA _) {}
void useAnonymousClassA(AnonymousClassA _) {}
void useDartClass(DartClass _) {}

void useNullableJSClassA(JSClassA? _) {}
void useNullableAnonymousClassA(AnonymousClassA? _) {}

// Avoid static type optimization by running all tests using this.
@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;

void main() {
  // Checks subtyping with the same type and nullability subtyping.
  expect(useJSClassA is void Function(JSClassA), true);
  expect(useAnonymousClassA is void Function(AnonymousClassA), true);
  expect(useJSClassA is void Function(JSClassA?), hasUnsoundNullSafety);
  expect(useAnonymousClassA is void Function(AnonymousClassA?),
      hasUnsoundNullSafety);
  expect(useNullableJSClassA is void Function(JSClassA?), true);
  expect(useNullableAnonymousClassA is void Function(AnonymousClassA?), true);
  expect(useNullableJSClassA is void Function(JSClassA), true);
  expect(useNullableAnonymousClassA is void Function(AnonymousClassA), true);

  expect(confuse(useJSClassA) is void Function(JSClassA), true);
  expect(confuse(useAnonymousClassA) is void Function(AnonymousClassA), true);
  expect(
      confuse(useJSClassA) is void Function(JSClassA?), hasUnsoundNullSafety);
  expect(confuse(useAnonymousClassA) is void Function(AnonymousClassA?),
      hasUnsoundNullSafety);
  expect(confuse(useNullableJSClassA) is void Function(JSClassA?), true);
  expect(confuse(useNullableAnonymousClassA) is void Function(AnonymousClassA?),
      true);
  expect(confuse(useNullableJSClassA) is void Function(JSClassA), true);
  expect(confuse(useNullableAnonymousClassA) is void Function(AnonymousClassA),
      true);

  // No subtyping between JS and anonymous classes.
  expect(useJSClassA is void Function(AnonymousClassA), false);
  expect(useAnonymousClassA is void Function(JSClassA), false);

  expect(confuse(useJSClassA) is void Function(AnonymousClassA), false);
  expect(confuse(useAnonymousClassA) is void Function(JSClassA), false);

  // No subtyping between separate classes even if they're both JS classes or
  // anonymous classes.
  expect(useJSClassA is void Function(JSClassB), false);
  expect(useAnonymousClassA is void Function(AnonymousClassB), false);

  expect(confuse(useJSClassA) is void Function(JSClassB), false);
  expect(confuse(useAnonymousClassA) is void Function(AnonymousClassB), false);

  // No subtyping between JS/anonymous classes and Dart classes.
  expect(useJSClassA is void Function(DartClass), false);
  expect(useAnonymousClassA is void Function(DartClass), false);

  expect(confuse(useJSClassA) is void Function(DartClass), false);
  expect(confuse(useAnonymousClassA) is void Function(DartClass), false);
}
