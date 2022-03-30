// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/collections.dart';
import 'package:analysis_server/src/domain_abstract.dart';
import 'package:analysis_server/src/handler/legacy/edit_bulk_fixes.dart';
import 'package:analysis_server/src/handler/legacy/edit_format.dart';
import 'package:analysis_server/src/handler/legacy/edit_format_if_enabled.dart';
import 'package:analysis_server/src/handler/legacy/edit_get_assists.dart';
import 'package:analysis_server/src/handler/legacy/edit_get_fixes.dart';
import 'package:analysis_server/src/handler/legacy/edit_get_postfix_completion.dart';
import 'package:analysis_server/src/handler/legacy/edit_get_statement_completion.dart';
import 'package:analysis_server/src/handler/legacy/edit_import_elements.dart';
import 'package:analysis_server/src/handler/legacy/edit_is_postfix_completion_applicable.dart';
import 'package:analysis_server/src/handler/legacy/edit_list_postfix_completion_templates.dart';
import 'package:analysis_server/src/handler/legacy/edit_organize_directives.dart';
import 'package:analysis_server/src/handler/legacy/edit_sort_members.dart';
import 'package:analysis_server/src/protocol_server.dart'
    hide AnalysisError, Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/utilities/progress.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';

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
  /// The workspace for rename refactorings.
  RefactoringWorkspace? refactoringWorkspace;

  /// The object used to manage uncompleted refactorings.
  _RefactoringManager? refactoringManager;

  /// Initialize a newly created handler to handle requests for the given
  /// [server].
  EditDomainHandler(AnalysisServer server) : super(server) {
    refactoringWorkspace =
        RefactoringWorkspace(server.driverMap.values, server.searchEngine);
    _newRefactoringManager();
  }

  @override
  Response? handleRequest(
      Request request, CancellationToken cancellationToken) {
    try {
      var requestName = request.method;
      if (requestName == EDIT_REQUEST_FORMAT) {
        EditFormatHandler(server, request, cancellationToken).handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_REQUEST_FORMAT_IF_ENABLED) {
        EditFormatIfEnabledHandler(server, request, cancellationToken).handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_REQUEST_GET_ASSISTS) {
        EditGetAssistsHandler(server, request, cancellationToken).handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_REQUEST_GET_AVAILABLE_REFACTORINGS) {
        _getAvailableRefactorings(request);
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_REQUEST_BULK_FIXES) {
        EditBulkFixes(server, request, cancellationToken).handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_REQUEST_GET_FIXES) {
        EditGetFixesHandler(server, request, cancellationToken).handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_REQUEST_GET_REFACTORING) {
        return _getRefactoring(request, cancellationToken);
      } else if (requestName == EDIT_REQUEST_IMPORT_ELEMENTS) {
        EditImportElementsHandler(server, request, cancellationToken).handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_REQUEST_ORGANIZE_DIRECTIVES) {
        EditOrganizeDirectivesHandler(server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_REQUEST_SORT_MEMBERS) {
        EditSortMembersHandler(server, request, cancellationToken).handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_REQUEST_GET_STATEMENT_COMPLETION) {
        EditGetStatementCompletionHandler(server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_REQUEST_IS_POSTFIX_COMPLETION_APPLICABLE) {
        EditIsPostfixCompletionApplicableHandler(
                server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EDIT_REQUEST_GET_POSTFIX_COMPLETION) {
        EditGetPostfixCompletionHandler(server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName ==
          EDIT_REQUEST_LIST_POSTFIX_COMPLETION_TEMPLATES) {
        EditListPostfixCompletionTemplatesHandler(
                server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  Future<void> _getAvailableRefactorings(Request request) async {
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
    final searchEngine = server.searchEngine;
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
          final refactoringWorkspace = this.refactoringWorkspace;
          if (refactoringWorkspace != null) {
            var renameRefactoring = RenameRefactoring.create(
                refactoringWorkspace, resolvedUnit, element);
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

  Response _getRefactoring(
      Request request, CancellationToken cancellationToken) {
    final refactoringManager = this.refactoringManager;
    if (refactoringManager == null) {
      return Response.unsupportedFeature(request.id, 'Search is not enabled.');
    }
    if (refactoringManager.hasPendingRequest) {
      refactoringManager.cancel();
      _newRefactoringManager();
    }
    refactoringManager.getRefactoring(request, cancellationToken);
    return Response.DELAYED_RESPONSE;
  }

  /// Initializes [refactoringManager] with a new instance.
  void _newRefactoringManager() {
    final refactoringWorkspace = this.refactoringWorkspace;
    if (refactoringWorkspace != null) {
      refactoringManager = _RefactoringManager(server, refactoringWorkspace);
    }
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
  StreamSubscription? subscriptionToReset;

  RefactoringKind? kind;
  String? file;
  int? offset;
  int? length;
  Refactoring? refactoring;
  RefactoringFeedback? feedback;
  late RefactoringStatus initStatus;
  late RefactoringStatus optionsStatus;
  late RefactoringStatus finalStatus;

  Request? request;
  EditGetRefactoringResult? result;

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
    var currentRequest = request;
    if (currentRequest != null) {
      server.sendResponse(Response.refactoringRequestCancelled(currentRequest));
      request = null;
    }
    _reset();
  }

  void getRefactoring(Request _request, CancellationToken cancellationToken) {
    // prepare for processing the request
    request = _request;
    final result = this.result = EditGetRefactoringResult(
        EMPTY_PROBLEM_LIST, EMPTY_PROBLEM_LIST, EMPTY_PROBLEM_LIST);
    // process the request
    var params = EditGetRefactoringParams.fromRequest(_request);
    var file = params.file;

    if (server.sendResponseErrorIfInvalidFilePath(_request, file)) {
      return;
    }

    server.options.analytics
        ?.sendEvent('refactor', params.kind.name.toLowerCase());

    runZonedGuarded(() async {
      await _init(
          params.kind, file, params.offset, params.length, cancellationToken);
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
      final refactoring = this.refactoring!;
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

  Future<void> _createRefactoringFromKind(String file, int offset, int length,
      CancellationToken cancellationToken) async {
    if (kind == RefactoringKind.CONVERT_GETTER_TO_METHOD) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        var node = NodeLocator(offset).searchWithin(resolvedUnit.unit);
        var element = server.getElementOfNode(node);
        if (element != null) {
          if (element is PropertyAccessorElement) {
            refactoring = ConvertGetterToMethodRefactoring(
                searchEngine, resolvedUnit.session, element);
          }
        }
      }
    } else if (kind == RefactoringKind.CONVERT_METHOD_TO_GETTER) {
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
    } else if (kind == RefactoringKind.EXTRACT_LOCAL_VARIABLE) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        refactoring = ExtractLocalRefactoring(resolvedUnit, offset, length);
        feedback = ExtractLocalVariableFeedback(<String>[], <int>[], <int>[],
            coveringExpressionOffsets: <int>[],
            coveringExpressionLengths: <int>[]);
      }
    } else if (kind == RefactoringKind.EXTRACT_METHOD) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        refactoring = ExtractMethodRefactoring(
            searchEngine, resolvedUnit, offset, length);
        feedback = ExtractMethodFeedback(offset, length, '', <String>[], false,
            <RefactoringMethodParameter>[], <int>[], <int>[]);
      }
    } else if (kind == RefactoringKind.EXTRACT_WIDGET) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        refactoring = ExtractWidgetRefactoring(
            searchEngine, resolvedUnit, offset, length);
        feedback = ExtractWidgetFeedback();
      }
    } else if (kind == RefactoringKind.INLINE_LOCAL_VARIABLE) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        refactoring = InlineLocalRefactoring(
          searchEngine,
          resolvedUnit,
          offset,
        );
      }
    } else if (kind == RefactoringKind.INLINE_METHOD) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        refactoring = InlineMethodRefactoring(
          searchEngine,
          resolvedUnit,
          offset,
        );
      }
    } else if (kind == RefactoringKind.MOVE_FILE) {
      refactoring = MoveFileRefactoring(
          server.resourceProvider, refactoringWorkspace, file)
        ..cancellationToken = cancellationToken;
    } else if (kind == RefactoringKind.RENAME) {
      var resolvedUnit = await server.getResolvedUnit(file);
      if (resolvedUnit != null) {
        var node = NodeLocator(offset).searchWithin(resolvedUnit.unit);
        var element = server.getElementOfNode(node);
        if (node != null && element != null) {
          final renameElement =
              RenameRefactoring.getElementToRename(node, element);
          if (renameElement != null) {
            // do create the refactoring
            refactoring = RenameRefactoring.create(
                refactoringWorkspace, resolvedUnit, renameElement.element);
            feedback = RenameFeedback(
                renameElement.offset, renameElement.length, 'kind', 'oldName');
          }
        }
      }
    }
  }

  /// Initializes this context to perform a refactoring with the specified
  /// parameters. The existing [Refactoring] is reused or created as needed.
  Future _init(RefactoringKind kind, String file, int offset, int length,
      CancellationToken cancellationToken) async {
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
    await _createRefactoringFromKind(file, offset, length, cancellationToken);
    final refactoring = this.refactoring;
    if (refactoring == null) {
      initStatus = RefactoringStatus.fatal('Unable to create a refactoring');
      return;
    }
    // check initial conditions
    initStatus = await refactoring.checkInitialConditions();
    _checkForReset_afterInitialConditions();
    if (refactoring is ExtractLocalRefactoring) {
      final feedback = this.feedback as ExtractLocalVariableFeedback;
      feedback.names = refactoring.names;
      feedback.offsets = refactoring.offsets;
      feedback.lengths = refactoring.lengths;
      feedback.coveringExpressionOffsets =
          refactoring.coveringExpressionOffsets;
      feedback.coveringExpressionLengths =
          refactoring.coveringExpressionLengths;
    } else if (refactoring is ExtractMethodRefactoring) {
      final feedback = this.feedback as ExtractMethodFeedback;
      feedback.canCreateGetter = refactoring.canCreateGetter;
      feedback.returnType = refactoring.returnType;
      feedback.names = refactoring.names;
      feedback.parameters = refactoring.parameters;
      feedback.offsets = refactoring.offsets;
      feedback.lengths = refactoring.lengths;
    } else if (refactoring is InlineLocalRefactoring) {
      if (!initStatus.hasFatalError) {
        feedback = InlineLocalVariableFeedback(
            refactoring.variableName ?? '', refactoring.referenceCount);
      }
    } else if (refactoring is InlineMethodRefactoring) {
      if (!initStatus.hasFatalError) {
        feedback = InlineMethodFeedback(
            refactoring.methodName ?? '', refactoring.isDeclaration,
            className: refactoring.className);
      }
    } else if (refactoring is RenameRefactoring) {
      final feedback = this.feedback as RenameFeedback;
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
    final request = this.request;
    if (request == null) {
      return;
    }
    // set feedback
    final result = this.result;
    if (result == null) {
      return;
    }
    result.feedback = feedback;
    // set problems
    result.initialProblems = initStatus.problems;
    result.optionsProblems = optionsStatus.problems;
    result.finalProblems = finalStatus.problems;
    // send the response
    server.sendResponse(result.toResponse(request.id));
    // done with this request
    this.request = null;
    this.result = null;
  }

  RefactoringStatus _setOptions(EditGetRefactoringParams params) {
    final refactoring = this.refactoring;
    if (refactoring is ExtractLocalRefactoring) {
      var extractOptions = params.options as ExtractLocalVariableOptions;
      refactoring.name = extractOptions.name;
      refactoring.extractAll = extractOptions.extractAll;
      return refactoring.checkName();
    } else if (refactoring is ExtractMethodRefactoring) {
      var extractOptions = params.options as ExtractMethodOptions;
      refactoring.createGetter = extractOptions.createGetter;
      refactoring.extractAll = extractOptions.extractAll;
      refactoring.name = extractOptions.name;
      refactoring.parameters = extractOptions.parameters;
      refactoring.returnType = extractOptions.returnType;
      return refactoring.checkName();
    } else if (refactoring is ExtractWidgetRefactoring) {
      var extractOptions = params.options as ExtractWidgetOptions;
      refactoring.name = extractOptions.name;
      return refactoring.checkName();
    } else if (refactoring is InlineMethodRefactoring) {
      var inlineOptions = params.options as InlineMethodOptions;
      refactoring.deleteSource = inlineOptions.deleteSource;
      refactoring.inlineAll = inlineOptions.inlineAll;
      return RefactoringStatus();
    } else if (refactoring is MoveFileRefactoring) {
      var moveOptions = params.options as MoveFileOptions;
      refactoring.newFile = moveOptions.newFile;
      return RefactoringStatus();
    } else if (refactoring is RenameRefactoring) {
      var renameOptions = params.options as RenameOptions;
      refactoring.newName = renameOptions.newName;
      return refactoring.checkNewName();
    }
    return RefactoringStatus();
  }
}

/// [_RefactoringManager] throws instances of this class internally to stop
/// processing in a manager that was reset.
class _ResetError {}
