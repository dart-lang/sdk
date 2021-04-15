// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous list usage with const functions.

import "package:expect/expect.dart";

const firstException = firstExceptionFn();
int firstExceptionFn() {
  const List<int> x = [];
  return x.first;
}

const lastException = lastExceptionFn();
int lastExceptionFn() {
  const List<int> x = [];
  return x.last;
}

const singleException = singleExceptionFn();
int singleExceptionFn() {
  const List<int> x = [];
  return x.single;
}

const singleExceptionMulti = singleExceptionMultiFn();
int singleExceptionMultiFn() {
  const List<int> x = [1, 2];
  return x.single;
}

const invalidProperty = invalidPropertyFn();
int invalidPropertyFn() {
  const List<int> x = [1, 2];
  return x.invalidProperty;
}

void main() {}
