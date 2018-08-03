// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the local IsolateMirror.

library test.local_isolate_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';

class Foo {}

void main() {
  LibraryMirror rootLibrary = reflectClass(Foo).owner;
  IsolateMirror isolate = currentMirrorSystem().isolate;
  Expect.isTrue(isolate.debugName is String);
  Expect.isTrue(isolate.isCurrent);
  Expect.equals(rootLibrary, isolate.rootLibrary);
}
