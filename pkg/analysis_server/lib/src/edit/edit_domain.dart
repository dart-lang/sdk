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
import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/completion/postfix/postfix_completion.dart';
import 'package:analysis_server/src/services/completion/statement/statement_completion.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix/analysis_options/fix_generator.dart';
import 'package:analysis_server/src/services/correction/fix/manifest/fix_generator.dart';
import 'package:analysis_server/src/services/correction/fix/pubspec/fix_generator.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analysis_server/src/services/correction/organize_directives.dart';
import 'package:analysis_server/src/services/correction/sort_members.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' as engine;
import 'package:analyzer/file_system/file_system.dart';
// ignore: deprecated_member_use
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/results.dart' as engine;
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart' as engine;
import 'package:analyzer/src/error/codes.dart' as engine;
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart' as engine;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/manifest/manifest_validator.dart';
import 'package:analyzer/src/manifest/manifest_values.dart';
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:dart_style/dart_style.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:path/src/context.dart';
import 'package:yaml/yaml.dart';

int test_resetCount = 0;

bool test_simulateRefactoringException_change = false;
bool test_simulateRefactoringException_final = false;
bool test_simulateRefactoringException_init = false;

bool test_simulateRefactoringReset_afterCreateChange = false;
bool test_simulateRefactoringReset_afterFinalConditions = false;
bool test_simulateRefactoringReset_afterInitialConditions = false;

/**
 * Instances of the class [EditDomainHandler] implement a [RequestHandler]
 * that handles requests in the edit domain.
 */
class EditDomainHandler extends AbstractRequestHandler {
  /**
   * The [SearchEngine] for this server.
   */
  SearchEngine searchEngine;

  /**
   * The workspace for rename refactorings.
   */
  RefactoringWorkspace refactoringWorkspace;

  /**
   * The object used to manage uncompleted refactorings.
   */
  _RefactoringManager refactoringManager;

  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  EditDomainHandler(AnalysisServer server) : super(server) {
    searchEngine = server.searchEngine;
    refactoringWorkspace =
        new RefactoringWorkspace(server.driverMap.values, searchEngine);
    _newRefactoringManager();
  }

  Future dartfix(Request request) async {
    // TODO(danrubel): Add support for dartfix plugins

    //
    // Compute fixes
    //
    var dartFix = new EditDartFix(server, request);
    Response response = await dartFix.compute();

    server.sendResponse(response);
  }

  Response format(Request request) {
    server.options.analytics?.sendEvent('edit', 'format');

    EditFormatParams params = new EditFormatParams.fromRequest(request);
    String file = params.file;

    String unformattedCode;
    try {
      var resource = server.resourceProvider.getFile(file);
      unformattedCode = resource.readAsStringSync();
    } catch (e) {
      return new Response.formatInvalidFile(request);
    }

    int start = params.selectionOffset;
    int length = params.selectionLength;

    // No need to preserve 0,0 selection
    if (start == 0 && length == 0) {
      start = null;
      length = null;
    }

    SourceCode code = new SourceCode(unformattedCode,
        uri: null,
        isCompilationUnit: true,
        selectionStart: start,
        selectionLength: length);
    DartFormatter formatter = new DartFormatter(pageWidth: params.lineLength);
    SourceCode formattedResult;
    try {
      formattedResult = formatter.formatSource(code);
    } on FormatterException {
      return new Response.formatWithErrors(request);
    }
    String formattedSource = formattedResult.text;

    List<SourceEdit> edits = <SourceEdit>[];

    if (formattedSource != unformattedCode) {
      //TODO: replace full replacements with smaller, more targeted edits
      SourceEdit edit =
          new SourceEdit(0, unformattedCode.length, formattedSource);
      edits.add(edit);
    }

    int newStart = formattedResult.selectionStart;
    int newLength = formattedResult.selectionLength;

    // Sending null start/length values would violate protocol, so convert back
    // to 0.
    if (newStart == null) {
      newStart = 0;
    }
    if (newLength == null) {
      newLength = 0;
    }

    return new EditFormatResult(edits, newStart, newLength)
        .toResponse(request.id);
  }

