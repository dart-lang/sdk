// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

// part of "internal_patch.dart";

@pragma("vm:entry-point")
class ClassID {
  @pragma("vm:entry-point", "call")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  static int getID(Object value) native "ClassID_getID";

  @pragma("vm:entry-point")
  static final int cidArray = 0;
  @pragma("vm:entry-point")
  static final int cidExternalOneByteString = 0;
  @pragma("vm:entry-point")
  static final int cidGrowableObjectArray = 0;
  @pragma("vm:entry-point")
  static final int cidImmutableArray = 0;
  @pragma("vm:entry-point")
  static final int cidOneByteString = 0;
  @pragma("vm:entry-point")
  static final int cidTwoByteString = 0;
  @pragma("vm:entry-point")
  static final int cidUint8ArrayView = 0;
}
