// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart' show CompilationUnit;
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary2/ast_binary_writer.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/linking_bundle_context.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/summary2/simply_bounded.dart';
import 'package:analyzer/src/summary2/top_level_inference.dart';
import 'package:analyzer/src/summary2/type_alias.dart';
import 'package:analyzer/src/summary2/types_builder.dart';

var timerLinkingLinkingBundle = Stopwatch();
var timerLinkingRemoveBundle = Stopwatch();

LinkResult link(
  LinkedElementFactory elementFactory,
  List<LinkInputLibrary> inputLibraries,
) {
  var linker = Linker(elementFactory);
  linker.link(inputLibraries);
  return LinkResult(linker.linkingBundle);
}

class Linker {
  final LinkedElementFactory elementFactory;

  LinkedNodeBundleBuilder linkingBundle;
  LinkedBundleContext bundleContext;
  LinkingBundleContext linkingBundleContext;

  /// Libraries that are being linked.
  final Map<Uri, LibraryBuilder> builders = {};

  InheritanceManager3 inheritance; // TODO(scheglov) cache it

  Linker(this.elementFactory) {
    linkingBundleContext = LinkingBundleContext(
      elementFactory.dynamicRef,
    );

    bundleContext = LinkedBundleContext.forAst(
      elementFactory,
      linkingBundleContext.references,
    );
  }

  AnalysisContextImpl get analysisContext {
    return elementFactory.analysisContext;
  }

  DeclaredVariables get declaredVariables {
    return analysisContext.declaredVariables;
  }

  Reference get rootReference => elementFactory.rootReference;

  void link(List<LinkInputLibrary> inputLibraries) {
    for (var inputLibrary in inputLibraries) {
      LibraryBuilder.build(this, inputLibrary);
    }
    // TODO(scheglov) do in build() ?
    elementFactory.addBundle(bundleContext);

    _buildOutlines();

    timerLinkingLinkingBundle.start();
    _createLinkingBundle();
    timerLinkingLinkingBundle.stop();

    timerLinkingRemoveBundle.start();
    linkingBundleContext.clearIndexes();
    elementFactory.removeBundle(bundleContext);
    timerLinkingRemoveBundle.stop();
  }

  void _buildOutlines() {
    _resolveUriDirectives();
    _computeLibraryScopes();
    _createTypeSystem();
    _resolveTypes();
    TypeAliasSelfReferenceFinder().perform(this);
    _performTopLevelInference();
    _resolveConstructors();
    _resolveConstantInitializers();
    _resolveDefaultValues();
    _resolveMetadata();
    _collectMixinSuperInvokedNames();
  }

  void _collectMixinSuperInvokedNames() {
    for (var library in builders.values) {
      library.collectMixinSuperInvokedNames();
    }
  }

  void _computeLibraryScopes() {
    for (var library in builders.values) {
      library.addLocalDeclarations();
    }

    for (var library in builders.values) {
      library.buildInitialExportScope();
    }

    var exporters = <LibraryBuilder>{};
    var exportees = <LibraryBuilder>{};

    for (var library in builders.values) {
      library.addExporters();
    }

    for (var library in builders.values) {
      if (library.exporters.isNotEmpty) {
        exportees.add(library);
        for (var exporter in library.exporters) {
          exporters.add(exporter.exporter);
        }
      }
    }

    var both = <LibraryBuilder>{};
    for (var exported in exportees) {
      if (exporters.contains(exported)) {
        both.add(exported);
      }
      for (var export in exported.exporters) {
        exported.exportScope.forEach(export.addToExportScope);
      }
    }

    while (true) {
      var hasChanges = false;
      for (var exported in both) {
        for (var export in exported.exporters) {
          exported.exportScope.forEach((name, member) {
            if (export.addToExportScope(name, member)) {
              hasChanges = true;
            }
          });
        }
      }
      if (!hasChanges) break;
    }

    for (var library in builders.values) {
      library.storeExportScope();
    }

    for (var library in builders.values) {
      library.buildElement();
    }
  }

  void _createLinkingBundle() {
    var linkingLibraries = <LinkedNodeLibraryBuilder>[];
    for (var builder in builders.values) {
      linkingLibraries.add(builder.node);

      for (var unitContext in builder.context.units) {
        var unit = unitContext.unit;

        var writer = AstBinaryWriter(linkingBundleContext);
        var unitLinkedNode = writer.writeUnit(unit);
        builder.node.units.add(
          LinkedNodeUnitBuilder(
            isSynthetic: unitContext.isSynthetic,
            partUriStr: unitContext.partUriStr,
            uriStr: unitContext.uriStr,
            node: unitLinkedNode,
            isNNBD: unit.featureSet.isEnabled(Feature.non_nullable),
          ),
        );
      }
    }
    linkingBundle = LinkedNodeBundleBuilder(
      references: linkingBundleContext.referencesBuilder,
      libraries: linkingLibraries,
    );
  }

  void _createTypeSystem() {
    var coreLib = elementFactory.libraryOfUri('dart:core');
    var asyncLib = elementFactory.libraryOfUri('dart:async');
    elementFactory.createTypeProviders(coreLib, asyncLib);

    inheritance = InheritanceManager3();
  }

  void _performTopLevelInference() {
    TopLevelInference(this).infer();
  }

  void _resolveConstantInitializers() {
    ConstantInitializersResolver(this).perform();
  }

  void _resolveConstructors() {
    for (var library in builders.values) {
      library.resolveConstructors();
    }
  }

  void _resolveDefaultValues() {
    for (var library in builders.values) {
      library.resolveDefaultValues();
    }
  }

  void _resolveMetadata() {
    for (var library in builders.values) {
      library.resolveMetadata();
    }
  }

  void _resolveTypes() {
    var nodesToBuildType = NodesToBuildType();
    for (var library in builders.values) {
      library.resolveTypes(nodesToBuildType);
    }
    computeSimplyBounded(bundleContext, builders.values);
    TypesBuilder().build(nodesToBuildType);
  }

  void _resolveUriDirectives() {
    for (var library in builders.values) {
      library.resolveUriDirectives();
    }
  }
}

class LinkInputLibrary {
  final Source source;
  final List<LinkInputUnit> units;

  LinkInputLibrary(this.source, this.units);
}

class LinkInputUnit {
  final String partUriStr;
  final Source source;
  final bool isSynthetic;
  final CompilationUnit unit;

  LinkInputUnit(
    this.partUriStr,
    this.source,
    this.isSynthetic,
    this.unit,
  );
}

class LinkResult {
  final LinkedNodeBundleBuilder bundle;

  LinkResult(this.bundle);
}
