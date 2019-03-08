// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart' show CompilationUnit;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:analyzer/src/summary2/ast_binary_writer.dart';
import 'package:analyzer/src/summary2/builder/source_library_builder.dart';
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/summary2/reference.dart';

LinkResult link(
  AnalysisContext analysisContext,
  AnalysisSession analysisSession,
  Reference rootReference,
  List<LinkedNodeBundle> inputs,
  Map<Source, Map<Source, CompilationUnit>> unitMap,
) {
  var linker = Linker(analysisContext, analysisSession, rootReference);
  linker.link(inputs, unitMap);
  return LinkResult(linker.linkingBundle);
}

class Linker {
  final AnalysisContext analysisContext;
  final AnalysisSession analysisSession;
  final Reference rootReference;
  LinkedElementFactory elementFactory;

  /// References used in all libraries being linked.
  /// Element references in [LinkedNode]s are indexes in this list.
  final List<Reference> references = [null];

  /// The references of the [linkingBundle].
  final LinkedNodeReferencesBuilder referencesBuilder =
      LinkedNodeReferencesBuilder(
    parent: [0],
    name: [''],
  );

  LinkedNodeBundleBuilder linkingBundle;

  /// Libraries that are being linked.
  final List<SourceLibraryBuilder> builders = [];

  TypeProvider typeProvider;
  Dart2TypeSystem typeSystem;

  Linker(this.analysisContext, this.analysisSession, this.rootReference) {
    elementFactory = LinkedElementFactory(
      analysisContext,
      analysisSession,
      rootReference,
    );
  }

  void addSyntheticConstructors() {
    for (var library in builders) {
      library.addSyntheticConstructors();
    }
  }

  void buildOutlines() {
    computeLibraryScopes();
    addSyntheticConstructors();
    createTypeSystem();
    resolveTypes();
    performTopLevelInference();
  }

  void computeLibraryScopes() {
    for (var library in builders) {
      library.addLocalDeclarations();
    }

    for (var library in builders) {
      library.buildInitialExportScope();
    }

    for (var library in builders) {
      library.addImportsToScope();
    }

    for (var library in builders) {
      library.storeExportScope();
    }

    // TODO(scheglov) process imports and exports
  }

  void createTypeSystem() {
    var coreRef = rootReference.getChild('dart:core');
    var coreLib = elementFactory.elementOfReference(coreRef);
    typeProvider = SummaryTypeProvider()..initializeCore(coreLib);

    typeSystem = Dart2TypeSystem(typeProvider);
  }

  int indexOfReference(Reference reference) {
    if (reference.parent == null) return 0;
    if (reference.index != null) return reference.index;

    var parentIndex = indexOfReference(reference.parent);
    referencesBuilder.parent.add(parentIndex);
    referencesBuilder.name.add(reference.name);

    reference.index = references.length;
    references.add(reference);
    return reference.index;
  }

  void link(List<LinkedNodeBundle> inputs,
      Map<Source, Map<Source, CompilationUnit>> unitMap) {
    for (var input in inputs) {
      elementFactory.addBundle(input);
    }

    var linkingLibraries = <LinkedNodeLibraryBuilder>[];
    linkingBundle = LinkedNodeBundleBuilder(
      references: referencesBuilder,
      libraries: linkingLibraries,
    );
    var bundleContext = LinkedBundleContext(
      elementFactory,
      linkingBundle.references,
    );

    for (var librarySource in unitMap.keys) {
      var libraryUriStr = librarySource.uri.toString();
      var libraryReference = rootReference.getChild(libraryUriStr);

      var units = <LinkedNodeUnitBuilder>[];
      var libraryNode = LinkedNodeLibraryBuilder(
        units: units,
        uriStr: libraryUriStr,
      );

      var libraryBuilder = SourceLibraryBuilder(
        this,
        elementFactory,
        librarySource.uri,
        libraryReference,
        libraryNode,
      );
      builders.add(libraryBuilder);

      var libraryUnits = unitMap[librarySource];
      for (var unitSource in libraryUnits.keys) {
        var unit = libraryUnits[unitSource];

        var writer = AstBinaryWriter();
        var unitData = writer.writeNode(unit);

        var unitContext = LinkedUnitContext(bundleContext, writer.tokens);
        libraryBuilder.addUnit(unitSource.uri, unitContext, unitData);

        libraryNode.units.add(
          LinkedNodeUnitBuilder(
            uriStr: '${unitSource.uri}',
            tokens: writer.tokens,
            node: unitData,
          ),
        );
      }
      linkingLibraries.add(libraryNode);
    }

    // Add libraries being linked, so we can ask for their elements as well.
    elementFactory.addBundle(linkingBundle, context: bundleContext);

    buildOutlines();
  }

  void performTopLevelInference() {
    for (var library in builders) {
      library.performTopLevelInference();
    }
  }

  void resolveTypes() {
    for (var library in builders) {
      library.resolveTypes();
    }
  }
}

class LinkResult {
  final LinkedNodeBundleBuilder bundle;

  LinkResult(this.bundle);
}
