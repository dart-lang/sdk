// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library edit.domain;

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/collections.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/sort_members.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/error.dart' as engine;
import 'package:analyzer/src/generated/parser.dart' as engine;
import 'package:analyzer/src/generated/scanner.dart' as engine;
import 'package:analyzer/src/generated/source.dart';
import 'package:dart_style/dart_style.dart';


bool test_simulateRefactoringException_change = false;
bool test_simulateRefactoringException_final = false;
bool test_simulateRefactoringException_init = false;


/**
 * Instances of the class [EditDomainHandler] implement a [RequestHandler]
 * that handles requests in the edit domain.
 */
class EditDomainHandler implements RequestHandler {
  /**
   * The analysis server that is using this handler to process requests.
   */
  final AnalysisServer server;

  /**
   * The [SearchEngine] for this server.
   */
  SearchEngine searchEngine;

  _RefactoringManager refactoringManager;

  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  EditDomainHandler(this.server) {
    searchEngine = server.searchEngine;
    _newRefactoringManager();
  }

  Response format(Request request) {

    EditFormatParams params = new EditFormatParams.fromRequest(request);
    String file = params.file;

    engine.AnalysisContext context = server.getAnalysisContext(file);
    if (context == null) {
      return new Response.formatInvalidFile(request);
    }

    Source source = server.getSource(file);
    engine.TimestampedData<String> contents;
    try {
      contents = context.getContents(source);
    } catch (e) {
      return new Response.formatInvalidFile(request);
    }

    String unformattedSource = contents.data;

    int start = params.selectionOffset;
    int length = params.selectionLength;

    // No need to preserve 0,0 selection
    if (start == 0 && length == 0) {
      start = null;
      length = null;
    }

    SourceCode code = new SourceCode(
        unformattedSource,
        uri: null,
        isCompilationUnit: true,
        selectionStart: start,
        selectionLength: length);
    DartFormatter formatter = new DartFormatter();
    SourceCode formattedResult = formatter.formatSource(code);
    String formattedSource = formattedResult.text;

    List<SourceEdit> edits = <SourceEdit>[];

    if (formattedSource != unformattedSource) {
      //TODO: replace full replacements with smaller, more targeted edits
      SourceEdit edit =
          new SourceEdit(0, unformattedSource.length, formattedSource);
      edits.add(edit);
    }

    return new EditFormatResult(
        edits,
        formattedResult.selectionStart,
        formattedResult.selectionLength).toResponse(request.id);
  }

  Response getAssists(Request request) {
    var params = new EditGetAssistsParams.fromRequest(request);
    List<SourceChange> changes = <SourceChange>[];
    List<CompilationUnit> units =
        server.getResolvedCompilationUnits(params.file);
    if (units.isNotEmpty) {
      CompilationUnit unit = units[0];
      List<Assist> assists = computeAssists(unit, params.offset, params.length);
      assists.forEach((Assist assist) {
        changes.add(assist.change);
      });
    }
    // respond
    return new EditGetAssistsResult(changes).toResponse(request.id);
  }

