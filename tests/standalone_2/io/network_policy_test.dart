// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:expect/expect.dart";

void _checkAllows(List<String> domains) {
  for (final domain in domains) {
    Expect.isTrue(
        isInsecureConnectionAllowed(domain), "$domain should be allowed.");
  }
}

void main() {
  // All domains and addresses are allowed.
  _checkAllows([
    "mailfoobar.com",
    "abc.com",
    "oobar.com",
    "foobar.co",
    "128.221.55.31",
    "fe80::4607:0bff:fea0:7747%invalid",
    "baz.foobar.com",
    "foobar.com",
    "test.baz.foobar.com",
    "test2.test.baz.foobar.com",
    "::1",
    "localhost",
  ]);
}
