// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'ir.dart';

class Globals {
  /// Imported globals.
  final List<ImportedGlobal> imported;

  /// Defined globals.
  final List<DefinedGlobal> defined;

  Globals(this.imported, this.defined);

  Global operator [](int index) => index < imported.length
      ? imported[index]
      : defined[index - imported.length];

  int get length => imported.length + defined.length;

  void collectUsedTypes(Set<DefType> usedTypes) {
    for (final global in defined) {
      global.collectUsedTypes(usedTypes);
    }
    for (final global in imported) {
      global.collectUsedTypes(usedTypes);
    }
  }
}
