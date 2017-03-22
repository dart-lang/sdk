// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.mixed_accessor;

import 'builder.dart' show Builder, LibraryBuilder;

/// Represents the import of a getter and setter from two different libraries.
class MixedAccessor extends Builder {
  final Builder getter;
  final Builder setter;

  MixedAccessor(this.getter, this.setter, LibraryBuilder parent)
      : super(
            parent,
            -1, // Synthetic element has no charOffset.
            parent.fileUri) {
    next = getter;
  }

  @override
  String get fullNameForErrors => getter.fullNameForErrors;
}
