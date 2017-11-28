// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

library library11.dart;

class Library11 {
  Library11(this.fld);
  Library11.namedConstructor(this.fld);
  func() {
    return 3;
  }

  var fld;
  static static_func() {
    return 2;
  }

  static var static_fld = 1;
}

class Library111<T> {
  Library111.namedConstructor(T this.fld);
  T fld;
}

const int top_level11 = 100;
top_level_func11() {
  return 200;
}
