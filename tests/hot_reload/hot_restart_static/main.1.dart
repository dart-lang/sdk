// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

String? noInitializer;
int withInitializer = 1;

class Statics {
  static String? noInitializer;
  static int withInitializer = 2;
}

class StaticsGeneric<T> {
  static String? noInitializer;
  static int withInitializer = 3;
}

class StaticsSetter {
  static int counter = 0;
  static const field = 5;
  static const field2 = null;
  static set field(int value) => StaticsSetter.counter += 1;
  static set field2(value) => 42;
}

Future<void> main() async {
  // All statics should contain their initial values.
  Expect.equals(null, noInitializer);
  Expect.equals(null, Statics.noInitializer);
  Expect.equals(null, StaticsGeneric.noInitializer);

  noInitializer = 'set via setter';
  Statics.noInitializer = 'Statics set via setter';
  StaticsGeneric.noInitializer = 'StaticsGeneric set via setter';

  // All statics should contain their set values.
  Expect.equals('set via setter', noInitializer);
  Expect.equals('Statics set via setter', Statics.noInitializer);
  Expect.equals('StaticsGeneric set via setter', StaticsGeneric.noInitializer);
  Expect.equals(1, withInitializer);
  Expect.equals(2, Statics.withInitializer);
  Expect.equals(3, StaticsGeneric.withInitializer);

  await hotRestart();
}
/** DIFF **/
/*
@@ -27,13 +27,19 @@
 }
 
 Future<void> main() async {
-  // Set static fields without explicit initializers. Avoid calling getters for
-  // these statics to ensure they are reset even if they are never accessed.
+  // All statics should contain their initial values.
+  Expect.equals(null, noInitializer);
+  Expect.equals(null, Statics.noInitializer);
+  Expect.equals(null, StaticsGeneric.noInitializer);
+
   noInitializer = 'set via setter';
   Statics.noInitializer = 'Statics set via setter';
   StaticsGeneric.noInitializer = 'StaticsGeneric set via setter';
 
-  // Initialized statics should contain their values.
+  // All statics should contain their set values.
+  Expect.equals('set via setter', noInitializer);
+  Expect.equals('Statics set via setter', Statics.noInitializer);
+  Expect.equals('StaticsGeneric set via setter', StaticsGeneric.noInitializer);
   Expect.equals(1, withInitializer);
   Expect.equals(2, Statics.withInitializer);
   Expect.equals(3, StaticsGeneric.withInitializer);
*/
