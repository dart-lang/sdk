// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

import 'util.dart';

Future<void> main() async {
  resolvePromise();
  await Future.delayed(Duration(milliseconds: 100));
  Expect.isTrue(resolveCalled);
}

/** DIFF **/
/*
 import 'util.dart';
 
 Future<void> main() async {
-  injectJS();
-  createPromise().toDart.then((_) => throw 'Should never run.');
+  resolvePromise();
   await Future.delayed(Duration(milliseconds: 100));
-  Expect.isFalse(resolveCalled);
-  await hotRestart();
+  Expect.isTrue(resolveCalled);
 }
*/
