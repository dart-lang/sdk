// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.prefix_builder;

import 'builder.dart' show Builder, LibraryBuilder;

class PrefixBuilder extends Builder {
  final String name;

  final Map<String, Builder> exports;

  final LibraryBuilder parent;

  PrefixBuilder(this.name, this.exports, LibraryBuilder parent, int charOffset)
      : parent = parent,
        super(parent, charOffset, parent.fileUri);

  Builder lookup(String name, int charOffset, Uri fileUri) {
    return exports[name];
  }

  @override
  String get fullNameForErrors => name;
}
