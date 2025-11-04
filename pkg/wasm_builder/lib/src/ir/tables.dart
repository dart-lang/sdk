// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'ir.dart';
import 'table.dart';

class Tables {
  /// Imported tables.
  final List<ImportedTable> imported;

  /// Defined tables.
  final List<DefinedTable> defined;

  Tables(this.imported, this.defined);

  Table operator [](int index) => index < imported.length
      ? imported[index]
      : defined[index - imported.length];

  int get length => imported.length + defined.length;
}
