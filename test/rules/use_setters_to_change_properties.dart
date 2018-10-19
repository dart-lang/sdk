// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N use_setters_to_change_properties`

abstract class A {
  int _w;
  int _x;

  void setW(int w) => this._w = w; // LINT

  void setX(int x) { // LINT
    this._x = x;
  }

  void setY(int y);
}

class B extends A {
  int _y;

  void setY(int y) { // OK because it is an inherited method.
    this._y = y;
  }
}
