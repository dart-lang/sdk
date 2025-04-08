// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  positionalWithoutDefaultOnLocal();
  positionalWithNullDefaultOnLocal();
  positionalWithOneDefaultOnLocal();
  positionalWithoutDefaultOnStatic();
  positionalWithNullDefaultOnStatic();
  positionalWithOneDefaultOnStatic();
}

/*member: positionalWithoutDefaultOnLocal:[null|powerset=1]*/
positionalWithoutDefaultOnLocal() {
  /*[null|powerset=1]*/
  local([/*[null|powerset=1]*/ parameter]) => parameter;
  return local();
}

/*member: positionalWithNullDefaultOnLocal:[null|powerset=1]*/
positionalWithNullDefaultOnLocal() {
  /*[null|powerset=1]*/
  local([/*[null|powerset=1]*/ parameter = null]) => parameter;
  return local();
}

/*member: positionalWithOneDefaultOnLocal:[exact=JSUInt31|powerset=0]*/
positionalWithOneDefaultOnLocal() {
  /*[exact=JSUInt31|powerset=0]*/
  local([/*[exact=JSUInt31|powerset=0]*/ parameter = 1]) => parameter;
  return local();
}

/*member: positionalWithoutDefaultOnStatic:[null|powerset=1]*/
positionalWithoutDefaultOnStatic([/*[null|powerset=1]*/ parameter]) {
  return parameter;
}

/*member: positionalWithNullDefaultOnStatic:[null|powerset=1]*/
positionalWithNullDefaultOnStatic([/*[null|powerset=1]*/ parameter = null]) {
  return parameter;
}

/*member: positionalWithOneDefaultOnStatic:[exact=JSUInt31|powerset=0]*/
positionalWithOneDefaultOnStatic([
  /*[exact=JSUInt31|powerset=0]*/ parameter = 1,
]) {
  return parameter;
}
