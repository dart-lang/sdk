// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef ListList<T> = List<List<T>>;

T top<T>(T value) => value;

class C {
  static T stat<T>(T value) => value;
  T inst<T>(T value) => value;
  void method() {
    var f1 = stat<int>;
    var f1TypeName = stat<int>.runtimeType.toString();
    var f2 = inst<int>;
    var f2TypeName = inst<int>.runtimeType.toString();
    var f3 = this.inst<int>;
    var f3TypeName = this.inst<int>.runtimeType.toString();
  }
}

mixin M on C {
  static T mstat<T>(T value) => value;
  T minst<T>(T value) => value;
  void mmethod() {
    var f1 = mstat<int>;
    var f1TypeName = mstat<int>.runtimeType.toString();
    var f2 = minst<int>;
    var f2TypeName = minst<int>.runtimeType.toString();
    var f3 = this.minst<int>;
    var f3TypeName = this.minst<int>.runtimeType.toString();
  }
}

extension Ext on C {
  static T estat<T>(T value) => value;
  T einst<T>(T value) => value;
  void emethod() {
    var f1 = estat<int>; // works like (int $) => Ext.estat<int>($)
    var f1TypeName = estat<int>.runtimeType.toString();
    var f2 = einst<int>; // works like (int $) => Ext(this).einst<int>($)
    var f2TypeName = einst<int>.runtimeType.toString();
    var f3 = this.einst<int>; // works like (int $) => Ext(this).einst<int>($)
    var f3TypeName = this.einst<int>.runtimeType.toString();
  }
}
class D extends C with M {
  void method() {
    var f4 = super.inst<int>; // works like (int $) => super.inst<int>($)
    var f4TypeName = super.inst<int>.runtimeType.toString();
  }
}
void main() {
  // Type literals.
  var t1 = List<int>; // Type object for `List<int>`.
  var t2 = ListList<int>; // Type object for `List<List<int>>`.

  // Instantiated function tear-offs.
  T local<T>(T value) => value;

  const f1 = top<int>; // int Function(int), works like (int $) => top<int>($);
  const f2 = C.stat<int>; // int Function(int), works like (int $) => C.stat<int>($);
  var f3 = local<int>; // int Function(int), works like (int $) => local<int>($);
  var d = D();
  var f4 = d.inst<int>; // int Function(int), works like (int $) => c.inst<int>($);
  var f5 = d.minst<int>; // int Function(int), works like (int $) => c.minst<int>($);
  var f6 = d.einst<int>; // int Function(int), works like (int $) => Ext(c).einst<int>($);

  var typeName = (List<int>).toString();
  var functionTypeName = local<int>.runtimeType.toString();
}