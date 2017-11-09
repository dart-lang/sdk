// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  positionalWithoutDefaultOnLocal();
  positionalWithNullDefaultOnLocal();
  positionalWithOneDefaultOnLocal();
  positionalWithoutDefaultOnStatic();
  positionalWithNullDefaultOnStatic();
  positionalWithOneDefaultOnStatic();
}

/*element: positionalWithoutDefaultOnLocal:[null]*/
positionalWithoutDefaultOnLocal() {
  /*[null]*/ local([/*[null]*/ parameter]) => parameter;
  return local();
}

/*element: positionalWithNullDefaultOnLocal:[null]*/
positionalWithNullDefaultOnLocal() {
  /*[null]*/ local([/*[null]*/ parameter = null]) => parameter;
  return local();
}

/*element: positionalWithOneDefaultOnLocal:[exact=JSUInt31]*/
positionalWithOneDefaultOnLocal() {
  /*[exact=JSUInt31]*/ local([/*[exact=JSUInt31]*/ parameter = 1]) => parameter;
  return local();
}

/*element: positionalWithoutDefaultOnStatic:[null]*/
positionalWithoutDefaultOnStatic([/*[null]*/ parameter]) {
  return parameter;
}

/*element: positionalWithNullDefaultOnStatic:[null]*/
positionalWithNullDefaultOnStatic([/*[null]*/ parameter = null]) {
  return parameter;
}

/*element: positionalWithOneDefaultOnStatic:[exact=JSUInt31]*/
positionalWithOneDefaultOnStatic([/*[exact=JSUInt31]*/ parameter = 1]) {
  return parameter;
}
