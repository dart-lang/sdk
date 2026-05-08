// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../serialize/serialize.dart';
import 'ir.dart';

class Imports {
  late final List<Import> all;

  final List<ImportedFunction> functions;
  final List<ImportedTag> tags;
  final List<ImportedGlobal> globals;
  final List<ImportedTable> tables;
  final List<ImportedMemory> memories;

  Imports(this.functions, this.tags, this.globals, this.tables, this.memories) {
    all = [
      ...functions,
      ...tags,
      ...globals,
      ...tables,
      ...memories,
    ];
  }

  Imports.deserialized(this.all, this.functions, this.tags, this.globals,
      this.tables, this.memories)
      : assert(all.length ==
            (functions.length +
                tags.length +
                globals.length +
                tables.length +
                memories.length));
}

/// Any import (function, table, memory or global).
abstract class Import implements Indexable, Serializable {
  String get module;

  @override
  String get name;
}
