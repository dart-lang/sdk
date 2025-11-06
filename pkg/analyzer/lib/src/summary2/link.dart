// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/name_union.dart';
import 'package:analyzer/src/fine/library_manifest.dart';
import 'package:analyzer/src/fine/requirements.dart';
import 'package:analyzer/src/summary2/bundle_writer.dart';
import 'package:analyzer/src/summary2/detach_nodes.dart';
import 'package:analyzer/src/summary2/enclosing_type_parameters_flag.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/summary2/simply_bounded.dart';
import 'package:analyzer/src/summary2/super_constructor_resolver.dart';
import 'package:analyzer/src/summary2/top_level_inference.dart';
import 'package:analyzer/src/summary2/type_alias.dart';
import 'package:analyzer/src/summary2/types_builder.dart';
import 'package:analyzer/src/summary2/variance_builder.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/uri_cache.dart';

LinkResult link({
  required LinkedElementFactory elementFactory,
  required OperationPerformanceImpl performance,
  required List<LibraryFileKind> inputLibraries,
  required String apiSignature,
}) {
  var linker = Linker(
    elementFactory: elementFactory,
    apiSignature: apiSignature,
  );
  linker.link(performance: performance, inputLibraries: inputLibraries);

  return LinkResult(resolutionBytes: linker.resolutionBytes);
}

class Linker {
  final LinkedElementFactory elementFactory;
  final String apiSignature;

  /// Libraries that are being linked.
  final Map<Uri, LibraryBuilder> builders = {};

  final Map<Object, ast.AstNode> elementNodes = Map.identity();

  late InheritanceManager3 inheritance; // TODO(scheglov): cache it

  Map<Uri, LibraryManifest> newLibraryManifests = {};
  late Uint8List resolutionBytes;

  Linker({required this.elementFactory, required this.apiSignature});

  AnalysisContextImpl get analysisContext {
    return elementFactory.analysisContext;
  }

  DeclaredVariables get declaredVariables {
    return analysisContext.declaredVariables;
  }

  Reference get rootReference => elementFactory.rootReference;

  bool get _isLinkingDartCore {
    var dartCoreUri = uriCache.parse('dart:core');
    return builders.containsKey(dartCoreUri);
  }

  /// If the [element] is part of a library being linked, return the node
  /// from which it was created.
  ast.AstNode? getLinkingNode(FragmentImpl element) {
    return elementNodes[element];
  }

  /// If the [fragment] is part of a library being linked, return the node
  /// from which it was created.
  ast.AstNode? getLinkingNode2(Fragment fragment) {
    return elementNodes[fragment];
  }

  bool isLinkingElement(Element element) {
    return builders.containsKey(element.library?.uri);
  }

  void link({
    required OperationPerformanceImpl performance,
    required List<LibraryFileKind> inputLibraries,
  }) {
    performance.run('LibraryBuilder.build', (performance) {
      for (var inputLibrary in inputLibraries) {
        LibraryBuilder.build(
          linker: this,
          inputLibrary: inputLibrary,
          performance: performance,
        );
      }
    });

    performance.run('buildOutlines', (performance) {
      _buildOutlines(performance: performance);
    });

    performance.run('writeLibraries', (performance) {
      _writeLibraries(performance: performance);
    });
  }

  void _buildClassSyntheticConstructors() {
    for (var library in builders.values) {
      library.buildClassSyntheticConstructors();
    }
  }

  void _buildElementNameUnions() {
    for (var builder in builders.values) {
      var element = builder.element;
      element.nameUnion = ElementNameUnion.forLibrary(element);
    }
  }

  void _buildEnumChildren() {
    for (var library in builders.values) {
      library.buildEnumChildren();
    }
  }

  void _buildEnumSyntheticConstructors() {
    for (var library in builders.values) {
      library.buildEnumSyntheticConstructors();
    }
  }

  void _buildExportScopes() {
    for (var library in builders.values) {
      library.buildInitialExportScope();
    }

    var exportingBuilders = <LibraryBuilder>{};
    var exportedBuilders = <LibraryBuilder>{};

    for (var library in builders.values) {
      library.addExporters();
    }

    for (var library in builders.values) {
      if (library.exports.isNotEmpty) {
        exportedBuilders.add(library);
        for (var export in library.exports) {
          exportingBuilders.add(export.exporter);
        }
      }
    }

    var both = <LibraryBuilder>{};
    for (var exported in exportedBuilders) {
      if (exportingBuilders.contains(exported)) {
        both.add(exported);
      }
      for (var export in exported.exports) {
        exported.exportScope.forEach(export.addToExportScope);
      }
    }

    // We keep a queue of exports to propagate.
    // First we loop over every reference that both exports and is exported,
    // but then we only process the exports that should be propagated.
    var additionalExportData = <_AdditionalExport>[];

    void addExport(Export export, String name, ExportedReference reference) {
      if (export.addToExportScope(name, reference)) {
        // We've added [name] to [export.exporter]s export scope.
        // We need to propagate that to anyone that exports that library.
        additionalExportData.add(
          _AdditionalExport(export.exporter, name, reference),
        );
      }
    }

    for (var exported in both) {
      for (var export in exported.exports) {
        exported.exportScope.forEach((name, reference) {
          addExport(export, name, reference);
        });
      }
    }

    while (additionalExportData.isNotEmpty) {
      var data = additionalExportData.removeLast();
      for (var export in data.exported.exports) {
        addExport(export, data.name, data.reference);
      }
    }

    assert(() {
      for (var exported in both) {
        for (var export in exported.exports) {
          exported.exportScope.forEach((name, reference) {
            if (export.addToExportScope(name, reference)) {
              throw "Error in export calculation: Assert failed.";
            }
          });
        }
      }
      return true;
    }(), true);

    for (var library in builders.values) {
      library.storeExportScope();
    }
  }

