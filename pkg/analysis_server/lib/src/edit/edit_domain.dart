// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/collections.dart';
import 'package:analysis_server/src/computer/import_elements_computer.dart';
import 'package:analysis_server/src/domain_abstract.dart';
import 'package:analysis_server/src/edit/edit_dartfix.dart' show EditDartFix;
import 'package:analysis_server/src/edit/fix/dartfix_info.dart' show allFixes;
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/plugin/result_converter.dart';
import 'package:analysis_server/src/protocol_server.dart'
    hide AnalysisError, Element;
import 'package:analysis_server/src/services/completion/postfix/postfix_completion.dart';
import 'package:analysis_server/src/services/completion/statement/statement_completion.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix/analysis_options/fix_generator.dart';
import 'package:analysis_server/src/services/correction/fix/dart/top_level_declarations.dart';
import 'package:analysis_server/src/services/correction/fix/manifest/fix_generator.dart';
import 'package:analysis_server/src/services/correction/fix/pubspec/fix_generator.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analysis_server/src/services/correction/organize_imports.dart';
import 'package:analysis_server/src/services/correction/sort_members.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' as engine;
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/results.dart' as engine;
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart' as engine;
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/exception/exception.dart';
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart' as engine;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/manifest/manifest_validator.dart';
import 'package:analyzer/src/manifest/manifest_values.dart';
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:dart_style/dart_style.dart';
import 'package:html/parser.dart';
import 'package:yaml/yaml.dart';

int test_resetCount = 0;

bool test_simulateRefactoringException_change = false;
bool test_simulateRefactoringException_final = false;
bool test_simulateRefactoringException_init = false;

bool test_simulateRefactoringReset_afterCreateChange = false;
bool test_simulateRefactoringReset_afterFinalConditions = false;
bool test_simulateRefactoringReset_afterInitialConditions = false;

/// Instances of the class [EditDomainHandler] implement a [RequestHandler]
/// that handles requests in the edit domain.
class EditDomainHandler extends AbstractRequestHandler {
  /// The [SearchEngine] for this server.
  SearchEngine searchEngine;

  /// The workspace for rename refactorings.
  RefactoringWorkspace refactoringWorkspace;

  /// The object used to manage uncompleted refactorings.
  _RefactoringManager refactoringManager;

  /// Initialize a newly created handler to handle requests for the given
  /// [server].
  EditDomainHandler(AnalysisServer server) : super(server) {
    searchEngine = server.searchEngine;
    refactoringWorkspace =
        RefactoringWorkspace(server.driverMap.values, searchEngine);
    _newRefactoringManager();
  }

