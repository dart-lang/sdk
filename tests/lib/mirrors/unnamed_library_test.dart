// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// No library declaration.

import 'dart:mirrors';

import 'package:expect/expect.dart';

class Class {}

main() {
  ClassMirror cm = reflectClass(Class);
  LibraryMirror lm = cm.owner;

  Expect.equals('Class', MirrorSystem.getName(cm.simpleName));
  Expect.equals('.Class', MirrorSystem.getName(cm.qualifiedName));
  Expect.equals('', MirrorSystem.getName(lm.simpleName));
  Expect.equals('', MirrorSystem.getName(lm.qualifiedName));
}
