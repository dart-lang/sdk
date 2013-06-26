// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// TODO(ngeoffray): test String methods with null arguments.
class StringTest {

  static testMain() {
    testOutOfRange();
    testIllegalArgument();
    testConcat();
    testIndex();
    testCodeUnitAt();
    testEquals();
    testEndsWith();
    testStartsWith();
    testIndexOf();
    testLastIndexOf();
    testContains();
    testReplaceAll();
    testCompareTo();
    testCharCodes();
  }

  static void testLength() {
    String str = "";
    for (var i = 0; i < 20; i++) {
      testStringLength(i, str);
      str += " ";
    }
  }

  static void testOutOfRange() {
    String a = "Hello";
    bool exception_caught = false;
    try {
      var c = a[20];  // Throw exception.
    } on RangeError catch (e) {
      exception_caught = true;
    }
    Expect.isTrue(exception_caught);
  }

  static testIllegalArgument() {
    String a = "Hello";
    bool exception_caught = false;
    try {
      var c = a[2.2];  // Throw exception.
      Expect.fail("Accepting double as index");
    } on ArgumentError catch (e) {
      exception_caught = true;
    } on TypeError catch (e) {  // Thrown in checked mode only.
      exception_caught = true;
    }
    Expect.isTrue(exception_caught);
  }

  static testIndex() {
    String str = "string";
    for (int i = 0; i < str.length; i++) {
      Expect.isTrue(str[i] is String);
      testStringLength(1, str[i]);
    }
  }

  static testCodeUnitAt() {
    String str = "string";
    for (int i = 0; i < str.length; i++) {
      Expect.isTrue(str.codeUnitAt(i) is int);
    }
  }

  static testConcat() {
    var a = "One";
    var b = "Four";
    var c = a + b;
    testStringLength(7, c);
    Expect.equals("OneFour", c);
  }

  static testEquals() {
    Expect.equals("str", "str");

    Expect.equals("str", "s" + "t" + "r");
    Expect.equals("s" + "t" + "r", "str");

    Expect.isFalse("str" == "s");
    Expect.isFalse("str" == "r");
    Expect.isFalse("str" == "st");
    Expect.isFalse("str" == "tr");

    Expect.isFalse("s" == "str");
    Expect.isFalse("r" == "str");
    Expect.isFalse("st" == "str");
    Expect.isFalse("tr" == "str");

    Expect.isFalse("" == "s");
    Expect.equals("", "");
  }

  static testEndsWith() {
    Expect.isTrue("str".endsWith("r"));
    Expect.isTrue("str".endsWith("tr"));
    Expect.isTrue("str".endsWith("str"));

    Expect.isFalse("str".endsWith("stri"));
    Expect.isFalse("str".endsWith("t"));
    Expect.isFalse("str".endsWith("st"));
    Expect.isFalse("str".endsWith("s"));

    Expect.isTrue("".endsWith(""));
    Expect.isFalse("".endsWith("s"));
  }

