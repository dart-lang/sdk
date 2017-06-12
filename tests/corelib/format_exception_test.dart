// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library format_exception_test;

import "package:expect/expect.dart";

test(exn, message, source, offset, toString) {
  Expect.equals(message, exn.message);
  Expect.equals(source, exn.source);
  Expect.equals(offset, exn.offset);
  Expect.equals(toString, exn.toString());
}

main() {
  var e;
  e = new FormatException();
  test(e, "", null, null, "FormatException");
  e = new FormatException("");
  test(e, "", null, null, "FormatException");
  e = new FormatException(null);
  test(e, null, null, null, "FormatException");

  e = new FormatException("message");
  test(e, "message", null, null, "FormatException: message");

  e = new FormatException("message", "source");
  test(e, "message", "source", null, "FormatException: message\nsource");

  e = new FormatException("message", "source" * 25);
  test(e, "message", "source" * 25, null,
      "FormatException: message\n" + "source" * 12 + "sou...");
  e = new FormatException("message", "source" * 25);
  test(e, "message", "source" * 25, null,
      "FormatException: message\n" + "source" * 12 + "sou...");
  e = new FormatException("message", "s1\nsource\ns2");
  test(e, "message", "s1\nsource\ns2", null,
      "FormatException: message\n" + "s1\nsource\ns2");

  var o = new Object();
  e = new FormatException("message", o, 10);
  test(e, "message", o, 10, "FormatException: message (at offset 10)");

  e = new FormatException("message", "source", 3);
  test(e, "message", "source", 3,
      "FormatException: message (at character 4)\nsource\n   ^\n");

  e = new FormatException("message", "s1\nsource\ns2", 6);
  test(e, "message", "s1\nsource\ns2", 6,
      "FormatException: message (at line 2, character 4)\nsource\n   ^\n");

  var longline = "watermelon cantaloupe " * 8 + "watermelon"; // Length > 160.
  var longsource = (longline + "\n") * 25;
  var line10 = (longline.length + 1) * 9;
  e = new FormatException("message", longsource, line10);
  test(
      e,
      "message",
      longsource,
      line10,
      "FormatException: message (at line 10, character 1)\n"
      "${longline.substring(0, 75)}...\n^\n");

  e = new FormatException("message", longsource, line10 - 1);
  test(
      e,
      "message",
      longsource,
      line10 - 1,
      "FormatException: message (at line 9, "
      "character ${longline.length + 1})\n"
      "...${longline.substring(longline.length - 75)}\n"
      "${' ' * 78}^\n");

  var half = longline.length ~/ 2;
  e = new FormatException("message", longsource, line10 + half);
  test(
      e,
      "message",
      longsource,
      line10 + half,
      "FormatException: message (at line 10, character ${half + 1})\n"
      "...${longline.substring(half - 36, half + 36)}...\n"
      "${' ' * 39}^\n");

  var sourceNL = "\nsource with leading NL";
  e = new FormatException("message", sourceNL, 2);
  test(
      e,
      "message",
      sourceNL,
      2,
      "FormatException: message (at line 2, character 2)\n"
      "source with leading NL\n"
      " ^\n");

  var sourceNL2 = "\n\nsource with leading NL";
  e = new FormatException("message", sourceNL2, 2);
  test(
      e,
      "message",
      sourceNL2,
      2,
      "FormatException: message (at line 3, character 1)\n"
      "source with leading NL\n"
      "^\n");
}
