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

import 'v8_regexp_utils.dart';
import 'package:expect/expect.dart';

void main() {
  var str = "ABX X";
  str = str.replaceAll(new RegExp(r"(\w)?X"), "c");
  assertEquals("Ac c", str);

  // Test zero-length matches.
  str = "Als Gregor Samsa eines Morgens";
  str = str.replaceAll(new RegExp(r"\b"), "/");
  assertEquals("/Als/ /Gregor/ /Samsa/ /eines/ /Morgens/", str);

  // Test zero-length matches that have non-zero-length sub-captures.
  str = "It was a pleasure to burn.";
  str = str.replaceAllMapped(
      new RegExp(r"(?=(\w+))\b"), (Match m) => m.group(1).length.toString());
  assertEquals("2It 3was 1a 8pleasure 2to 4burn.", str);

  // Test multiple captures.
  str = "Try not. Do, or do not. There is no try.";
  str = str.replaceAllMapped(
      new RegExp(r"(not?)|(do)|(try)", caseSensitive: false), (m) {
    if (m.group(1) != null) return "-";
    if (m.group(2) != null) return "+";
    if (m.group(3) != null) return "=";
  });
  assertEquals("= -. +, or + -. There is - =.", str);

  // Test multiple alternate captures.
  str = "FOUR LEGS GOOD, TWO LEGS BAD!";
  str = str.replaceAllMapped(new RegExp(r"(FOUR|TWO) LEGS (GOOD|BAD)"), (m) {
    if (m.group(1) == "FOUR") assertTrue(m.group(2) == "GOOD");
    if (m.group(1) == "TWO") assertTrue(m.group(2) == "BAD");
    return (m.group(0).length - 10).toString();
  });
  assertEquals("4, 2!", str);

  // The same tests with UC16.

  //Test that an optional capture is cleared between two matches.
  str = "AB\u1234 \u1234";
  str = str.replaceAll(new RegExp(r"(\w)?\u1234"), "c");
  assertEquals("Ac c", str);

  // Test zero-length matches.
  str = "Als \u2623\u2642 eines Morgens";
  str = str.replaceAll(new RegExp(r"\b"), "/");

  // Test zero-length matches that have non-zero-length sub-captures.
  str = "It was a pleasure to \u70e7.";
  str = str.replaceAllMapped(
      new RegExp(r"(?=(\w+))\b"), (m) => "${m.group(1).length}");
  assertEquals("2It 3was 1a 8pleasure 2to \u70e7.", str);

  // Test multiple captures.
  str = "Try not. D\u26aa, or d\u26aa not. There is no try.";
  str = str.replaceAllMapped(
      new RegExp(r"(not?)|(d\u26aa)|(try)", caseSensitive: false), (m) {
    if (m.group(1) != null) return "-";
    if (m.group(2) != null) return "+";
    if (m.group(3) != null) return "=";
  });
  assertEquals("= -. +, or + -. There is - =.", str);

  // Test multiple alternate captures.
  str = "FOUR \u817f GOOD, TWO \u817f BAD!";
  str = str.replaceAllMapped(new RegExp(r"(FOUR|TWO) \u817f (GOOD|BAD)"), (m) {
    if (m.group(1) == "FOUR") assertTrue(m.group(2) == "GOOD");
    if (m.group(1) == "TWO") assertTrue(m.group(2) == "BAD");
    return (m.group(0).length - 7).toString();
  });
  assertEquals("4, 2!", str);

  // Test capture that is a real substring.
  str = "Beasts of England, beasts of Ireland";
  str = str.replaceAll(new RegExp(r"(.*)"), '~');
  assertEquals("~~", str);

  // Test zero-length matches that have non-zero-length sub-captures that do not
  // start at the match start position.
  str = "up up up up";
  str = str.replaceAllMapped(
      new RegExp(r"\b(?=u(p))"), (m) => "${m.group(1).length}");

  assertEquals("1up 1up 1up 1up", str);

  // Create regexp that has a *lot* of captures.
  var re_string = "(a)";
  for (var i = 0; i < 500; i++) {
    re_string = "(" + re_string + ")";
  }
  re_string = re_string + "1";
  // re_string = "(((...((a))...)))1"

  var regexps = new List();
  var last_match_expectations = new List();
  var first_capture_expectations = new List();

  // Atomic regexp.
  regexps.add(new RegExp(r"a1"));
  last_match_expectations.add("a1");
  first_capture_expectations.add("");
  // Small regexp (no capture);
  regexps.add(new RegExp(r"\w1"));
  last_match_expectations.add("a1");
  first_capture_expectations.add("");
  // Small regexp (one capture).
  regexps.add(new RegExp(r"(a)1"));
  last_match_expectations.add("a1");
  first_capture_expectations.add("a");
  // Large regexp (a lot of captures).
  regexps.add(new RegExp(re_string));
  last_match_expectations.add("a1");
  first_capture_expectations.add("a");

  dynamic test_replace(result_expectation, subject, regexp, replacement) {
    for (var i = 0; i < regexps.length; i++) {
      // Conduct tests.
      assertEquals(
          result_expectation, subject.replaceAll(regexps[i], replacement));
    }
  }

  // Test for different number of matches.
  for (var m = 0; m < 33; m++) {
    // Create string that matches m times.
    var subject = "";
    var test_1_expectation = "";
    var test_2_expectation = "";
    var test_3_expectation = (m == 0) ? null : new List();
    for (var i = 0; i < m; i++) {
      subject += "a11";
      test_1_expectation += "x1";
      test_2_expectation += "1";
      test_3_expectation.add("a1");
    }

    // Test 1a: String.replace with string.
    test_replace(test_1_expectation, subject, new RegExp(r"a1"), "x");

    // Test 2a: String.replace with empty string.
    test_replace(test_2_expectation, subject, new RegExp(r"a1"), "");
  }

  // Test String hashing (compiling regular expression includes hashing).
  var crosscheck = "\x80";
  for (var i = 0; i < 12; i++) crosscheck += crosscheck;
  new RegExp(crosscheck);

  var subject = "ascii~only~string~here~";
  var replacement = "\x80";
  var result = subject.replaceAll(new RegExp(r"~"), replacement);
  for (var i = 0; i < 5; i++) result += result;
  new RegExp(result);
}
