// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:typed_data";

import "package:expect/expect.dart";

extension ListCopy<T> on List<T> {
  @pragma("vm:never-inline")
  void copyToNotInlined(List<T> to) {
    to.setRange(0, this.length, this);
  }
}

extension ListCopyInlined<T> on List<T> {
  @pragma("vm:prefer-inline")
  void copyToInlined(List<T> to) {
    to.setRange(0, this.length, this);
  }
}

void testNotInlined() {
  List<num> numList = Uint32List.fromList([1, 2, 3, 4]);

  List<int> intList = [2, 4, 6, 8];
  // Calls _slowSetRange (from is not a _TypedListBase)
  numList.copyToNotInlined(intList);
  Expect.deepEquals(numList, intList);

  Uint32List uint32List = Uint32List(numList.length);
  numList.copyToNotInlined(uint32List);
  // Calls _fastSetRange (from is a _TypedListBase and element sizes match)
  Expect.deepEquals(numList, uint32List);

  Uint8List uint8List = Uint8List(numList.length);
  numList.copyToNotInlined(uint8List);
  // Calls _slowSetRange (element sizes differ)
  Expect.deepEquals(numList, uint8List);

  List<double> doubleList = [2.0, 4.0, 6.0, 8.0];
  Expect.isTrue(doubleList.length >= numList.length);
  // Would call _slowSetRange (from is not a _TypedListBase)
  Expect.throws<TypeError>(() => numList.copyToNotInlined(doubleList));

  Float32List float32List = Float32List(numList.length);
  // Would call _fastSetRange (from is a _TypedListBase and element sizes match)
  Expect.throws<TypeError>(() => numList.copyToNotInlined(float32List));
}

void testInlined() {
  List<num> numList = Uint32List.fromList([1, 2, 3, 4]);

  List<int> intList = [2, 4, 6, 8];
  // Calls _slowSetRange (from is not a _TypedListBase)
  numList.copyToInlined(intList);
  Expect.deepEquals(numList, intList);

  Uint32List uint32List = Uint32List(numList.length);
  numList.copyToInlined(uint32List);
  // Calls _fastSetRange (from is a _TypedListBase and element sizes match)
  Expect.deepEquals(numList, uint32List);

  Uint8List uint8List = Uint8List(numList.length);
  numList.copyToInlined(uint8List);
  // Calls _slowSetRange (element sizes differ)
  Expect.deepEquals(numList, uint8List);

  List<double> doubleList = [2.0, 4.0, 6.0, 8.0];
  Expect.isTrue(doubleList.length >= numList.length);
  // Would call _slowSetRange (from is not a _TypedListBase)
  Expect.throws<TypeError>(() => numList.copyToInlined(doubleList));

  Float32List float32List = Float32List(numList.length);
  // Would call _fastSetRange (from is a _TypedListBase and element sizes match)
  Expect.throws<TypeError>(() => numList.copyToInlined(float32List));
}

void main() {
  testNotInlined();
  testInlined();
}