  static testStartsWith() {
    Expect.isTrue("str".startsWith("s"));
    Expect.isTrue("str".startsWith("st"));
    Expect.isTrue("str".startsWith("str"));

    Expect.isFalse("str".startsWith("stri"));
    Expect.isFalse("str".startsWith("r"));
    Expect.isFalse("str".startsWith("tr"));
    Expect.isFalse("str".startsWith("t"));

    Expect.isTrue("".startsWith(""));
    Expect.isFalse("".startsWith("s"));

    Expect.isFalse("strstr".startsWith("s", 1));
    Expect.isFalse("strstr".startsWith("s", 2));
    Expect.isTrue("strstr".startsWith("s", 3));
    Expect.isFalse("strstr".startsWith("s", 4));

    Expect.isFalse("strstr".startsWith("st", 1));
    Expect.isFalse("strstr".startsWith("st", 2));
    Expect.isTrue("strstr".startsWith("st", 3));
    Expect.isFalse("strstr".startsWith("st", 4));

    Expect.isFalse("strstr".startsWith("str", 1));
    Expect.isFalse("strstr".startsWith("str", 2));
    Expect.isTrue("strstr".startsWith("str", 3));
    Expect.isFalse("strstr".startsWith("str", 4));

    Expect.isTrue("str".startsWith("", 0));
    Expect.isTrue("str".startsWith("", 1));
    Expect.isTrue("str".startsWith("", 2));
    Expect.isTrue("str".startsWith("", 3));

    Expect.throws(() => "str".startsWith("", -1));
    Expect.throws(() => "str".startsWith("", 4));

    var regexp = new RegExp("s(?:tr?)?");
    Expect.isTrue("s".startsWith(regexp));
    Expect.isTrue("st".startsWith(regexp));
    Expect.isTrue("str".startsWith(regexp));
    Expect.isTrue("sX".startsWith(regexp));
    Expect.isTrue("stX".startsWith(regexp));
    Expect.isTrue("strX".startsWith(regexp));

    Expect.isFalse("".startsWith(regexp));
    Expect.isFalse("astr".startsWith(regexp));

    Expect.isTrue("".startsWith(new RegExp("")));
    Expect.isTrue("".startsWith(new RegExp("a?")));

    Expect.isFalse("strstr".startsWith(regexp, 1));
    Expect.isFalse("strstr".startsWith(regexp, 2));
    Expect.isTrue("strstr".startsWith(regexp, 3));
    Expect.isFalse("strstr".startsWith(regexp, 4));

    Expect.isTrue("str".startsWith(new RegExp(""), 0));
    Expect.isTrue("str".startsWith(new RegExp(""), 1));
    Expect.isTrue("str".startsWith(new RegExp(""), 2));
    Expect.isTrue("str".startsWith(new RegExp(""), 3));
    Expect.isTrue("str".startsWith(new RegExp("a?"), 0));
    Expect.isTrue("str".startsWith(new RegExp("a?"), 1));
    Expect.isTrue("str".startsWith(new RegExp("a?"), 2));
    Expect.isTrue("str".startsWith(new RegExp("a?"), 3));

    Expect.throws(() => "str".startsWith(regexp, -1));
    Expect.throws(() => "str".startsWith(regexp, 4));

    regexp = new RegExp("^str");
    Expect.isTrue("strstr".startsWith(regexp));
    Expect.isTrue("strstr".startsWith(regexp, 0));
    Expect.isFalse("strstr".startsWith(regexp, 1));
    Expect.isFalse("strstr".startsWith(regexp, 2));
    Expect.isFalse("strstr".startsWith(regexp, 3));  // Second "str" isn't at ^.
  }

