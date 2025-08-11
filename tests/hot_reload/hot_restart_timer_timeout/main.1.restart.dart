// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

bool restarted() => true;

void callback() {
  throw Exception('Should never run.');
}

Future<void> main() async {
  await new Future.delayed(Duration(milliseconds: 300));
  Expect.isTrue(restarted());
}

/** DIFF **/
/*
 import 'package:expect/expect.dart';
 import 'package:reload_test/reload_test_utils.dart';
 
-bool restarted() => false;
+bool restarted() => true;
 
 void callback() {
   throw Exception('Should never run.');
 }
 
 Future<void> main() async {
-  Timer(Duration(milliseconds: 200), callback);
-  await hotRestart();
+  await new Future.delayed(Duration(milliseconds: 300));
+  Expect.isTrue(restarted());
 }
*/
