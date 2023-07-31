// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../serialize/serialize.dart';

part 'type.dart';

class Types {
  /// Types defined in this module.
  final List<DefType> defined;

  /// Recursion group splits.
  final List<int> recursionGroupSplits;

  /// Name count.
  final int namedCount;

  Types(this.defined, this.recursionGroupSplits, this.namedCount);
}