  Future getAssists(Request request) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    EditGetAssistsParams params = new EditGetAssistsParams.fromRequest(request);
    String file = params.file;
    int offset = params.offset;
    int length = params.length;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    List<SourceChange> changes = <SourceChange>[];
    //
    // Allow plugins to start computing assists.
    //
    Map<PluginInfo, Future<plugin.Response>> pluginFutures;
    plugin.EditGetAssistsParams requestParams =
        new plugin.EditGetAssistsParams(file, offset, length);
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
    ResolvedUnitResult result = await server.getResolvedUnit(file);
    if (result != null) {
      var context = new DartAssistContextImpl(
        DartChangeWorkspace(server.currentSessions),
        result,
        offset,
        length,
      );
      try {
        AssistProcessor processor = new AssistProcessor(context);
        List<Assist> assists = await processor.compute();
        assists.sort(Assist.SORT_BY_RELEVANCE);
        for (Assist assist in assists) {
          changes.add(assist.change);
        }
      } catch (_) {}
    }
    //
    // Add the fixes produced by plugins to the server-generated fixes.
    //
    List<plugin.Response> responses =
        await waitForResponses(pluginFutures, requestParameters: requestParams);
    ResultConverter converter = new ResultConverter();
    List<plugin.PrioritizedSourceChange> pluginChanges =
        <plugin.PrioritizedSourceChange>[];
    for (plugin.Response response in responses) {
      plugin.EditGetAssistsResult result =
          new plugin.EditGetAssistsResult.fromResponse(response);
      pluginChanges.addAll(result.assists);
    }
    pluginChanges
        .sort((first, second) => first.priority.compareTo(second.priority));
    changes.addAll(pluginChanges.map(converter.convertPrioritizedSourceChange));
    //
    // Send the response.
    //
    server
        .sendResponse(new EditGetAssistsResult(changes).toResponse(request.id));
  }

  Response getDartfixInfo(Request request) =>
      new EditGetDartfixInfoResult(allFixes.map((i) => i.asDartFix()).toList())
          .toResponse(request.id);

  Future<void> getFixes(Request request) async {
    EditGetFixesParams params = new EditGetFixesParams.fromRequest(request);
    String file = params.file;
    int offset = params.offset;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }
    //
    // Allow plugins to start computing fixes.
    //
    Map<PluginInfo, Future<plugin.Response>> pluginFutures;
    plugin.EditGetFixesParams requestParams =
        new plugin.EditGetFixesParams(file, offset);
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
    List<AnalysisErrorFixes> errorFixesList = null;
    while (errorFixesList == null) {
      try {
        errorFixesList = await _computeServerErrorFixes(file, offset);
      } on InconsistentAnalysisException {
        // Loop around to try again to compute the fixes.
      }
    }
    //
    // Add the fixes produced by plugins to the server-generated fixes.
    //
    List<plugin.Response> responses =
        await waitForResponses(pluginFutures, requestParameters: requestParams);
    ResultConverter converter = new ResultConverter();
    for (plugin.Response response in responses) {
      plugin.EditGetFixesResult result =
          new plugin.EditGetFixesResult.fromResponse(response);
      errorFixesList
          .addAll(result.fixes.map(converter.convertAnalysisErrorFixes));
    }
    //
    // Send the response.
    //
    server.sendResponse(
        new EditGetFixesResult(errorFixesList).toResponse(request.id));
  }

  Future getPostfixCompletion(Request request) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    server.options.analytics?.sendEvent('edit', 'getPostfixCompletion');

    var params = new EditGetPostfixCompletionParams.fromRequest(request);
    var file = params.file;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    SourceChange change;

    ResolvedUnitResult result = await server.getResolvedUnit(file);
    if (result != null) {
      PostfixCompletionContext context = new PostfixCompletionContext(
        result,
        params.offset,
        params.key,
      );
      PostfixCompletionProcessor processor =
          new PostfixCompletionProcessor(context);
      PostfixCompletion completion = await processor.compute();
      change = completion?.change;
    }
    if (change == null) {
      change = new SourceChange("", edits: []);
    }

    Response response =
        new EditGetPostfixCompletionResult(change).toResponse(request.id);
    server.sendResponse(response);
  }

  Future getStatementCompletion(Request request) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;

    var params = new EditGetStatementCompletionParams.fromRequest(request);
    var file = params.file;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    SourceChange change;

    ResolvedUnitResult result = await server.getResolvedUnit(file);
    if (result != null) {
      var context = new StatementCompletionContext(result, params.offset);
      StatementCompletionProcessor processor =
          new StatementCompletionProcessor(context);
      StatementCompletion completion = await processor.compute();
      change = completion.change;
    }
    if (change == null) {
      change = new SourceChange("", edits: []);
    }

    Response response = new EditGetStatementCompletionResult(change, false)
        .toResponse(request.id);
    server.sendResponse(response);
  }

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == EDIT_REQUEST_FORMAT) {
        return format(request);
      } else if (requestName == EDIT_REQUEST_GET_ASSISTS) {
        getAssists(request);
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_REQUEST_GET_AVAILABLE_REFACTORINGS) {
        return _getAvailableRefactorings(request);
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
        listPostfixCompletionTemplates(request);
        return Response.DELAYED_RESPONSE;
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  /**
   * Implement the `edit.importElements` request.
   */
  Future<void> importElements(Request request) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;

    var params = new EditImportElementsParams.fromRequest(request);
    var file = params.file;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    //
    // Prepare the resolved unit.
    //
    ResolvedUnitResult result = await server.getResolvedUnit(file);
    if (result == null) {
      server.sendResponse(new Response.importElementsInvalidFile(request));
    }
    CompilationUnitElement libraryUnit =
        result.libraryElement.definingCompilationUnit;
    if (libraryUnit != result.unit.declaredElement) {
      // The file in the request is a part of a library. We need to pass the
      // defining compilation unit to the computer, not the part.
      result = await server.getResolvedUnit(libraryUnit.source.fullName);
      if (result == null) {
        server.sendResponse(new Response.importElementsInvalidFile(request));
      }
    }
    //
    // Compute the edits required to import the required elements.
    //
    ImportElementsComputer computer =
        new ImportElementsComputer(server.resourceProvider, result);
    SourceChange change = await computer.createEdits(params.elements);
    List<SourceFileEdit> edits = change.edits;
    SourceFileEdit edit = edits.isEmpty ? null : edits[0];
    //
    // Send the response.
    //
    server.sendResponse(
        new EditImportElementsResult(edit: edit).toResponse(request.id));
  }

  Future isPostfixCompletionApplicable(Request request) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    var params = new EditGetPostfixCompletionParams.fromRequest(request);
    var file = params.file;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    bool value = false;

    ResolvedUnitResult result = await server.getResolvedUnit(file);
    if (result != null) {
      var context = new PostfixCompletionContext(
        result,
        params.offset,
        params.key,
      );
      var processor = new PostfixCompletionProcessor(context);
      value = await processor.isApplicable();
    }

    Response response = new EditIsPostfixCompletionApplicableResult(value)
        .toResponse(request.id);
    server.sendResponse(response);
  }

  Future listPostfixCompletionTemplates(Request request) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    var templates = DartPostfixCompletion.ALL_TEMPLATES
        .map((pfc) =>
            new PostfixTemplateDescriptor(pfc.name, pfc.key, pfc.example))
        .toList();

    Response response = new EditListPostfixCompletionTemplatesResult(templates)
        .toResponse(request.id);
    server.sendResponse(response);
  }

  Future<void> organizeDirectives(Request request) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    server.options.analytics?.sendEvent('edit', 'organizeDirectives');

    var params = new EditOrganizeDirectivesParams.fromRequest(request);
    var file = params.file;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }
    if (!engine.AnalysisEngine.isDartFileName(file)) {
      server.sendResponse(new Response.fileNotAnalyzed(request, file));
      return;
    }

    // Prepare the file information.
    ResolvedUnitResult result = await server.getResolvedUnit(file);
    if (result == null) {
      server.sendResponse(new Response.fileNotAnalyzed(request, file));
      return;
    }
    int fileStamp = -1;
    String code = result.content;
    CompilationUnit unit = result.unit;
    List<engine.AnalysisError> errors = result.errors;
    // check if there are scan/parse errors in the file
    int numScanParseErrors = _getNumberOfScanParseErrors(errors);
    if (numScanParseErrors != 0) {
      server.sendResponse(new Response.organizeDirectivesError(
          request, 'File has $numScanParseErrors scan/parse errors.'));
      return;
    }
    // do organize
    DirectiveOrganizer sorter = new DirectiveOrganizer(code, unit, errors);
    List<SourceEdit> edits = sorter.organize();
    SourceFileEdit fileEdit = new SourceFileEdit(file, fileStamp, edits: edits);
    server.sendResponse(
        new EditOrganizeDirectivesResult(fileEdit).toResponse(request.id));
  }

  Future<void> sortMembers(Request request) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    var params = new EditSortMembersParams.fromRequest(request);
    var file = params.file;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }
    if (!engine.AnalysisEngine.isDartFileName(file)) {
      server.sendResponse(new Response.sortMembersInvalidFile(request));
      return;
    }

    // Prepare the file information.
    ParsedUnitResult result = await server.getParsedUnit(file);
    if (result == null) {
      server.sendResponse(new Response.fileNotAnalyzed(request, file));
      return;
    }

    int fileStamp = -1;
    String code = result.content;
    CompilationUnit unit = result.unit;
    List<engine.AnalysisError> errors = result.errors;
    // Check if there are scan/parse errors in the file.
    int numScanParseErrors = _getNumberOfScanParseErrors(errors);
    if (numScanParseErrors != 0) {
      server.sendResponse(
          new Response.sortMembersParseErrors(request, numScanParseErrors));
      return;
    }
    // Do sort.
    MemberSorter sorter = new MemberSorter(code, unit);
    List<SourceEdit> edits = sorter.sort();
    SourceFileEdit fileEdit = new SourceFileEdit(file, fileStamp, edits: edits);
    server.sendResponse(
        new EditSortMembersResult(fileEdit).toResponse(request.id));
  }

  /**
   * Compute and return the fixes associated with server-generated errors in
   * analysis options files.
   */
  Future<List<AnalysisErrorFixes>> _computeAnalysisOptionsFixes(
      String file, int offset) async {
    List<AnalysisErrorFixes> errorFixesList = <AnalysisErrorFixes>[];
    File optionsFile = server.resourceProvider.getFile(file);
    String content = _safelyRead(optionsFile);
    if (content == null) {
      return errorFixesList;
    }
    AnalysisDriver driver = server.getAnalysisDriver(file);
    var session = driver.currentSession;
    SourceFactory sourceFactory = driver.sourceFactory;
    List<engine.AnalysisError> errors = analyzeAnalysisOptions(
        optionsFile.createSource(), content, sourceFactory);
    YamlMap options = _getOptions(sourceFactory, content);
    if (options == null) {
      return errorFixesList;
    }
    for (engine.AnalysisError error in errors) {
      AnalysisOptionsFixGenerator generator =
          new AnalysisOptionsFixGenerator(error, content, options);
      List<Fix> fixes = await generator.computeFixes();
      if (fixes.isNotEmpty) {
        fixes.sort(Fix.SORT_BY_RELEVANCE);
        LineInfo lineInfo = new LineInfo.fromContent(content);
        ResolvedUnitResult result = new engine.ResolvedUnitResultImpl(
            session, file, null, true, content, lineInfo, false, null, errors);
        AnalysisError serverError = newAnalysisError_fromEngine(result, error);
        AnalysisErrorFixes errorFixes = new AnalysisErrorFixes(serverError);
        errorFixesList.add(errorFixes);
        fixes.forEach((fix) {
          errorFixes.fixes.add(fix.change);
        });
      }
    }
    return errorFixesList;
  }

  /**
   * Compute and return the fixes associated with server-generated errors in
   * Dart files.
   */
  Future<List<AnalysisErrorFixes>> _computeDartFixes(
      String file, int offset) async {
    List<AnalysisErrorFixes> errorFixesList = <AnalysisErrorFixes>[];
    var result = await server.getResolvedUnit(file);
    if (result != null) {
      LineInfo lineInfo = result.lineInfo;
      int requestLine = lineInfo.getLocation(offset).lineNumber;
      for (engine.AnalysisError error in result.errors) {
        int errorLine = lineInfo.getLocation(error.offset).lineNumber;
        if (errorLine == requestLine) {
          var workspace = DartChangeWorkspace(server.currentSessions);
          var context = new DartFixContextImpl(workspace, result, error);
          List<Fix> fixes =
              await new DartFixContributor().computeFixes(context);
          if (fixes.isNotEmpty) {
            fixes.sort(Fix.SORT_BY_RELEVANCE);
            AnalysisError serverError =
                newAnalysisError_fromEngine(result, error);
            AnalysisErrorFixes errorFixes = new AnalysisErrorFixes(serverError);
            errorFixesList.add(errorFixes);
            fixes.forEach((fix) {
              errorFixes.fixes.add(fix.change);
            });
          }
        }
      }
    }
    return errorFixesList;
  }

  /**
   * Compute and return the fixes associated with server-generated errors in
   * Android manifest files.
   */
  Future<List<AnalysisErrorFixes>> _computeManifestFixes(
      String file, int offset) async {
    List<AnalysisErrorFixes> errorFixesList = <AnalysisErrorFixes>[];
    File manifestFile = server.resourceProvider.getFile(file);
    String content = _safelyRead(manifestFile);
    if (content == null) {
      return errorFixesList;
    }
    DocumentFragment document =
        parseFragment(content, container: MANIFEST_TAG, generateSpans: true);
    if (document == null) {
      return errorFixesList;
    }
    ManifestValidator validator =
        new ManifestValidator(manifestFile.createSource());
    AnalysisSession session = server.getAnalysisDriver(file).currentSession;
    List<engine.AnalysisError> errors = validator.validate(content, true);
    for (engine.AnalysisError error in errors) {
      ManifestFixGenerator generator =
          new ManifestFixGenerator(error, content, document);
      List<Fix> fixes = await generator.computeFixes();
      if (fixes.isNotEmpty) {
        fixes.sort(Fix.SORT_BY_RELEVANCE);
        LineInfo lineInfo = new LineInfo.fromContent(content);
        ResolvedUnitResult result = new engine.ResolvedUnitResultImpl(
            session, file, null, true, content, lineInfo, false, null, errors);
        AnalysisError serverError = newAnalysisError_fromEngine(result, error);
        AnalysisErrorFixes errorFixes = new AnalysisErrorFixes(serverError);
        errorFixesList.add(errorFixes);
        fixes.forEach((fix) {
          errorFixes.fixes.add(fix.change);
        });
      }
    }
    return errorFixesList;
  }

  /**
   * Compute and return the fixes associated with server-generated errors in
   * pubspec.yaml files.
   */
  Future<List<AnalysisErrorFixes>> _computePubspecFixes(
      String file, int offset) async {
    List<AnalysisErrorFixes> errorFixesList = <AnalysisErrorFixes>[];
    File pubspecFile = server.resourceProvider.getFile(file);
    String content = _safelyRead(pubspecFile);
    if (content == null) {
      return errorFixesList;
    }
    SourceFactory sourceFactory = server.getAnalysisDriver(file).sourceFactory;
    YamlMap pubspec = _getOptions(sourceFactory, content);
    if (pubspec == null) {
      return errorFixesList;
    }
    PubspecValidator validator = new PubspecValidator(
        server.resourceProvider, pubspecFile.createSource());
    AnalysisSession session = server.getAnalysisDriver(file).currentSession;
    List<engine.AnalysisError> errors = validator.validate(pubspec.nodes);
    for (engine.AnalysisError error in errors) {
      PubspecFixGenerator generator =
          new PubspecFixGenerator(error, content, pubspec);
      List<Fix> fixes = await generator.computeFixes();
      if (fixes.isNotEmpty) {
        fixes.sort(Fix.SORT_BY_RELEVANCE);
        LineInfo lineInfo = new LineInfo.fromContent(content);
        ResolvedUnitResult result = new engine.ResolvedUnitResultImpl(
            session, file, null, true, content, lineInfo, false, null, errors);
        AnalysisError serverError = newAnalysisError_fromEngine(result, error);
        AnalysisErrorFixes errorFixes = new AnalysisErrorFixes(serverError);
        errorFixesList.add(errorFixes);
        fixes.forEach((fix) {
          errorFixes.fixes.add(fix.change);
        });
      }
    }
    return errorFixesList;
  }

  /**
   * Compute and return the fixes associated with server-generated errors.
   */
  Future<List<AnalysisErrorFixes>> _computeServerErrorFixes(
      String file, int offset) async {
    Context context = server.resourceProvider.pathContext;
    if (AnalysisEngine.isDartFileName(file)) {
      return _computeDartFixes(file, offset);
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
    var params = new EditGetAvailableRefactoringsParams.fromRequest(request);
    String file = params.file;
    int offset = params.offset;
    int length = params.length;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    // add refactoring kinds
    List<RefactoringKind> kinds = <RefactoringKind>[];
    // Check nodes.
    {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        // Try EXTRACT_LOCAL_VARIABLE.
        if (new ExtractLocalRefactoring(resolvedUnit, offset, length)
            .isAvailable()) {
          kinds.add(RefactoringKind.EXTRACT_LOCAL_VARIABLE);
        }
        // Try EXTRACT_METHOD.
        if (new ExtractMethodRefactoring(
                searchEngine, resolvedUnit, offset, length)
            .isAvailable()) {
          kinds.add(RefactoringKind.EXTRACT_METHOD);
        }
        // Try EXTRACT_WIDGETS.
        if (new ExtractWidgetRefactoring(
                searchEngine, resolvedUnit, offset, length)
            .isAvailable()) {
          kinds.add(RefactoringKind.EXTRACT_WIDGET);
        }
      }
    }
    // check elements
    {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        var node = new NodeLocator(offset).searchWithin(resolvedUnit.unit);
        var element = server.getElementOfNode(node);
        if (element != null) {
          // try CONVERT_METHOD_TO_GETTER
          if (element is ExecutableElement) {
            Refactoring refactoring = new ConvertMethodToGetterRefactoring(
                searchEngine, resolvedUnit.session, element);
            RefactoringStatus status =
                await refactoring.checkInitialConditions();
            if (!status.hasFatalError) {
              kinds.add(RefactoringKind.CONVERT_METHOD_TO_GETTER);
            }
          }
          // try RENAME
          {
            RenameRefactoring renameRefactoring = new RenameRefactoring(
                refactoringWorkspace, resolvedUnit, element);
            if (renameRefactoring != null) {
              kinds.add(RefactoringKind.RENAME);
            }
          }
        }
      }
    }
    // respond
    var result = new EditGetAvailableRefactoringsResult(kinds);
    server.sendResponse(result.toResponse(request.id));
  }

  YamlMap _getOptions(SourceFactory sourceFactory, String content) {
    AnalysisOptionsProvider optionsProvider =
        new AnalysisOptionsProvider(sourceFactory);
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

  /**
   * Initializes [refactoringManager] with a new instance.
   */
  void _newRefactoringManager() {
    refactoringManager = new _RefactoringManager(server, refactoringWorkspace);
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
    int numScanParseErrors = 0;
    for (engine.AnalysisError error in errors) {
      if (error.errorCode is engine.ScannerErrorCode ||
          error.errorCode is engine.ParserErrorCode) {
        numScanParseErrors++;
      }
    }
    return numScanParseErrors;
  }
}