  static testIndexOf() {
    Expect.equals(0, "str".indexOf("", 0));
    Expect.equals(0, "".indexOf("", 0));
    Expect.equals(-1, "".indexOf("a", 0));

    Expect.equals(1, "str".indexOf("t", 0));
    Expect.equals(1, "str".indexOf("tr", 0));
    Expect.equals(0, "str".indexOf("str", 0));
    Expect.equals(0, "str".indexOf("st", 0));
    Expect.equals(0, "str".indexOf("s", 0));
    Expect.equals(2, "str".indexOf("r", 0));
    Expect.equals(-1, "str".indexOf("string", 0));

    Expect.equals(1, "strstr".indexOf("t", 0));
    Expect.equals(1, "strstr".indexOf("tr", 0));
    Expect.equals(0, "strstr".indexOf("str", 0));
    Expect.equals(0, "strstr".indexOf("st", 0));
    Expect.equals(0, "strstr".indexOf("s", 0));
    Expect.equals(2, "strstr".indexOf("r", 0));
    Expect.equals(-1, "str".indexOf("string", 0));

    Expect.equals(4, "strstr".indexOf("t", 2));
    Expect.equals(4, "strstr".indexOf("tr", 2));
    Expect.equals(3, "strstr".indexOf("str", 1));
    Expect.equals(3, "strstr".indexOf("str", 2));
    Expect.equals(3, "strstr".indexOf("str", 3));
    Expect.equals(3, "strstr".indexOf("st", 1));
    Expect.equals(3, "strstr".indexOf("s", 3));
    Expect.equals(5, "strstr".indexOf("r", 3));
    Expect.equals(5, "strstr".indexOf("r", 4));
    Expect.equals(5, "strstr".indexOf("r", 5));

    String str = "hello";
    for (int i = 0; i < 10; i++) {
      if (i > str.length) {
        Expect.throws(() => str.indexOf("", i));
      } else {
        int result = str.indexOf("", i);
        Expect.equals(i, result);
      }
    }

    var re = new RegExp("an?");
    Expect.equals(1, "banana".indexOf(re));
    Expect.equals(1, "banana".indexOf(re, 0));
    Expect.equals(1, "banana".indexOf(re, 1));
    Expect.equals(3, "banana".indexOf(re, 2));
    Expect.equals(3, "banana".indexOf(re, 3));
    Expect.equals(5, "banana".indexOf(re, 4));
    Expect.equals(5, "banana".indexOf(re, 5));
    Expect.equals(-1, "banana".indexOf(re, 6));
    Expect.throws(() => "banana".indexOf(re, -1));
    Expect.throws(() => "banana".indexOf(re, 7));
    re = new RegExp("x?");
    for (int i = 0; i <= str.length; i++) {
      Expect.equals(i, str.indexOf(re, i));
    }
  }

  static testLastIndexOf() {
    Expect.equals(2, "str".lastIndexOf("", 2));
    Expect.equals(0, "".lastIndexOf("", 0));
    Expect.equals(-1, "".lastIndexOf("a", 0));

    Expect.equals(1, "str".lastIndexOf("t", 2));
    Expect.equals(1, "str".lastIndexOf("tr", 2));
    Expect.equals(0, "str".lastIndexOf("str", 2));
    Expect.equals(0, "str".lastIndexOf("st", 2));
    Expect.equals(0, "str".lastIndexOf("s", 2));
    Expect.equals(2, "str".lastIndexOf("r", 2));
    Expect.equals(-1, "str".lastIndexOf("string", 2));

    Expect.equals(4, "strstr".lastIndexOf("t", 5));
    Expect.equals(4, "strstr".lastIndexOf("tr", 5));
    Expect.equals(3, "strstr".lastIndexOf("str", 5));
    Expect.equals(3, "strstr".lastIndexOf("st", 5));
    Expect.equals(3, "strstr".lastIndexOf("s", 5));
    Expect.equals(5, "strstr".lastIndexOf("r", 5));
    Expect.throws(() {
        "str".lastIndexOf("string", 5);
    });
    Expect.equals(4, "strstr".lastIndexOf("t", 5));
    Expect.equals(4, "strstr".lastIndexOf("tr", 5));
    Expect.equals(3, "strstr".lastIndexOf("str", 5));
    Expect.equals(3, "strstr".lastIndexOf("str", 5));
    Expect.equals(3, "strstr".lastIndexOf("str", 5));
    Expect.equals(3, "strstr".lastIndexOf("st", 5));
    Expect.equals(3, "strstr".lastIndexOf("s", 5));
    Expect.equals(5, "strstr".lastIndexOf("r", 5));
    Expect.equals(2, "strstr".lastIndexOf("r", 4));
    Expect.equals(2, "strstr".lastIndexOf("r", 3));
    Expect.equals(5, "strstr".lastIndexOf("r"));
    Expect.equals(5, "strstr".lastIndexOf("r", null));

    String str = "hello";
    for (int i = 0; i < 10; i++) {
      if (i > str.length) {
        Expect.throws(() => str.indexOf("", i));
      } else {
        int result = str.lastIndexOf("", i);
        Expect.equals(i, result);
      }
    }

    var re = new RegExp("an?");
    Expect.equals(5, "banana".lastIndexOf(re));
    Expect.equals(5, "banana".lastIndexOf(re, 6));
    Expect.equals(5, "banana".lastIndexOf(re, 5));
    Expect.equals(3, "banana".lastIndexOf(re, 4));
    Expect.equals(3, "banana".lastIndexOf(re, 3));
    Expect.equals(1, "banana".lastIndexOf(re, 2));
    Expect.equals(1, "banana".lastIndexOf(re, 1));
    Expect.equals(-1, "banana".lastIndexOf(re, 0));
    Expect.throws(() => "banana".lastIndexOf(re, -1));
    Expect.throws(() => "banana".lastIndexOf(re, 7));
    re = new RegExp("x?");
    for (int i = 0; i <= str.length; i++) {
      Expect.equals(i, str.indexOf(re, i));
    }
  }

