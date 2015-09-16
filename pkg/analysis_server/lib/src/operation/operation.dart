// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library operation;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * [MergeableOperation] can decide whether other operation can be merged into
 * it, so that it should not be added as a separate operation.
 */
abstract class MergeableOperation extends ServerOperation {
  MergeableOperation(AnalysisContext context) : super(context);

  /**
   * Attempt to merge the given [other] operation into this one, return `true`
   * in case of success, so that [other] should not be added as a separate
   * operation.
   */
  bool merge(ServerOperation other);
}

/**
 * The class [ServerOperation] defines the behavior of objects used to perform
 * operations on a [AnalysisServer].
 */
abstract class ServerOperation {
  /**
   * The context for this operation.  Operations will be automatically
   * de-queued when their context is destroyed.
   */
  final AnalysisContext context;

  ServerOperation(this.context);

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
 * The enumeration [ServerOperationPriority] defines the priority levels used
 * to organize [ServerOperation]s in an optimal order. A smaller ordinal value
 * equates to a higher priority.
 */
class ServerOperationPriority {
  static const int COUNT = 6;

  static const ServerOperationPriority ANALYSIS_NOTIFICATION =
      const ServerOperationPriority._(0, "ANALYSIS_NOTIFICATION");

  static const ServerOperationPriority ANALYSIS_INDEX =
      const ServerOperationPriority._(1, "ANALYSIS_INDEX");

  static const ServerOperationPriority PRIORITY_ANALYSIS_CONTINUE =
      const ServerOperationPriority._(2, "PRIORITY_ANALYSIS_CONTINUE");

  static const ServerOperationPriority PRIORITY_ANALYSIS =
      const ServerOperationPriority._(3, "PRIORITY_ANALYSIS");

  static const ServerOperationPriority ANALYSIS_CONTINUE =
      const ServerOperationPriority._(4, "ANALYSIS_CONTINUE");

  static const ServerOperationPriority ANALYSIS =
      const ServerOperationPriority._(5, "ANALYSIS");

  final int ordinal;
  final String name;

  const ServerOperationPriority._(this.ordinal, this.name);

  @override
  String toString() => name;
}

/**
 * [SourceSensitiveOperation] can decide if the operation should be discarded
 * before a change is applied to a [Source].
 */
abstract class SourceSensitiveOperation extends ServerOperation {
  SourceSensitiveOperation(AnalysisContext context) : super(context);

  /**
   * The given [source] is about to be changed.
   * Check if this [SourceSensitiveOperation] should be discarded.
   */
  bool shouldBeDiscardedOnSourceChange(Source source);
}
