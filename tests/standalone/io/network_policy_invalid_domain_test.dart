// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=-Ddart.library.io.domain_network_policies=[["com",true,true]]

import 'dart:io';

import "package:expect/expect.dart";

// This test passes in an invalid domain as a network policy and checks that
// loading the policies throws.
void main() {
  Expect.throwsArgumentError(() => isInsecureConnectionAllowed("test.com"));
}
