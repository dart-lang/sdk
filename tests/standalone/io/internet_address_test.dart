// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:expect/expect.dart";

void testDefaultAddresses() {
  var loopback4 = InternetAddress.LOOPBACK_IP_V4;
  Expect.isNotNull(loopback4);
  Expect.equals(InternetAddressType.IP_V4, loopback4.type);
  Expect.equals("localhost", loopback4.host);
  Expect.equals("127.0.0.1", loopback4.address);

  var loopback6 = InternetAddress.LOOPBACK_IP_V6;
  Expect.isNotNull(loopback6);
  Expect.equals(InternetAddressType.IP_V6, loopback6.type);
  Expect.equals("ip6-localhost", loopback6.host);
  Expect.equals("::1", loopback6.address);

  var any4 = InternetAddress.ANY_IP_V4;
  Expect.isNotNull(any4);
  Expect.equals(InternetAddressType.IP_V4, any4.type);
  Expect.equals("0.0.0.0", any4.host);
  Expect.equals("0.0.0.0", any4.address);

  var any6 = InternetAddress.ANY_IP_V6;
  Expect.isNotNull(any6);
  Expect.equals(InternetAddressType.IP_V6, any6.type);
  Expect.equals("::", any6.host);
  Expect.equals("::", any6.address);
}

void testReverseLookup() {
  InternetAddress.lookup('localhost').then((addrs) {
    addrs.first.reverse().then((addr) {
      Expect.isNotNull(addr.host);
    });
  });

  InternetAddress.lookup('127.0.0.1').then((addrs) {
    Expect.equals('127.0.0.1', addrs.first.host);
    addrs.first.reverse().then((addr) {
      Expect.isNotNull(addr.host);
      Expect.notEquals('127.0.0.1', addr.host);
    });
  });
}

void main() {
  testDefaultAddresses();
  testReverseLookup();
}
