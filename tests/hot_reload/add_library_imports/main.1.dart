import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

import 'dart:math';
import 'dart:convert';

void validate() {
  // Symbols in 'dart:convert' are visible after hot reload.
  Expect.equals(1, hotReloadGeneration);
  Expect.equals(e, 2.718281828459045);
  Expect.type<double>(e);
  Expect.type<Codec>(utf8);
  Expect.type<Function>(jsonEncode);
}

Future<void> main() async {
  validate();
  await hotReload();
  validate();
}
/** DIFF **/
/*
@@ -2,12 +2,15 @@
 import 'package:reload_test/reload_test_utils.dart';
 
 import 'dart:math';
+import 'dart:convert';
 
 void validate() {
-  // Initial program is valid. Symbols in 'dart:math' are visible.
-  Expect.equals(0, hotReloadGeneration);
+  // Symbols in 'dart:convert' are visible after hot reload.
+  Expect.equals(1, hotReloadGeneration);
   Expect.equals(e, 2.718281828459045);
   Expect.type<double>(e);
+  Expect.type<Codec>(utf8);
+  Expect.type<Function>(jsonEncode);
 }
 
 Future<void> main() async {
*/
