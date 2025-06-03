// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  positionalWithoutDefaultOnLocal();
  positionalWithNullDefaultOnLocal();
  positionalWithOneDefaultOnLocal();
  positionalWithoutDefaultOnStatic();
  positionalWithNullDefaultOnStatic();
  positionalWithOneDefaultOnStatic();
}

/*member: positionalWithoutDefaultOnLocal:[null|powerset={null}]*/
positionalWithoutDefaultOnLocal() {
  /*[null|powerset={null}]*/
  local([/*[null|powerset={null}]*/ parameter]) => parameter;
  return local();
}

/*member: positionalWithNullDefaultOnLocal:[null|powerset={null}]*/
positionalWithNullDefaultOnLocal() {
  /*[null|powerset={null}]*/
  local([/*[null|powerset={null}]*/ parameter = null]) => parameter;
  return local();
}

/*member: positionalWithOneDefaultOnLocal:[exact=JSUInt31|powerset={I}{O}{N}]*/
positionalWithOneDefaultOnLocal() {
  /*[exact=JSUInt31|powerset={I}{O}{N}]*/
  local([/*[exact=JSUInt31|powerset={I}{O}{N}]*/ parameter = 1]) => parameter;
  return local();
}

/*member: positionalWithoutDefaultOnStatic:[null|powerset={null}]*/
positionalWithoutDefaultOnStatic([/*[null|powerset={null}]*/ parameter]) {
  return parameter;
}

/*member: positionalWithNullDefaultOnStatic:[null|powerset={null}]*/
positionalWithNullDefaultOnStatic([
  /*[null|powerset={null}]*/ parameter = null,
]) {
  return parameter;
}

/*member: positionalWithOneDefaultOnStatic:[exact=JSUInt31|powerset={I}{O}{N}]*/
positionalWithOneDefaultOnStatic([
  /*[exact=JSUInt31|powerset={I}{O}{N}]*/ parameter = 1,
]) {
  return parameter;
}
