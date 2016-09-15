// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.error.pending_error;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * A pending error is an analysis error that could not be reported at the time
 * it was discovered because some piece of information might be missing. After
 * the information has been computed, the pending error can be converted into a
 * real error.
 */
abstract class PendingError {
  /**
   * Create an analysis error based on the information in the pending error.
   */
  AnalysisError toAnalysisError();
}

/**
 * A pending error used to compute either a [HintCode.MISSING_REQUIRED_PARAM] or
 * [HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS] analysis error. These errors
 * require that the value of the `@required` annotation be computed, which is
 * not always true when the error is discovered.
 */
class PendingMissingRequiredParameterError implements PendingError {
  /**
   * The source against which the error will be reported.
   */
  final Source source;

  /**
   * The name of the parameter that is required.
   */
  final String parameterName;

  /**
   * The offset of the name of the method / function at the invocation site.
   */
  final int offset;

  /**
   * The length of the name of the method / function at the invocation site.
   */
  final int length;

  /**
   * The `@required` annotation whose value is used to compose the error message.
   */
  final ElementAnnotation annotation;

  /**
   * Initialize a newly created pending error.
   */
  PendingMissingRequiredParameterError(
      this.source, this.parameterName, AstNode node, this.annotation)
      : offset = node.offset,
        length = node.length;

  @override
  AnalysisError toAnalysisError() {
    HintCode errorCode;
    List<String> arguments;
    DartObject constantValue = annotation.constantValue;
    String reason = constantValue?.getField('reason')?.toStringValue();
    if (reason != null) {
      errorCode = HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS;
      arguments = [parameterName, reason];
    } else {
      errorCode = HintCode.MISSING_REQUIRED_PARAM;
      arguments = [parameterName];
    }
    return new AnalysisError(source, offset, length, errorCode, arguments);
  }
}
