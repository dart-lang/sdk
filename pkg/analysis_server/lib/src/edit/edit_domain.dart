// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library edit.domain;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/edit/fix.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/protocol2.dart' show AnalysisError,
    EditGetAssistsParams, EditGetAvailableRefactoringsParams,
    EditGetAvailableRefactoringsResult, EditGetFixesParams, RefactoringKind;
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/change.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/json.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/error.dart' as engine;
import 'package:analyzer/src/generated/source.dart';


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

  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  EditDomainHandler(this.server) {
    searchEngine = server.searchEngine;
  }

  Response getAssists(Request request) {
    var params = new EditGetAssistsParams.fromRequest(request);
    List<Change> changes = <Change>[];
    List<CompilationUnit> units =
        server.getResolvedCompilationUnits(params.file);
    if (units.isNotEmpty) {
      CompilationUnit unit = units[0];
      List<Assist> assists =
          computeAssists(searchEngine, unit, params.offset, params.length);
      assists.forEach((Assist assist) {
        changes.add(assist.change);
      });
    }
    // respond
    Response response = new Response(request.id);
    response.setResult(ASSISTS, objectToJson(changes));
    return response;
  }

  Response getAvailableRefactorings(Request request) {
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
    // try RENAME
    {
      List<Element> elements = server.getElementsAtOffset(file, offset);
      if (elements.isNotEmpty) {
        Element element = elements[0];
        RenameRefactoring renameRefactoring =
            new RenameRefactoring(searchEngine, element);
        if (renameRefactoring != null) {
          kinds.add(RefactoringKind.RENAME);
        }
      }
    }
    // respond
    return new EditGetAvailableRefactoringsResult(kinds).toResponse(request.id);
  }

  Response getFixes(Request request) {
    var params = new EditGetFixesParams.fromRequest(request);
    String file = params.file;
    int offset = params.offset;
    // add fixes
    List<ErrorFixes> errorFixesList = <ErrorFixes>[];
    List<CompilationUnit> units = server.getResolvedCompilationUnits(file);
    for (CompilationUnit unit in units) {
      engine.AnalysisErrorInfo errorInfo = server.getErrors(file);
      if (errorInfo != null) {
        LineInfo lineInfo = errorInfo.lineInfo;
        int requestLine = lineInfo.getLocation(offset).lineNumber;
        for (engine.AnalysisError error in errorInfo.errors) {
          int errorLine = lineInfo.getLocation(error.offset).lineNumber;
          if (errorLine == requestLine) {
            List<Fix> fixes = computeFixes(searchEngine, unit, error);
            if (fixes.isNotEmpty) {
              AnalysisError serverError =
                  new AnalysisError.fromEngine(lineInfo, error);
              ErrorFixes errorFixes = new ErrorFixes(serverError);
              errorFixesList.add(errorFixes);
              fixes.forEach((fix) {
                errorFixes.addFix(fix);
              });
            }
          }
        }
      }
    }
    // respond
    return new Response(request.id)..setResult(FIXES, errorFixesList);
  }

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == EDIT_GET_AVAILABLE_REFACTORINGS) {
        return getAvailableRefactorings(request);
      } else if (requestName == EDIT_GET_ASSISTS) {
        return getAssists(request);
      } else if (requestName == EDIT_GET_FIXES) {
        return getFixes(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }
}
