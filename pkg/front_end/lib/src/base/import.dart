// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' show LibraryDependency;

import '../builder/builder.dart';
import '../builder/library_builder.dart';
import '../builder/name_iterator.dart';
import '../builder/prefix_builder.dart';
import '../source/source_library_builder.dart';
import 'combinator.dart' show CombinatorBuilder;
import 'configuration.dart' show Configuration;

class Import {
  /// The library being imported.
  CompilationUnit? importedCompilationUnit;

  final PrefixFragment? prefixFragment;

  final bool isAugmentationImport;

  final bool deferred;

  final String? prefix;

  final List<CombinatorBuilder>? combinators;

  final List<Configuration>? configurations;

  final int importOffset;

  final int prefixOffset;

  // The LibraryBuilder for the imported library ('imported') may be null when
  // this field is set.
  final String? nativeImportPath;

  /// The [LibraryDependency] node corresponding to this import.
  ///
  /// This set in [SourceLibraryBuilder._addDependencies].
  LibraryDependency? libraryDependency;

  Import(
      SourceCompilationUnit importer,
      this.importedCompilationUnit,
      this.isAugmentationImport,
      this.deferred,
      this.prefix,
      this.combinators,
      this.configurations,
      Uri fileUri,
      this.importOffset,
      this.prefixOffset,
      {this.nativeImportPath})
      : prefixFragment = createPrefixFragment(
            prefix,
            importer,
            importedCompilationUnit,
            combinators,
            deferred,
            fileUri,
            importOffset,
            prefixOffset);

  LibraryBuilder? get importedLibraryBuilder =>
      importedCompilationUnit?.libraryBuilder;

  void finalizeImports(SourceCompilationUnit importer) {
    if (nativeImportPath != null) return;

    void Function(String, Builder) add;

    PrefixFragment? prefixFragment = this.prefixFragment;
    if (prefixFragment == null) {
      add = (String name, Builder builder) {
        importer.addImportedBuilderToScope(
            name: name, builder: builder, charOffset: importOffset);
      };
    } else {
      if (importer.addPrefixFragment(
          prefixFragment.name, prefixFragment, prefixOffset)) {
        importer.addImportedBuilderToScope(
            name: prefixFragment.name,
            builder: prefixFragment.builder,
            charOffset: prefixOffset);
      }

      add = (String name, Builder member) {
        prefixFragment.builder.addToPrefixScope(name, member,
            importOffset: importOffset, prefixOffset: prefixOffset);
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
  }
}

PrefixFragment? createPrefixFragment(
    String? prefix,
    SourceCompilationUnit importer,
    CompilationUnit? imported,
    List<CombinatorBuilder>? combinators,
    bool deferred,
    Uri fileUri,
    int charOffset,
    int prefixCharOffset) {
  if (prefix == null) return null;
  return new PrefixFragment(
      name: prefix,
      importer: importer,
      imported: imported,
      combinators: combinators,
      deferred: deferred,
      fileUri: fileUri,
      importOffset: charOffset,
      prefixOffset: prefixCharOffset);
}
