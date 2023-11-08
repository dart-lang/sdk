// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/plugin/result_converter.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/request_handler_mixin.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix/analysis_options/fix_generator.dart';
import 'package:analysis_server/src/services/correction/fix/pubspec/fix_generator.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/dart/analysis/results.dart' as engine;
import 'package:analyzer/src/exception/exception.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:yaml/yaml.dart';

/// The handler for the `edit.getFixes` request.
class EditGetFixesHandler extends LegacyHandler
    with RequestHandlerMixin<LegacyAnalysisServer> {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  EditGetFixesHandler(
      super.server, super.request, super.cancellationToken, super.performance);

  @override
  Future<void> handle() async {
    var params = EditGetFixesParams.fromRequest(request);
    var file = params.file;
    var offset = params.offset;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    if (!server.isAnalyzed(file)) {
      server.sendResponse(Response.getFixesInvalidFile(request));
      return;
    }

    //
    // Allow plugins to start computing fixes.
    //
    var requestParams = plugin.EditGetFixesParams(file, offset);
    var driver = server.getAnalysisDriver(file);
    var pluginFutures = server.broadcastRequestToPlugins(requestParams, driver);
    //
    // Compute fixes associated with server-generated errors.
    //
    List<AnalysisErrorFixes>? errorFixesList;
    while (errorFixesList == null) {
      try {
        errorFixesList = await _computeServerErrorFixes(request, file, offset);
      } on InconsistentAnalysisException {
        // Loop around to try again to compute the fixes.
      }
    }
    //
    // Add the fixes produced by plugins to the server-generated fixes.
    //
    var responses =
        await waitForResponses(pluginFutures, requestParameters: requestParams);
    server.requestStatistics?.addItemTimeNow(request, 'pluginResponses');
    var converter = ResultConverter();
    for (var response in responses) {
      var result = plugin.EditGetFixesResult.fromResponse(response);
      errorFixesList
          .addAll(result.fixes.map(converter.convertAnalysisErrorFixes));
    }
    //
    // Send the response.
    //
    sendResult(EditGetFixesResult(errorFixesList));
  }

  /// Compute and return the fixes associated with server-generated errors in
  /// analysis options files.
  Future<List<AnalysisErrorFixes>> _computeAnalysisOptionsFixes(
      String file, int offset) async {
    var errorFixesList = <AnalysisErrorFixes>[];
    var resourceProvider = server.resourceProvider;
    var optionsFile = resourceProvider.getFile(file);
    var content = _safelyRead(optionsFile);
    if (content == null) {
      return errorFixesList;
    }
    var driver = server.getAnalysisDriver(file);
    if (driver == null) {
      return errorFixesList;
    }
    await driver.applyPendingFileChanges();
    var session = driver.currentSession;
    var sourceFactory = driver.sourceFactory;
    var analysisContext = session.analysisContext;
    var analysisOptions =
        analysisContext.getAnalysisOptionsForFile(optionsFile);
    var errors = analyzeAnalysisOptions(
      optionsFile.createSource(),
      content,
      sourceFactory,
      analysisContext.contextRoot.root.path,
      analysisOptions.sdkVersionConstraint,
    );
    var options = _getOptions(sourceFactory, content);
    if (options == null) {
      return errorFixesList;
    }
    for (var error in errors) {
      var generator = AnalysisOptionsFixGenerator(
          resourceProvider, error, content, options);
      var fixes = await generator.computeFixes();
      if (fixes.isNotEmpty) {
        fixes.sort(Fix.compareFixes);
        var lineInfo = LineInfo.fromContent(content);
        var result = engine.ErrorsResultImpl(
          session: session,
          file: optionsFile,
          uri: optionsFile.toUri(),
          lineInfo: lineInfo,
          isAugmentation: false,
          isLibrary: true,
          isPart: false,
          errors: errors,
        );
        var serverError = newAnalysisError_fromEngine(result, error);
        var errorFixes = AnalysisErrorFixes(serverError);
        errorFixesList.add(errorFixes);
        for (var fix in fixes) {
          errorFixes.fixes.add(fix.change);
        }
      }
    }
    return errorFixesList;
  }

  /// Compute and return the fixes associated with server-generated errors in
  /// Dart files.
  Future<List<AnalysisErrorFixes>> _computeDartFixes(
      Request request, String file, int offset) async {
    var errorFixesList = <AnalysisErrorFixes>[];
    var result = await server.getResolvedUnit(file);
    server.requestStatistics?.addItemTimeNow(request, 'resolvedUnit');
    if (result != null) {
      var lineInfo = result.lineInfo;
      var requestLine = lineInfo.getLocation(offset).lineNumber;
      for (var error in result.errors) {
        var errorLine = lineInfo.getLocation(error.offset).lineNumber;
        if (errorLine == requestLine) {
          var workspace = DartChangeWorkspace(
            await server.currentSessions,
          );
          var context = DartFixContextImpl(
              server.instrumentationService, workspace, result, error);

          List<Fix> fixes;
          try {
            fixes = await DartFixContributor().computeFixes(context);
          } on InconsistentAnalysisException {
            fixes = [];
          } catch (exception, stackTrace) {
            var parametersFile = '''
offset: $offset
error: $error
error.errorCode: ${error.errorCode}
''';
            throw CaughtExceptionWithFiles(exception, stackTrace, {
              file: result.content,
              'parameters': parametersFile,
            });
          }

          if (fixes.isNotEmpty) {
            fixes.sort(Fix.compareFixes);
            var serverError = newAnalysisError_fromEngine(result, error);
            var errorFixes = AnalysisErrorFixes(serverError);
            errorFixesList.add(errorFixes);
            for (var fix in fixes) {
              errorFixes.fixes.add(fix.change);
            }
          }
        }
      }
    }
    server.requestStatistics?.addItemTimeNow(request, 'computedFixes');
    return errorFixesList;
  }

  /// Compute and return the fixes associated with server-generated errors in
  /// pubspec.yaml files.
  Future<List<AnalysisErrorFixes>> _computePubspecFixes(
      String file, int offset) async {
    var errorFixesList = <AnalysisErrorFixes>[];
    var resourceProvider = server.resourceProvider;
    var pubspecFile = resourceProvider.getFile(file);
    var content = _safelyRead(pubspecFile);
    if (content == null) {
      return errorFixesList;
    }
    var session = await server.getAnalysisSession(file);
    if (session == null) {
      return errorFixesList;
    }

    YamlNode node;
    try {
      node = loadYamlNode(content);
    } catch (exception) {
      return errorFixesList;
    }
    if (node is! YamlMap) {
      return errorFixesList;
    }
    final analysisOptions =
        session.analysisContext.getAnalysisOptionsForFile(pubspecFile);
    final errors = validatePubspec(
      contents: node,
      source: pubspecFile.createSource(),
      provider: resourceProvider,
      analysisOptions: analysisOptions,
    );
    for (var error in errors) {
      var generator =
          PubspecFixGenerator(resourceProvider, error, content, node);
      var fixes = await generator.computeFixes();
      if (fixes.isNotEmpty) {
        fixes.sort(Fix.compareFixes);
        var lineInfo = LineInfo.fromContent(content);
        // TODO(pq) package:analyzer results are specific to *.dart files and we
        // shouldn't use them to represent errors in non-Dart files.
        // see: https://dart-review.googlesource.com/c/sdk/+/333588
        var result = engine.ErrorsResultImpl(
          session: session,
          file: pubspecFile,
          uri: pubspecFile.toUri(),
          lineInfo: lineInfo,
          isAugmentation: false,
          isLibrary: true,
          isPart: false,
          errors: errors,
        );
        var serverError = newAnalysisError_fromEngine(result, error);
        var errorFixes = AnalysisErrorFixes(serverError);
        errorFixesList.add(errorFixes);
        for (var fix in fixes) {
          errorFixes.fixes.add(fix.change);
        }
      }
    }
    return errorFixesList;
  }

  /// Compute and return the fixes associated with server-generated errors.
  Future<List<AnalysisErrorFixes>> _computeServerErrorFixes(
      Request request, String file, int offset) async {
    var pathContext = server.resourceProvider.pathContext;
    if (file_paths.isDart(pathContext, file)) {
      return _computeDartFixes(request, file, offset);
    } else if (file_paths.isAnalysisOptionsYaml(pathContext, file)) {
      return _computeAnalysisOptionsFixes(file, offset);
    } else if (file_paths.isPubspecYaml(pathContext, file)) {
      return _computePubspecFixes(file, offset);
    }
    return <AnalysisErrorFixes>[];
  }

  YamlMap? _getOptions(SourceFactory sourceFactory, String content) {
    var optionsProvider = AnalysisOptionsProvider(sourceFactory);
    try {
      return optionsProvider.getOptionsFromString(content);
    } on OptionsFormatException {
      return null;
    }
  }

  /// Return the contents of the [file], or `null` if the file does not exist or
  /// cannot be read.
  String? _safelyRead(File file) {
    try {
      return file.readAsStringSync();
    } on FileSystemException {
      return null;
    }
  }
}
