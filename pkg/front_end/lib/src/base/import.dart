// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart';

import '../builder/builder.dart';
import '../builder/compilation_unit.dart';
import '../builder/library_builder.dart';
import '../builder/prefix_builder.dart';
import '../source/source_library_builder.dart';
import 'combinator.dart' show CombinatorBuilder;
import 'configuration.dart' show Configuration;
import 'uri_offset.dart';

class Import({
  required SourceCompilationUnit importer,

  /// The library being imported.
  required var CompilationUnit? importedCompilationUnit,
  required final bool deferred,
  required final List<CombinatorBuilder>? combinators,
  required final List<Configuration>? configurations,
  required final UriOffsetLength importUriOffset,
  required final UriOffsetName? prefixUriOffsetName,

  /// The LibraryBuilder for the imported library ('imported') may be null when
  /// this field is set.
  final String? nativeImportPath,
}) {
  final PrefixFragment? prefixFragment;

  /// The [LibraryDependency] node corresponding to this import.
  ///
  /// This set in [SourceLibraryBuilder._addDependencies].
  LibraryDependency? libraryDependency;

  this
    : prefixFragment = createPrefixFragment(
        importer,
        importedCompilationUnit,
        combinators,
        deferred,
        importUriOffset,
        prefixUriOffsetName,
      );

  int get importOffset => importUriOffset.fileOffset;

  String? get prefix => prefixUriOffsetName?.name;

  int get prefixOffset => prefixUriOffsetName?.fileOffset ?? TreeNode.noOffset;

  LibraryBuilder? get importedLibraryBuilder =>
      importedCompilationUnit?.libraryBuilder;

  void finalizeImports(SourceCompilationUnit importer) {
    if (nativeImportPath != null) return;

    void Function(String, NamedBuilder) add;

    PrefixFragment? prefixFragment = this.prefixFragment;
    if (prefixFragment == null) {
      add = (String name, NamedBuilder builder) {
        importer.addImportedBuilderToScope(
          name: name,
          builder: builder,
          charOffset: importOffset,
        );
      };
    } else {
      if (importer.addPrefixFragment(
        prefixFragment.name,
        prefixFragment,
        prefixOffset,
      )) {
        importer.addImportedBuilderToScope(
          name: prefixFragment.name,
          builder: prefixFragment.builder,
          charOffset: prefixOffset,
        );
      }

      add = (String name, NamedBuilder member) {
        prefixFragment.builder.addToPrefixScope(
          name,
          member,
          importOffset: importOffset,
          prefixUriOffset: prefixFragment.uriOffset,
          prefixOffset: prefixOffset,
        );
      };
    }
    Iterator<NamedBuilder> iterator = importedLibraryBuilder!.exportNameSpace
        .filteredIterator();
    while (iterator.moveNext()) {
      NamedBuilder member = iterator.current;
      String name = member.name;
      bool include = true;
      if (combinators != null) {
        List<CombinatorBuilder> combinators = this.combinators!;
        for (int i = 0; i < combinators.length; i++) {
          CombinatorBuilder combinator = combinators[i];
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
  SourceCompilationUnit importer,
  CompilationUnit? imported,
  List<CombinatorBuilder>? combinators,
  bool deferred,
  UriOffsetLength importUriOffset,
  UriOffsetName? prefixUriOffsetName,
) {
  if (prefixUriOffsetName == null) return null;
  return new PrefixFragment(
    importer: importer,
    imported: imported,
    combinators: combinators,
    deferred: deferred,
    importUriOffset: importUriOffset,
    prefixUriOffsetName: prefixUriOffsetName,
  );
}
