// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;

int _finalizeIndexables(int index, Iterable<ir.Indexable> indexables) {
  for (final f in indexables) {
    f.finalizableIndex.finalize(index++);
  }
  return index;
}

/// Finalizes imports and definitions.
void finalizeImportsAndDefinitions(
  Iterable<ir.Indexable> imported,
  Iterable<ir.Indexable> defined,
) {
  int index = _finalizeIndexables(0, imported);
  _finalizeIndexables(index, defined);
}
