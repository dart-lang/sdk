// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Parser throws an error when parsing x is! T with malformed type T.

f(obj) {
  // 'Baz' is not loaded error.
  return (obj is !Baz);  /// 01: runtime error
}

main () {
  f(null);  
}
