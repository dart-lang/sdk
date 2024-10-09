// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export "exported_main_lib.dart";

@pragma("vm:entry-point")
foo() {
  // The frontend will not recognize that this is the root library. Though this
  // library is not reachable from what the frontend considers the root library,
  // the entry point pragma will still cause this function to compiled by
  // gen_snapshot, so it is important that this library is assigned to a
  // loading unit.
}
