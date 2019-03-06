// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart' show CompilationUnit;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/ast_binary_writer.dart';
import 'package:analyzer/src/summary2/builder/library_builder.dart';
import 'package:analyzer/src/summary2/builder/source_library_builder.dart';
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/summary2/reference.dart';

LinkResult link(
  Reference rootReference,
  Map<Source, Map<Source, CompilationUnit>> unitMap,
) {
  var linker = Linker(rootReference);
  linker.link(unitMap);
  return LinkResult(linker.references, linker.libraryResults);
}

class LibraryLinkResult {
  final Source source;
  final Map<Source, UnitLinkResult> units;

  LibraryLinkResult(this.source, this.units);
}

class Linker {
  final Reference rootReference;

  /// References used in all libraries being linked.
  /// Element references in [LinkedNode]s are indexes in this list.
  final List<Reference> references = [null];

  /// The output results.
  var libraryResults = <Source, LibraryLinkResult>{};

  /// Libraries that are being linked, or are already linked.
  final Map<Uri, LibraryBuilder> builders = {};

  Linker(this.rootReference);

  void addBuilder(LibraryBuilder builder) {
    builders[builder.uri] = builder;
  }

  void addSyntheticConstructors() {
    for (var library in builders.values) {
      if (library is SourceLibraryBuilder) {
        library.addSyntheticConstructors();
      }
    }
  }

  void buildOutlines() {
    computeLibraryScopes();
    resolveTypes();
    addSyntheticConstructors();
  }

  void computeLibraryScopes() {
    for (var uri in builders.keys) {
      var library = builders[uri];
      library.buildInitialExportScope();
    }

    // TODO(scheglov) process imports and exports
  }

  void link(Map<Source, Map<Source, CompilationUnit>> unitMap) {
    var linkedBundleContext = LinkedBundleContext(references);
    for (var librarySource in unitMap.keys) {
      var libraryUriStr = librarySource.uri.toString();
      var libraryReference = rootReference.getChild(libraryUriStr);

      var unitResults = <Source, UnitLinkResult>{};
      libraryResults[librarySource] = LibraryLinkResult(
        librarySource,
        unitResults,
      );

      var libraryBuilder = SourceLibraryBuilder(
        this,
        linkedBundleContext,
        librarySource.uri,
        libraryReference,
      );
      addBuilder(libraryBuilder);

      var libraryUnits = unitMap[librarySource];
      for (var unitSource in libraryUnits.keys) {
        var unit = libraryUnits[unitSource];

        var writer = AstBinaryWriter();
        var unitData = writer.writeNode(unit);

        var unitLinkResult = UnitLinkResult(writer.tokens, unitData);
        unitResults[unitSource] = unitLinkResult;

        var linkedUnitContext = LinkedUnitContext(
          linkedBundleContext,
          writer.tokens,
        );
        libraryBuilder.addUnit(linkedUnitContext, unitData);
      }

      libraryBuilder.addLocalDeclarations();
    }

    buildOutlines();
  }

  void resolveTypes() {
    for (var uri in builders.keys) {
      var library = builders[uri];
      if (library is SourceLibraryBuilder) {
        library.resolveTypes();
      }
    }
  }
}

class LinkResult {
  /// Element references in [LinkedNode]s are indexes in this list.
  final List<Reference> references;

  final Map<Source, LibraryLinkResult> libraries;

  LinkResult(this.references, this.libraries);
}

class UnitLinkResult {
  final UnlinkedTokensBuilder tokens;
  final LinkedNodeBuilder node;

  UnitLinkResult(this.tokens, this.node);
}
