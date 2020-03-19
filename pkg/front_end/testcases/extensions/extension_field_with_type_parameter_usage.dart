// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension E<U> on String {
  U field1 = null;
  int field2 = () { U x = null; return null; }();
  List<U> field3 = null;
  U Function(U) field4 = null;
  List<U> Function(List<U>) field5 = null;
  int field6 = <E>() { E x = null; return null; }<String>();
  int field7 = <E>() { E x = null; return null; }<U>();
}

main() {}