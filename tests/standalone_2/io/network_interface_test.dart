// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:expect/expect.dart";

void testListLoopback() {
  NetworkInterface.list(includeLoopback: false).then((list) {
    for (var i in list) {
      for (var a in i.addresses) {
        Expect.isFalse(a.isLoopback);
      }
    }
  });

  NetworkInterface.list(includeLoopback: true).then((list) {
    Expect.isTrue(list.any((i) => i.addresses.any((a) => a.isLoopback)));
  });
}

void testListLinkLocal() {
  NetworkInterface.list(includeLinkLocal: false).then((list) {
    for (var i in list) {
      for (var a in i.addresses) {
        Expect.isFalse(a.isLinkLocal);
      }
    }
  });
}

void testListIndex() {
  var set = new Set();
  NetworkInterface.list(includeLoopback: true).then((list) {
    for (var i in list) {
      Expect.isNotNull(i.index);
      Expect.isFalse(set.contains(i.index));
      set.add(i.index);
      Expect.isTrue(set.contains(i.index));
    }
  });
}

void main() {
  if (!NetworkInterface.listSupported) {
    return;
  }
  testListLoopback();
  testListLinkLocal();
  testListIndex();
}
