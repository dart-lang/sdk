// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  String jsText = r"""'$'
""";
  String htmlStr = '%%DART';
  String htmlOut = htmlStr.replaceAll("%%DART", jsText);
  Expect.equals(jsText, htmlOut);
  htmlOut = htmlStr.replaceFirst("%%DART", jsText);
  Expect.equals(jsText, htmlOut);
  htmlOut = htmlStr.replaceAll(new RegExp("%%DART"), jsText);
  Expect.equals(jsText, htmlOut);
  htmlOut = htmlStr.replaceFirst(new RegExp("%%DART"), jsText);
  Expect.equals(jsText, htmlOut);

  // Regression test, http://dartbug.com/17886
  String doubleDollar = r"$'$`";
  var string = r"flip-flip-flop";
  var result = string.replaceFirst("flip", doubleDollar);
  Expect.equals(r"$'$`-flip-flop", result);
  result = string.replaceAll("flip", doubleDollar);
  Expect.equals(r"$'$`-$'$`-flop", result);
}
