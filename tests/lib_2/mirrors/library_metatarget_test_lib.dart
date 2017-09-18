// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for the combined use of metatargets and library tags.

@usedOnlyOnLibrary
library subLib;

import 'library_metatarget_test_annotations_lib.dart';

class A {
  @reflectable
  var reflectableField = 1;
  var nonreflectableField = 2;
}
