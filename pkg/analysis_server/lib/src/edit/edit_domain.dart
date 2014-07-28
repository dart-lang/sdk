// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library edit.domain;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_services/constants.dart';
import 'package:analysis_services/correction/fix.dart';
import 'package:analysis_services/search/search_engine.dart';
import 'package:analyzer/src/generated/error.dart' as engine;
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analysis_server/src/computer/error.dart';
import 'package:analysis_server/src/edit/fix.dart';


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

  Response applyRefactoring(Request request) {
    // id
    RequestDatum idDatum = request.getRequiredParameter(ID);
    String id = idDatum.asString();
    // TODO(brianwilkerson) implement
    return null;
  }

  Response createRefactoring(Request request) {
    // kind
    RequestDatum kindDatum = request.getRequiredParameter(KIND);
    String kind = kindDatum.asString();
    // file
    RequestDatum fileDatum = request.getRequiredParameter(FILE);
    String file = fileDatum.asString();
    // offset
    RequestDatum offsetDatum = request.getRequiredParameter(OFFSET);
    int offset = offsetDatum.asInt();
    // length
    RequestDatum lengthDatum = request.getRequiredParameter(LENGTH);
    int length = lengthDatum.asInt();
    // TODO(brianwilkerson) implement
    return null;
  }

  Response deleteRefactoring(Request request) {
    // id
    RequestDatum idDatum = request.getRequiredParameter(ID);
    String id = idDatum.asString();
    // TODO(brianwilkerson) implement
    return null;
  }

  Response getAssists(Request request) {
    // file
    RequestDatum fileDatum = request.getRequiredParameter(FILE);
    String file = fileDatum.asString();
    // offset
    RequestDatum offsetDatum = request.getRequiredParameter(OFFSET);
    int offset = offsetDatum.asInt();
    // length
    RequestDatum lengthDatum = request.getRequiredParameter(LENGTH);
    int length = lengthDatum.asInt();
    // TODO(brianwilkerson) implement
    return null;
  }

  Response getFixes(Request request) {
    String file = request.getRequiredParameter(FILE).asString();
    int offset = request.getRequiredParameter(OFFSET).asInt();
    List<ErrorFixes> errorFixesList = <ErrorFixes>[];
    List<CompilationUnit> units = server.getResolvedCompilationUnits(file);
    for (CompilationUnit unit in units) {
      engine.AnalysisErrorInfo errorInfo = server.getErrors(file);
      if (errorInfo != null) {
        for (engine.AnalysisError error in errorInfo.errors) {
          List<Fix> fixes = computeFixes(searchEngine, unit, error);
          if (fixes.isNotEmpty) {
            AnalysisError serverError =
                new AnalysisError.fromEngine(errorInfo.lineInfo, error);
            ErrorFixes errorFixes = new ErrorFixes(serverError);
            errorFixesList.add(errorFixes);
            fixes.forEach((fix) {
              return errorFixes.addFix(fix);
            });
          }
        }
      }
    }
    // respond
    return new Response(request.id)..setResult(FIXES, errorFixesList);
  }

  Response getRefactorings(Request request) {
    // file
    RequestDatum fileDatum = request.getRequiredParameter(FILE);
    String file = fileDatum.asString();
    // offset
    RequestDatum offsetDatum = request.getRequiredParameter(OFFSET);
    int offset = offsetDatum.asInt();
    // length
    RequestDatum lengthDatum = request.getRequiredParameter(LENGTH);
    int length = lengthDatum.asInt();
    // TODO(brianwilkerson) implement
    return null;
  }

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == EDIT_APPLY_REFACTORING) {
        return applyRefactoring(request);
      } else if (requestName == EDIT_CREATE_REFACTORING) {
        return createRefactoring(request);
      } else if (requestName == EDIT_DELETE_REFACTORING) {
        return deleteRefactoring(request);
      } else if (requestName == EDIT_GET_ASSISTS) {
        return getAssists(request);
      } else if (requestName == EDIT_GET_FIXES) {
        return getFixes(request);
      } else if (requestName == EDIT_GET_REFACTORINGS) {
        return getRefactorings(request);
      } else if (requestName == EDIT_SET_REFACTORING_OPTIONS) {
        return setRefactoringOptions(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  Response setRefactoringOptions(Request request) {
    // id
    RequestDatum idDatum = request.getRequiredParameter(ID);
    String id = idDatum.asString();
    // TODO(brianwilkerson) implement
    return null;
  }
}
