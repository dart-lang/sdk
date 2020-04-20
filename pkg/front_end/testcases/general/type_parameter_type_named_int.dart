// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Foo<T> {
  List<T> get list;
  void setList<T>(List<T> value);
}

class Bar implements Foo<int> {
  List<int> list;
  void setList<int>(List<int> value) {
    list = value;
  }
}
