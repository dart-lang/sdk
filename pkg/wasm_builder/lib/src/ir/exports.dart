// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../serialize/serialize.dart';

/// Any class which can be exported from a module.
abstract class Exportable {
  /// All exports must have unique names.
  Export export(String name);
}

/// Any export (function, table, memory or global).
abstract class Export implements Serializable {
  final String name;

  Export(this.name);
}

class Exports {
  /// All exports from this module.
  final List<Export> exported;

  Exports(this.exported);
}