  Response getFixes(Request request) {
    var params = new EditGetFixesParams.fromRequest(request);
    String file = params.file;
    int offset = params.offset;
    // add fixes
    List<AnalysisErrorFixes> errorFixesList = <AnalysisErrorFixes>[];
    List<CompilationUnit> units = server.getResolvedCompilationUnits(file);
    for (CompilationUnit unit in units) {
      engine.AnalysisErrorInfo errorInfo = server.getErrors(file);
      if (errorInfo != null) {
        LineInfo lineInfo = errorInfo.lineInfo;
        int requestLine = lineInfo.getLocation(offset).lineNumber;
        for (engine.AnalysisError error in errorInfo.errors) {
          int errorLine = lineInfo.getLocation(error.offset).lineNumber;
          if (errorLine == requestLine) {
            List<Fix> fixes = computeFixes(unit, error);
            if (fixes.isNotEmpty) {
              AnalysisError serverError =
                  newAnalysisError_fromEngine(lineInfo, error);
              AnalysisErrorFixes errorFixes =
                  new AnalysisErrorFixes(serverError);
              errorFixesList.add(errorFixes);
              fixes.forEach((fix) {
                errorFixes.fixes.add(fix.change);
              });
            }
          }
        }
      }
    }
    // respond
    return new EditGetFixesResult(errorFixesList).toResponse(request.id);
  }

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == EDIT_FORMAT) {
        return format(request);
      } else if (requestName == EDIT_GET_ASSISTS) {
        return getAssists(request);
      } else if (requestName == EDIT_GET_AVAILABLE_REFACTORINGS) {
        return _getAvailableRefactorings(request);
      } else if (requestName == EDIT_GET_FIXES) {
        return getFixes(request);
      } else if (requestName == EDIT_GET_REFACTORING) {
        return _getRefactoring(request);
      } else if (requestName == EDIT_SORT_MEMBERS) {
        return sortMembers(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  Response sortMembers(Request request) {
    var params = new EditSortMembersParams.fromRequest(request);
    // prepare file
    String file = params.file;
    if (!engine.AnalysisEngine.isDartFileName(file)) {
      return new Response.sortMembersInvalidFile(request);
    }
    // prepare resolved units
    List<CompilationUnit> units = server.getResolvedCompilationUnits(file);
    if (units.isEmpty) {
      return new Response.sortMembersInvalidFile(request);
    }
    // prepare context
    CompilationUnit unit = units.first;
    engine.AnalysisContext context = unit.element.context;
    Source source = unit.element.source;
    // check if there are no scan/parse errors in the file
    engine.AnalysisErrorInfo errors = context.getErrors(source);
    int numScanParseErrors = 0;
    errors.errors.forEach((engine.AnalysisError error) {
      if (error.errorCode is engine.ScannerErrorCode ||
          error.errorCode is engine.ParserErrorCode) {
        numScanParseErrors++;
      }
    });
    if (numScanParseErrors != 0) {
      return new Response.sortMembersParseErrors(request, numScanParseErrors);
    }
    // do sort
    int fileStamp = context.getModificationStamp(source);
    String code = context.getContents(source).data;
    MemberSorter sorter = new MemberSorter(code, unit);
    List<SourceEdit> edits = sorter.sort();
    SourceFileEdit fileEdit = new SourceFileEdit(file, fileStamp, edits: edits);
    return new EditSortMembersResult(fileEdit).toResponse(request.id);
  }

  Response _getAvailableRefactorings(Request request) {
    if (searchEngine == null) {
      return new Response.noIndexGenerated(request);
    }
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
      List<Element> elements = server.getElementsAtOffset(file, offset);
      if (elements.isNotEmpty) {
        Element element = elements[0];
        // try CONVERT_METHOD_TO_GETTER
        if (element is ExecutableElement) {
          Refactoring refactoring =
              new ConvertMethodToGetterRefactoring(searchEngine, element);
          RefactoringStatus status = await refactoring.checkInitialConditions();
          if (!status.hasFatalError) {
            kinds.add(RefactoringKind.CONVERT_METHOD_TO_GETTER);
          }
        }
        // try RENAME
        {
          RenameRefactoring renameRefactoring =
              new RenameRefactoring(searchEngine, element);
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
    if (searchEngine == null) {
      return new Response.noIndexGenerated(request);
    }
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
  static const List<RefactoringProblem> EMPTY_PROBLEM_LIST = const
      <RefactoringProblem>[
      ];

  final AnalysisServer server;
  final SearchEngine searchEngine;
  StreamSubscription onAnalysisStartedSubscription;

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
    onAnalysisStartedSubscription = server.onAnalysisStarted.listen(_reset);
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
    onAnalysisStartedSubscription.cancel();
    server.sendResponse(new Response.refactoringRequestCancelled(request));
    request = null;
  }

  void getRefactoring(Request _request) {
    // prepare for processing the request
    request = _request;
    result = new EditGetRefactoringResult(
        EMPTY_PROBLEM_LIST,
        EMPTY_PROBLEM_LIST,
        EMPTY_PROBLEM_LIST);
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
      _sendResultResponse();
    }, onError: (exception, stackTrace) {
      server.instrumentationService.logException(exception, stackTrace);
      server.sendResponse(
          new Response.serverError(_request, exception, stackTrace));
      _reset();
    });
  }

  /**
   * Initializes this context to perform a refactoring with the specified
   * parameters. The existing [Refactoring] is reused or created as needed.
   */
  Future _init(RefactoringKind kind, String file, int offset,
      int length) async {
    await server.onAnalysisComplete;
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
      List<Element> elements = server.getElementsAtOffset(file, offset);
      if (elements.isNotEmpty) {
        Element element = elements[0];
        if (element is ExecutableElement) {
          refactoring =
              new ConvertGetterToMethodRefactoring(searchEngine, element);
        }
      }
    }
    if (kind == RefactoringKind.CONVERT_METHOD_TO_GETTER) {
      List<Element> elements = server.getElementsAtOffset(file, offset);
      if (elements.isNotEmpty) {
        Element element = elements[0];
        if (element is ExecutableElement) {
          refactoring =
              new ConvertMethodToGetterRefactoring(searchEngine, element);
        }
      }
    }
    if (kind == RefactoringKind.EXTRACT_LOCAL_VARIABLE) {
      List<CompilationUnit> units = server.getResolvedCompilationUnits(file);
      if (units.isNotEmpty) {
        refactoring = new ExtractLocalRefactoring(units[0], offset, length);
        feedback = new ExtractLocalVariableFeedback([], [], []);
      }
    }
    if (kind == RefactoringKind.EXTRACT_METHOD) {
      List<CompilationUnit> units = server.getResolvedCompilationUnits(file);
      if (units.isNotEmpty) {
        refactoring =
            new ExtractMethodRefactoring(searchEngine, units[0], offset, length);
        feedback =
            new ExtractMethodFeedback(offset, length, null, [], false, [], [], []);
      }
    }
    if (kind == RefactoringKind.INLINE_LOCAL_VARIABLE) {
      List<CompilationUnit> units = server.getResolvedCompilationUnits(file);
      if (units.isNotEmpty) {
        refactoring =
            new InlineLocalRefactoring(searchEngine, units[0], offset);
      }
    }
    if (kind == RefactoringKind.INLINE_METHOD) {
      List<CompilationUnit> units = server.getResolvedCompilationUnits(file);
      if (units.isNotEmpty) {
        refactoring =
            new InlineMethodRefactoring(searchEngine, units[0], offset);
      }
    }
    if (kind == RefactoringKind.MOVE_FILE) {
      engine.AnalysisContext context = server.getAnalysisContext(file);
      Source source = server.getSource(file);
      refactoring = new MoveFileRefactoring(
          server.resourceProvider.pathContext,
          searchEngine,
          context,
          source);
    }
    if (kind == RefactoringKind.RENAME) {
      List<AstNode> nodes = server.getNodesAtOffset(file, offset);
      List<Element> elements = server.getElementsOfNodes(nodes, offset);
      if (nodes.isNotEmpty && elements.isNotEmpty) {
        AstNode node = nodes[0];
        Element element = elements[0];
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
        refactoring = new RenameRefactoring(searchEngine, element);
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
    if (refactoring is ExtractLocalRefactoring) {
      ExtractLocalRefactoring refactoring = this.refactoring;
      ExtractLocalVariableFeedback feedback = this.feedback;
      feedback.names = refactoring.names;
      feedback.offsets = refactoring.offsets;
      feedback.lengths = refactoring.lengths;
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
            refactoring.variableName,
            refactoring.referenceCount);
      }
    }
    if (refactoring is InlineMethodRefactoring) {
      InlineMethodRefactoring refactoring = this.refactoring;
      if (!initStatus.hasFatalError) {
        feedback = new InlineMethodFeedback(
            refactoring.methodName,
            refactoring.isDeclaration,
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

  void _reset([engine.AnalysisContext context]) {
    kind = null;
    offset = null;
    length = null;
    refactoring = null;
    feedback = null;
    initStatus = new RefactoringStatus();
    optionsStatus = new RefactoringStatus();
    finalStatus = new RefactoringStatus();
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
