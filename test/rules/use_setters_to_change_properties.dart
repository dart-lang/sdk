// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N use_setters_to_change_properties`

abstract class A {
  int _w;
  int _x;

  void setW(int w) => _w = w; // LINT

  void setW1(int w) => this._w = w; // LINT

  void setX(int x) { // LINT
    _x = x;
  }

  void setX1(int x) { // LINT
    this._x = x;
  }

  void setY(int y);

  void grow1(int value) => _w += value; //OK
}

class B extends A {
  int _y;

  void setY(int y) { // OK because it is an inherited method.
    this._y = y;
  }
}

abstract class C {
  void setY(int y);
}

class D implements C {
  int _y;
  int dd;

  void setY(int y) { // OK because it is an implementation method.
    this._y = y;
  }
}

extension E on D {
  void setDD(int dd) { // LINT
    this.dd = dd;
  }
}
