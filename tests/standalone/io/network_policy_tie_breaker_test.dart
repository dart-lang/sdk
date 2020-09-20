// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=-Ddart.library.io.domain_network_policies=[["baz.foobar.com",true,true],["baz.foobar.com",false,false]]

import 'dart:io';

import "package:expect/expect.dart";

void main() {
  Expect.isFalse(isInsecureConnectionAllowed("baz.foobar.com"));
  Expect.isTrue(isInsecureConnectionAllowed("test.baz.foobar.com"));
}
