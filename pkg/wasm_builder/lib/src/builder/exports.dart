// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';

/// The interface for exports of this module.
class ExportsBuilder with Builder<ir.Exports> {
  final _exports = <ir.Export>[];

  /// Exports the provided [Exportable] under the provided name which must be
  /// unique.
  void export(String name, ir.Exportable exportable) {
    assert(!_exports.any((e) => e.name == name), name);
    _exports.add(exportable.export(name));
  }

  @override
  ir.Exports forceBuild() => ir.Exports(_exports);
}
