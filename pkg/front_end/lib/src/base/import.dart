// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.import;

import 'package:kernel/ast.dart' show LibraryDependency;

import '../builder/builder.dart';
import '../builder/library_builder.dart';
import '../builder/name_iterator.dart';
import '../builder/prefix_builder.dart';
import '../kernel/load_library_builder.dart';
import '../kernel/utils.dart' show toKernelCombinators;
import '../source/source_library_builder.dart';
import 'combinator.dart' show CombinatorBuilder;
import 'configuration.dart' show Configuration;

class Import {
  /// The library being imported.
  CompilationUnit? importedCompilationUnit;

  final PrefixBuilder? prefixBuilder;

  final bool isAugmentationImport;

  final bool deferred;

  final String? prefix;

  final List<CombinatorBuilder>? combinators;

  final List<Configuration>? configurations;

  final int charOffset;

  final int prefixCharOffset;

  // The LibraryBuilder for the imported library ('imported') may be null when
  // this field is set.
  final String? nativeImportPath;

  /// The [LibraryDependency] node corresponding to this import.
  ///
  /// This set in [SourceLibraryBuilder._addDependencies].
  LibraryDependency? libraryDependency;

  Import(
      SourceLibraryBuilder importer,
      this.importedCompilationUnit,
      this.isAugmentationImport,
      this.deferred,
      this.prefix,
      this.combinators,
      this.configurations,
      this.charOffset,
      this.prefixCharOffset,
      int importIndex,
      {this.nativeImportPath})
      : prefixBuilder = createPrefixBuilder(
            prefix,
            importer,
            importedCompilationUnit,
            combinators,
            deferred,
            charOffset,
            prefixCharOffset,
            importIndex);

  LibraryBuilder? get importedLibraryBuilder =>
      importedCompilationUnit?.libraryBuilder;

  void finalizeImports(SourceCompilationUnit importer) {
    if (nativeImportPath != null) return;
    void Function(String, Builder) add;
    if (prefixBuilder == null) {
      add = (String name, Builder member) {
        importer.addToScope(name, member, charOffset, true);
      };
    } else {
      add = (String name, Builder member) {
        prefixBuilder!.addToExportScope(name, member, charOffset);
      };
    }
    NameIterator<Builder> iterator = importedLibraryBuilder!.exportNameSpace
        .filteredNameIterator(
            includeDuplicates: false, includeAugmentations: false);
    while (iterator.moveNext()) {
      String name = iterator.name;
      Builder member = iterator.current;
      bool include = true;
      if (combinators != null) {
        for (CombinatorBuilder combinator in combinators!) {
          if (combinator.isShow && !combinator.names.contains(name)) {
            include = false;
            break;
          }
          if (combinator.isHide && combinator.names.contains(name)) {
            include = false;
            break;
          }
        }
      }
      if (include) {
        add(name, member);
      }
    }
    if (prefixBuilder != null) {
      Builder? existing = importer.addBuilder(
          prefixBuilder!.name, prefixBuilder!, prefixCharOffset);
      if (existing == prefixBuilder) {
        importer.addToScope(prefix!, prefixBuilder!, prefixCharOffset, true);
      }
    }
  }
}

PrefixBuilder? createPrefixBuilder(
    String? prefix,
    SourceLibraryBuilder importer,
    CompilationUnit? imported,
    List<CombinatorBuilder>? combinators,
    bool deferred,
    int charOffset,
    int prefixCharOffset,
    int importIndex) {
  if (prefix == null) return null;
  LoadLibraryBuilder? loadLibraryBuilder;
  if (deferred) {
    loadLibraryBuilder = new LoadLibraryBuilder(importer, prefixCharOffset,
        imported!, prefix, charOffset, toKernelCombinators(combinators));
  }

  return new PrefixBuilder(prefix, deferred, importer, loadLibraryBuilder,
      prefixCharOffset, importIndex);
}
