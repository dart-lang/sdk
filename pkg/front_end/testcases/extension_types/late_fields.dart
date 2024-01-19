// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type ET1(int id) {
  late int id = 0;
}

extension type ET2(int id) {
  late int x = 0;
}

extension type ET3(int id) {
  late final x = 0;
}

extension type ET4(int id) {
  late final int x;
}

main() {
  print(ET1);
  print(ET2);
  print(ET3);
  print(ET4);
}