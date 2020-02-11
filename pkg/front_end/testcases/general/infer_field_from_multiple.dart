// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {
  var field1 = 0;
  var field2 = 0;
  var field3 = 0;
  var field4 = 0;
  int field5;
  int field6;
  int field7;
  int field8;
  var field9;
  T field10;
  T field11;
  T field12;
  T field13;
  T field14;
  var field15 = 0;
  int field16;
  var field17 = 0;
  int field18;
}

class B<T, S> {
  var field1 = 1;
  var field2 = '';
  var field3 = 1;
  var field4 = '';
  int field5;
  String field6;
  int field7;
  String field8;
  var field9;
  T field10;
  S field11;
  T field12;
  T field13;
  S field14;
  int field15;
  var field16 = 0;
  String field17;
  var field18 = '';
}

class C implements A<int>, B<int, String> {
  var field1;
  var field2; // error
  var field3 = 0;
  var field4 = 0; // error
  var field5;
  var field6; // error
  var field7 = 0;
  var field8 = 0; // error
  var field9;
  var field10;
  var field11; // error
  int field12;
  var field13 = 0;
  int field14; // error
  var field15;
  var field16;
  var field17; // error
  var field18; // error

  C(
      this.field1,
      this.field2,
      this.field3,
      this.field4,
      this.field5,
      this.field6,
      this.field7,
      this.field8,
      this.field9,
      this.field10,
      this.field11,
      this.field12,
      this.field13,
      this.field14,
      this.field15,
      this.field16,
      this.field17,
      this.field18);
}

class D<T> implements A<T>, B<T, T> {
  var field1;
  var field2; // error
  var field3 = 0;
  var field4 = 0; // error
  var field5;
  var field6; // error
  var field7 = 0;
  var field8 = 0; // error
  var field9;
  var field10;
  var field11;
  T field12;
  var field13 = null;
  T field14;
  var field15;
  var field16;
  var field17; // error
  var field18; // error

  D(
      this.field1,
      this.field2,
      this.field3,
      this.field4,
      this.field5,
      this.field6,
      this.field7,
      this.field8,
      this.field9,
      this.field10,
      this.field11,
      this.field12,
      this.field13,
      this.field14,
      this.field15,
      this.field16,
      this.field17,
      this.field18);
}
