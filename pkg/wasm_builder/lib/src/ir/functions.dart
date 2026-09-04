// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'ir.dart';

/// The interface for the functions in a module.
class Functions {
  /// Imported functions.
  final List<ImportedFunction> imported;

  /// Defined functions.
  final List<DefinedFunction> defined;

  Functions(this.imported, this.defined);

  BaseFunction operator [](int index) => index < imported.length
      ? imported[index]
      : defined[index - imported.length];

  int get length => imported.length + defined.length;

  void collectUsedTypes(Set<DefType> usedTypes) {
    for (final f in defined) {
      f.collectUsedTypes(usedTypes);
    }
    for (final f in imported) {
      f.collectUsedTypes(usedTypes);
    }
  }
}
