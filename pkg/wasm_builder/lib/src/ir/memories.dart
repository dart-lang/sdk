// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../serialize/serialize.dart';
import 'ir.dart';

part 'memory.dart';

class Memories {
  /// Imported memories.
  final List<Import> imported;

  /// Defined memories.
  final List<DefinedMemory> defined;

  Memories(this.imported, this.defined);
}
