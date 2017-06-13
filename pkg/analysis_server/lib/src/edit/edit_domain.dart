// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/plugin/edit/assist/assist_dart.dart';
import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/plugin/edit/fix/fix_dart.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/collections.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_abstract.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/plugin/result_converter.dart';
import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/completion/statement/statement_completion.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analysis_server/src/services/correction/organize_directives.dart';
import 'package:analysis_server/src/services/correction/sort_members.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' as engine;
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/ast_provider_driver.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/element/ast_provider.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart' as engine;
import 'package:analyzer/src/error/codes.dart' as engine;
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/parser.dart' as engine;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:dart_style/dart_style.dart';

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
   * The object used to manage uncompleted refactorings.
   */
  _RefactoringManager refactoringManager;

  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  EditDomainHandler(AnalysisServer server) : super(server) {
    searchEngine = server.searchEngine;
    _newRefactoringManager();
  }

  Response format(Request request) {
    EditFormatParams params = new EditFormatParams.fromRequest(request);
    String file = params.file;

    String unformattedSource;
    try {
      Source source = server.resourceProvider.getFile(file).createSource();
      if (server.options.enableNewAnalysisDriver) {
        unformattedSource = server.fileContentOverlay[file];
      } else {
        unformattedSource = server.overlayState.getContents(source);
      }
      unformattedSource ??= source.contents.data;
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

    SourceCode code = new SourceCode(unformattedSource,
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

    if (formattedSource != unformattedSource) {
      //TODO: replace full replacements with smaller, more targeted edits
      SourceEdit edit =
          new SourceEdit(0, unformattedSource.length, formattedSource);
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
    EditGetAssistsParams params = new EditGetAssistsParams.fromRequest(request);
    String file = params.file;
    int offset = params.offset;
    int length = params.length;

    List<SourceChange> changes = <SourceChange>[];
    //
    // Allow plugins to start computing assists.
    //
    Map<PluginInfo, Future<plugin.Response>> pluginFutures;
    plugin.EditGetAssistsParams requestParams =
        new plugin.EditGetAssistsParams(file, offset, length);
    AnalysisDriver driver = server.getAnalysisDriver(file);
    if (driver == null) {
      pluginFutures = <PluginInfo, Future<plugin.Response>>{};
    } else {
      pluginFutures = server.pluginManager
          .broadcastRequest(requestParams, contextRoot: driver.contextRoot);
    }
    //
    // Compute fixes associated with server-generated errors.
    //
    AnalysisResult result = await server.getAnalysisResult(file);
    if (result != null) {
      CompilationUnit unit = result.unit;
      CompilationUnitElement compilationUnitElement =
          resolutionMap.elementDeclaredByCompilationUnit(unit);
      DartAssistContext dartAssistContext = new _DartAssistContextForValues(
          compilationUnitElement.source,
          offset,
          length,
          driver,
          new AstProviderForDriver(driver),
          unit);
      try {
        AssistProcessor processor = new AssistProcessor(dartAssistContext);
        List<Assist> assists = await processor.compute();
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

  Future getFixes(Request request) async {
    var params = new EditGetFixesParams.fromRequest(request);
    String file = params.file;
    int offset = params.offset;

    List<AnalysisErrorFixes> errorFixesList = <AnalysisErrorFixes>[];
    //
    // Allow plugins to start computing fixes.
    //
    Map<PluginInfo, Future<plugin.Response>> pluginFutures;
    plugin.EditGetFixesParams requestParams =
        new plugin.EditGetFixesParams(file, offset);
    AnalysisDriver driver = server.getAnalysisDriver(file);
    if (driver == null) {
      pluginFutures = <PluginInfo, Future<plugin.Response>>{};
    } else {
      pluginFutures = server.pluginManager
          .broadcastRequest(requestParams, contextRoot: driver.contextRoot);
    }
    //
    // Compute fixes associated with server-generated errors.
    //
    AnalysisResult result = await server.getAnalysisResult(file);
    if (result != null) {
      CompilationUnit unit = result.unit;
      LineInfo lineInfo = result.lineInfo;
      int requestLine = lineInfo.getLocation(offset).lineNumber;
      for (engine.AnalysisError error in result.errors) {
        int errorLine = lineInfo.getLocation(error.offset).lineNumber;
        if (errorLine == requestLine) {
          var context = new _DartFixContextImpl(server.resourceProvider,
              result.driver, new AstProviderForDriver(driver), unit, error);
          List<Fix> fixes =
              await new DefaultFixContributor().internalComputeFixes(context);
          if (fixes.isNotEmpty) {
            fixes.sort(Fix.SORT_BY_RELEVANCE);
            AnalysisError serverError =
                newAnalysisError_fromEngine(lineInfo, error);
            AnalysisErrorFixes errorFixes = new AnalysisErrorFixes(serverError);
            errorFixesList.add(errorFixes);
            fixes.forEach((fix) {
              errorFixes.fixes.add(fix.change);
            });
          }
        }
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

  Future getStatementCompletion(Request request) async {
    var params = new EditGetStatementCompletionParams.fromRequest(request);
    SourceChange change;

    AnalysisResult result = await server.getAnalysisResult(params.file);
    if (result != null) {
      CompilationUnit unit = result.unit;
      CompilationUnitElement unitElement =
          resolutionMap.elementDeclaredByCompilationUnit(unit);
      if (unitElement.context != null) {
        StatementCompletionContext context = new StatementCompletionContext(
            params.file,
            result.lineInfo,
            params.offset,
            unit,
            unitElement,
            result.errors);
        StatementCompletionProcessor processor =
            new StatementCompletionProcessor(context);
        StatementCompletion completion = await processor.compute();
        change = completion.change;
      }
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
      if (requestName == EDIT_FORMAT) {
        return format(request);
      } else if (requestName == EDIT_GET_ASSISTS) {
        getAssists(request);
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_GET_AVAILABLE_REFACTORINGS) {
        return _getAvailableRefactorings(request);
      } else if (requestName == EDIT_GET_FIXES) {
        getFixes(request);
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_GET_REFACTORING) {
        return _getRefactoring(request);
      } else if (requestName == EDIT_ORGANIZE_DIRECTIVES) {
        organizeDirectives(request);
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_SORT_MEMBERS) {
        sortMembers(request);
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_GET_STATEMENT_COMPLETION) {
        getStatementCompletion(request);
        return Response.DELAYED_RESPONSE;
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  Future<Null> organizeDirectives(Request request) async {
    var params = new EditOrganizeDirectivesParams.fromRequest(request);
    // prepare file
    String file = params.file;
    if (!engine.AnalysisEngine.isDartFileName(file)) {
      server.sendResponse(new Response.fileNotAnalyzed(request, file));
      return;
    }
    // Prepare the file information.
    int fileStamp;
    String code;
    CompilationUnit unit;
    List<engine.AnalysisError> errors;
    if (server.options.enableNewAnalysisDriver) {
      AnalysisResult result = await server.getAnalysisResult(file);
      if (result == null) {
        server.sendResponse(new Response.fileNotAnalyzed(request, file));
        return;
      }
      fileStamp = -1;
      code = result.content;
      unit = result.unit;
      errors = result.errors;
    } else {
      // prepare resolved unit
      unit = await server.getResolvedCompilationUnit(file);
      if (unit == null) {
        server.sendResponse(new Response.fileNotAnalyzed(request, file));
        return;
      }
      // prepare context
      CompilationUnitElement compilationUnitElement =
          resolutionMap.elementDeclaredByCompilationUnit(unit);
      engine.AnalysisContext context = compilationUnitElement.context;
      Source source = compilationUnitElement.source;
      errors = context.computeErrors(source);
      // prepare code
      fileStamp = context.getModificationStamp(source);
      code = context.getContents(source).data;
    }
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

  Future<Null> sortMembers(Request request) async {
    var params = new EditSortMembersParams.fromRequest(request);
    // prepare file
    String file = params.file;
    if (!engine.AnalysisEngine.isDartFileName(file)) {
      server.sendResponse(new Response.sortMembersInvalidFile(request));
      return;
    }
    // Prepare the file information.
    int fileStamp;
    String code;
    CompilationUnit unit;
    List<engine.AnalysisError> errors;
    if (server.options.enableNewAnalysisDriver) {
      AnalysisDriver driver = server.getAnalysisDriver(file);
      ParseResult result = await driver?.parseFile(file);
      if (result == null) {
        server.sendResponse(new Response.fileNotAnalyzed(request, file));
        return;
      }
      fileStamp = -1;
      code = result.content;
      unit = result.unit;
      errors = result.errors;
    } else {
      // prepare location
      ContextSourcePair contextSource = server.getContextSourcePair(file);
      engine.AnalysisContext context = contextSource.context;
      Source source = contextSource.source;
      if (context == null || source == null) {
        server.sendResponse(new Response.sortMembersInvalidFile(request));
        return;
      }
      // prepare code
      fileStamp = context.getModificationStamp(source);
      code = context.getContents(source).data;
      // prepare parsed unit
      try {
        unit = context.parseCompilationUnit(source);
      } catch (e) {
        server.sendResponse(new Response.sortMembersInvalidFile(request));
        return;
      }
      // Get the errors.
      errors = context.getErrors(source).errors;
    }
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

  Response _getAvailableRefactorings(Request request) {
    _getAvailableRefactoringsImpl(request);
    return Response.DELAYED_RESPONSE;
  }

  Future _getAvailableRefactoringsImpl(Request request) async {
    // prepare parameters
    var params = new EditGetAvailableRefactoringsParams.fromRequest(request);
    String file = params.file;
    int offset = params.offset;
    int length = params.length;
    // add refactoring kinds
    List<RefactoringKind> kinds = <RefactoringKind>[];
    // try EXTRACT_*
    if (length != 0) {
      kinds.add(RefactoringKind.EXTRACT_LOCAL_VARIABLE);
      kinds.add(RefactoringKind.EXTRACT_METHOD);
    }
    // check elements
    {
      Element element = await server.getElementAtOffset(file, offset);
      if (element != null) {
        // try CONVERT_METHOD_TO_GETTER
        if (element is ExecutableElement) {
          Refactoring refactoring = new ConvertMethodToGetterRefactoring(
              searchEngine, server.getAstProvider(file), element);
          RefactoringStatus status = await refactoring.checkInitialConditions();
          if (!status.hasFatalError) {
            kinds.add(RefactoringKind.CONVERT_METHOD_TO_GETTER);
          }
        }
        // try RENAME
        {
          RenameRefactoring renameRefactoring = new RenameRefactoring(
              searchEngine, server.getAstProvider(file), element);
          if (renameRefactoring != null) {
            kinds.add(RefactoringKind.RENAME);
          }
        }
      }
    }
    // respond
    var result = new EditGetAvailableRefactoringsResult(kinds);
    server.sendResponse(result.toResponse(request.id));
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
    refactoringManager = new _RefactoringManager(server, searchEngine);
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
 * Implementation of [DartAssistContext] that is based on the values passed
 * in the constructor, as opposite to be partially based on [AssistContext].
 */
class _DartAssistContextForValues implements DartAssistContext {
  @override
  final Source source;

  @override
  final int selectionOffset;

  @override
  final int selectionLength;

  @override
  final AnalysisDriver analysisDriver;

  @override
  final AstProvider astProvider;

  @override
  final CompilationUnit unit;

  _DartAssistContextForValues(this.source, this.selectionOffset,
      this.selectionLength, this.analysisDriver, this.astProvider, this.unit);
}

/**
 * And implementation of [DartFixContext].
 */
class _DartFixContextImpl implements DartFixContext {
  @override
  final ResourceProvider resourceProvider;

  @override
  final AnalysisDriver analysisDriver;

  @override
  final AstProvider astProvider;

  @override
  final CompilationUnit unit;

  @override
  final engine.AnalysisError error;

  _DartFixContextImpl(this.resourceProvider, this.analysisDriver,
      this.astProvider, this.unit, this.error);

  @override
  GetTopLevelDeclarations get getTopLevelDeclarations =>
      analysisDriver.getTopLevelNameDeclarations;
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

  _RefactoringManager(this.server, this.searchEngine) {
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
    runZoned(() async {
      await _init(params.kind, params.file, params.offset, params.length);
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
      result.potentialEdits = nullIfEmpty(refactoring.potentialEditIds);
      _checkForReset_afterCreateChange();
      _sendResultResponse();
    }, onError: (exception, stackTrace) {
      if (exception is _ResetError) {
        cancel();
      } else {
        server.instrumentationService.logException(exception, stackTrace);
        server.sendResponse(
            new Response.serverError(_request, exception, stackTrace));
      }
      _reset();
    });
  }

  /**
   * Perform enough analysis to be able to perform refactoring of the given
   * [kind] in the given [file].
   */
  Future<Null> _analyzeForRefactoring(String file, RefactoringKind kind) async {
    if (server.options.enableNewAnalysisDriver) {
      return;
    }
    // "Extract Local" and "Inline Local" refactorings need only local analysis.
    if (kind == RefactoringKind.EXTRACT_LOCAL_VARIABLE ||
        kind == RefactoringKind.INLINE_LOCAL_VARIABLE) {
      ContextSourcePair pair = server.getContextSourcePair(file);
      engine.AnalysisContext context = pair.context;
      Source source = pair.source;
      if (context != null && source != null) {
        if (context.computeResult(source, SOURCE_KIND) == SourceKind.LIBRARY) {
          await context.computeResolvedCompilationUnitAsync(source, source);
          return;
        }
      }
    }
    // A refactoring for which we cannot optimize analysis.
    // So, wait for full analysis.
    await server.onAnalysisComplete;
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
    await _analyzeForRefactoring(file, kind);
    // check if we can continue with the existing Refactoring instance
    if (this.kind == kind &&
        this.file == file &&
        this.offset == offset &&
        this.length == length) {
      return;
    }
    _reset();
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
      Element element = await server.getElementAtOffset(file, offset);
      if (element != null) {
        if (element is ExecutableElement) {
          _resetOnAnalysisStarted();
          refactoring = new ConvertGetterToMethodRefactoring(
              searchEngine, server.getAstProvider(file), element);
        }
      }
    }
    if (kind == RefactoringKind.CONVERT_METHOD_TO_GETTER) {
      Element element = await server.getElementAtOffset(file, offset);
      if (element != null) {
        if (element is ExecutableElement) {
          _resetOnAnalysisStarted();
          refactoring = new ConvertMethodToGetterRefactoring(
              searchEngine, server.getAstProvider(file), element);
        }
      }
    }
    if (kind == RefactoringKind.EXTRACT_LOCAL_VARIABLE) {
      CompilationUnit unit = await server.getResolvedCompilationUnit(file);
      if (unit != null) {
        _resetOnFileResolutionChanged(file);
        refactoring = new ExtractLocalRefactoring(unit, offset, length);
        feedback = new ExtractLocalVariableFeedback(
            <String>[], <int>[], <int>[],
            coveringExpressionOffsets: <int>[],
            coveringExpressionLengths: <int>[]);
      }
    }
    if (kind == RefactoringKind.EXTRACT_METHOD) {
      CompilationUnit unit = await server.getResolvedCompilationUnit(file);
      if (unit != null) {
        _resetOnAnalysisStarted();
        refactoring =
            new ExtractMethodRefactoring(searchEngine, unit, offset, length);
        feedback = new ExtractMethodFeedback(offset, length, '', <String>[],
            false, <RefactoringMethodParameter>[], <int>[], <int>[]);
      }
    }
    if (kind == RefactoringKind.INLINE_LOCAL_VARIABLE) {
      CompilationUnit unit = await server.getResolvedCompilationUnit(file);
      if (unit != null) {
        _resetOnFileResolutionChanged(file);
        refactoring = new InlineLocalRefactoring(
            searchEngine, server.getAstProvider(file), unit, offset);
      }
    }
    if (kind == RefactoringKind.INLINE_METHOD) {
      CompilationUnit unit = await server.getResolvedCompilationUnit(file);
      if (unit != null) {
        _resetOnAnalysisStarted();
        refactoring = new InlineMethodRefactoring(
            searchEngine, server.getAstProvider(file), unit, offset);
      }
    }
    if (kind == RefactoringKind.MOVE_FILE) {
      _resetOnAnalysisStarted();
      ContextSourcePair contextSource = server.getContextSourcePair(file);
      engine.AnalysisContext context = contextSource.context;
      Source source = contextSource.source;
      refactoring = new MoveFileRefactoring(
          server.resourceProvider, searchEngine, context, source, file);
    }
    if (kind == RefactoringKind.RENAME) {
      AstNode node = await server.getNodeAtOffset(file, offset);
      Element element = server.getElementOfNode(node);
      if (node != null && element != null) {
        if (element is FieldFormalParameterElement) {
          element = (element as FieldFormalParameterElement).field;
        }
        // climb from "Class" in "new Class.named()" to "Class.named"
        if (node.parent is TypeName && node.parent.parent is ConstructorName) {
          ConstructorName constructor = node.parent.parent;
          node = constructor;
          element = constructor.staticElement;
        }
        // do create the refactoring
        _resetOnAnalysisStarted();
        refactoring = new RenameRefactoring(
            searchEngine, server.getAstProvider(file), element);
        feedback =
            new RenameFeedback(node.offset, node.length, 'kind', 'oldName');
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

  void _resetOnAnalysisStarted() {
    subscriptionToReset?.cancel();
    subscriptionToReset = server.onAnalysisStarted.listen((_) => _reset());
  }

  /**
   * We're performing a refactoring that affects only the given [file].
   * So, when the [file] resolution is changed, we need to reset refactoring.
   * But when any other file is changed or analyzed, we can continue.
   */
  void _resetOnFileResolutionChanged(String file) {
    if (server.options.enableNewAnalysisDriver) {
      return;
    }
    subscriptionToReset?.cancel();
    subscriptionToReset = server
        .getAnalysisContext(file)
        ?.onResultChanged(RESOLVED_UNIT)
        ?.listen((event) {
      Source targetSource = event.target.source;
      if (targetSource?.fullName == file) {
        _reset();
      }
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
