// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

import 'library_a.dart';
import 'library_b.dart';

/// Tests for constant semantics across hot restart in DDC.
///
/// DDC has multiple layers of constant caching. Failing to clear them can
/// result in stale constants being referenced across hot restarts.
///
/// Cases tested include:
/// 1) Failing to clear all constant caches.
///   An old 'ConstObject' is returned, which fails to reflect the edited
///   'variableToModifyToForceRecompile'.
/// 2) Clearing constant caches but failing to clear constant containers.
///   Constants in reloaded modules fail to compare with constants in stale
///   constant containers, causing 'ConstantEqualityFailure's.
class ConstObject {
  const ConstObject();
  String get text => 'ConstObject('
      'reloadVariable: $variableToModifyToForceRecompile, '
      '${value1 == value2 ? 'ConstantEqualitySuccess' : 'ConstantEqualityFailure'})';
}

void main() {
  Expect.equals('ConstObject(reloadVariable: 45, ConstantEqualitySuccess)',
      '${const ConstObject().text}');
}
/** DIFF **/
/*
@@ -28,7 +28,6 @@
 }
 
 void main() {
-  Expect.equals('ConstObject(reloadVariable: 23, ConstantEqualitySuccess)',
+  Expect.equals('ConstObject(reloadVariable: 45, ConstantEqualitySuccess)',
       '${const ConstObject().text}');
-  hotRestart();
 }
*/
