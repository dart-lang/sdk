// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 14348.

import "package:collection/equality.dart";

main() {
  const Equality<Iterable> eq = const UnorderedIterableEquality();
  const Equality<Map<dynamic, Iterable>> mapeq =
      const MapEquality<dynamic, dynamic>(values: eq);
}
