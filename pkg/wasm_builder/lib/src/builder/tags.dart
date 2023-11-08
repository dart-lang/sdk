// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';

/// The interface for the tags in a module.
class TagsBuilder with Builder<ir.Tags> {
  final List<ir.Tag> _tags = [];

  /// Defines a new tag in the module.
  ir.Tag define(ir.FunctionType type) {
    final tag = ir.Tag(_tags.length, type);
    _tags.add(tag);
    return tag;
  }

  @override
  ir.Tags forceBuild() => ir.Tags(_tags);
}
