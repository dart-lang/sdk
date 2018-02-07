// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.import;

import 'package:kernel/ast.dart' show LibraryDependency;

import 'builder/builder.dart' show Builder, LibraryBuilder, PrefixBuilder;

import 'kernel/kernel_builder.dart' show toKernelCombinators;

import 'combinator.dart' show Combinator;

import 'configuration.dart' show Configuration;

typedef void AddToScope(String name, Builder member);

class Import {
  /// The library that is importing [imported];
  final LibraryBuilder importer;

  /// The library being imported.
  final LibraryBuilder imported;

  final PrefixBuilder prefixBuilder;

  final bool deferred;

  final String prefix;

  final List<Combinator> combinators;

  final List<Configuration> configurations;

  final int charOffset;

  final int prefixCharOffset;

  // The LibraryBuilder for the imported library ('imported') may be null when
  // this field is set.
  final Uri nativeImportUri;

  Import(
      this.importer,
      this.imported,
      this.deferred,
      this.prefix,
      this.combinators,
      this.configurations,
      this.charOffset,
      this.prefixCharOffset,
      {this.nativeImportUri})
      : prefixBuilder = createPrefixBuilder(prefix, importer, imported,
            combinators, deferred, charOffset, prefixCharOffset);

  Uri get fileUri => importer.fileUri;

  void finalizeImports(LibraryBuilder importer) {
    if (nativeImportUri != null) return;
    AddToScope add;
    if (prefixBuilder == null) {
      add = (String name, Builder member) {
        importer.addToScope(name, member, charOffset, true);
      };
    } else {
      add = (String name, Builder member) {
        prefixBuilder.addToExportScope(name, member, charOffset);
      };
    }
    imported.exportScope.forEach((String name, Builder member) {
      if (combinators != null) {
        for (Combinator combinator in combinators) {
          if (combinator.isShow && !combinator.names.contains(name)) return;
          if (combinator.isHide && combinator.names.contains(name)) return;
        }
      }
      add(name, member);
    });
    if (prefixBuilder != null) {
      Builder existing = importer.addBuilder(prefix, prefixBuilder, charOffset);
      if (existing == prefixBuilder) {
        importer.addToScope(prefix, prefixBuilder, prefixCharOffset, true);
      }
    }
  }
}

createPrefixBuilder(
    String prefix,
    LibraryBuilder importer,
    LibraryBuilder imported,
    List<Combinator> combinators,
    bool deferred,
    int charOffset,
    int prefixCharOffset) {
  if (prefix == null) return null;
  LibraryDependency dependency = null;
  if (deferred) {
    dependency = new LibraryDependency.deferredImport(imported.target, prefix,
        combinators: toKernelCombinators(combinators))
      ..fileOffset = charOffset;
  }
  return new PrefixBuilder(
      prefix, deferred, importer, dependency, prefixCharOffset);
}
