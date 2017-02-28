// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class C1 {
  var x;
  C1(y) : x = (() => print('Hello $y'));
}

class C2 {
  var x;
  C2(y) {
    x = () => print('Hello $y');
  }
}

main() {
  new C1('hest').x();
  new C2('naebdyr').x();
}