  Future bulkFixes(Request request) async {
    //
    // Compute bulk fixes
    //
    try {
      var params = EditBulkFixesParams.fromRequest(request);
      for (var file in params.included) {
        if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
          return;
        }
      }

      var workspace = DartChangeWorkspace(server.currentSessions);
      var processor =
          BulkFixProcessor(server.instrumentationService, workspace);

      String sdkPath;
      var sdk = server.findSdk();
      if (sdk is FolderBasedDartSdk) {
        sdkPath = sdk.directory.path;
      }
      var collection = AnalysisContextCollectionImpl(
        includedPaths: params.included,
        resourceProvider: server.resourceProvider,
        sdkPath: sdkPath,
      );
      var changeBuilder = await processor.fixErrors(collection.contexts);

      var response = EditBulkFixesResult(
              changeBuilder.sourceChange.edits, processor.fixDetails)
          .toResponse(request.id);
      server.sendResponse(response);
    } catch (exception, stackTrace) {
      server.sendServerErrorNotification('Exception while getting bulk fixes',
          CaughtException(exception, stackTrace), stackTrace);
    }
  }

  Future dartfix(Request request) async {
    // TODO(danrubel): Add support for dartfix plugins

    //
    // Compute fixes
    //
    try {
      var dartFix = EditDartFix(server, request);
      var response = await dartFix.compute();

      server.sendResponse(response);
    } catch (exception, stackTrace) {
      server.sendServerErrorNotification('Exception while running dartfix',
          CaughtException(exception, stackTrace), stackTrace);
    }
  }

  Response format(Request request) {
    server.options.analytics?.sendEvent('edit', 'format');

    var params = EditFormatParams.fromRequest(request);
    var file = params.file;

    String unformattedCode;
    try {
      var resource = server.resourceProvider.getFile(file);
      unformattedCode = resource.readAsStringSync();
    } catch (e) {
      return Response.formatInvalidFile(request);
    }

    var start = params.selectionOffset;
    var length = params.selectionLength;

    // No need to preserve 0,0 selection
    if (start == 0 && length == 0) {
      start = null;
      length = null;
    }

    var code = SourceCode(unformattedCode,
        uri: null,
        isCompilationUnit: true,
        selectionStart: start,
        selectionLength: length);
    var formatter = DartFormatter(pageWidth: params.lineLength);
    SourceCode formattedResult;
    try {
      formattedResult = formatter.formatSource(code);
    } on FormatterException {
      return Response.formatWithErrors(request);
    }
    var formattedSource = formattedResult.text;

    var edits = <SourceEdit>[];

    if (formattedSource != unformattedCode) {
      //TODO: replace full replacements with smaller, more targeted edits
      var edit = SourceEdit(0, unformattedCode.length, formattedSource);
      edits.add(edit);
    }

    var newStart = formattedResult.selectionStart;
    var newLength = formattedResult.selectionLength;

    // Sending null start/length values would violate protocol, so convert back
    // to 0.
    newStart ??= 0;
    newLength ??= 0;

    return EditFormatResult(edits, newStart, newLength).toResponse(request.id);
  }

  Future getAssists(Request request) async {
    var params = EditGetAssistsParams.fromRequest(request);
    var file = params.file;
    var offset = params.offset;
    var length = params.length;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    //
    // Allow plugins to start computing assists.
    //
    Map<PluginInfo, Future<plugin.Response>> pluginFutures;
    var requestParams = plugin.EditGetAssistsParams(file, offset, length);
    var driver = server.getAnalysisDriver(file);
    if (driver == null) {
      pluginFutures = <PluginInfo, Future<plugin.Response>>{};
    } else {
      pluginFutures = server.pluginManager
          .broadcastRequest(requestParams, contextRoot: driver.contextRoot);
    }

    //
    // Compute fixes associated with server-generated errors.
    //
    var changes = await _computeServerAssists(request, file, offset, length);

    //
    // Add the fixes produced by plugins to the server-generated fixes.
    //
    var responses =
        await waitForResponses(pluginFutures, requestParameters: requestParams);
    server.requestStatistics?.addItemTimeNow(request, 'pluginResponses');
    var converter = ResultConverter();
    var pluginChanges = <plugin.PrioritizedSourceChange>[];
    for (var response in responses) {
      var result = plugin.EditGetAssistsResult.fromResponse(response);
      pluginChanges.addAll(result.assists);
    }
    pluginChanges
        .sort((first, second) => first.priority.compareTo(second.priority));
    changes.addAll(pluginChanges.map(converter.convertPrioritizedSourceChange));

    //
    // Send the response.
    //
    server.sendResponse(EditGetAssistsResult(changes).toResponse(request.id));
  }

  Response getDartfixInfo(Request request) =>
      EditGetDartfixInfoResult(allFixes.map((i) => i.asDartFix()).toList())
          .toResponse(request.id);

  Future<void> getFixes(Request request) async {
    var params = EditGetFixesParams.fromRequest(request);
    var file = params.file;
    var offset = params.offset;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    if (!server.contextManager.isInAnalysisRoot(file)) {
      server.sendResponse(Response.getFixesInvalidFile(request));
      return;
    }

    //
    // Allow plugins to start computing fixes.
    //
    Map<PluginInfo, Future<plugin.Response>> pluginFutures;
    var requestParams = plugin.EditGetFixesParams(file, offset);
    var driver = server.getAnalysisDriver(file);
    if (driver == null) {
      pluginFutures = <PluginInfo, Future<plugin.Response>>{};
    } else {
      pluginFutures = server.pluginManager
          .broadcastRequest(requestParams, contextRoot: driver.contextRoot);
    }
    //
    // Compute fixes associated with server-generated errors.
    //
    List<AnalysisErrorFixes> errorFixesList;
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
    server.sendResponse(
        EditGetFixesResult(errorFixesList).toResponse(request.id));
  }

  Future getPostfixCompletion(Request request) async {
    server.options.analytics?.sendEvent('edit', 'getPostfixCompletion');

    var params = EditGetPostfixCompletionParams.fromRequest(request);
    var file = params.file;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    SourceChange change;

    var result = await server.getResolvedUnit(file);
    if (result != null) {
      var context = PostfixCompletionContext(
        result,
        params.offset,
        params.key,
      );
      var processor = PostfixCompletionProcessor(context);
      var completion = await processor.compute();
      change = completion?.change;
    }
    change ??= SourceChange('', edits: []);

    var response =
        EditGetPostfixCompletionResult(change).toResponse(request.id);
    server.sendResponse(response);
  }

  Future getStatementCompletion(Request request) async {
    var params = EditGetStatementCompletionParams.fromRequest(request);
    var file = params.file;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    SourceChange change;

    var result = await server.getResolvedUnit(file);
    if (result != null) {
      var context = StatementCompletionContext(result, params.offset);
      var processor = StatementCompletionProcessor(context);
      var completion = await processor.compute();
      change = completion.change;
    }
    change ??= SourceChange('', edits: []);

    var response =
        EditGetStatementCompletionResult(change, false).toResponse(request.id);
    server.sendResponse(response);
  }

  @override
  Response handleRequest(Request request) {
    try {
      var requestName = request.method;
      if (requestName == EDIT_REQUEST_FORMAT) {
        return format(request);
      } else if (requestName == EDIT_REQUEST_GET_ASSISTS) {
        getAssists(request);
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_REQUEST_GET_AVAILABLE_REFACTORINGS) {
        return _getAvailableRefactorings(request);
      } else if (requestName == EDIT_REQUEST_BULK_FIXES) {
        bulkFixes(request);
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_REQUEST_GET_DARTFIX_INFO) {
        return getDartfixInfo(request);
      } else if (requestName == EDIT_REQUEST_GET_FIXES) {
        getFixes(request);
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_REQUEST_DARTFIX) {
        dartfix(request);
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_REQUEST_GET_REFACTORING) {
        return _getRefactoring(request);
      } else if (requestName == EDIT_REQUEST_IMPORT_ELEMENTS) {
        importElements(request);
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_REQUEST_ORGANIZE_DIRECTIVES) {
        organizeDirectives(request);
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_REQUEST_SORT_MEMBERS) {
        sortMembers(request);
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_REQUEST_GET_STATEMENT_COMPLETION) {
        getStatementCompletion(request);
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_REQUEST_IS_POSTFIX_COMPLETION_APPLICABLE) {
        isPostfixCompletionApplicable(request);
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_REQUEST_GET_POSTFIX_COMPLETION) {
        getPostfixCompletion(request);
        return Response.DELAYED_RESPONSE;
      } else if (requestName ==
          EDIT_REQUEST_LIST_POSTFIX_COMPLETION_TEMPLATES) {
        return listPostfixCompletionTemplates(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  /// Implement the `edit.importElements` request.
  Future<void> importElements(Request request) async {
    var params = EditImportElementsParams.fromRequest(request);
    var file = params.file;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    //
    // Prepare the resolved unit.
    //
    var result = await server.getResolvedUnit(file);
    if (result == null) {
      server.sendResponse(Response.importElementsInvalidFile(request));
    }
    var libraryUnit = result.libraryElement.definingCompilationUnit;
    if (libraryUnit != result.unit.declaredElement) {
      // The file in the request is a part of a library. We need to pass the
      // defining compilation unit to the computer, not the part.
      result = await server.getResolvedUnit(libraryUnit.source.fullName);
      if (result == null) {
        server.sendResponse(Response.importElementsInvalidFile(request));
      }
    }
    //
    // Compute the edits required to import the required elements.
    //
    var computer = ImportElementsComputer(server.resourceProvider, result);
    var change = await computer.createEdits(params.elements);
    var edits = change.edits;
    var edit = edits.isEmpty ? null : edits[0];
    //
    // Send the response.
    //
    server.sendResponse(
        EditImportElementsResult(edit: edit).toResponse(request.id));
  }

  Future isPostfixCompletionApplicable(Request request) async {
    var params = EditGetPostfixCompletionParams.fromRequest(request);
    var file = params.file;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    var value = false;

    var result = await server.getResolvedUnit(file);
    if (result != null) {
      var context = PostfixCompletionContext(
        result,
        params.offset,
        params.key,
      );
      var processor = PostfixCompletionProcessor(context);
      value = await processor.isApplicable();
    }

    var response =
        EditIsPostfixCompletionApplicableResult(value).toResponse(request.id);
    server.sendResponse(response);
  }

  Response listPostfixCompletionTemplates(Request request) {
    var templates = DartPostfixCompletion.ALL_TEMPLATES
        .map((PostfixCompletionKind kind) =>
            PostfixTemplateDescriptor(kind.name, kind.key, kind.example))
        .toList();

    return EditListPostfixCompletionTemplatesResult(templates)
        .toResponse(request.id);
  }

  Future<void> organizeDirectives(Request request) async {
    server.options.analytics?.sendEvent('edit', 'organizeDirectives');

    var params = EditOrganizeDirectivesParams.fromRequest(request);
    var file = params.file;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }
    if (!engine.AnalysisEngine.isDartFileName(file)) {
      server.sendResponse(Response.fileNotAnalyzed(request, file));
      return;
    }

    // Prepare the file information.
    var result = await server.getResolvedUnit(file);
    if (result == null) {
      server.sendResponse(Response.fileNotAnalyzed(request, file));
      return;
    }
    var fileStamp = -1;
    var code = result.content;
    var unit = result.unit;
    var errors = result.errors;
    // check if there are scan/parse errors in the file
    var numScanParseErrors = _getNumberOfScanParseErrors(errors);
    if (numScanParseErrors != 0) {
      server.sendResponse(Response.organizeDirectivesError(
          request, 'File has $numScanParseErrors scan/parse errors.'));
      return;
    }
    // do organize
    var sorter = ImportOrganizer(code, unit, errors);
    var edits = sorter.organize();
    var fileEdit = SourceFileEdit(file, fileStamp, edits: edits);
    server.sendResponse(
        EditOrganizeDirectivesResult(fileEdit).toResponse(request.id));
  }

  Future<void> sortMembers(Request request) async {
    var params = EditSortMembersParams.fromRequest(request);
    var file = params.file;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }
    if (!engine.AnalysisEngine.isDartFileName(file)) {
      server.sendResponse(Response.sortMembersInvalidFile(request));
      return;
    }

    // Prepare the file information.
    var result = server.getParsedUnit(file);
    if (result == null) {
      server.sendResponse(Response.fileNotAnalyzed(request, file));
      return;
    }

    var fileStamp = -1;
    var code = result.content;
    var unit = result.unit;
    var errors = result.errors;
    // Check if there are scan/parse errors in the file.
    var numScanParseErrors = _getNumberOfScanParseErrors(errors);
    if (numScanParseErrors != 0) {
      server.sendResponse(
          Response.sortMembersParseErrors(request, numScanParseErrors));
      return;
    }
    // Do sort.
    var sorter = MemberSorter(code, unit);
    var edits = sorter.sort();
    var fileEdit = SourceFileEdit(file, fileStamp, edits: edits);
    server.sendResponse(EditSortMembersResult(fileEdit).toResponse(request.id));
  }

  /// Compute and return the fixes associated with server-generated errors in
  /// analysis options files.
  Future<List<AnalysisErrorFixes>> _computeAnalysisOptionsFixes(
      String file, int offset) async {
    var errorFixesList = <AnalysisErrorFixes>[];
    var optionsFile = server.resourceProvider.getFile(file);
    var content = _safelyRead(optionsFile);
    if (content == null) {
      return errorFixesList;
    }
    var driver = server.getAnalysisDriver(file);
    var session = driver.currentSession;
    var sourceFactory = driver.sourceFactory;
    var errors = analyzeAnalysisOptions(
        optionsFile.createSource(), content, sourceFactory);
    var options = _getOptions(sourceFactory, content);
    if (options == null) {
      return errorFixesList;
    }
    for (var error in errors) {
      var generator = AnalysisOptionsFixGenerator(error, content, options);
      var fixes = await generator.computeFixes();
      if (fixes.isNotEmpty) {
        fixes.sort(Fix.SORT_BY_RELEVANCE);
        var lineInfo = LineInfo.fromContent(content);
        ResolvedUnitResult result = engine.ResolvedUnitResultImpl(
            session, file, null, true, content, lineInfo, false, null, errors);
        var serverError = newAnalysisError_fromEngine(result, error);
        var errorFixes = AnalysisErrorFixes(serverError);
        errorFixesList.add(errorFixes);
        fixes.forEach((fix) {
          errorFixes.fixes.add(fix.change);
        });
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
          var workspace = DartChangeWorkspace(server.currentSessions);
          var context = DartFixContextImpl(
              server.instrumentationService, workspace, result, error, (name) {
            var tracker = server.declarationsTracker;
            var provider = TopLevelDeclarationsProvider(tracker);
            return provider.get(
              result.session.analysisContext,
              result.path,
              name,
            );
          });

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
            fixes.sort(Fix.SORT_BY_RELEVANCE);
            var serverError = newAnalysisError_fromEngine(result, error);
            var errorFixes = AnalysisErrorFixes(serverError);
            errorFixesList.add(errorFixes);
            fixes.forEach((fix) {
              errorFixes.fixes.add(fix.change);
            });
          }
        }
      }
    }
    server.requestStatistics?.addItemTimeNow(request, 'computedFixes');
    return errorFixesList;
  }

  /// Compute and return the fixes associated with server-generated errors in
  /// Android manifest files.
  Future<List<AnalysisErrorFixes>> _computeManifestFixes(
      String file, int offset) async {
    var errorFixesList = <AnalysisErrorFixes>[];
    var manifestFile = server.resourceProvider.getFile(file);
    var content = _safelyRead(manifestFile);
    if (content == null) {
      return errorFixesList;
    }
    var document =
        parseFragment(content, container: MANIFEST_TAG, generateSpans: true);
    if (document == null) {
      return errorFixesList;
    }
    var validator = ManifestValidator(manifestFile.createSource());
    var session = server.getAnalysisDriver(file).currentSession;
    var errors = validator.validate(content, true);
    for (var error in errors) {
      var generator = ManifestFixGenerator(error, content, document);
      var fixes = await generator.computeFixes();
      if (fixes.isNotEmpty) {
        fixes.sort(Fix.SORT_BY_RELEVANCE);
        var lineInfo = LineInfo.fromContent(content);
        ResolvedUnitResult result = engine.ResolvedUnitResultImpl(
            session, file, null, true, content, lineInfo, false, null, errors);
        var serverError = newAnalysisError_fromEngine(result, error);
        var errorFixes = AnalysisErrorFixes(serverError);
        errorFixesList.add(errorFixes);
        fixes.forEach((fix) {
          errorFixes.fixes.add(fix.change);
        });
      }
    }
    return errorFixesList;
  }

  /// Compute and return the fixes associated with server-generated errors in
  /// pubspec.yaml files.
  Future<List<AnalysisErrorFixes>> _computePubspecFixes(
      String file, int offset) async {
    var errorFixesList = <AnalysisErrorFixes>[];
    var pubspecFile = server.resourceProvider.getFile(file);
    var content = _safelyRead(pubspecFile);
    if (content == null) {
      return errorFixesList;
    }
    var sourceFactory = server.getAnalysisDriver(file).sourceFactory;
    var pubspec = _getOptions(sourceFactory, content);
    if (pubspec == null) {
      return errorFixesList;
    }
    var validator =
        PubspecValidator(server.resourceProvider, pubspecFile.createSource());
    var session = server.getAnalysisDriver(file).currentSession;
    var errors = validator.validate(pubspec.nodes);
    for (var error in errors) {
      var generator = PubspecFixGenerator(error, content, pubspec);
      var fixes = await generator.computeFixes();
      if (fixes.isNotEmpty) {
        fixes.sort(Fix.SORT_BY_RELEVANCE);
        var lineInfo = LineInfo.fromContent(content);
        ResolvedUnitResult result = engine.ResolvedUnitResultImpl(
            session, file, null, true, content, lineInfo, false, null, errors);
        var serverError = newAnalysisError_fromEngine(result, error);
        var errorFixes = AnalysisErrorFixes(serverError);
        errorFixesList.add(errorFixes);
        fixes.forEach((fix) {
          errorFixes.fixes.add(fix.change);
        });
      }
    }
    return errorFixesList;
  }

  Future<List<SourceChange>> _computeServerAssists(
      Request request, String file, int offset, int length) async {
    var changes = <SourceChange>[];

    var result = await server.getResolvedUnit(file);
    server.requestStatistics?.addItemTimeNow(request, 'resolvedUnit');

    if (result != null) {
      var context = DartAssistContextImpl(
        server.instrumentationService,
        DartChangeWorkspace(server.currentSessions),
        result,
        offset,
        length,
      );

      try {
        var processor = AssistProcessor(context);
        var assists = await processor.compute();
        assists.sort(Assist.SORT_BY_RELEVANCE);
        for (var assist in assists) {
          changes.add(assist.change);
        }
      } on InconsistentAnalysisException {
        // ignore
      } catch (exception, stackTrace) {
        var parametersFile = '''
offset: $offset
length: $length
      ''';
        throw CaughtExceptionWithFiles(exception, stackTrace, {
          file: result.content,
          'parameters': parametersFile,
        });
      }

      server.requestStatistics?.addItemTimeNow(request, 'computedAssists');
    }

    return changes;
  }

  /// Compute and return the fixes associated with server-generated errors.
  Future<List<AnalysisErrorFixes>> _computeServerErrorFixes(
      Request request, String file, int offset) async {
    var context = server.resourceProvider.pathContext;
    if (AnalysisEngine.isDartFileName(file)) {
      return _computeDartFixes(request, file, offset);
    } else if (AnalysisEngine.isAnalysisOptionsFileName(file, context)) {
      return _computeAnalysisOptionsFixes(file, offset);
    } else if (context.basename(file) == 'pubspec.yaml') {
      return _computePubspecFixes(file, offset);
    } else if (context.basename(file) == 'manifest.xml') {
      // TODO(brianwilkerson) Do we need to check more than the file name?
      return _computeManifestFixes(file, offset);
    }
    return <AnalysisErrorFixes>[];
  }

  Response _getAvailableRefactorings(Request request) {
    _getAvailableRefactoringsImpl(request);
    return Response.DELAYED_RESPONSE;
  }

  Future _getAvailableRefactoringsImpl(Request request) async {
    var params = EditGetAvailableRefactoringsParams.fromRequest(request);
    var file = params.file;
    var offset = params.offset;
    var length = params.length;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    // add refactoring kinds
    var kinds = <RefactoringKind>[];
    // Check nodes.
    {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        // Try EXTRACT_LOCAL_VARIABLE.
        if (ExtractLocalRefactoring(resolvedUnit, offset, length)
            .isAvailable()) {
          kinds.add(RefactoringKind.EXTRACT_LOCAL_VARIABLE);
        }
        // Try EXTRACT_METHOD.
        if (ExtractMethodRefactoring(searchEngine, resolvedUnit, offset, length)
            .isAvailable()) {
          kinds.add(RefactoringKind.EXTRACT_METHOD);
        }
        // Try EXTRACT_WIDGETS.
        if (ExtractWidgetRefactoring(searchEngine, resolvedUnit, offset, length)
            .isAvailable()) {
          kinds.add(RefactoringKind.EXTRACT_WIDGET);
        }
      }
    }
    // check elements
    {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        var node = NodeLocator(offset).searchWithin(resolvedUnit.unit);
        var element = server.getElementOfNode(node);
        if (element != null) {
          // try CONVERT_METHOD_TO_GETTER
          if (element is ExecutableElement) {
            Refactoring refactoring = ConvertMethodToGetterRefactoring(
                searchEngine, resolvedUnit.session, element);
            var status = await refactoring.checkInitialConditions();
            if (!status.hasFatalError) {
              kinds.add(RefactoringKind.CONVERT_METHOD_TO_GETTER);
            }
          }
          // try RENAME
          {
            var renameRefactoring =
                RenameRefactoring(refactoringWorkspace, resolvedUnit, element);
            if (renameRefactoring != null) {
              kinds.add(RefactoringKind.RENAME);
            }
          }
        }
      }
    }
    // respond
    var result = EditGetAvailableRefactoringsResult(kinds);
    server.sendResponse(result.toResponse(request.id));
  }

  YamlMap _getOptions(SourceFactory sourceFactory, String content) {
    var optionsProvider = AnalysisOptionsProvider(sourceFactory);
    try {
      return optionsProvider.getOptionsFromString(content);
    } on OptionsFormatException {
      return null;
    }
  }

  Response _getRefactoring(Request request) {
    if (refactoringManager.hasPendingRequest) {
      refactoringManager.cancel();
      _newRefactoringManager();
    }
    refactoringManager.getRefactoring(request);
    return Response.DELAYED_RESPONSE;
  }

  /// Initializes [refactoringManager] with a new instance.
  void _newRefactoringManager() {
    refactoringManager = _RefactoringManager(server, refactoringWorkspace);
  }

  /// Return the contents of the [file], or `null` if the file does not exist or
  /// cannot be read.
  String _safelyRead(File file) {
    try {
      return file.readAsStringSync();
    } on FileSystemException {
      return null;
    }
  }

  static int _getNumberOfScanParseErrors(List<engine.AnalysisError> errors) {
    var numScanParseErrors = 0;
    for (var error in errors) {
      if (error.errorCode is engine.ScannerErrorCode ||
          error.errorCode is engine.ParserErrorCode) {
        numScanParseErrors++;
      }
    }
    return numScanParseErrors;
  }
}

