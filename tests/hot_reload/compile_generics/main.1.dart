// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

import 'lib.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/36c0788137d55c6c77f4b9a8be12e557bc764b1c/runtime/vm/isolate_reload_test.cc#L204

class Account {
  int balance() => 24;
}

class MyAccountState extends State<Account> {
  MyAccountState(Account a) : super(a) {}
}

Future<void> main() async {
  var balance = (MyAccountState(Account())).howAreTheThings().balance();
  Expect.equals(42, balance);
  await hotReload();

  balance = (MyAccountState(Account())).howAreTheThings().balance();
  Expect.equals(24, balance);
}
/** DIFF **/
/*
@@ -11,7 +11,7 @@
 // https://github.com/dart-lang/sdk/blob/36c0788137d55c6c77f4b9a8be12e557bc764b1c/runtime/vm/isolate_reload_test.cc#L204
 
 class Account {
-  int balance() => 42;
+  int balance() => 24;
 }
 
 class MyAccountState extends State<Account> {
*/
