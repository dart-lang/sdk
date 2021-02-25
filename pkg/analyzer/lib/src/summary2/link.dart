// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/ast/ast.dart' show CompilationUnit;
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary2/bundle_writer.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/summary2/simply_bounded.dart';
import 'package:analyzer/src/summary2/top_level_inference.dart';
import 'package:analyzer/src/summary2/type_alias.dart';
import 'package:analyzer/src/summary2/types_builder.dart';
import 'package:analyzer/src/summary2/variance_builder.dart';
import 'package:meta/meta.dart';

var timerLinkingLinkingBundle = Stopwatch();
var timerLinkingRemoveBundle = Stopwatch();

LinkResult link(
  LinkedElementFactory elementFactory,
  List<LinkInputLibrary> inputLibraries,
  bool withInformative,
) {
  var linker = Linker(elementFactory, withInformative);
  linker.link(inputLibraries);
  return LinkResult(
    astBytes: linker.astBytes,
    resolutionBytes: linker.resolutionBytes,
  );
}

class Linker {
  final LinkedElementFactory elementFactory;
  final bool withInformative;

  /// Libraries that are being linked.
  final Map<Uri, LibraryBuilder> builders = {};

  InheritanceManager3 inheritance; // TODO(scheglov) cache it

  BundleWriter bundleWriter;
  Uint8List astBytes;
  Uint8List resolutionBytes;

  Linker(this.elementFactory, this.withInformative);

  AnalysisContextImpl get analysisContext {
    return elementFactory.analysisContext;
  }

  DeclaredVariables get declaredVariables {
    return analysisContext.declaredVariables;
  }

  Reference get rootReference => elementFactory.rootReference;

  void link(List<LinkInputLibrary> inputLibraries) {
    bundleWriter = BundleWriter(
      withInformative,
      elementFactory.dynamicRef,
    );
    _writeAst(inputLibraries);

    for (var inputLibrary in inputLibraries) {
      LibraryBuilder.build(this, inputLibrary);
    }

    _buildOutlines();

    timerLinkingLinkingBundle.start();
    _writeResolution();
    timerLinkingLinkingBundle.stop();

    timerLinkingRemoveBundle.start();
    elementFactory.removeBundle(
      inputLibraries.map((e) => e.uriStr).toSet(),
    );
    timerLinkingRemoveBundle.stop();
  }

  void _buildOutlines() {
    _computeLibraryScopes();
    _createTypeSystem();
    _resolveTypes();
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
      library.buildElement();
    }

    for (var library in builders.values) {
      library.buildDirectives();
      library.addLocalDeclarations();
    }

    for (var library in builders.values) {
      library.resolveUriDirectives();
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
      library.buildScope();
    }
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
    VarianceBuilder().perform(this);
    computeSimplyBounded(builders.values);
    TypeAliasSelfReferenceFinder().perform(this);
    TypesBuilder().build(nodesToBuildType);
  }

  void _writeAst(List<LinkInputLibrary> inputLibraries) {
    for (var inputLibrary in inputLibraries) {
      bundleWriter.addLibraryAst(
        LibraryToWriteAst(
          units: inputLibrary.units.map((e) {
            return UnitToWriteAst(
              node: e.unit,
            );
          }).toList(),
        ),
      );
    }
  }

  void _writeResolution() {
    for (var builder in builders.values) {
      bundleWriter.addLibraryResolution(
        LibraryToWriteResolution(
          uriStr: '${builder.uri}',
          exports: builder.exports,
          units: builder.context.units.map((e) {
            return UnitToWriteResolution(
              uriStr: e.uriStr,
              partUriStr: e.partUriStr,
              node: e.unit,
              isSynthetic: e.isSynthetic,
            );
          }).toList(),
        ),
      );
    }

    var writeWriterResult = bundleWriter.finish();
    astBytes = writeWriterResult.astBytes;
    resolutionBytes = writeWriterResult.resolutionBytes;
  }
}

class LinkInputLibrary {
  final Source source;
  final List<LinkInputUnit> units;

  LinkInputLibrary(this.source, this.units);

  Uri get uri => source.uri;

  String get uriStr => '$uri';
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

  String get uriStr {
    if (source == null) {
      return '';
    }
    return '${source.uri}';
  }
}

class LinkResult {
  final Uint8List astBytes;
  final Uint8List resolutionBytes;

  LinkResult({
    @required this.astBytes,
    @required this.resolutionBytes,
  });
}
