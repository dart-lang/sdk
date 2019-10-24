#!/usr/bin/env dart
// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test program for Dart AOT (dart2native, dartaotruntime).

void main(List<String> args) async {
  final String who = !args.isEmpty ? args[0] : '世界';
  print('Hello, ${who}.');
}
