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
import 'package:analyzer/src/summary2/builder/source_library_builder.dart';
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/reference.dart';

LinkResult link(
  AnalysisOptions analysisOptions,
  SourceFactory sourceFactory,
  Reference rootReference,
  List<LinkedNodeBundle> inputs,
  Map<Source, Map<Source, CompilationUnit>> unitMap,
) {
  var linker = Linker(analysisOptions, sourceFactory, rootReference);
  linker.link(inputs, unitMap);
  return LinkResult(linker.linkingBundle);
}

class Linker {
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

  List<LinkedNodeLibraryBuilder> linkingLibraries = [];
  LinkedNodeBundleBuilder linkingBundle;
  LinkedBundleContext bundleContext;

  /// Libraries that are being linked.
  final List<SourceLibraryBuilder> builders = [];

  _AnalysisContextForLinking analysisContext;
  TypeProvider typeProvider;
  Dart2TypeSystem typeSystem;

  Linker(AnalysisOptions analysisOptions, SourceFactory sourceFactory,
      this.rootReference) {
    analysisContext = _AnalysisContextForLinking(
      analysisOptions,
      sourceFactory,
    );

    elementFactory = LinkedElementFactory(
      analysisContext,
      _AnalysisSessionForLinking(),
      rootReference,
    );

    linkingBundle = LinkedNodeBundleBuilder(
      references: referencesBuilder,
      libraries: linkingLibraries,
    );

    bundleContext = LinkedBundleContext(
      elementFactory,
      linkingBundle.references,
    );
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

    for (var librarySource in unitMap.keys) {
      SourceLibraryBuilder.build(this, librarySource, unitMap[librarySource]);
    }

    // Add libraries being linked, so we can ask for their elements as well.
    elementFactory.addBundle(linkingBundle, context: bundleContext);

    _buildOutlines();
  }

  void _addSyntheticConstructors() {
    for (var library in builders) {
      library.addSyntheticConstructors();
    }
  }

  void _buildOutlines() {
    _computeLibraryScopes();
    _addSyntheticConstructors();
    _createTypeSystem();
    _resolveTypes();
    _performTopLevelInference();
  }

  void _computeLibraryScopes() {
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

  void _createTypeSystem() {
    var coreRef = rootReference.getChild('dart:core');
    var coreLib = elementFactory.elementOfReference(coreRef);
    typeProvider = SummaryTypeProvider()..initializeCore(coreLib);
    analysisContext.typeProvider = typeProvider;

    typeSystem = Dart2TypeSystem(typeProvider);
    analysisContext.typeSystem = typeSystem;
  }

  void _performTopLevelInference() {
    for (var library in builders) {
      library.performTopLevelInference();
    }
  }

  void _resolveTypes() {
    for (var library in builders) {
      library.resolveTypes();
    }
  }
}

class LinkResult {
  final LinkedNodeBundleBuilder bundle;

  LinkResult(this.bundle);
}

class _AnalysisContextForLinking implements AnalysisContext {
  @override
  final AnalysisOptions analysisOptions;

  @override
  final SourceFactory sourceFactory;

  @override
  TypeProvider typeProvider;

  @override
  TypeSystem typeSystem;

  _AnalysisContextForLinking(this.analysisOptions, this.sourceFactory);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AnalysisSessionForLinking implements AnalysisSession {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
