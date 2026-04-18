// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import "package:expect/expect.dart";

void testLoopbackIPv4() {
  NetworkInterface.list(includeLoopback: true).then((list) {
    for (var iface in list) {
      for (var entry in iface.addresses) {
        if (!entry.isLoopback) continue;
        if (entry.type != InternetAddressType.IPv4) continue;
        // 127.0.0.1/8 -> prefixLength=8, broadcast=127.255.255.255
        Expect.equals(8, entry.prefixLength);
        Expect.isNotNull(entry.broadcast);
        Expect.equals("127.255.255.255", entry.broadcast!.address);
        Expect.equals(InternetAddressType.IPv4, entry.broadcast!.type);
      }
    }
  });
}

void testLoopbackIPv6() {
  NetworkInterface.list(includeLoopback: true).then((list) {
    for (var iface in list) {
      for (var entry in iface.addresses) {
        if (!entry.isLoopback) continue;
        if (entry.type != InternetAddressType.IPv6) continue;
        // ::1/128 -> prefixLength=128, broadcast=null
        Expect.equals(128, entry.prefixLength);
        Expect.isNull(entry.broadcast);
      }
    }
  });
}

void testPrefixLengthRange() {
  NetworkInterface.list(includeLoopback: true).then((list) {
    for (var iface in list) {
      for (var entry in iface.addresses) {
        if (entry.type == InternetAddressType.IPv4) {
          Expect.isTrue(entry.prefixLength >= 0);
          Expect.isTrue(entry.prefixLength <= 32);
        } else if (entry.type == InternetAddressType.IPv6) {
          Expect.isTrue(entry.prefixLength >= 0);
          Expect.isTrue(entry.prefixLength <= 128);
        }
      }
    }
  });
}

void testIPv4BroadcastNotNull() {
  NetworkInterface.list(includeLoopback: true).then((list) {
    for (var iface in list) {
      for (var entry in iface.addresses) {
        if (entry.type != InternetAddressType.IPv4) continue;
        Expect.isNotNull(entry.broadcast);
        Expect.equals(InternetAddressType.IPv4, entry.broadcast!.type);
      }
    }
  });
}

void testIPv6BroadcastIsNull() {
  NetworkInterface.list(includeLoopback: true).then((list) {
    for (var iface in list) {
      for (var entry in iface.addresses) {
        if (entry.type != InternetAddressType.IPv6) continue;
        Expect.isNull(entry.broadcast);
      }
    }
  });
}

void main() {
  testLoopbackIPv4();
  testLoopbackIPv6();
  testPrefixLengthRange();
  testIPv4BroadcastNotNull();
  testIPv6BroadcastIsNull();
}
