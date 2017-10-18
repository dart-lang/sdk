// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void testParseIPv4Address() {
  void pass(String host, List<int> out) {
    Expect.listEquals(Uri.parseIPv4Address(host), out);
  }

  void fail(String host) {
    Expect.throwsFormatException(() => Uri.parseIPv4Address(host));
  }

  pass('127.0.0.1', [127, 0, 0, 1]);
  pass('128.0.0.1', [128, 0, 0, 1]);
  pass('255.255.255.255', [255, 255, 255, 255]);
  pass('0.0.0.0', [0, 0, 0, 0]);
  fail('127.0.0.-1');
  fail('255.255.255.256');
  fail('0.0.0.0.');
  fail('0.0.0.0.0');
  fail('a.0.0.0');
  fail('0.0..0');
}

void main() {
  testParseIPv4Address();
}
