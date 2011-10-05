// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Box<T> {
  T t;
  getT() { return t; }
  setT(T t) { this.t = t; }
}

class UseBox {
  Box<Box<Box<prefix.Fisk>>> boxIt(Box<Box<prefix.Fisk>> box) {
    return new Box<Box<Box<prefix.Fisk>>>(box);
  }
}
