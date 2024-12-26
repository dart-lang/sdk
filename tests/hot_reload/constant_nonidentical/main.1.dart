// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/26f2ff4f11f56841fc5a250231ef7d49f01eb234/runtime/vm/isolate_reload_test.cc#L2604
// Extended with logic to check for non-identity.

class Fruit {
  final String name;
  final String field = 'field';
  const Fruit(this.name);
  String toString() => name;
}

var x;

helper() {
  return const Fruit('Pear');
}

Future<void> main() async {
  x = const Fruit('Pear');
  Expect.equals('Pear', x.toString());
  Expect.identical(x, helper());

  await hotReload();
  Expect.equals('Pear', x.toString());
  Expect.identical(x, const Fruit('Pear'));
  Expect.notIdentical(x, helper());
}
/** DIFF **/
/*
@@ -11,6 +11,7 @@
 
 class Fruit {
   final String name;
+  final String field = 'field';
   const Fruit(this.name);
   String toString() => name;
 }
*/
