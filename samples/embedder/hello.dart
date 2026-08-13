// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@pragma('vm:entry-point', 'call')
void main(List<String> args) {
  greet(args[0]);
}

void greet(String person) {
  print("hi, $person!");
}
