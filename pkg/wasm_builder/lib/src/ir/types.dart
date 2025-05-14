// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'type.dart';

class Types {
  /// Types defined in this module.
  final List<List<DefType>> recursionGroups;

  /// Number of types with names.
  final int namedCount;

  /// Number of types with field names.
  final int typesWithNamedFieldsCount;

  Types(this.recursionGroups, this.namedCount, this.typesWithNamedFieldsCount);
}