/// An object managing a single [Refactoring] instance.
///
/// The instance is identified by its kind, file, offset and length.
/// It is initialized when the a set of parameters is given for the first time.
/// All subsequent requests are performed on this [Refactoring] instance.
///
/// Once new set of parameters is received, the previous [Refactoring] instance
/// is invalidated and a new one is created and initialized.
class _RefactoringManager {
  static const List<RefactoringProblem> EMPTY_PROBLEM_LIST =
      <RefactoringProblem>[];

  final AnalysisServer server;
  final RefactoringWorkspace refactoringWorkspace;
  final SearchEngine searchEngine;
  StreamSubscription subscriptionToReset;

  RefactoringKind kind;
  String file;
  int offset;
  int length;
  Refactoring refactoring;
  RefactoringFeedback feedback;
  RefactoringStatus initStatus;
  RefactoringStatus optionsStatus;
  RefactoringStatus finalStatus;

  Request request;
  EditGetRefactoringResult result;

  _RefactoringManager(this.server, this.refactoringWorkspace)
      : searchEngine = refactoringWorkspace.searchEngine {
    _reset();
  }

  /// Returns `true` if a response for the current request has not yet been
  /// sent.
  bool get hasPendingRequest => request != null;

  bool get _hasFatalError {
    return initStatus.hasFatalError ||
        optionsStatus.hasFatalError ||
        finalStatus.hasFatalError;
  }

