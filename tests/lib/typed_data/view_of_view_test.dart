// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The view implementation requires flattening views of views.

import "dart:typed_data";
import "package:expect/expect.dart";

const int kListSize = 100;
const int kLoopSize = 1000;

@pragma("vm:never-inline")
void readArray(Uint8List list) {
  for (var i = 0; i < list.length; i++) {
    Expect.equals(0, list[i]);
  }
}

@pragma("vm:never-inline")
void readView(Uint8List list) {
  for (var i = 0; i < list.length; i++) {
    Expect.equals(0, list[i]);
  }
}

@pragma("vm:never-inline")
void readUnmodifiableView(Uint8List list) {
  for (var i = 0; i < list.length; i++) {
    Expect.equals(0, list[i]);
  }
}

@pragma("vm:never-inline")
void readPolymorphic(Uint8List list) {
  for (var i = 0; i < list.length; i++) {
    Expect.equals(0, list[i]);
  }
}

@pragma("vm:never-inline")
void readDynamic(dynamic list) {
  for (var i = 0; i < list.length; i++) {
    Expect.equals(0, list[i]);
  }
}

void main() {
  var array = new Uint8List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readArray(array);
    readPolymorphic(array);
    readDynamic(array);
  }

  var view = new Uint8List.view(array.buffer);
  for (var i = 0; i < kLoopSize; i++) {
    readView(view);
    readPolymorphic(view);
    readDynamic(view);
  }

  var unmodifiableView1 = array.asUnmodifiableView();
  for (var i = 0; i < kLoopSize; i++) {
    readUnmodifiableView(unmodifiableView1);
    readPolymorphic(unmodifiableView1);
    readDynamic(unmodifiableView1);
  }

  var unmodifiableView2 = view.asUnmodifiableView();
  for (var i = 0; i < kLoopSize; i++) {
    readUnmodifiableView(unmodifiableView2);
    readPolymorphic(unmodifiableView2);
    readDynamic(unmodifiableView2);
  }

  var viewOfView1 = new Uint8List.view(view.buffer);
  for (var i = 0; i < kLoopSize; i++) {
    readView(viewOfView1);
    readPolymorphic(viewOfView1);
    readDynamic(viewOfView1);
  }

  var viewOfView2 = new Uint8List.view(unmodifiableView1.buffer);
  for (var i = 0; i < kLoopSize; i++) {
    readView(viewOfView2);
    readPolymorphic(viewOfView2);
    readDynamic(viewOfView2);
  }

  var viewOfView3 = new Uint8List.view(unmodifiableView2.buffer);
  for (var i = 0; i < kLoopSize; i++) {
    readView(viewOfView3);
    readDynamic(viewOfView3);
  }
}
