// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

closure0() {
  var fs = [];
  for (var x = 1; x <= 3; x++) {
    fs.add(() { return x; });
  }
  Expect.equals(3, fs.length);
  Expect.equals(1, fs[0]());
  Expect.equals(2, fs[1]());
  Expect.equals(3, fs[2]());
}

closure1() {
  var fs = [];
  for (var x = 0; x < 6; x++) {
    fs.add(() { return x; });
    x++;
  }
  Expect.equals(3, fs.length);
  Expect.equals(1, fs[0]());
  Expect.equals(3, fs[1]());
  Expect.equals(5, fs[2]());
}

closure2() {
  var input = [1, 2, 3];
  var fs = [];
  for (var i = 0; i < input.length; i++) {
    fs.add(() { return input[i]; });
  }
  Expect.equals(3, fs.length);
  Expect.equals(1, fs[0]());
  Expect.equals(2, fs[1]());
  Expect.equals(3, fs[2]());
}

closure3() {
  var fs = [];
  for (var i = 0;
       i < 3;
       (() {
         fs.add(() => i);
         i++;
       })()) {
    i++;
  }
  Expect.equals(2, fs.length);
  Expect.equals(3, fs[0]());
  Expect.equals(4, fs[1]());
}

closure4() {
  var g;
  for (var i = 0;
       (() {
         g = () => i;
         return false;
       })();
       i++){
    Expect.equals(false, true);
  }
  Expect.equals(0, g());
}

main() {
  closure0();
  closure1();
  closure2();
  closure3();
  closure4();
}