  void _buildOutlines({required OperationPerformanceImpl performance}) {
    _createTypeSystemIfNotLinkingDartCore();

    performance.run('computeLibraryScopes', (performance) {
      _computeLibraryScopes(performance: performance);
    });

    globalResultRequirements?.addExcludedLibraries(
      builders.values.map((builder) => builder.uri),
    );

    _createTypeSystem();
    _resolveTypes();
    _computeHasNonFinalField();
    _setDefaultSupertypes();

    _buildClassSyntheticConstructors();
    _buildEnumSyntheticConstructors();
    _replaceConstFieldsIfNoConstConstructor();
    _resolveConstructorFieldFormals();
    _buildEnumChildren();
    _computeFieldPromotability();
    SuperConstructorResolver(this).perform();
    _performTopLevelInference();
    _resolveConstructors();
    _resolveConstantInitializers();
    _resolveDefaultValues();
    _resolveMetadata();

    _collectMixinSuperInvokedNames();
    EnclosingTypeParameterReferenceFlag(this).perform();
    _buildElementNameUnions();
    _detachNodes();
  }

  void _collectMixinSuperInvokedNames() {
    for (var library in builders.values) {
      library.collectMixinSuperInvokedNames();
    }
  }

  void _computeFieldPromotability() {
    for (var library in builders.values) {
      library.computeFieldPromotability();
    }
  }

  /// Set [InterfaceElementImpl.hasNonFinalField] for classes and mixins.
  ///
  /// We actually use it only for classes (which can have `const` constructors),
  /// but mixins contribute to it.
  void _computeHasNonFinalField() {
    var linkingElements = builders.values
        .expand((builder) => builder.element.children)
        .whereType<InterfaceElementImpl>()
        .toSet();

    var alreadyComputed = Set<InterfaceElementImpl>.identity();

    bool computeFor(InterfaceElementImpl element) {
      if (!linkingElements.contains(element) || !alreadyComputed.add(element)) {
        return element.hasNonFinalField;
      }

      var hasNonFinalField = [
        element.supertype,
        ...element.mixins,
      ].nonNulls.any((type) => computeFor(type.element));

      hasNonFinalField |= element.fields.any((field) {
        return !field.isFinal &&
            !field.isConst &&
            !field.isStatic &&
            !field.isSynthetic;
      });

      return element.hasNonFinalField = hasNonFinalField;
    }

    for (var element in linkingElements) {
      computeFor(element);
    }
  }

  void _computeLibraryScopes({required OperationPerformanceImpl performance}) {
    globalResultRequirements.untracked(
      reason: 'No complete elements yet',
      operation: () {
        for (var library in builders.values) {
          library.buildElements();
        }
      },
    );

    _buildExportScopes();
  }

  void _createTypeSystem() {
    elementFactory.createTypeProviders(
      elementFactory.dartCoreElement,
      elementFactory.dartAsyncElement,
    );

    inheritance = InheritanceManager3();
  }

  /// To resolve macro annotations we need to access exported namespaces of
  /// imported (and already linked) libraries. While computing it we might
  /// need `Null` from `dart:core` (to convert null safe types to legacy).
  void _createTypeSystemIfNotLinkingDartCore() {
    if (!_isLinkingDartCore) {
      _createTypeSystem();
    }
  }

  void _detachNodes() {
    for (var builder in builders.values) {
      detachElementsFromNodes(builder.element);
    }
  }

  void _performTopLevelInference() {
    TopLevelInference(this).infer();
  }

  void _replaceConstFieldsIfNoConstConstructor() {
    for (var library in builders.values) {
      library.replaceConstFieldsIfNoConstConstructor();
    }
  }

  void _resolveConstantInitializers() {
    ConstantInitializersResolver(this).perform();
  }

  void _resolveConstructorFieldFormals() {
    for (var library in builders.values) {
      library.resolveConstructorFieldFormals();
    }
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
    VarianceBuilder(this).perform();
    computeSimplyBounded(this);
    TypeAliasSelfReferenceFinder().perform(this);
    TypesBuilder(this).build(nodesToBuildType);
  }

  void _setDefaultSupertypes() {
    for (var library in builders.values) {
      library.setDefaultSupertypes();
    }
  }

  void _writeLibraries({required OperationPerformanceImpl performance}) {
    var bundleWriter = BundleWriter();

    for (var builder in builders.values) {
      bundleWriter.writeLibraryElement(builder.element);
    }

    var writeWriterResult = performance.run('bundleWriteFinish', (performance) {
      return bundleWriter.finish();
    });
    resolutionBytes = writeWriterResult.resolutionBytes;

    performance.getDataInt('length').add(resolutionBytes.length);
  }
}

class LinkResult {
  final Uint8List resolutionBytes;

  LinkResult({required this.resolutionBytes});
}

class _AdditionalExport {
  final LibraryBuilder exported;
  final String name;
  final ExportedReference reference;

  _AdditionalExport(this.exported, this.name, this.reference);
}
