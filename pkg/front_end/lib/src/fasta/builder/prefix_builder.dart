// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.prefix_builder;

import 'package:kernel/ast.dart' show LibraryDependency;

import '../kernel/load_library_builder.dart' show LoadLibraryBuilder;

import '../fasta_codes.dart';

import '../scope.dart';

import 'builder.dart';
import 'extension_builder.dart';
import 'library_builder.dart';

class PrefixBuilder extends BuilderImpl {
  final String name;

  final Scope exportScope = new Scope.top();

  final LibraryBuilder parent;

  final bool deferred;

  @override
  final int charOffset;

  final int importIndex;

  final LibraryDependency dependency;

  LoadLibraryBuilder loadLibraryBuilder;

  PrefixBuilder(this.name, this.deferred, this.parent, this.dependency,
      this.charOffset, this.importIndex) {
    if (deferred) {
      loadLibraryBuilder =
          new LoadLibraryBuilder(parent, dependency, charOffset);
      addToExportScope('loadLibrary', loadLibraryBuilder, charOffset);
    }
  }

  Uri get fileUri => parent.fileUri;

  Builder lookup(String name, int charOffset, Uri fileUri) {
    return exportScope.lookup(name, charOffset, fileUri);
  }

  void addToExportScope(String name, Builder member, int charOffset) {
    if (deferred && member is ExtensionBuilder) {
      parent.addProblem(templateDeferredExtensionImport.withArguments(name),
          charOffset, noLength, fileUri);
    }

    Builder existing =
        exportScope.lookupLocalMember(name, setter: member.isSetter);
    Builder result;
    if (existing != null) {
      result = parent.computeAmbiguousDeclaration(
          name, existing, member, charOffset,
          isExport: true);
    } else {
      result = member;
    }
    exportScope.addLocalMember(name, result, setter: member.isSetter);
    if (result is ExtensionBuilder) {
      exportScope.addExtension(result);
    }
  }

  @override
  String get fullNameForErrors => name;
}
