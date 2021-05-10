// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests lists with const functions.

import "package:expect/expect.dart";

const firstVar = firstFn();
int firstFn() {
  const List<int> x = [1, 2];
  return x.first;
}

const firstCatchVar = firstCatchFn();
int firstCatchFn() {
  try {
    const List<int> x = [];
    var v = x.first;
  } on StateError {
    return 0;
  }
  return 1;
}

const isEmptyVar = isEmptyFn();
bool isEmptyFn() {
  const List<int> x = [1, 2];
  return x.isEmpty;
}

const isNotEmptyVar = isNotEmptyFn();
bool isNotEmptyFn() {
  const List<int> x = [1, 2];
  return x.isNotEmpty;
}

const lastVar = lastFn();
int lastFn() {
  const List<int> x = [1, 2];
  return x.last;
}

const lastCatchVar = lastCatchFn();
int lastCatchFn() {
  try {
    const List<int> x = [];
    var v = x.last;
  } on StateError {
    return 0;
  }
  return 1;
}

const lengthVar = lengthFn();
int lengthFn() {
  const List<int> x = [1, 2];
  return x.length;
}

const singleVar = singleFn();
int singleFn() {
  const List<int> x = [1];
  return x.single;
}

const singleCatchVar = singleCatchFn();
int singleCatchFn() {
  try {
    const List<int> x = [];
    var v = x.single;
  } on StateError {
    return 0;
  }
  return 1;
}

const singleCatchVar2 = singleCatchFn2();
int singleCatchFn2() {
  try {
    const List<int> x = [1, 2];
    var v = x.single;
  } on StateError {
    return 0;
  }
  return 1;
}

const getWithIndexVar = getWithIndexFn();
int getWithIndexFn() {
  const List<int> x = [1];
  return x[0];
}

const rangeErrorCatchVar = rangeErrorCatchFn();
int rangeErrorCatchFn() {
  try {
    const List<int> x = [1];
    var v = x[1];
  } on RangeError {
    return 0;
  }
  return 1;
}

const mutableListVar = mutableList();
List<int> mutableList() {
  List<int> x = [1, 2];
  return x;
}

const mutableListAddVar = mutableListAdd();
List<int> mutableListAdd() {
  List<int> x = [1, 2];
  x.add(3);
  return x;
}

void main() {
  Expect.equals(firstVar, 1);
  Expect.equals(firstCatchVar, 0);
  Expect.equals(isEmptyVar, false);
  Expect.equals(isNotEmptyVar, true);
  Expect.equals(lastVar, 2);
  Expect.equals(lastCatchVar, 0);
  Expect.equals(lengthVar, 2);
  Expect.equals(singleVar, 1);
  Expect.equals(singleCatchVar, 0);
  Expect.equals(singleCatchVar2, 0);
  Expect.equals(getWithIndexVar, 1);
  Expect.equals(rangeErrorCatchVar, 0);
  Expect.equals(mutableListVar, const [1, 2]);
  Expect.equals(mutableListAddVar, const [1, 2, 3]);
}
