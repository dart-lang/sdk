// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:compiler/src/platform_configuration.dart";
import "package:expect/expect.dart";

/// Runs the parser on [input] and compares it with [expectedResult]
///
/// A '*' in [input] indicates that the parser will report an error at the
/// given point (On [input] with the "*" removed).
test(String input, [Map<String, Map<String, String>> expectedOutput]) {
  int starIndex = input.indexOf("*");
  String inputWithoutStar = input.replaceFirst("*", "");

  parse() => parseIni(inputWithoutStar.codeUnits,
      allowedSections: new Set.from(["AA", "BB"]));

  if (starIndex != -1) {
    Expect.equals(expectedOutput, null);
    Expect.throws(parse, (e) {
      Expect.isTrue(e is FormatException);
      Expect.equals(starIndex, e.offset);
      return e is FormatException;
    });
  } else {
    Map<String, Map<String, String>> result = parse();
    Expect.equals(expectedOutput.length, result.length);
    expectedOutput.forEach((String name, Map<String, String> properties) {
      Expect.isTrue(expectedOutput.containsKey(name), "Missing section $name");
      Expect.mapEquals(expectedOutput[name], properties);
    });
  }
}

main() {
  // Empty file.
  test("""
# Nothing here
""", {});

  // Text outside section.
  test("""
*aaa
""");

  // Malformed header.
  test("""
*[AABC
name:value
""");

  // Text after header.
  test("""
[AABC]*abcde
""");

  // Empty section name.
  test("""
[*]
""");

  // Duplicate section name.
  test("""
[AA]
[BB]
[*AA]
""");

  // Unrecognized section name.
  test("""
[*CC]
""");

  // Empty property name.
  test("""
[AA]
*:value
name:value
""");

  // Ok.
  test("""
[AA]
name:value
[BB]
name:value
name2:value2
""", {
    "AA": {"name": "value"},
    "BB": {"name": "value", "name2": "value2"}
  });

  // Ok, file not ending in newline.
  test("""
[AA]
name:value""", {
    "A": {"name": "value"}
  });

  // Ok, whitespace is trimmed away.
  test("""
[ AA ]
 name\t:  value """, {
    "A": {"name": "value"}
  });

  // Duplicate property name.
  test("""
[AA]
a:b
b:c
*a:c
""");

  // No ':' on property line.
  test("""
[AA]
*name1
name2:value
""");
}
