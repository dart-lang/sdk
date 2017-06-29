// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';

/**
 * A concrete implementation of [AssistCollector].
 */
class AssistCollectorImpl implements AssistCollector {
  /**
   * The list of assists that have been collected.
   */
  final List<PrioritizedSourceChange> assists = <PrioritizedSourceChange>[];

  @override
  void addAssist(PrioritizedSourceChange assist) {
    assists.add(assist);
  }
}

/**
 * A concrete implementation of [DartAssistRequest].
 */
class DartAssistRequestImpl implements DartAssistRequest {
  @override
  final ResourceProvider resourceProvider;

  @override
  final int offset;

  @override
  final int length;

  @override
  final ResolveResult result;

  /**
   * Initialize a newly create request with the given data.
   */
  DartAssistRequestImpl(
      this.resourceProvider, this.offset, this.length, this.result);
}
