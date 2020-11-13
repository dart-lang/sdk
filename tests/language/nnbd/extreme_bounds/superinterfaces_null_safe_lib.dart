// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This library establishes an opted in class hierarchy which has a single
// non-generic top element, with a generic element below it, and a null safety
// specific instantantiation of the generic below that.  This is used to test
// how upper bounds behave when some super-interfaces come from opted in
// libraries and some from legacy libraries.

class Root {
  Object? rootMethod() => 3;
}

class Generic<T> extends Root {
  T genericMethod() => throw "Unreachable";
}

class NonNullable extends Generic<int> {
  int nonNullableMethod() => 3;
}

class Nullable extends Generic<int?> {
  int nullableMethod() => 3;
}

var nonNullable = NonNullable();
var nullable = Nullable();
