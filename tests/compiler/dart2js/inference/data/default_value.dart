// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  positionalWithoutDefaultOnLocal();
  positionalWithNullDefaultOnLocal();
  positionalWithOneDefaultOnLocal();
  positionalWithoutDefaultOnStatic();
  positionalWithNullDefaultOnStatic();
  positionalWithOneDefaultOnStatic();
}

/*member: positionalWithoutDefaultOnLocal:[null]*/
positionalWithoutDefaultOnLocal() {
  /*[null]*/ local([/*[null]*/ parameter]) => parameter;
  return local();
}

/*member: positionalWithNullDefaultOnLocal:[null]*/
positionalWithNullDefaultOnLocal() {
  /*[null]*/ local([/*[null]*/ parameter = null]) => parameter;
  return local();
}

/*member: positionalWithOneDefaultOnLocal:[exact=JSUInt31]*/
positionalWithOneDefaultOnLocal() {
  /*[exact=JSUInt31]*/ local([/*[exact=JSUInt31]*/ parameter = 1]) => parameter;
  return local();
}

/*member: positionalWithoutDefaultOnStatic:[null]*/
positionalWithoutDefaultOnStatic([/*[null]*/ parameter]) {
  return parameter;
}

/*member: positionalWithNullDefaultOnStatic:[null]*/
positionalWithNullDefaultOnStatic([/*[null]*/ parameter = null]) {
  return parameter;
}

/*member: positionalWithOneDefaultOnStatic:[exact=JSUInt31]*/
positionalWithOneDefaultOnStatic([/*[exact=JSUInt31]*/ parameter = 1]) {
  return parameter;
}