  /// Checks if [refactoring] requires options.
  bool get _requiresOptions {
    return refactoring is ExtractLocalRefactoring ||
        refactoring is ExtractMethodRefactoring ||
        refactoring is ExtractWidgetRefactoring ||
        refactoring is InlineMethodRefactoring ||
        refactoring is MoveFileRefactoring ||
        refactoring is RenameRefactoring;
  }

  /// Cancels processing of the current request and cleans up.
  void cancel() {
    if (request != null) {
      server.sendResponse(Response.refactoringRequestCancelled(request));
      request = null;
    }
    _reset();
  }

  void getRefactoring(Request _request) {
    // prepare for processing the request
    request = _request;
    result = EditGetRefactoringResult(
        EMPTY_PROBLEM_LIST, EMPTY_PROBLEM_LIST, EMPTY_PROBLEM_LIST);
    // process the request
    var params = EditGetRefactoringParams.fromRequest(_request);
    var file = params.file;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    if (params.kind != null) {
      server.options.analytics
          ?.sendEvent('refactor', params.kind.name.toLowerCase());
    }

    runZonedGuarded(() async {
      await _init(params.kind, file, params.offset, params.length);
      if (initStatus.hasFatalError) {
        feedback = null;
        _sendResultResponse();
        return;
      }
      // set options
      if (_requiresOptions) {
        if (params.options == null) {
          optionsStatus = RefactoringStatus();
          _sendResultResponse();
          return;
        }
        optionsStatus = _setOptions(params);
        if (_hasFatalError) {
          _sendResultResponse();
          return;
        }
      }
      // done if just validation
      if (params.validateOnly) {
        finalStatus = RefactoringStatus();
        _sendResultResponse();
        return;
      }
      // simulate an exception
      if (test_simulateRefactoringException_final) {
        throw 'A simulated refactoring exception - final.';
      }
      // validation and create change
      finalStatus = await refactoring.checkFinalConditions();
      _checkForReset_afterFinalConditions();
      if (_hasFatalError) {
        _sendResultResponse();
        return;
      }
      // simulate an exception
      if (test_simulateRefactoringException_change) {
        throw 'A simulated refactoring exception - change.';
      }
      // create change
      result.change = await refactoring.createChange();
      _checkForReset_afterCreateChange();
      result.potentialEdits = nullIfEmpty(refactoring.potentialEditIds);
      _sendResultResponse();
    }, (exception, stackTrace) {
      if (exception is _ResetError ||
          exception is InconsistentAnalysisException) {
        cancel();
      } else {
        server.instrumentationService.logException(exception, stackTrace);
        server.sendResponse(
            Response.serverError(_request, exception, stackTrace));
      }
      _reset();
    });
  }

