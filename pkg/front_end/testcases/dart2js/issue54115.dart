// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  final int? _x;
  C(this._x);

  @pragma("dart2js:never-inline")
  void manual() {
    var x = _x;
    if (x != null)
      print(x);
    else
      print("null");
  }

  @pragma("dart2js:never-inline")
  void pattern() {
    if (_x case var x?)
      print(x);
    else
      print("null");
  }

  @pragma("dart2js:never-inline")
  void promote() {
    if (_x != null)
      print(_x);
    else
      print("null");
  }
}
