// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library operation;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;


/**
 * The enumeration [ServerOperationPriority] defines the priority levels used
 * to organize [ServerOperation]s in an optimal order. A smaller ordinal value
 * equates to a higher priority.
 */
class ServerOperationPriority {
  final int ordinal;
  final String name;

  static const int COUNT = 4;

  static const ServerOperationPriority ANALYSIS_CONTINUE = const ServerOperationPriority._(0, "ANALYSIS_CONTINUE");
  static const ServerOperationPriority ANALYSIS = const ServerOperationPriority._(1, "ANALYSIS");
  static const ServerOperationPriority SEARCH = const ServerOperationPriority._(2, "SEARCH");
  static const ServerOperationPriority REFACTORING = const ServerOperationPriority._(3, "REFACTORING");

  @override
  String toString() => name;

  const ServerOperationPriority._(this.ordinal, this.name);
}


/**
 * The class [ServerOperation] defines the behavior of objects used to perform
 * operations on a [AnalysisServer].
 */
abstract class ServerOperation {
  /**
   * Returns the priority of this operation.
   */
  ServerOperationPriority get priority;

  /**
   * Performs the operation implemented by this operation.
   */
  void perform(AnalysisServer server);
}


/**
 * Instances of [PerformAnalysisOperation] perform a single analysis task.
 */
class PerformAnalysisOperation extends ServerOperation {
  final AnalysisContext context;
  final bool isContinue;

  PerformAnalysisOperation(this.context, this.isContinue);

  @override
  ServerOperationPriority get priority {
    if (isContinue) {
      return ServerOperationPriority.ANALYSIS_CONTINUE;
    } else {
      return ServerOperationPriority.ANALYSIS;
    }
  }

  @override
  void perform(AnalysisServer server) {
    server.internalPerformAnalysis(context);
  }
}