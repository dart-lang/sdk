// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Element;
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/services/flutter/widget_previews.dart';
import 'package:analyzer/dart/analysis/results.dart';

class FlutterWidgetPreviewsHandler
    extends
        SharedMessageHandler<TextDocumentIdentifier, FlutterWidgetPreviews?> {
  FlutterWidgetPreviewsHandler(super.server);

  @override
  Method get handlesMessage => CustomMethods.getFlutterWidgetPreviews;

  @override
  LspJsonHandler<TextDocumentIdentifier> get jsonHandler =>
      TextDocumentIdentifier.jsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<FlutterWidgetPreviews?>> handle(
    TextDocumentIdentifier params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    var lspServer = server as LspAnalysisServer;
    var path = pathOfDoc(params);
    if (path.isError) {
      return failure(path);
    }

    var pathResult = path.resultOrNull!;
    var result = await lspServer.getResolvedUnit(pathResult);
    if (result == null) {
      return success(null);
    }

    var graph = <Uri, LibraryPreviewNode>{};
    var processed = <Uri>{};
    var flutterWidgetPreviewDetector = FlutterWidgetPreviewDetector();

    // Build a graph starting from this library to track dependencies and errors.
    Future<void> buildGraph(ResolvedUnitResult unit) async {
      var fileUri = unit.uri;
      if (processed.contains(fileUri)) return;
      processed.add(fileUri);

      // Scan all units in the library.
      var libraryElement = unit.libraryElement;
      for (var unitPath in libraryElement.fragments.map(
        (f) => f.source.fullName,
      )) {
        var resolvedUnit = await lspServer.getResolvedUnit(unitPath);
        if (resolvedUnit != null) {
          flutterWidgetPreviewDetector.findPreviews(resolvedUnit, graph: graph);
        }
      }

      var node = graph[libraryElement.uri]!;
      for (var dependency in node.dependsOn) {
        if (processed.contains(dependency.uri)) continue;

        var depPath = dependency.path;
        var driver = lspServer.getAnalysisDriver(depPath);
        if (driver == null || !driver.addedFiles.contains(depPath)) {
          continue;
        }

        var depResult = await lspServer.getResolvedUnit(depPath);
        if (depResult != null) {
          await buildGraph(depResult);
        }
      }
    }

    await buildGraph(result);
    flutterWidgetPreviewDetector.propagateErrors(graph);

    var node = graph[result.libraryElement.uri]!;
    return success(
      FlutterWidgetPreviews(
        scriptUris: node.previews.map((e) => e.scriptUri).toSet().toList(),
        previews: node.previews,
        namespaces: flutterWidgetPreviewDetector.namespaces,
      ),
    );
  }
}

class WorkspaceFlutterWidgetPreviewsHandler
    extends SharedMessageHandler<void, FlutterWidgetPreviews?> {
  WorkspaceFlutterWidgetPreviewsHandler(super.server);

  @override
  Method get handlesMessage => CustomMethods.getWorkspaceFlutterWidgetPreviews;

  @override
  LspJsonHandler<void> get jsonHandler => nullJsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<FlutterWidgetPreviews?>> handle(
    void _,
    MessageInfo message,
    CancellationToken token,
  ) async {
    var lspServer = server as LspAnalysisServer;
    var graph = <Uri, LibraryPreviewNode>{};
    var processedLibraries = <Uri>{};
    var flutterWidgetPreviewDetector = FlutterWidgetPreviewDetector();

    for (var driver in lspServer.driverMap.values) {
      for (var file in driver.addedFiles) {
        var libraryResult = await lspServer.getResolvedLibrary(file);
        if (libraryResult != null) {
          var uri = libraryResult.element.uri;
          if (processedLibraries.contains(uri)) continue;
          processedLibraries.add(uri);

          for (var unit in libraryResult.units) {
            flutterWidgetPreviewDetector.findPreviews(unit, graph: graph);
          }
        }
      }
    }

    flutterWidgetPreviewDetector.propagateErrors(graph);

    var allPreviews = <FlutterWidgetPreviewDetails>[];
    var allScriptUris = <Uri>{};

    for (var node in graph.values) {
      allPreviews.addAll(node.previews);
      for (var preview in node.previews) {
        allScriptUris.add(preview.scriptUri);
      }
    }

    return success(
      FlutterWidgetPreviews(
        namespaces: flutterWidgetPreviewDetector.namespaces,
        previews: allPreviews,
        scriptUris: allScriptUris.toList(),
      ),
    );
  }
}
