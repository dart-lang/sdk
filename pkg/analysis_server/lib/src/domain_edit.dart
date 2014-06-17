// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domain.edit;

import 'package:analyzer/src/generated/error.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';

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
   * Initialize a newly created handler to handle requests for the given [server].
   */
  EditDomainHandler(this.server);

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
    // errors
    RequestDatum errorsDatum = request.getRequiredParameter(ERRORS);
    List<AnalysisError> errors = errorsDatum.asList((RequestDatum datum) {
      return _createAnalysisError(request, datum);
    });
    // TODO(brianwilkerson) implement
    return null;
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

  Response setRefactoringOptions(Request request) {
    // id
    RequestDatum idDatum = request.getRequiredParameter(ID);
    String id = idDatum.asString();
    // TODO(brianwilkerson) implement
    return null;
  }

  /**
   * Convert the given data from a request into an analysis error.
   */
  AnalysisError _createAnalysisError(Request request, RequestDatum datum) {
    String file = datum[FILE].asString();
    String errorCodeName = datum[ERROR_CODE].asString();
    int offset = datum[OFFSET].asInt();
    int length = datum[LENGTH].asInt();
    String message = datum[MESSAGE].asString();
    String correction;
    if (datum.hasKey(CORRECTION)) {
      correction = datum[CORRECTION].asString();
    }
    ErrorCode errorCode = convertErrorCode(errorCodeName);
    if (errorCode == null) {
//      throw new RequestFailure(new Response.invalidErrorCode(request));
    }
    // TODO(brianwilkerson) Implement this.
//    return new AnalysisError.con2(
//        server.sourceFromFile(file),
//        offset,
//        length,
//        errorCode,
//        null);
    return null;
  }

  /**
   * Return the error code corresponding to the given [errorCodeName], or `null`
   * if the given name is not a valid error code.
   */
  ErrorCode convertErrorCode(String errorCodeName) {
    // TODO(brianwilkerson) Implement this.
//    Enum2 errorCode = Enum2.valueOf(AngularCode.values, errorCodeName);
//    if (errorCode == null) {
//      errorCode = Enum2.valueOf(CompileTimeErrorCode.values, errorCodeName);
//    }
//    if (errorCode == null) {
//      errorCode = Enum2.valueOf(HintCode.values, errorCodeName);
//    }
//    if (errorCode == null) {
//      errorCode = Enum2.valueOf(HtmlWarningCode.values, errorCodeName);
//    }
//    if (errorCode == null) {
//      errorCode = Enum2.valueOf(ParserErrorCode.values, errorCodeName);
//    }
//    if (errorCode == null) {
//      errorCode = Enum2.valueOf(PolymerCode.values, errorCodeName);
//    }
//    if (errorCode == null) {
//      errorCode = Enum2.valueOf(PubSuggestionCode.values, errorCodeName);
//    }
//    if (errorCode == null) {
//      errorCode = Enum2.valueOf(ResolverErrorCode.values, errorCodeName);
//    }
//    if (errorCode == null) {
//      errorCode = Enum2.valueOf(ScannerErrorCode.values, errorCodeName);
//    }
//    if (errorCode == null) {
//      errorCode = Enum2.valueOf(StaticTypeErrorCode.values, errorCodeName);
//    }
//    if (errorCode == null) {
//      errorCode = Enum2.valueOf(StaticWarningErrorCode.values, errorCodeName);
//    }
//    if (errorCode == null) {
//      errorCode = Enum2.valueOf(TodoCode.values, errorCodeName);
//    }
    return null;
  }
}
