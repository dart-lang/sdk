// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'ir.dart';

class Elements {
  final List<ElementSegment> segments;

  Elements(this.segments);

  void collectUsedTypes(Set<DefType> usedTypes) {
    for (final segment in segments) {
      segment.collectUsedTypes(usedTypes);
    }
  }
}
