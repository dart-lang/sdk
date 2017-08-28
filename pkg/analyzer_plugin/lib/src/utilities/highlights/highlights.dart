// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:analyzer_plugin/utilities/highlights/highlights.dart';

/**
 * A concrete implementation of [DartHighlightsRequest].
 */
class DartHighlightsRequestImpl implements DartHighlightsRequest {
  @override
  final ResourceProvider resourceProvider;

  @override
  final ResolveResult result;

  /**
   * Initialize a newly create request with the given data.
   */
  DartHighlightsRequestImpl(this.resourceProvider, this.result);

  @override
  String get path => result.path;
}

/**
 * A concrete implementation of [HighlightsCollector].
 */
class HighlightsCollectorImpl implements HighlightsCollector {
  /**
   * The regions that have been collected.
   */
  List<HighlightRegion> regions = <HighlightRegion>[];

  @override
  void addRange(SourceRange range, HighlightRegionType type) {
    regions.add(new HighlightRegion(type, range.offset, range.length));
  }

  @override
  void addRegion(int offset, int length, HighlightRegionType type) {
    regions.add(new HighlightRegion(type, offset, length));
  }
}
