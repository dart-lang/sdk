// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.import;

import 'package:kernel/ast.dart' show LibraryDependency;

import 'builder/builder.dart' show Declaration, LibraryBuilder;

import 'kernel/kernel_builder.dart' show toKernelCombinators;

import 'kernel/kernel_prefix_builder.dart' show KernelPrefixBuilder;

import 'combinator.dart' show Combinator;

import 'configuration.dart' show Configuration;

class Import {
  /// The library that is importing [imported];
  final LibraryBuilder importer;

  /// The library being imported.
  final LibraryBuilder imported;

  final KernelPrefixBuilder prefixBuilder;

  final bool deferred;

  final String prefix;

  final List<Combinator> combinators;

  final List<Configuration> configurations;

  final int charOffset;

  final int prefixCharOffset;

  // The LibraryBuilder for the imported library ('imported') may be null when
  // this field is set.
  final String nativeImportPath;

  Import(
      this.importer,
      this.imported,
      this.deferred,
      this.prefix,
      this.combinators,
      this.configurations,
      this.charOffset,
      this.prefixCharOffset,
      int importIndex,
      {this.nativeImportPath})
      : prefixBuilder = createPrefixBuilder(prefix, importer, imported,
            combinators, deferred, charOffset, prefixCharOffset, importIndex);

  Uri get fileUri => importer.fileUri;

  void finalizeImports(LibraryBuilder importer) {
    if (nativeImportPath != null) return;
    void Function(String, Declaration) add;
    if (prefixBuilder == null) {
      add = (String name, Declaration member) {
        importer.addToScope(name, member, charOffset, true);
      };
    } else {
      add = (String name, Declaration member) {
        prefixBuilder.addToExportScope(name, member, charOffset);
      };
    }
    imported.exportScope.forEach((String name, Declaration member) {
      if (combinators != null) {
        for (Combinator combinator in combinators) {
          if (combinator.isShow && !combinator.names.contains(name)) return;
          if (combinator.isHide && combinator.names.contains(name)) return;
        }
      }
      add(name, member);
    });
    if (prefixBuilder != null) {
      Declaration existing =
          importer.addBuilder(prefix, prefixBuilder, charOffset);
      if (existing == prefixBuilder) {
        importer.addToScope(prefix, prefixBuilder, prefixCharOffset, true);
      }
    }
  }
}

KernelPrefixBuilder createPrefixBuilder(
    String prefix,
    LibraryBuilder importer,
    LibraryBuilder imported,
    List<Combinator> combinators,
    bool deferred,
    int charOffset,
    int prefixCharOffset,
    int importIndex) {
  if (prefix == null) return null;
  LibraryDependency dependency = null;
  if (deferred) {
    dependency = new LibraryDependency.deferredImport(imported.target, prefix,
        combinators: toKernelCombinators(combinators))
      ..fileOffset = charOffset;
  }
  return new KernelPrefixBuilder(
      prefix, deferred, importer, dependency, prefixCharOffset, importIndex);
}
