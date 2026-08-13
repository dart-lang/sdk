// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test() {
  X bounded<X extends num>(X x) => x;
  String a = bounded('');
  String b = bounded<String>('');
  String Function(String) c = bounded;
  String d = c('');
}

main() {}
