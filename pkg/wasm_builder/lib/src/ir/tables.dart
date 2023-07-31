// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../serialize/serialize.dart';
import 'ir.dart';

part 'table.dart';

class Tables {
  /// Imported tables.
  final List<Import> imported;

  /// Defined tables.
  final List<DefinedTable> defined;

  Tables(this.imported, this.defined);
}
