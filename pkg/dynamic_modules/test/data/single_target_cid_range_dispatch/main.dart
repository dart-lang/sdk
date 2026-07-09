// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

import 'shared/shared.dart';

@pragma('vm:never-inline')
@pragma('wasm:never-inline')
String callCreateElement(Base obj) {
  // Call site which dispatches to different dynamic objects.
  return obj.createElement();
}

/// Regression test for b/493677699.
/// Verifies that single target cid range dispatching works properly
/// for dynamically loaded classes.
void main() async {
  final createObj = (await helper.load('entry1.dart')) as Base Function(int);

  // Transition call site from unlinked to monomorphic.
  Expect.equals('Element1', callCreateElement(createObj(1)));
  // Transition call site from monomorphic to a single target cid range
  // (if a dynamically loaded class C2 is not properly accounted).
  Expect.equals('Element1', callCreateElement(createObj(3)));
  // Class id of C2 is within [C1..C3] range, so single target dispatch
  // would result in the incorrect dispatch target.
  Expect.equals('Element2', callCreateElement(createObj(2)));

  helper.done();
}
