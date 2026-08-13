// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Almost valid string interpolation syntax.

main() {
  var x;

  x = "$";
  //    ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).
  x = "x$";
  //     ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).
  x = "$x$";
  //      ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).
  x = "$$x";
  //    ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).
  x = "$ ";
  //    ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).

  x = '$';
  //    ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).
  x = 'x$';
  //     ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).
  x = '$x$';
  //      ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).
  x = '$$x';
  //    ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).
  x = '$ ';
  //    ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).

  x = """$""";
  //      ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).
  x = """x$""";
  //       ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).
  x = """$x$""";
  //        ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).
  x = """$$x""";
  //      ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).
  x = """$ """;
  //      ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).

  x = '''$''';
  //      ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).
  x = '''x$''';
  //       ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).
  x = '''$x$''';
  //        ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).
  x = '''$$x''';
  //      ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).
  x = '''$ ''';
  //      ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).

  return x;
}
