// Copyright (c) 2014, the Dart project authors. All rights reserved.
// Copyright 2012 the V8 project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import "package:expect/expect.dart";

void testEscape(str, regex) {
  assertEquals("foo:bar:baz", str.split(regex).join(":"));
}

void assertEquals(actual, expected, [message]) =>
    Expect.equals(actual, expected, message);
void assertTrue(actual, [message]) => Expect.isTrue(actual, message);
void assertFalse(actual, [message]) => Expect.isFalse(actual, message);
void assertThrows(fn) => Expect.throws(fn);

void main() {
  testEscape("foo\nbar\nbaz", new RegExp(r"\n"));
  testEscape("foo bar baz", new RegExp(r"\s"));
  testEscape("foo\tbar\tbaz", new RegExp(r"\s"));
  testEscape("foo-bar-baz", new RegExp(r"\u002D"));

  // Test containing null char in regexp.
  var s = '[' + new String.fromCharCode(0) + ']';
  var re = new RegExp(s);
  assertEquals(re.allMatches(s).length, 1);
  assertEquals(re.stringMatch(s), new String.fromCharCode(0));

  final _vmFrame = new RegExp(r'^#\d+\s+(\S.*) \((.+?):(\d+)(?::(\d+))?\)$');
  final _traceLine =
      "#0      Trace.Trace.parse (package:stack_trace/src/trace.dart:130:7)";
  Expect.equals(_vmFrame.firstMatch(_traceLine).group(0), _traceLine);

  // Test the UTF16 case insensitive comparison.
  re = new RegExp(r"x(a)\1x", caseSensitive: false);
  Expect.equals(re.firstMatch("xaAx\u1234").group(0), "xaAx");

  // Test strings containing all line separators
  s = 'aA\nbB\rcC\r\ndD\u2028eE\u2029fF';
  // any non-newline character at the beginning of a line
  re = new RegExp(r"^.", multiLine: true);
  var result = re.allMatches(s).toList();
  assertEquals(result.length, 6);
  assertEquals(result[0][0], 'a');
  assertEquals(result[1][0], 'b');
  assertEquals(result[2][0], 'c');
  assertEquals(result[3][0], 'd');
  assertEquals(result[4][0], 'e');
  assertEquals(result[5][0], 'f');

  // any non-newline character at the end of a line
  re = new RegExp(r".$", multiLine: true);
  result = re.allMatches(s).toList();
  assertEquals(result.length, 6);
  assertEquals(result[0][0], 'A');
  assertEquals(result[1][0], 'B');
  assertEquals(result[2][0], 'C');
  assertEquals(result[3][0], 'D');
  assertEquals(result[4][0], 'E');
  assertEquals(result[5][0], 'F');

  // *any* character at the beginning of a line
  re = new RegExp(r"^[^]", multiLine: true);
  result = re.allMatches(s).toList();
  assertEquals(result.length, 7);
  assertEquals(result[0][0], 'a');
  assertEquals(result[1][0], 'b');
  assertEquals(result[2][0], 'c');
  assertEquals(result[3][0], '\n');
  assertEquals(result[4][0], 'd');
  assertEquals(result[5][0], 'e');
  assertEquals(result[6][0], 'f');

  // *any* character at the end of a line
  re = new RegExp(r"[^]$", multiLine: true);
  result = re.allMatches(s).toList();
  assertEquals(result.length, 7);
  assertEquals(result[0][0], 'A');
  assertEquals(result[1][0], 'B');
  assertEquals(result[2][0], 'C');
  assertEquals(result[3][0], '\r');
  assertEquals(result[4][0], 'D');
  assertEquals(result[5][0], 'E');
  assertEquals(result[6][0], 'F');

  // Some tests from the Mozilla tests, where our behavior used to differ
  // from SpiderMonkey.
  // From ecma_3/RegExp/regress-334158.js
  assertTrue("\x01".contains(new RegExp(r"\ca")));
  assertFalse("\\ca".contains(new RegExp(r"\ca")));
  assertFalse("ca".contains(new RegExp(r"\ca")));
  assertTrue("\\ca".contains(new RegExp(r"\c[a/]")));
  assertTrue("\\c/".contains(new RegExp(r"\c[a/]")));

  // Test \c in character class
  re = r"^[\cM]$";
  assertTrue("\r".contains(new RegExp(re)));
  assertFalse("M".contains(new RegExp(re)));
  assertFalse("c".contains(new RegExp(re)));
  assertFalse("\\".contains(new RegExp(re)));
  assertFalse("\x03".contains(new RegExp(re))); // I.e., read as \cc

  re = r"^[\c]]$";
  assertTrue("c]".contains(new RegExp(re)));
  assertTrue("\\]".contains(new RegExp(re)));
  assertFalse("\x1d".contains(new RegExp(re))); // ']' & 0x1f
  assertFalse("\x03]".contains(new RegExp(re))); // I.e., read as \cc

  // Digit control characters are masked in character classes.
  re = r"^[\c1]$";
  assertTrue("\x11".contains(new RegExp(re)));
  assertFalse("\\".contains(new RegExp(re)));
  assertFalse("c".contains(new RegExp(re)));
  assertFalse("1".contains(new RegExp(re)));

  // Underscore control character is masked in character classes.
  re = r"^[\c_]$";
  assertTrue("\x1f".contains(new RegExp(re)));
  assertFalse("\\".contains(new RegExp(re)));
  assertFalse("c".contains(new RegExp(re)));
  assertFalse("_".contains(new RegExp(re)));

  re = r"^[\c$]$"; // Other characters are interpreted literally.
  assertFalse("\x04".contains(new RegExp(re)));
  assertTrue("\\".contains(new RegExp(re)));
  assertTrue("c".contains(new RegExp(re)));
  assertTrue(r"$".contains(new RegExp(re)));

  assertTrue("Z[\\cde".contains(new RegExp(r"^[Z-\c-e]*$")));

  // Test that we handle \s and \S correctly on special Unicode characters.
  re = r"\s";
  assertTrue("\u2028".contains(new RegExp(re)));
  assertTrue("\u2029".contains(new RegExp(re)));
  assertTrue("\uFEFF".contains(new RegExp(re)));

  re = r"\S";
  assertFalse("\u2028".contains(new RegExp(re)));
  assertFalse("\u2029".contains(new RegExp(re)));
  assertFalse("\uFEFF".contains(new RegExp(re)));

  // Test that we handle \s and \S correctly inside some bizarre
  // character classes.
  re = r"[\s-:]";
  assertTrue('-'.contains(new RegExp(re)));
  assertTrue(':'.contains(new RegExp(re)));
  assertTrue(' '.contains(new RegExp(re)));
  assertTrue('\t'.contains(new RegExp(re)));
  assertTrue('\n'.contains(new RegExp(re)));
  assertFalse('a'.contains(new RegExp(re)));
  assertFalse('Z'.contains(new RegExp(re)));

  re = r"[\S-:]";
  assertTrue('-'.contains(new RegExp(re)));
  assertTrue(':'.contains(new RegExp(re)));
  assertFalse(' '.contains(new RegExp(re)));
  assertFalse('\t'.contains(new RegExp(re)));
  assertFalse('\n'.contains(new RegExp(re)));
  assertTrue('a'.contains(new RegExp(re)));
  assertTrue('Z'.contains(new RegExp(re)));

  re = r"[^\s-:]";
  assertFalse('-'.contains(new RegExp(re)));
  assertFalse(':'.contains(new RegExp(re)));
  assertFalse(' '.contains(new RegExp(re)));
  assertFalse('\t'.contains(new RegExp(re)));
  assertFalse('\n'.contains(new RegExp(re)));
  assertTrue('a'.contains(new RegExp(re)));
  assertTrue('Z'.contains(new RegExp(re)));

  re = r"[^\S-:]";
  assertFalse('-'.contains(new RegExp(re)));
  assertFalse(':'.contains(new RegExp(re)));
  assertTrue(' '.contains(new RegExp(re)));
  assertTrue('\t'.contains(new RegExp(re)));
  assertTrue('\n'.contains(new RegExp(re)));
  assertFalse('a'.contains(new RegExp(re)));
  assertFalse('Z'.contains(new RegExp(re)));

  re = r"[\s]";
  assertFalse('-'.contains(new RegExp(re)));
  assertFalse(':'.contains(new RegExp(re)));
  assertTrue(' '.contains(new RegExp(re)));
  assertTrue('\t'.contains(new RegExp(re)));
  assertTrue('\n'.contains(new RegExp(re)));
  assertFalse('a'.contains(new RegExp(re)));
  assertFalse('Z'.contains(new RegExp(re)));

  re = r"[^\s]";
  assertTrue('-'.contains(new RegExp(re)));
  assertTrue(':'.contains(new RegExp(re)));
  assertFalse(' '.contains(new RegExp(re)));
  assertFalse('\t'.contains(new RegExp(re)));
  assertFalse('\n'.contains(new RegExp(re)));
  assertTrue('a'.contains(new RegExp(re)));
  assertTrue('Z'.contains(new RegExp(re)));

  re = r"[\S]";
  assertTrue('-'.contains(new RegExp(re)));
  assertTrue(':'.contains(new RegExp(re)));
  assertFalse(' '.contains(new RegExp(re)));
  assertFalse('\t'.contains(new RegExp(re)));
  assertFalse('\n'.contains(new RegExp(re)));
  assertTrue('a'.contains(new RegExp(re)));
  assertTrue('Z'.contains(new RegExp(re)));

  re = r"[^\S]";
  assertFalse('-'.contains(new RegExp(re)));
  assertFalse(':'.contains(new RegExp(re)));
  assertTrue(' '.contains(new RegExp(re)));
  assertTrue('\t'.contains(new RegExp(re)));
  assertTrue('\n'.contains(new RegExp(re)));
  assertFalse('a'.contains(new RegExp(re)));
  assertFalse('Z'.contains(new RegExp(re)));

  re = r"[\s\S]";
  assertTrue('-'.contains(new RegExp(re)));
  assertTrue(':'.contains(new RegExp(re)));
  assertTrue(' '.contains(new RegExp(re)));
  assertTrue('\t'.contains(new RegExp(re)));
  assertTrue('\n'.contains(new RegExp(re)));
  assertTrue('a'.contains(new RegExp(re)));
  assertTrue('Z'.contains(new RegExp(re)));

  re = r"[^\s\S]";
  assertFalse('-'.contains(new RegExp(re)));
  assertFalse(':'.contains(new RegExp(re)));
  assertFalse(' '.contains(new RegExp(re)));
  assertFalse('\t'.contains(new RegExp(re)));
  assertFalse('\n'.contains(new RegExp(re)));
  assertFalse('a'.contains(new RegExp(re)));
  assertFalse('Z'.contains(new RegExp(re)));

  // First - is treated as range operator, second as literal minus.
  // This follows the specification in parsing, but doesn't throw on
  // the \s at the beginning of the range.
  re = r"[\s-0-9]";
  assertTrue(' '.contains(new RegExp(re)));
  assertTrue('\xA0'.contains(new RegExp(re)));
  assertTrue('-'.contains(new RegExp(re)));
  assertTrue('0'.contains(new RegExp(re)));
  assertTrue('9'.contains(new RegExp(re)));
  assertFalse('1'.contains(new RegExp(re)));

  // Test beginning and end of line assertions with or without the
  // multiline flag.
  re = r"^\d+";
  assertFalse("asdf\n123".contains(new RegExp(re)));
  re = new RegExp(r"^\d+", multiLine: true);
  assertTrue("asdf\n123".contains(re));

  re = r"\d+$";
  assertFalse("123\nasdf".contains(new RegExp(re)));
  re = new RegExp(r"\d+$", multiLine: true);
  assertTrue("123\nasdf".contains(re));

  // Test that empty matches are handled correctly for multiline global
  // regexps.
  re = new RegExp(r"^(.*)", multiLine: true);
  assertEquals(3, re.allMatches("a\n\rb").length);
  assertEquals("*a\n*b\r*c\n*\r*d\r*\n*e",
      "a\nb\rc\n\rd\r\ne".replaceAllMapped(re, (Match m) => "*${m.group(1)}"));

  // Test that empty matches advance one character
  re = new RegExp("");
  assertEquals("xAx", "A".replaceAll(re, "x"));
  assertEquals(3, new String.fromCharCode(161).replaceAll(re, "x").length);

  // Check for lazy RegExp literal creation
  lazyLiteral(doit) {
    if (doit)
      return "".replaceAll(new RegExp(r"foo(", caseSensitive: false), "");
    return true;
  }

  assertTrue(lazyLiteral(false));
  assertThrows(() => lazyLiteral(true));

  // Check $01 and $10
  re = new RegExp("(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)");
  assertEquals(
      "t", "123456789t".replaceAllMapped(re, (Match m) => m.group(10)));
  assertEquals(
      "15", "123456789t".replaceAllMapped(re, (Match m) => "${m.group(1)}5"));
  assertEquals("1", "123456789t".replaceAllMapped(re, (Match m) => m.group(1)));

  assertFalse("football".contains(new RegExp(r"()foo$\1")), "football1");
  assertFalse("football".contains(new RegExp(r"foo$(?=ball)")), "football2");
  assertFalse("football".contains(new RegExp(r"foo$(?!bar)")), "football3");
  assertTrue("foo".contains(new RegExp(r"()foo$\1")), "football4");
  assertTrue("foo".contains(new RegExp(r"foo$(?=(ball)?)")), "football5");
  assertTrue("foo".contains(new RegExp(r"()foo$(?!bar)")), "football6");
  assertFalse("football".contains(new RegExp(r"(x?)foo$\1")), "football7");
  assertFalse("football".contains(new RegExp(r"foo$(?=ball)")), "football8");
  assertFalse("football".contains(new RegExp(r"foo$(?!bar)")), "football9");
  assertTrue("foo".contains(new RegExp(r"(x?)foo$\1")), "football10");
  assertTrue("foo".contains(new RegExp(r"foo$(?=(ball)?)")), "football11");
  assertTrue("foo".contains(new RegExp(r"foo$(?!bar)")), "football12");

  // Check that the back reference has two successors.  See
  // BackReferenceNode::PropagateForward.
  assertFalse('foo'.contains(new RegExp(r"f(o)\b\1")));
  assertTrue('foo'.contains(new RegExp(r"f(o)\B\1")));

  // Back-reference, ignore case:
  // ASCII
  assertEquals(
      "a",
      new RegExp(r"x(a)\1x", caseSensitive: false).firstMatch("xaAx").group(1),
      "backref-ASCII");
  assertFalse("xaaaaa".contains(new RegExp(r"x(...)\1", caseSensitive: false)),
      "backref-ASCII-short");
  assertTrue("xx".contains(new RegExp(r"x((?:))\1\1x", caseSensitive: false)),
      "backref-ASCII-empty");
  assertTrue(
      "xabcx".contains(new RegExp(r"x(?:...|(...))\1x", caseSensitive: false)),
      "backref-ASCII-uncaptured");
  assertTrue(
      "xabcABCx"
          .contains(new RegExp(r"x(?:...|(...))\1x", caseSensitive: false)),
      "backref-ASCII-backtrack");
  assertEquals(
      "aBc",
      new RegExp(r"x(...)\1\1x", caseSensitive: false)
          .firstMatch("xaBcAbCABCx")
          .group(1),
      "backref-ASCII-twice");

  for (var i = 0; i < 128; i++) {
    var testName = "backref-ASCII-char-$i,,${i^0x20}";
    var test = new String.fromCharCodes([i, i ^ 0x20])
        .contains(new RegExp(r"^(.)\1$", caseSensitive: false));
    if (('A'.codeUnitAt(0) <= i && i <= 'Z'.codeUnitAt(0)) ||
        ('a'.codeUnitAt(0) <= i && i <= 'z'.codeUnitAt(0))) {
      assertTrue(test, testName);
    } else {
      assertFalse(test, testName);
    }
  }

  assertFalse('foo'.contains(new RegExp(r"f(o)$\1")), "backref detects at_end");

  // Check decimal escapes doesn't overflow.
  // (Note: \214 is interpreted as octal).
  assertEquals(
      "\x8c7483648",
      new RegExp(r"\2147483648").firstMatch("\x8c7483648").group(0),
      "Overflow decimal escape");

  // Check numbers in quantifiers doesn't overflow and doesn't throw on
  // too large numbers.
  assertFalse(
      'b'.contains(
          new RegExp(r"a{111111111111111111111111111111111111111111111}")),
      "overlarge1");
  assertFalse(
      'b'.contains(
          new RegExp(r"a{999999999999999999999999999999999999999999999}")),
      "overlarge2");
  assertFalse(
      'b'.contains(
          new RegExp(r"a{1,111111111111111111111111111111111111111111111}")),
      "overlarge3");
  assertFalse(
      'b'.contains(
          new RegExp(r"a{1,999999999999999999999999999999999999999999999}")),
      "overlarge4");
  assertFalse('b'.contains(new RegExp(r"a{2147483648}")), "overlarge5");
  assertFalse('b'.contains(new RegExp(r"a{21474836471}")), "overlarge6");
  assertFalse('b'.contains(new RegExp(r"a{1,2147483648}")), "overlarge7");
  assertFalse('b'.contains(new RegExp(r"a{1,21474836471}")), "overlarge8");
  assertFalse(
      'b'.contains(new RegExp(r"a{2147483648,2147483648}")), "overlarge9");
  assertFalse(
      'b'.contains(new RegExp(r"a{21474836471,21474836471}")), "overlarge10");
  assertFalse('b'.contains(new RegExp(r"a{2147483647}")), "overlarge11");
  assertFalse('b'.contains(new RegExp(r"a{1,2147483647}")), "overlarge12");
  assertTrue('a'.contains(new RegExp(r"a{1,2147483647}")), "overlarge13");
  assertFalse(
      'a'.contains(new RegExp(r"a{2147483647,2147483647}")), "overlarge14");

  // Check that we don't read past the end of the string.
  assertFalse('b'.contains(new RegExp(r"f")));
  assertFalse('x'.contains(new RegExp(r"[abc]f")));
  assertFalse('xa'.contains(new RegExp(r"[abc]f")));
  assertFalse('x'.contains(new RegExp(r"[abc]<")));
  assertFalse('xa'.contains(new RegExp(r"[abc]<")));
  assertFalse('b'.contains(new RegExp(r"f", caseSensitive: false)));
  assertFalse('x'.contains(new RegExp(r"[abc]f", caseSensitive: false)));
  assertFalse('xa'.contains(new RegExp(r"[abc]f", caseSensitive: false)));
  assertFalse('x'.contains(new RegExp(r"[abc]<", caseSensitive: false)));
  assertFalse('xa'.contains(new RegExp(r"[abc]<", caseSensitive: false)));
  assertFalse('x'.contains(new RegExp(r"f[abc]")));
  assertFalse('xa'.contains(new RegExp(r"f[abc]")));
  assertFalse('x'.contains(new RegExp(r"<[abc]")));
  assertFalse('xa'.contains(new RegExp(r"<[abc]")));
  assertFalse('x'.contains(new RegExp(r"f[abc]", caseSensitive: false)));
  assertFalse('xa'.contains(new RegExp(r"f[abc]", caseSensitive: false)));
  assertFalse('x'.contains(new RegExp(r"<[abc]", caseSensitive: false)));
  assertFalse('xa'.contains(new RegExp(r"<[abc]", caseSensitive: false)));

  // Test that merging of quick test masks gets it right.
  assertFalse('x7%%y'.contains(new RegExp(r"x([0-7]%%x|[0-6]%%y)")), 'qt');
  assertFalse(
      'xy7%%%y'
          .contains(new RegExp(r"()x\1(y([0-7]%%%x|[0-6]%%%y)|dkjasldkas)")),
      'qt2');
  assertFalse(
      'xy%%%y'
          .contains(new RegExp(r"()x\1(y([0-7]%%%x|[0-6]%%%y)|dkjasldkas)")),
      'qt3');
  assertFalse(
      'xy7%%%y'.contains(new RegExp(r"()x\1y([0-7]%%%x|[0-6]%%%y)")), 'qt4');
  assertFalse(
      'xy%%%y'
          .contains(new RegExp(r"()x\1(y([0-7]%%%x|[0-6]%%%y)|dkjasldkas)")),
      'qt5');
  assertFalse(
      'xy7%%%y'.contains(new RegExp(r"()x\1y([0-7]%%%x|[0-6]%%%y)")), 'qt6');
  assertFalse(
      'xy7%%%y'.contains(new RegExp(r"xy([0-7]%%%x|[0-6]%%%y)")), 'qt7');
  assertFalse('x7%%%y'.contains(new RegExp(r"x([0-7]%%%x|[0-6]%%%y)")), 'qt8');

  // Don't hang on this one.
  "".contains(new RegExp(r"[^\xfe-\xff]*"));

  var longbuffer = new StringBuffer("a");
  for (var i = 0; i < 100000; i++) {
    longbuffer.write("a?");
  }
  var long = longbuffer.toString();

  // Don't crash on this one, but maybe throw an exception.
  try {
    new RegExp(long).allMatches("a");
  } catch (e) {
    assertTrue(e.toString().indexOf("Stack overflow") >= 0, "overflow");
  }

  // Test boundary-checks.
  void assertRegExpTest(re, input, test) {
    assertEquals(
        test, input.contains(new RegExp(re)), "test:" + re + ":" + input);
  }

  assertRegExpTest(r"b\b", "b", true);
  assertRegExpTest(r"b\b$", "b", true);
  assertRegExpTest(r"\bb", "b", true);
  assertRegExpTest(r"^\bb", "b", true);
  assertRegExpTest(r",\b", ",", false);
  assertRegExpTest(r",\b$", ",", false);
  assertRegExpTest(r"\b,", ",", false);
  assertRegExpTest(r"^\b,", ",", false);

  assertRegExpTest(r"b\B", "b", false);
  assertRegExpTest(r"b\B$", "b", false);
  assertRegExpTest(r"\Bb", "b", false);
  assertRegExpTest(r"^\Bb", "b", false);
  assertRegExpTest(r",\B", ",", true);
  assertRegExpTest(r",\B$", ",", true);
  assertRegExpTest(r"\B,", ",", true);
  assertRegExpTest(r"^\B,", ",", true);

  assertRegExpTest(r"b\b", "b,", true);
  assertRegExpTest(r"b\b", "ba", false);
  assertRegExpTest(r"b\B", "b,", false);
  assertRegExpTest(r"b\B", "ba", true);

  assertRegExpTest(r"b\Bb", "bb", true);
  assertRegExpTest(r"b\bb", "bb", false);

  assertRegExpTest(r"b\b[,b]", "bb", false);
  assertRegExpTest(r"b\B[,b]", "bb", true);
  assertRegExpTest(r"b\b[,b]", "b,", true);
  assertRegExpTest(r"b\B[,b]", "b,", false);

  assertRegExpTest(r"[,b]\bb", "bb", false);
  assertRegExpTest(r"[,b]\Bb", "bb", true);
  assertRegExpTest(r"[,b]\bb", ",b", true);
  assertRegExpTest(r"[,b]\Bb", ",b", false);

  assertRegExpTest(r"[,b]\b[,b]", "bb", false);
  assertRegExpTest(r"[,b]\B[,b]", "bb", true);
  assertRegExpTest(r"[,b]\b[,b]", ",b", true);
  assertRegExpTest(r"[,b]\B[,b]", ",b", false);
  assertRegExpTest(r"[,b]\b[,b]", "b,", true);
  assertRegExpTest(r"[,b]\B[,b]", "b,", false);

  // Skipped tests from V8:

  // Test that caching of result doesn't share result objects.
  // More iterations increases the chance of hitting a GC.

  // Test that we perform the spec required conversions in the correct order.

  // Check that properties of RegExp have the correct permissions.

  // Check that end-anchored regexps are optimized correctly.
  re = r"(?:a|bc)g$";
  assertTrue("ag".contains(new RegExp(re)));
  assertTrue("bcg".contains(new RegExp(re)));
  assertTrue("abcg".contains(new RegExp(re)));
  assertTrue("zimbag".contains(new RegExp(re)));
  assertTrue("zimbcg".contains(new RegExp(re)));

  assertFalse("g".contains(new RegExp(re)));
  assertFalse("".contains(new RegExp(re)));

  // Global regexp (non-zero start).
  re = r"(?:a|bc)g$";
  assertTrue("ag".contains(new RegExp(re)));
  // Near start of string.
  assertTrue(new RegExp(re).allMatches("zimbag", 1).isNotEmpty);
  // At end of string.
  assertTrue(new RegExp(re).allMatches("zimbag", 6).isEmpty);
  // Near end of string.
  assertTrue(new RegExp(re).allMatches("zimbag", 5).isEmpty);
  assertTrue(new RegExp(re).allMatches("zimbag", 4).isNotEmpty);

  // Anchored at both ends.
  re = r"^(?:a|bc)g$";
  assertTrue("ag".contains(new RegExp(re)));
  assertTrue(new RegExp(re).allMatches("ag", 1).isEmpty);
  assertTrue(new RegExp(re).allMatches("zag", 1).isEmpty);

  // Long max_length of RegExp.
  re = r"VeryLongRegExp!{1,1000}$";
  assertTrue("BahoolaVeryLongRegExp!!!!!!".contains(new RegExp(re)));
  assertFalse("VeryLongRegExp".contains(new RegExp(re)));
  assertFalse("!".contains(new RegExp(re)));

  // End anchor inside disjunction.
  re = r"(?:a$|bc$)";
  assertTrue("a".contains(new RegExp(re)));
  assertTrue("bc".contains(new RegExp(re)));
  assertTrue("abc".contains(new RegExp(re)));
  assertTrue("zimzamzumba".contains(new RegExp(re)));
  assertTrue("zimzamzumbc".contains(new RegExp(re)));
  assertFalse("c".contains(new RegExp(re)));
  assertFalse("".contains(new RegExp(re)));

  // Only partially anchored.
  re = r"(?:a|bc$)";
  assertTrue("a".contains(new RegExp(re)));
  assertTrue("bc".contains(new RegExp(re)));
  assertEquals("a", new RegExp(re).firstMatch("abc").group(0));
  assertEquals(4, new RegExp(re).firstMatch("zimzamzumba").start);
  assertEquals("bc", new RegExp(re).firstMatch("zimzomzumbc").group(0));
  assertFalse("c".contains(new RegExp(re)));
  assertFalse("".contains(new RegExp(re)));

  // Valid syntax in ES5.
  re = new RegExp("(?:x)*");
  re = new RegExp("(x)*");

  // Syntax extension relative to ES5, for matching JSC (and ES3).
  // Shouldn't throw.
  re = new RegExp("(?=x)*");
  re = new RegExp("(?!x)*");

  // Should throw. Shouldn't hit asserts in debug mode.
  assertThrows(() => new RegExp('(*)'));
  assertThrows(() => new RegExp('(?:*)'));
  assertThrows(() => new RegExp('(?=*)'));
  assertThrows(() => new RegExp('(?!*)'));

  // Test trimmed regular expression for RegExp.test().
  assertTrue("abc".contains(new RegExp(r".*abc")));
  assertFalse("q".contains(new RegExp(r".*\d+")));

  // Tests skipped from V8:
  // Test that RegExp.prototype.toString() throws TypeError for
  // incompatible receivers (ES5 section 15.10.6 and 15.10.6.4).
}
