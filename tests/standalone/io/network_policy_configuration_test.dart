// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=-Ddart.library.io.domain_network_policies=[["foobar.com",true,true],["foobar.com",true,true],["baz.foobar.com",true,true],["baz.foobar.com",false,false]] -Ddart.library.io.may_insecurely_connect_to_all_domains=false

import 'dart:io';

import "package:expect/expect.dart";

void _checkAllows(List<String> domains) {
  for (final domain in domains) {
    Expect.isTrue(
        isInsecureConnectionAllowed(domain), "$domain should be allowed.");
  }
}

void _checkDenies(List<String> domains) {
  for (final domain in domains) {
    Expect.isFalse(
        isInsecureConnectionAllowed(domain), "$domain should not be allowed.");
  }
}

void main() {
  // These have no policy but the default is false.
  _checkDenies([
    "mailfoobar.com",
    "abc.com",
    "oobar.com",
    "foobar.co",
    "128.221.55.31",
    "fe80::4607:0bff:fea0:7747%invalid",
  ]);
  // These are explicitly denied.
  _checkDenies(["baz.foobar.com"]);
  _checkAllows(
      ["foobar.com", "test.baz.foobar.com", "test2.test.baz.foobar.com"]);
  _checkAllows(["::1", "localhost"]);
}
