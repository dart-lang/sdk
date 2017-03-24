// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Almost valid string interpolation syntax.

main() {
  var x;

  x = "$"; //   //# 1: compile-time error
  x = "x$"; //  //# 2: compile-time error
  x = "$x$"; // //# 3: compile-time error
  x = "$$x"; // //# 4: compile-time error
  x = "$ "; //  //# 5: compile-time error

  x = '$'; //   //# 6: compile-time error
  x = 'x$'; //  //# 7: compile-time error
  x = '$x$'; // //# 8: compile-time error
  x = '$$x'; // //# 9: compile-time error
  x = '$ '; //  //# 10: compile-time error

  x = """$"""; //   //# 11: compile-time error
  x = """x$"""; //  //# 12: compile-time error
  x = """$x$"""; // //# 13: compile-time error
  x = """$$x"""; // //# 14: compile-time error
  x = """$ """; //  //# 15: compile-time error

  x = '''$'''; //   //# 16: compile-time error
  x = '''x$'''; //  //# 17: compile-time error
  x = '''$x$'''; // //# 18: compile-time error
  x = '''$$x'''; // //# 19: compile-time error
  x = '''$ '''; //  //# 20: compile-time error

  return x;
}
