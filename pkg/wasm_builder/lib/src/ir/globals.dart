// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../builder/module.dart';
import '../serialize/serialize.dart';
import 'ir.dart';

part 'global.dart';

class Globals {
  /// Imported globals.
  final List<ImportedGlobal> imported;

  /// Defined globals.
  final List<DefinedGlobal> defined;

  /// Number of named globals.
  final int namedCount;

  Globals(this.imported, this.defined, this.namedCount);
}
