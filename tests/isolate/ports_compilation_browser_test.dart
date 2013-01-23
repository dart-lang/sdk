// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to crash when compiling
// [foo]. See http://code.google.com/p/dart/issues/detail?id=7448.

library ports_compilation;
import 'dart:html';
import 'dart:isolate';
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';

void foo() {
  // Create a "SendPortSync" object and access one of its members.
  SendPortSync s_port;
  s_port.callSync;
  
  // Create a "ReceivePortSync" object (with the constructor) and
  // access one of its members.
  var r_port = new ReceivePortSync();
  r_port.receive;
  
  // Call getComputedStyle() from the HTML library.
  query("").getComputedStyle("");
}

int inscrutable(int x) => x == 0 ? 0 : x | inscrutable(x & (x - 1));

void main() {
  // Generate the call, but don't execute it.
  if (inscrutable(1) != 1) foo();
  useHtmlConfiguration();
  bar();
  // Also generate it here in case the compiler's worklist goes from
  // last seen to first seen.
  if (inscrutable(1) != 1) foo();
}

bar() {
  test('compile', () { });
}
