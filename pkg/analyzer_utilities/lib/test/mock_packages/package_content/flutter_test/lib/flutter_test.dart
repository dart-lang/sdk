// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

void test(Object description, dynamic Function() body) {}

void group(Object description, void Function() body) {}

void main() {
  // Because this file is called 'flutter_test.dart' and is inside the 'test'
  // folder, it will be considered a test suite. To avoid it failing the bots
  // with "Invoked Dart programs must have a 'main' function defined", provide
  // an empty main function.
}
