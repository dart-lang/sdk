// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  forStatement();
  patternForStatement();
  forElement();
  patternForElement();
}

void forStatement() {
  List<int Function()> capturedInCondition = [];
  int inCondition(int Function() f) {
    capturedInCondition.add(f);
    return f();
  }

  List<int Function()> capturedInUpdate = [];
  int inUpdate(int Function() f) {
    capturedInUpdate.add(f);
    return f();
  }

  List<int Function()> capturedInBody = [];
  int inBody(int Function() f) {
    capturedInBody.add(f);
    return f();
  }

  for (int i = 0; inCondition(() => i) < 10; inUpdate(() => i++)) {
    inBody(() => i);
  }

  check(capturedInCondition, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  check(capturedInUpdate, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  check(capturedInBody, [0, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
}

void patternForStatement() {
  List<int Function()> capturedInCondition = [];
  int inCondition(int Function() f) {
    capturedInCondition.add(f);
    return f();
  }

  List<int Function()> capturedInUpdate = [];
  int inUpdate(int Function() f) {
    capturedInUpdate.add(f);
    return f();
  }

  List<int Function()> capturedInBody = [];
  int inBody(int Function() f) {
    capturedInBody.add(f);
    return f();
  }

  for (var (int i,) = (0,); inCondition(() => i) < 10; inUpdate(() => i++)) {
    inBody(() => i);
  }

  check(capturedInCondition, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  check(capturedInUpdate, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  check(capturedInBody, [0, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
}

void forElement() {
  List<int Function()> capturedInCondition = [];
  int inCondition(int Function() f) {
    capturedInCondition.add(f);
    return f();
  }

  List<int Function()> capturedInUpdate = [];
  int inUpdate(int Function() f) {
    capturedInUpdate.add(f);
    return f();
  }

  List<int Function()> capturedInBody = [];
  int inBody(int Function() f) {
    capturedInBody.add(f);
    return f();
  }

  var list = [
    for (int i = 0; inCondition(() => i) < 10; inUpdate(() => i++))
      inBody(() => i),
  ];

  check(capturedInCondition, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  check(capturedInUpdate, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  check(capturedInBody, [0, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
}

void patternForElement() {
  List<int Function()> capturedInCondition = [];
  int inCondition(int Function() f) {
    capturedInCondition.add(f);
    return f();
  }

  List<int Function()> capturedInUpdate = [];
  int inUpdate(int Function() f) {
    capturedInUpdate.add(f);
    return f();
  }

  List<int Function()> capturedInBody = [];
  int inBody(int Function() f) {
    capturedInBody.add(f);
    return f();
  }

  var list = [
    for (var (int i,) = (0,); inCondition(() => i) < 10; inUpdate(() => i++))
      inBody(() => i),
  ];

  check(capturedInCondition, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  check(capturedInUpdate, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  check(capturedInBody, [0, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
}

void check(List<int Function()> actual, List<int> expected) {
  if (actual.length != expected.length) {
    throw 'Expected ${expected.length} elements';
  }
  for (int i = 0; i < expected.length; i++) {
    int value = actual[i]();
    if (value != expected[i]) {
      throw 'Expected value ${expected[i]} at index $i, found ${value}';
    }
  }
}
