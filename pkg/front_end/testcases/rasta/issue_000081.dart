// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class Base {
  int hashCode = 42;
}

class Sub extends Base {
  int _hashCode = null;

  get hashCode => _hashCode ??= super.hashCode;

  foo() {
    _hashCode ??= super.hashCode;
  }
}

main() {
  print(new Sub().hashCode);
  var l = [null];
  l[0] ??= "fisk";
}