/**
 * An object managing a single [Refactoring] instance.
 *
 * The instance is identified by its kind, file, offset and length.
 * It is initialized when the a set of parameters is given for the first time.
 * All subsequent requests are performed on this [Refactoring] instance.
 *
 * Once new set of parameters is received, the previous [Refactoring] instance
 * is invalidated and a new one is created and initialized.
 */
class _RefactoringManager {
  static const List<RefactoringProblem> EMPTY_PROBLEM_LIST =
      const <RefactoringProblem>[];

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

  /**
   * Returns `true` if a response for the current request has not yet been sent.
   */
  bool get hasPendingRequest => request != null;

  bool get _hasFatalError {
    return initStatus.hasFatalError ||
        optionsStatus.hasFatalError ||
        finalStatus.hasFatalError;
  }

  /**
   * Checks if [refactoring] requires options.
   */
  bool get _requiresOptions {
    return refactoring is ExtractLocalRefactoring ||
        refactoring is ExtractMethodRefactoring ||
        refactoring is ExtractWidgetRefactoring ||
        refactoring is InlineMethodRefactoring ||
        refactoring is MoveFileRefactoring ||
        refactoring is RenameRefactoring;
  }

  /**
   * Cancels processing of the current request and cleans up.
   */
  void cancel() {
    if (request != null) {
      server.sendResponse(new Response.refactoringRequestCancelled(request));
      request = null;
    }
    _reset();
  }

