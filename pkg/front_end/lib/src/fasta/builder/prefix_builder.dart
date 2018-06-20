// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.prefix_builder;

import 'builder.dart' show Declaration, LibraryBuilder, Scope;

class PrefixBuilder extends Declaration {
  final String name;

  final Scope exportScope = new Scope.top();

  final LibraryBuilder parent;

  final bool deferred;

  @override
  final int charOffset;

  final int importIndex;

  PrefixBuilder(
      this.name, this.deferred, this.parent, this.charOffset, this.importIndex);

  Uri get fileUri => parent.fileUri;

  Declaration lookup(String name, int charOffset, Uri fileUri) {
    return exportScope.lookup(name, charOffset, fileUri);
  }

  void addToExportScope(String name, Declaration member, int charOffset) {
    Map<String, Declaration> map =
        member.isSetter ? exportScope.setters : exportScope.local;
    Declaration existing = map[name];
    if (existing != null) {
      map[name] = parent.computeAmbiguousDeclaration(
          name, existing, member, charOffset,
          isExport: true);
    } else {
      map[name] = member;
    }
  }

  @override
  String get fullNameForErrors => name;
}
