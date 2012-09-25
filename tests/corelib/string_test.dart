// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(ngeoffray): test String methods with null arguments.
class StringTest {

  static testMain() {
    testOutOfRange();
    testIllegalArgument();
    testConcat();
    testIndex();
    testCharCodeAt();
    testEquals();
    testEndsWith();
    testStartsWith();
    testIndexOf();
    testLastIndexOf();
    testContains();
    testReplaceAll();
    testCompareTo();
    testToList();
    testCharCodes();
  }

  static void testOutOfRange() {
    String a = "Hello";
    bool exception_caught = false;
    try {
      var c = a[20];  // Throw exception.
    } on IndexOutOfRangeException catch (e) {
      exception_caught = true;
    }
    Expect.equals(true, exception_caught);
  }

  static testIllegalArgument() {
    String a = "Hello";
    bool exception_caught = false;
    try {
      var c = a[2.2];  // Throw exception.
      Expect.equals(true, false);
    } on ArgumentError catch (e) {
      exception_caught = true;
    } on TypeError catch (e) {  // Thrown in checked mode only.
      exception_caught = true;
    }
    Expect.equals(true, exception_caught);
  }

  static testIndex() {
    String str = "string";
    for (int i = 0; i < str.length; i++) {
      Expect.equals(true, str[i] is String);
      Expect.equals(1, str[i].length);
    }
  }

  static testCharCodeAt() {
    String str = "string";
    for (int i = 0; i < str.length; i++) {
      Expect.equals(true, str.charCodeAt(i) is int);
    }
  }

  static testConcat() {
    var a = "One";
    var b = "Four";
    var c = a.concat(b);
    Expect.equals(7, c.length);
    Expect.equals("OneFour", c);
  }

  static testEquals() {
    Expect.equals("str", "str");

    Expect.equals("str", "s".concat("t").concat("r"));
    Expect.equals("s".concat("t").concat("r"), "str");

    Expect.equals(false, "str" == "s");
    Expect.equals(false, "str" == "r");
    Expect.equals(false, "str" == "st");
    Expect.equals(false, "str" == "tr");

    Expect.equals(false, "s" == "str");
    Expect.equals(false, "r" == "str");
    Expect.equals(false, "st" == "str");
    Expect.equals(false, "tr" == "str");

    Expect.equals(false, "" == "s");
    Expect.equals("", "");
  }

  static testEndsWith() {
    Expect.equals(true, "str".endsWith("r"));
    Expect.equals(true, "str".endsWith("tr"));
    Expect.equals(true, "str".endsWith("str"));

    Expect.equals(false, "str".endsWith("stri"));
    Expect.equals(false, "str".endsWith("t"));
    Expect.equals(false, "str".endsWith("st"));
    Expect.equals(false, "str".endsWith("s"));

    Expect.equals(true, "".endsWith(""));
    Expect.equals(false, "".endsWith("s"));
  }

  static testStartsWith() {
    Expect.equals(true, "str".startsWith("s"));
    Expect.equals(true, "str".startsWith("st"));
    Expect.equals(true, "str".startsWith("str"));

    Expect.equals(false, "str".startsWith("stri"));
    Expect.equals(false, "str".startsWith("r"));
    Expect.equals(false, "str".startsWith("tr"));
    Expect.equals(false, "str".startsWith("t"));

    Expect.equals(true, "".startsWith(""));
    Expect.equals(false, "".startsWith("s"));
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
      int result = str.indexOf("", i);
      if (i > str.length) {
        Expect.equals(str.length, result);
      } else {
        Expect.equals(i, result);
      }
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
    Expect.equals(-1, "str".lastIndexOf("string", 5));

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

    String str = "hello";
    for (int i = 0; i < 10; i++) {
      int result = str.lastIndexOf("", i);
      if (i > str.length) {
        Expect.equals(str.length, result);
      } else {
        Expect.equals(i, result);
      }
    }
  }

  static testContains() {
    Expect.equals(true, "str".contains("s", 0));
    Expect.equals(true, "str".contains("st", 0));
    Expect.equals(true, "str".contains("str", 0));
    Expect.equals(true, "str".contains("t", 0));
    Expect.equals(true, "str".contains("r", 0));
    Expect.equals(true, "str".contains("tr", 0));

    Expect.equals(false, "str".contains("sr", 0));
    Expect.equals(false, "str".contains("string", 0));

    Expect.equals(true, "str".contains("", 0));
    Expect.equals(true, "".contains("", 0));
    Expect.equals(false, "".contains("s", 0));
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

  static testToList() {
    test(str) {
      var list = str.splitChars();
      Expect.equals(str.length, list.length);
      for (int i = 0; i < str.length; i++) {
        Expect.equals(str[i], list[i]);
      }
    }
    test("abc");
    test("");
    test(" ");
  }

  static testCharCodes() {
    test(str) {
      var list = str.charCodes();
      Expect.equals(str.length, list.length);
      for (int i = 0; i < str.length; i++) {
        Expect.equals(str.charCodeAt(i), list[i]);
      }
    }
    test("abc");
    test("");
    test(" ");
  }
}

main() {
  StringTest.testMain();
}
