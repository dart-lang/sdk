// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class MyClass<T> {
  MyClass(x) { }
  T operator [](int index) {
  }
  void operator []=(int index, int val) {
  }
}

class Main {
  static void main() {
    // base case (should be inlined).
    List<int> _list0_ = new List<int>(10);
    _list0_[0] = 1;
    int lhs0 = _list0_[0];
    
    // final case - only 'reads' can be inlined.
    final List<int> _list1_ = new List<int>(10);
    _list1_[0] = 1;
    int lhs1 = _list1_[0];

    // operator [] - cannot inline reads or writes.
    MyClass<String> _list2_ = new MyClass<String>(2);
    _list2_[0] = "foo";
    String lhs2 = _list2_[0];

    // untyped.
    var _list3_ = new List<String>(2);
    _list3_[0] = "foo";
    String lhs3 = _list3_[0];

    // untyped.
    List<String> _list4_ = new List<String>(2);
    int i_0 = 0;
    int j_0 = 0;
    _list4_[i_0 + j_0] = "foo";
    String lhs4 = _list4_[i_0 - j_0];

    // nested list (should be inlined).
    List<List<List<int>>> _list5_ = new List<List<List<int>>>(10);
    _list5_[0] = null;
    var lhs5 = _list5_[0];
    _list5_[0][1] = null;
    lhs5 = _list5_[0][1];
    _list5_[0][1][2] = 1;
    lhs5 = _list5_[0][1][2];
  }
}
