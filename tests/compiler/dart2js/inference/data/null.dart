// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  ifThenNullCheck(0);
  ifThenNullCheck(null);
  ifThenElseNullCheck(0);
  ifThenElseNullCheck(null);
  ifNotThenNullCheck(0);
  ifNotThenNullCheck(null);
  ifNotThenElseNullCheck(0);
  ifNotThenElseNullCheck(null);
  ifThenNotNullComplexCheck(0, 0);
  ifThenNotNullComplexCheck(null, null);
  ifThenElseNotNullComplexCheck(0, 0);
  ifThenElseNotNullComplexCheck(null, null);
  ifThenNotNullGradualCheck1(0, 0);
  ifThenNotNullGradualCheck1(null, 0);
  ifThenNotNullGradualCheck2(0, 0);
  ifThenNotNullGradualCheck2(null, 0);
}

/*member: ifThenNullCheck:[exact=JSUInt31]*/
ifThenNullCheck(int /*[null|exact=JSUInt31]*/ value) {
  if (value /*invoke: [null|subclass=JSInt]*/ == null) {
    return 0;
  }
  return value;
}

/*member: ifThenElseNullCheck:[exact=JSUInt31]*/
ifThenElseNullCheck(int /*[null|exact=JSUInt31]*/ value) {
  if (value /*invoke: [null|subclass=JSInt]*/ == null) {
    return 0;
  } else {
    return value;
  }
}

/*member: ifNotThenNullCheck:[exact=JSUInt31]*/
ifNotThenNullCheck(int /*[null|exact=JSUInt31]*/ value) {
  if (value /*invoke: [null|subclass=JSInt]*/ != null) {
    return value;
  }
  return 0;
}

/*member: ifNotThenElseNullCheck:[exact=JSUInt31]*/
ifNotThenElseNullCheck(int /*[null|exact=JSUInt31]*/ value) {
  if (value /*invoke: [null|subclass=JSInt]*/ != null) {
    return value;
  } else {
    return 0;
  }
}

/*member: ifThenNotNullComplexCheck:[exact=JSUInt31]*/
ifThenNotNullComplexCheck(
    int /*[null|exact=JSUInt31]*/ a, int /*[null|exact=JSUInt31]*/ b) {
  if (a /*invoke: [null|subclass=JSInt]*/ != null &&
      a /*invoke: [exact=JSUInt31]*/ != b) {
    return a;
  }
  return 0;
}

/*member: ifThenElseNotNullComplexCheck:[null|exact=JSUInt31]*/
ifThenElseNotNullComplexCheck(
    int /*[null|exact=JSUInt31]*/ a, int /*[null|exact=JSUInt31]*/ b) {
  if (a /*invoke: [null|subclass=JSInt]*/ != null &&
      a /*invoke: [exact=JSUInt31]*/ != b) {
    return a;
  }
  return a;
}

/*member: ifThenNotNullGradualCheck1:[exact=JSUInt31]*/
ifThenNotNullGradualCheck1(
    int /*[null|exact=JSUInt31]*/ a, int /*[exact=JSUInt31]*/ b) {
  if (a /*invoke: [null|exact=JSUInt31]*/ != b) {
    if (a /*invoke: [null|subclass=JSInt]*/ != null) {
      return a;
    }
  }
  return 0;
}

/*member: ifThenNotNullGradualCheck2:[exact=JSUInt31]*/
ifThenNotNullGradualCheck2(
    int /*[null|exact=JSUInt31]*/ a, int /*[exact=JSUInt31]*/ b) {
  if (a /*invoke: [null|subclass=JSInt]*/ != null) {
    if (a /*invoke: [exact=JSUInt31]*/ != b) {
      return a;
    }
  }
  return 0;
}