  void _checkForReset_afterCreateChange() {
    if (test_simulateRefactoringReset_afterCreateChange) {
      _reset();
    }
    if (refactoring == null) {
      throw _ResetError();
    }
  }

  void _checkForReset_afterFinalConditions() {
    if (test_simulateRefactoringReset_afterFinalConditions) {
      _reset();
    }
    if (refactoring == null) {
      throw _ResetError();
    }
  }

  void _checkForReset_afterInitialConditions() {
    if (test_simulateRefactoringReset_afterInitialConditions) {
      _reset();
    }
    if (refactoring == null) {
      throw _ResetError();
    }
  }

  /// Initializes this context to perform a refactoring with the specified
  /// parameters. The existing [Refactoring] is reused or created as needed.
  Future _init(
      RefactoringKind kind, String file, int offset, int length) async {
    // check if we can continue with the existing Refactoring instance
    if (this.kind == kind &&
        this.file == file &&
        this.offset == offset &&
        this.length == length) {
      return;
    }
    _reset();
    _resetOnAnalysisSetChanged();
    this.kind = kind;
    this.file = file;
    this.offset = offset;
    this.length = length;
    // simulate an exception
    if (test_simulateRefactoringException_init) {
      throw 'A simulated refactoring exception - init.';
    }
    // create a new Refactoring instance
    if (kind == RefactoringKind.CONVERT_GETTER_TO_METHOD) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        var node = NodeLocator(offset).searchWithin(resolvedUnit.unit);
        var element = server.getElementOfNode(node);
        if (element != null) {
          if (element is ExecutableElement) {
            refactoring = ConvertGetterToMethodRefactoring(
                searchEngine, resolvedUnit.session, element);
          }
        }
      }
    }
    if (kind == RefactoringKind.CONVERT_METHOD_TO_GETTER) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        var node = NodeLocator(offset).searchWithin(resolvedUnit.unit);
        var element = server.getElementOfNode(node);
        if (element != null) {
          if (element is ExecutableElement) {
            refactoring = ConvertMethodToGetterRefactoring(
                searchEngine, resolvedUnit.session, element);
          }
        }
      }
    }
    if (kind == RefactoringKind.EXTRACT_LOCAL_VARIABLE) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        refactoring = ExtractLocalRefactoring(resolvedUnit, offset, length);
        feedback = ExtractLocalVariableFeedback(<String>[], <int>[], <int>[],
            coveringExpressionOffsets: <int>[],
            coveringExpressionLengths: <int>[]);
      }
    }
    if (kind == RefactoringKind.EXTRACT_METHOD) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        refactoring = ExtractMethodRefactoring(
            searchEngine, resolvedUnit, offset, length);
        feedback = ExtractMethodFeedback(offset, length, '', <String>[], false,
            <RefactoringMethodParameter>[], <int>[], <int>[]);
      }
    }
    if (kind == RefactoringKind.EXTRACT_WIDGET) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        refactoring = ExtractWidgetRefactoring(
            searchEngine, resolvedUnit, offset, length);
        feedback = ExtractWidgetFeedback();
      }
    }
    if (kind == RefactoringKind.INLINE_LOCAL_VARIABLE) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        refactoring = InlineLocalRefactoring(
          searchEngine,
          resolvedUnit,
          offset,
        );
      }
    }
    if (kind == RefactoringKind.INLINE_METHOD) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        refactoring = InlineMethodRefactoring(
          searchEngine,
          resolvedUnit,
          offset,
        );
      }
    }
    if (kind == RefactoringKind.MOVE_FILE) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        refactoring = MoveFileRefactoring(
            server.resourceProvider, refactoringWorkspace, resolvedUnit, file);
      }
    }
    if (kind == RefactoringKind.RENAME) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        var node = NodeLocator(offset).searchWithin(resolvedUnit.unit);
        var element = server.getElementOfNode(node);
        if (node != null && element != null) {
          final renameElement =
              RenameRefactoring.getElementToRename(node, element);

          // do create the refactoring
          refactoring = RenameRefactoring(
              refactoringWorkspace, resolvedUnit, renameElement.element);
          feedback = RenameFeedback(
              renameElement.offset, renameElement.length, 'kind', 'oldName');
        }
      }
    }
    if (refactoring == null) {
      initStatus = RefactoringStatus.fatal('Unable to create a refactoring');
      return;
    }
    // check initial conditions
    initStatus = await refactoring.checkInitialConditions();
    _checkForReset_afterInitialConditions();
    if (refactoring is ExtractLocalRefactoring) {
      ExtractLocalRefactoring refactoring = this.refactoring;
      ExtractLocalVariableFeedback feedback = this.feedback;
      feedback.names = refactoring.names;
      feedback.offsets = refactoring.offsets;
      feedback.lengths = refactoring.lengths;
      feedback.coveringExpressionOffsets =
          refactoring.coveringExpressionOffsets;
      feedback.coveringExpressionLengths =
          refactoring.coveringExpressionLengths;
    }
    if (refactoring is ExtractMethodRefactoring) {
      ExtractMethodRefactoring refactoring = this.refactoring;
      ExtractMethodFeedback feedback = this.feedback;
      feedback.canCreateGetter = refactoring.canCreateGetter;
      feedback.returnType = refactoring.returnType;
      feedback.names = refactoring.names;
      feedback.parameters = refactoring.parameters;
      feedback.offsets = refactoring.offsets;
      feedback.lengths = refactoring.lengths;
    }
    if (refactoring is InlineLocalRefactoring) {
      InlineLocalRefactoring refactoring = this.refactoring;
      if (!initStatus.hasFatalError) {
        feedback = InlineLocalVariableFeedback(
            refactoring.variableName, refactoring.referenceCount);
      }
    }
    if (refactoring is InlineMethodRefactoring) {
      InlineMethodRefactoring refactoring = this.refactoring;
      if (!initStatus.hasFatalError) {
        feedback = InlineMethodFeedback(
            refactoring.methodName, refactoring.isDeclaration,
            className: refactoring.className);
      }
    }
    if (refactoring is RenameRefactoring) {
      RenameRefactoring refactoring = this.refactoring;
      RenameFeedback feedback = this.feedback;
      feedback.elementKindName = refactoring.elementKindName;
      feedback.oldName = refactoring.oldName;
    }
  }

  void _reset() {
    test_resetCount++;
    kind = null;
    offset = null;
    length = null;
    refactoring = null;
    feedback = null;
    initStatus = RefactoringStatus();
    optionsStatus = RefactoringStatus();
    finalStatus = RefactoringStatus();
    subscriptionToReset?.cancel();
    subscriptionToReset = null;
  }

  void _resetOnAnalysisSetChanged() {
    subscriptionToReset?.cancel();
    subscriptionToReset = server.onAnalysisSetChanged.listen((_) {
      _reset();
    });
  }

  void _sendResultResponse() {
    // ignore if was cancelled
    if (request == null) {
      return;
    }
    // set feedback
    result.feedback = feedback;
    // set problems
    result.initialProblems = initStatus.problems;
    result.optionsProblems = optionsStatus.problems;
    result.finalProblems = finalStatus.problems;
    // send the response
    server.sendResponse(result.toResponse(request.id));
    // done with this request
    request = null;
    result = null;
  }

  RefactoringStatus _setOptions(EditGetRefactoringParams params) {
    if (refactoring is ExtractLocalRefactoring) {
      ExtractLocalRefactoring extractRefactoring = refactoring;
      ExtractLocalVariableOptions extractOptions = params.options;
      extractRefactoring.name = extractOptions.name;
      extractRefactoring.extractAll = extractOptions.extractAll;
      return extractRefactoring.checkName();
    }
    if (refactoring is ExtractMethodRefactoring) {
      ExtractMethodRefactoring extractRefactoring = refactoring;
      ExtractMethodOptions extractOptions = params.options;
      extractRefactoring.createGetter = extractOptions.createGetter;
      extractRefactoring.extractAll = extractOptions.extractAll;
      extractRefactoring.name = extractOptions.name;
      if (extractOptions.parameters != null) {
        extractRefactoring.parameters = extractOptions.parameters;
      }
      extractRefactoring.returnType = extractOptions.returnType;
      return extractRefactoring.checkName();
    }
    if (refactoring is ExtractWidgetRefactoring) {
      ExtractWidgetRefactoring extractRefactoring = refactoring;
      ExtractWidgetOptions extractOptions = params.options;
      extractRefactoring.name = extractOptions.name;
      return extractRefactoring.checkName();
    }
    if (refactoring is InlineMethodRefactoring) {
      InlineMethodRefactoring inlineRefactoring = refactoring;
      InlineMethodOptions inlineOptions = params.options;
      inlineRefactoring.deleteSource = inlineOptions.deleteSource;
      inlineRefactoring.inlineAll = inlineOptions.inlineAll;
      return RefactoringStatus();
    }
    if (refactoring is MoveFileRefactoring) {
      MoveFileRefactoring moveRefactoring = refactoring;
      MoveFileOptions moveOptions = params.options;
      moveRefactoring.newFile = moveOptions.newFile;
      return RefactoringStatus();
    }
    if (refactoring is RenameRefactoring) {
      RenameRefactoring renameRefactoring = refactoring;
      RenameOptions renameOptions = params.options;
      renameRefactoring.newName = renameOptions.newName;
      return renameRefactoring.checkNewName();
    }
    return RefactoringStatus();
  }
}

/// [_RefactoringManager] throws instances of this class internally to stop
/// processing in a manager that was reset.
class _ResetError {}
