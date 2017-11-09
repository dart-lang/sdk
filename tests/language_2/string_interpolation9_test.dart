// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Almost valid string interpolation syntax.

main() {
  var x;

  x = "$"; //   //# 1: syntax error
  x = "x$"; //  //# 2: syntax error
  x = "$x$"; // //# 3: syntax error
  x = "$$x"; // //# 4: syntax error
  x = "$ "; //  //# 5: syntax error

  x = '$'; //   //# 6: syntax error
  x = 'x$'; //  //# 7: syntax error
  x = '$x$'; // //# 8: syntax error
  x = '$$x'; // //# 9: syntax error
  x = '$ '; //  //# 10: syntax error

  x = """$"""; //   //# 11: syntax error
  x = """x$"""; //  //# 12: syntax error
  x = """$x$"""; // //# 13: syntax error
  x = """$$x"""; // //# 14: syntax error
  x = """$ """; //  //# 15: syntax error

  x = '''$'''; //   //# 16: syntax error
  x = '''x$'''; //  //# 17: syntax error
  x = '''$x$'''; // //# 18: syntax error
  x = '''$$x'''; // //# 19: syntax error
  x = '''$ '''; //  //# 20: syntax error

  return x;
}
