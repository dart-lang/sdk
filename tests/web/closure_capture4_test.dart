// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

closure0() {
  var input = [1, 2, 3];
  var fs = [];
  for (var x in input) {
    fs.add(() {
      return x;
    });
  }
  Expect.equals(3, fs.length);
  Expect.equals(1, fs[0]());
  Expect.equals(2, fs[1]());
  Expect.equals(3, fs[2]());
}

closure1() {
  var input = [1, 2, 3];
  var fs = [];
  for (var x in input) {
    fs.add(() {
      return x;
    });
    x++;
  }
  Expect.equals(3, fs.length);
  Expect.equals(2, fs[0]());
  Expect.equals(3, fs[1]());
  Expect.equals(4, fs[2]());
}

closure2() {
  var input = [1, 2, 3];
  var fs = [];
  for (var i = 0; i < input.length; i++) {
    var j = i;
    fs.add(() {
      return input[j];
    });
  }
  Expect.equals(3, fs.length);
  Expect.equals(1, fs[0]());
  Expect.equals(2, fs[1]());
  Expect.equals(3, fs[2]());
}

closure3() {
  var input = [1, 2, 3];
  var fs = [];
  for (var i = 0; i < input.length; i++) {
    var x = input[i];
    fs.add(() {
      return x;
    });
    x++;
  }
  Expect.equals(3, fs.length);
  Expect.equals(2, fs[0]());
  Expect.equals(3, fs[1]());
  Expect.equals(4, fs[2]());
}

closure4() {
  var input = [1, 2, 3];
  var fs = [];
  var x;
  for (var i = 0; i < input.length; i++) {
    x = input[i];
    fs.add(() {
      return x;
    });
    x++;
  }
  Expect.equals(3, fs.length);
  Expect.equals(4, fs[0]());
  Expect.equals(4, fs[1]());
  Expect.equals(4, fs[2]());
}

closure5() {
  var input = [1, 2, 3];
  var fs = [];
  var i = 0;
  do {
    var x = input[i];
    fs.add(() {
      return x;
    });
  } while (++i < input.length);
  Expect.equals(3, fs.length);
  Expect.equals(1, fs[0]());
  Expect.equals(2, fs[1]());
  Expect.equals(3, fs[2]());
}

closure6() {
  var input = [1, 2, 3];
  var fs = [];
  var i = 0;
  do {
    var x = input[i];
    fs.add(() {
      return x;
    });
    x++;
  } while (++i < input.length);
  Expect.equals(3, fs.length);
  Expect.equals(2, fs[0]());
  Expect.equals(3, fs[1]());
  Expect.equals(4, fs[2]());
}

closure7() {
  var input = [1, 2, 3];
  var fs = [];
  var i = 0;
  while (i < input.length) {
    var x = input[i];
    fs.add(() {
      return x;
    });
    x++;
    i++;
  }
  Expect.equals(3, fs.length);
  Expect.equals(2, fs[0]());
  Expect.equals(3, fs[1]());
  Expect.equals(4, fs[2]());
}

main() {
  closure0();
  closure1();
  closure2();
  closure3();
  closure4();
  closure5();
  closure6();
  closure7();
}
