// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  dynamic hello = 'Hello';
  dynamic world = 'world';
  dynamic s = 0;
  s = world;
  hello = 'Greetings';
  print("$hello, $world!");
}
