// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'type.dart';

class Types {
  /// Types defined in this module.
  final List<List<DefType>> recursionGroups;

  late final List<DefType> defined;

  Types(this.recursionGroups)
      : defined = recursionGroups.expand((g) => g).toList();

  DefType operator [](int index) => defined[index];

  int get length => defined.length;
}
