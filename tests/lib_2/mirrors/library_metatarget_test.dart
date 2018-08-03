// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for the combined use of metatargets and library tags.

library topLib;

import 'library_metatarget_test_lib.dart';
import 'library_metatarget_test_annotations_lib.dart';

@MirrorsUsed(metaTargets: const [Reflectable])
import 'dart:mirrors';

void main() {
  print(new A());
}
