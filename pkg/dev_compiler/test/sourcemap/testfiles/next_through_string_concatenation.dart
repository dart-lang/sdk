// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*Debugger:stepOver*/

void main() {
  String qux;
  qux = '${/*bc:1*/ foo()} x ${/*bc:2*/ bar()} x ${/*bc:3*/ baz()}';
  print(qux);
}

String foo() => 'a';
String bar() => 'b';
String baz() => 'c';
