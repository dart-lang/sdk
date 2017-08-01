// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.prefix_builder;

import 'builder.dart' show Builder, LibraryBuilder, Scope;

class PrefixBuilder extends Builder {
  final String name;

  final Scope exportScope = new Scope.top();

  final LibraryBuilder parent;

  final bool deferred;

  @override
  final int charOffset;

  PrefixBuilder(this.name, this.deferred, LibraryBuilder parent, int charOffset)
      : parent = parent,
        charOffset = charOffset,
        super(parent, charOffset, parent.fileUri);

  Builder lookup(String name, int charOffset, Uri fileUri) {
    return exportScope.lookup(name, charOffset, fileUri);
  }

  @override
  String get fullNameForErrors => name;
}
