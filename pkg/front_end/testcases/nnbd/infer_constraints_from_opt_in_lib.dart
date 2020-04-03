// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T> {}

C field1 = new C();
C? field2;
C<int> field3 = new C<int>();
C<int>? field4;
C<int?> field5;
C<int?>? field6;
int field7;
int? field8;

method() {
  var local0 = [];
  var local1a = [field1];
  var local1b = [field2];
  var local1c = [field3];
  var local1d = [field4];
  var local1e = [field5];
  var local1f = [field6];
  var local1g = [field7];
  var local1h = [field8];
  var local1i = [null];
  var local2a = {field1, null};
  var local2b = {field2, null};
  var local2c = {field3, null};
  var local2d = {field4, null};
  var local2e = {field5, null};
  var local2f = {field6, null};
  var local2g = {field7, null};
  var local2h = {field8, null};
  var local3a = {null, field1};
  var local3b = {null, field2};
  var local3c = {null, field3};
  var local3d = {null, field4};
  var local3e = {null, field5};
  var local3f = {null, field6};
  var local3g = {null, field7};
  var local3h = {null, field8};
}

abstract class B {
  X bar<X extends List<int?>?>();
  foo(List<int> list);
}
