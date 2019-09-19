// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "internal_patch.dart";

@pragma("vm:entry-point")
class ClassID {
  @pragma("vm:entry-point")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  static int getID(Object value) native "ClassID_getID";

  // VM injects class id constants into this class.
}
