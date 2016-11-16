// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ClassID {
  static int getID(Object value) native "ClassID_getID";

  static int _lookup(String name) native "ClassID_byName";

  static final int cidArray = _lookup('Array');
  static final int cidExternalOneByteString = _lookup('ExternalOneByteString');
  static final int cidGrowableObjectArray = _lookup('GrowableObjectArray');
  static final int cidImmutableArray = _lookup('ImmutableArray');
  static final int cidOneByteString = _lookup('OneByteString');
  static final int cidTwoByteString = _lookup('TwoByteString');
  static final int cidBigint = _lookup('Bigint');
}
