// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.prefix_builder;

import '../builder/builder.dart' show Builder, LibraryBuilder, Scope;

class PrefixBuilder extends Builder {
  final String name;

  final Scope exportScope = new Scope.top();

  final LibraryBuilder parent;

  final bool deferred;

  @override
  final int charOffset;

  PrefixBuilder(this.name, this.deferred, this.parent, this.charOffset)
      : super(parent, charOffset, parent.fileUri);

  Builder lookup(String name, int charOffset, Uri fileUri) {
    return exportScope.lookup(name, charOffset, fileUri);
  }

  void addToExportScope(String name, Builder member, int charOffset) {
    Map<String, Builder> map =
        member.isSetter ? exportScope.setters : exportScope.local;
    Builder existing = map[name];
    if (existing != null) {
      map[name] = parent.buildAmbiguousBuilder(
          name, existing, member, charOffset,
          isExport: true);
    } else {
      map[name] = member;
    }
  }

  @override
  String get fullNameForErrors => name;
}
