// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  static int staticMethod() => 42;
}

class G<T> {}

class Const {
  const Const();
  const Const.otherConstructor();
  static const instance = const Const();
}

const constantInstance = const Const();
