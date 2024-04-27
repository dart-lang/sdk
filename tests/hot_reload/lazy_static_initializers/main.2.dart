// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

var value = "before";

Future<void> main() async {
  // Declare an unreferenced lazy static field.
  Expect.equals(0, hotReloadGeneration);
  await hotReload();

  // The lazy static field changes value but remains unread.
  Expect.equals(1, hotReloadGeneration);
  await hotReload();

  // The lazy static is now read and contains the updated value.
  print(value);
  Expect.equals(2, hotReloadGeneration);
  Expect.equals("before", value);
  await hotReload();

  // The lazy static is updated and read but retains the old value.
  Expect.equals(3, hotReloadGeneration);
  Expect.equals("before", value);
}
/** DIFF **/
/*
@@ -17,6 +17,7 @@
   await hotReload();
 
   // The lazy static is now read and contains the updated value.
+  print(value);
   Expect.equals(2, hotReloadGeneration);
   Expect.equals("before", value);
   await hotReload();
*/
