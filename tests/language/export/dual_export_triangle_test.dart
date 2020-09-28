// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for cyclic export regression seen in: https://github.com/flutter/flutter/issues/64011

// dual_export_triangle_entrypoint imports dual_export_triangle_a.
// dual_export_triangle_a defines A (extends B).
// dual_export_triangle_b defines B (extends C).
// dual_export_triangle_c defines C (with type parameter A).
// dual_export_triangle_test exports both dual_export_triangle_entrypoint and
// either dual_export_triangle_b or dual_export_triangle_c.

library dual_export_triangle_test;

import 'dual_export_triangle_entrypoint.dart';

export 'dual_export_triangle_entrypoint.dart';
export 'dual_export_triangle_b.dart';

main() {
  print(Entrypoint());
}
