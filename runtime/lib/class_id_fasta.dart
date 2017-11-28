// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "internal_patch.dart";

class ClassID {
  static int getID(Object value) native "ClassID_getID";

  static final int cidArray = 0;
  static final int cidExternalOneByteString = 0;
  static final int cidGrowableObjectArray = 0;
  static final int cidImmutableArray = 0;
  static final int cidOneByteString = 0;
  static final int cidTwoByteString = 0;
  static final int cidBigint = 0;
}
