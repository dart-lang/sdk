// Copyright (c) 2014, the Dart project authors. All rights reserved.
// Copyright 2008 the V8 project authors. All rights reserved.
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

/**
 * @fileoverview Check that various regexp constructs work as intended.
 * Particularly those regexps that use ^ and $.
 */

import 'v8_regexp_utils.dart';
import 'package:expect/expect.dart';

void main() {
  assertTrue(new RegExp(r"^bar").hasMatch("bar"));
  assertTrue(new RegExp(r"^bar").hasMatch("bar\nfoo"));
  assertFalse(new RegExp(r"^bar").hasMatch("foo\nbar"));
  assertTrue(new RegExp(r"^bar", multiLine: true).hasMatch("bar"));
  assertTrue(new RegExp(r"^bar", multiLine: true).hasMatch("bar\nfoo"));
  assertTrue(new RegExp(r"^bar", multiLine: true).hasMatch("foo\nbar"));

  assertTrue(new RegExp(r"bar$").hasMatch("bar"));
  assertFalse(new RegExp(r"bar$").hasMatch("bar\nfoo"));
  assertTrue(new RegExp(r"bar$").hasMatch("foo\nbar"));
  assertTrue(new RegExp(r"bar$", multiLine: true).hasMatch("bar"));
  assertTrue(new RegExp(r"bar$", multiLine: true).hasMatch("bar\nfoo"));
  assertTrue(new RegExp(r"bar$", multiLine: true).hasMatch("foo\nbar"));

  assertFalse(new RegExp(r"^bxr").hasMatch("bar"));
  assertFalse(new RegExp(r"^bxr").hasMatch("bar\nfoo"));
  assertFalse(new RegExp(r"^bxr", multiLine: true).hasMatch("bar"));
  assertFalse(new RegExp(r"^bxr", multiLine: true).hasMatch("bar\nfoo"));
  assertFalse(new RegExp(r"^bxr", multiLine: true).hasMatch("foo\nbar"));

  assertFalse(new RegExp(r"bxr$").hasMatch("bar"));
  assertFalse(new RegExp(r"bxr$").hasMatch("foo\nbar"));
  assertFalse(new RegExp(r"bxr$", multiLine: true).hasMatch("bar"));
  assertFalse(new RegExp(r"bxr$", multiLine: true).hasMatch("bar\nfoo"));
  assertFalse(new RegExp(r"bxr$", multiLine: true).hasMatch("foo\nbar"));


  assertTrue(new RegExp(r"^.*$").hasMatch(""));
  assertTrue(new RegExp(r"^.*$").hasMatch("foo"));
  assertFalse(new RegExp(r"^.*$").hasMatch("\n"));
  assertTrue(new RegExp(r"^.*$", multiLine: true).hasMatch("\n"));

  assertTrue(new RegExp(r"^[\s]*$").hasMatch(" "));
  assertTrue(new RegExp(r"^[\s]*$").hasMatch("\n"));

  assertTrue(new RegExp(r"^[^]*$").hasMatch(""));
  assertTrue(new RegExp(r"^[^]*$").hasMatch("foo"));
  assertTrue(new RegExp(r"^[^]*$").hasMatch("\n"));

  assertTrue(new RegExp(r"^([()\s]|.)*$").hasMatch("()\n()"));
  assertTrue(new RegExp(r"^([()\n]|.)*$").hasMatch("()\n()"));
  assertFalse(new RegExp(r"^([()]|.)*$").hasMatch("()\n()"));
  assertTrue(new RegExp(r"^([()]|.)*$", multiLine: true).hasMatch("()\n()"));
  assertTrue(new RegExp(r"^([()]|.)*$", multiLine: true).hasMatch("()\n"));
  assertTrue(new RegExp(r"^[()]*$", multiLine: true).hasMatch("()\n."));

  assertTrue(new RegExp(r"^[\].]*$").hasMatch("...]..."));


  dynamic check_case(lc, uc) {
    var a = new RegExp("^" + lc + r"$");
    assertFalse(a.hasMatch(uc));
    a = new RegExp("^" + lc + r"$", caseSensitive: false);
    assertTrue(a.hasMatch(uc));

    var A = new RegExp("^" + uc + r"$");
    assertFalse(A.hasMatch(lc));
    A = new RegExp("^" + uc + r"$", caseSensitive: false);
    assertTrue(A.hasMatch(lc));

    a = new RegExp("^[" + lc + r"]$");
    assertFalse(a.hasMatch(uc));
    a = new RegExp("^[" + lc + r"]$", caseSensitive: false);
    assertTrue(a.hasMatch(uc));

    A = new RegExp("^[" + uc + r"]$");
    assertFalse(A.hasMatch(lc));
    A = new RegExp("^[" + uc + r"]$", caseSensitive: false);
    assertTrue(A.hasMatch(lc));
  }


  check_case("a", "A");
  // Aring
  check_case(new String.fromCharCode(229), new String.fromCharCode(197));
  // Russian G
  check_case(new String.fromCharCode(0x413), new String.fromCharCode(0x433));


  assertThrows(() => new RegExp('[z-a]'));
}
