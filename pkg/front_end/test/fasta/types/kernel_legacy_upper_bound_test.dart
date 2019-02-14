// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "legacy_upper_bound_helper.dart" show LegacyUpperBoundTest;

main() {
  new LegacyUpperBoundTest().test_getLegacyLeastUpperBound_expansive();

  new LegacyUpperBoundTest().test_getLegacyLeastUpperBound_generic();

  new LegacyUpperBoundTest().test_getLegacyLeastUpperBound_nonGeneric();
}
