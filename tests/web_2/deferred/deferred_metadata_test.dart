// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// Regression tests to ensure that member metadata is not considered by the
/// deferred loading algorithm, unless mirrors are available.
///
/// This test was failing in the past because the deferred-loading algorithm was
/// adding entities to the K-element-map after we had closed the world and we
/// had created the J-element-map.  Later, when we convert the K annotation to
/// its J conterpart, we couldn't find it in the conversion maps because it was
/// added too late.
///
/// If we add support for mirrors in the future, we just need to ensure that
/// such K annotations are discovered during resolution, before the deferred
/// loading phase.

import 'deferred_metadata_lib.dart' deferred as d show foo;

main() async {
  await d.loadLibrary();
  print(d.foo());
}