  static testContains() {
    Expect.isTrue("str".contains("s", 0));
    Expect.isTrue("str".contains("st", 0));
    Expect.isTrue("str".contains("str", 0));
    Expect.isTrue("str".contains("t", 0));
    Expect.isTrue("str".contains("r", 0));
    Expect.isTrue("str".contains("tr", 0));

    Expect.isFalse("str".contains("sr", 0));
    Expect.isFalse("str".contains("string", 0));

    Expect.isTrue("str".contains("", 0));
    Expect.isTrue("".contains("", 0));
    Expect.isFalse("".contains("s", 0));
  }

  static testReplaceAll() {
    Expect.equals(
        "AtoBtoCDtoE", "AfromBfromCDfromE".replaceAll("from", "to"));

    // Test with the replaced string at the begining.
    Expect.equals(
        "toABtoCDtoE", "fromABfromCDfromE".replaceAll("from", "to"));

    // Test with the replaced string at the end.
    Expect.equals(
        "toABtoCDtoEto", "fromABfromCDfromEfrom".replaceAll("from", "to"));

    // Test when there are no occurence of the string to replace.
    Expect.equals("ABC", "ABC".replaceAll("from", "to"));

    // Test when the string to change is the empty string.
    Expect.equals("", "".replaceAll("from", "to"));

    // Test when the string to change is a substring of the string to
    // replace.
    Expect.equals("fro", "fro".replaceAll("from", "to"));

    // Test when the string to change is the replaced string.
    Expect.equals("to", "from".replaceAll("from", "to"));

    // Test when the string to change is the replacement string.
    Expect.equals("to", "to".replaceAll("from", "to"));

    // Test replacing by the empty string.
    Expect.equals("", "from".replaceAll("from", ""));
    Expect.equals("AB", "AfromB".replaceAll("from", ""));

    // Test changing the empty string.
    Expect.equals("to", "".replaceAll("", "to"));

    // Test replacing the empty string.
    Expect.equals("toAtoBtoCto", "ABC".replaceAll("", "to"));
  }

  static testCompareTo() {
    Expect.equals(0, "".compareTo(""));
    Expect.equals(0, "str".compareTo("str"));
    Expect.equals(-1, "str".compareTo("string"));
    Expect.equals(1, "string".compareTo("str"));
    Expect.equals(1, "string".compareTo(""));
    Expect.equals(-1, "".compareTo("string"));
  }

  static testCharCodes() {
    test(str) {
      var list = str.codeUnits;
      Expect.equals(str.length, list.length);
      for (int i = 0; i < str.length; i++) {
        Expect.equals(str.codeUnitAt(i), list[i]);
      }
    }
    test("abc");
    test("");
    test(" ");
  }
}

void testStringLength(int length, String str) {
  Expect.equals(length, str.length);
  (length == 0 ? Expect.isTrue : Expect.isFalse)(str.isEmpty);
  (length != 0 ? Expect.isTrue : Expect.isFalse)(str.isNotEmpty);
}

main() {
  StringTest.testMain();
}
