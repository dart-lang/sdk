// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/cb96256bc2be8021c649da6d36c010de97cd3986/runtime/vm/isolate_reload_test.cc#L3381

var retained;

class C {
  deleted(newParameter) {
    return 'hello';
  }
}

class D extends C {}

helper() {}

Future<void> main() async {
  helper();
  Expect.equals('hello', retained());
  await hotReload();

  Expect.throws<NoSuchMethodError>(
    retained,
    (error) => '$error'.contains('deleted'),
  );
}

/** DIFF **/
/*
 var retained;
 
 class C {
-  deleted() {
+  deleted(newParameter) {
     return 'hello';
   }
 }
 
-class D extends C {
-  curry() => () => super.deleted();
-}
+class D extends C {}
 
-helper() {
-  retained = D().curry();
-}
+helper() {}
 
 Future<void> main() async {
   helper();
*/
