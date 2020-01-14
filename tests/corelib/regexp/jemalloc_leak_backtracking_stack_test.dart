// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/29007

String escape(String string) {
  var regex = new RegExp("(\\?|\\\$|\\*|\\(|\\)|\\[)|\\+|\\.|\\\\");
  return string.replaceAllMapped(
      regex, (Match m) => "\\" + string.substring(m.start, m.end));
}

main() {
  var text = """
Yet but three? Come one more.
Two of both kinds make up four.
""";
  var accumulate = 0;
  for (var i = 0; i < 65536; i++) {
    accumulate += escape(text).length;
  }

  print(accumulate);
}