  void getRefactoring(Request _request) {
    // prepare for processing the request
    request = _request;
    result = new EditGetRefactoringResult(
        EMPTY_PROBLEM_LIST, EMPTY_PROBLEM_LIST, EMPTY_PROBLEM_LIST);
    // process the request
    var params = new EditGetRefactoringParams.fromRequest(_request);
    var file = params.file;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    if (params.kind != null) {
      server.options.analytics
          ?.sendEvent('refactor', params.kind.name.toLowerCase());
    }

    runZoned(() async {
      // TODO(brianwilkerson) Determine whether this await is necessary.
      await null;
      await _init(params.kind, file, params.offset, params.length);
      if (initStatus.hasFatalError) {
        feedback = null;
        _sendResultResponse();
        return;
      }
      // set options
      if (_requiresOptions) {
        if (params.options == null) {
          optionsStatus = new RefactoringStatus();
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
        finalStatus = new RefactoringStatus();
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
    }, onError: (exception, stackTrace) {
      if (exception is _ResetError ||
          exception is InconsistentAnalysisException) {
        cancel();
      } else {
        server.instrumentationService.logException(exception, stackTrace);
        server.sendResponse(
            new Response.serverError(_request, exception, stackTrace));
      }
      _reset();
    });
  }

  void _checkForReset_afterCreateChange() {
    if (test_simulateRefactoringReset_afterCreateChange) {
      _reset();
    }
    if (refactoring == null) {
      throw new _ResetError();
    }
  }

  void _checkForReset_afterFinalConditions() {
    if (test_simulateRefactoringReset_afterFinalConditions) {
      _reset();
    }
    if (refactoring == null) {
      throw new _ResetError();
    }
  }

  void _checkForReset_afterInitialConditions() {
    if (test_simulateRefactoringReset_afterInitialConditions) {
      _reset();
    }
    if (refactoring == null) {
      throw new _ResetError();
    }
  }

  /**
   * Initializes this context to perform a refactoring with the specified
   * parameters. The existing [Refactoring] is reused or created as needed.
   */
  Future _init(
      RefactoringKind kind, String file, int offset, int length) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
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
        var node = new NodeLocator(offset).searchWithin(resolvedUnit.unit);
        var element = server.getElementOfNode(node);
        if (element != null) {
          if (element is ExecutableElement) {
            refactoring = new ConvertGetterToMethodRefactoring(
                searchEngine, resolvedUnit.session, element);
          }
        }
      }
    }
    if (kind == RefactoringKind.CONVERT_METHOD_TO_GETTER) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        var node = new NodeLocator(offset).searchWithin(resolvedUnit.unit);
        var element = server.getElementOfNode(node);
        if (element != null) {
          if (element is ExecutableElement) {
            refactoring = new ConvertMethodToGetterRefactoring(
                searchEngine, resolvedUnit.session, element);
          }
        }
      }
    }
    if (kind == RefactoringKind.EXTRACT_LOCAL_VARIABLE) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        refactoring = new ExtractLocalRefactoring(resolvedUnit, offset, length);
        feedback = new ExtractLocalVariableFeedback(
            <String>[], <int>[], <int>[],
            coveringExpressionOffsets: <int>[],
            coveringExpressionLengths: <int>[]);
      }
    }
    if (kind == RefactoringKind.EXTRACT_METHOD) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        refactoring = new ExtractMethodRefactoring(
            searchEngine, resolvedUnit, offset, length);
        feedback = new ExtractMethodFeedback(offset, length, '', <String>[],
            false, <RefactoringMethodParameter>[], <int>[], <int>[]);
      }
    }
    if (kind == RefactoringKind.EXTRACT_WIDGET) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        refactoring = new ExtractWidgetRefactoring(
            searchEngine, resolvedUnit, offset, length);
        feedback = new ExtractWidgetFeedback();
      }
    }
    if (kind == RefactoringKind.INLINE_LOCAL_VARIABLE) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        refactoring = new InlineLocalRefactoring(
          searchEngine,
          resolvedUnit,
          offset,
        );
      }
    }
    if (kind == RefactoringKind.INLINE_METHOD) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        refactoring = new InlineMethodRefactoring(
          searchEngine,
          resolvedUnit,
          offset,
        );
      }
    }
    if (kind == RefactoringKind.MOVE_FILE) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        refactoring = new MoveFileRefactoring(
            server.resourceProvider, refactoringWorkspace, resolvedUnit, file);
      }
    }
    if (kind == RefactoringKind.RENAME) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        var node = new NodeLocator(offset).searchWithin(resolvedUnit.unit);
        var element = server.getElementOfNode(node);
        if (node != null && element != null) {
          final renameElement =
              RenameRefactoring.getElementToRename(node, element);

          // do create the refactoring
          refactoring = new RenameRefactoring(
              refactoringWorkspace, resolvedUnit, renameElement.element);
          feedback = new RenameFeedback(
              renameElement.offset, renameElement.length, 'kind', 'oldName');
        }
      }
    }
    if (refactoring == null) {
      initStatus =
          new RefactoringStatus.fatal('Unable to create a refactoring');
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
        feedback = new InlineLocalVariableFeedback(
            refactoring.variableName, refactoring.referenceCount);
      }
    }
    if (refactoring is InlineMethodRefactoring) {
      InlineMethodRefactoring refactoring = this.refactoring;
      if (!initStatus.hasFatalError) {
        feedback = new InlineMethodFeedback(
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
    initStatus = new RefactoringStatus();
    optionsStatus = new RefactoringStatus();
    finalStatus = new RefactoringStatus();
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
      ExtractMethodRefactoring extractRefactoring = this.refactoring;
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
      ExtractWidgetRefactoring extractRefactoring = this.refactoring;
      ExtractWidgetOptions extractOptions = params.options;
      extractRefactoring.name = extractOptions.name;
      return extractRefactoring.checkName();
    }
    if (refactoring is InlineMethodRefactoring) {
      InlineMethodRefactoring inlineRefactoring = this.refactoring;
      InlineMethodOptions inlineOptions = params.options;
      inlineRefactoring.deleteSource = inlineOptions.deleteSource;
      inlineRefactoring.inlineAll = inlineOptions.inlineAll;
      return new RefactoringStatus();
    }
    if (refactoring is MoveFileRefactoring) {
      MoveFileRefactoring moveRefactoring = this.refactoring;
      MoveFileOptions moveOptions = params.options;
      moveRefactoring.newFile = moveOptions.newFile;
      return new RefactoringStatus();
    }
    if (refactoring is RenameRefactoring) {
      RenameRefactoring renameRefactoring = refactoring;
      RenameOptions renameOptions = params.options;
      renameRefactoring.newName = renameOptions.newName;
      return renameRefactoring.checkNewName();
    }
    return new RefactoringStatus();
  }
}

/**
 * [_RefactoringManager] throws instances of this class internally to stop
 * processing in a manager that was reset.
 */
class _ResetError {}
