// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:analyzer_plugin/utilities/folding/folding.dart';

/**
 * A concrete implementation of [DartFoldingRequest].
 */
class DartFoldingRequestImpl implements DartFoldingRequest {
  @override
  final ResourceProvider resourceProvider;

  @override
  final ResolveResult result;

  /**
   * Initialize a newly create request with the given data.
   */
  DartFoldingRequestImpl(this.resourceProvider, this.result);

  @override
  String get path => result.path;
}

/**
 * A concrete implementation of [FoldingCollector].
 */
class FoldingCollectorImpl implements FoldingCollector {
  /**
   * The list of folding regions that have been collected.
   */
  List<FoldingRegion> regions = <FoldingRegion>[];

  /**
   * Initialize a newly created collector.
   */
  FoldingCollectorImpl();

  @override
  void addRange(SourceRange range, FoldingKind kind) {
    addRegion(range.offset, range.length, kind);
  }

  @override
  void addRegion(int offset, int length, FoldingKind kind) {
    regions.add(new FoldingRegion(kind, offset, length));
  }
}
