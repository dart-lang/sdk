// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class A<T> {
  List<T> x = throw '';
  void set y(List<T> value) {}
}

test() {
  A<int> a_int = new A<int>();
  A<Object> a_object = new A<Object>();
  A<dynamic> a_dynamic = new A<dynamic>();
  var x_int = a_int.x = [0];
  var y_int = a_int.y = [0];
  var x_object = a_object.x = [0];
  var y_object = a_object.y = [0];
  var x_dynamic = a_dynamic.x = [0];
  var y_dynamic = a_dynamic.y = [0];
  var x_int_explicit = a_int.x = <int>[0];
  var y_int_explicit = a_int.y = <int>[0];
  var x_object_explicit = a_object.x = <int>[0];
  var y_object_explicit = a_object.y = <int>[0];
  var x_dynamic_explicit = a_dynamic.x = <int>[0];
  var y_dynamic_explicit = a_dynamic.y = <int>[0];
  List<int> x_int_downward = a_int.x = [0];
  List<int> y_int_downward = a_int.y = [0];
}

main() {}
