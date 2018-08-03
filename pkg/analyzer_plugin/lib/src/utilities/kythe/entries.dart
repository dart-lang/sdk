// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/kythe/entries.dart';

/**
 * A concrete implementation of [EntryRequest].
 */
class DartEntryRequestImpl implements DartEntryRequest {
  @override
  final ResourceProvider resourceProvider;

  @override
  final ResolveResult result;

  /**
   * Initialize a newly create request with the given data.
   */
  DartEntryRequestImpl(this.resourceProvider, this.result);

  @override
  String get path => result.path;
}

/**
 * A concrete implementation of [EntryCollector].
 */
class EntryCollectorImpl implements EntryCollector {
  /**
   * A list of entries.
   */
  final List<KytheEntry> entries = <KytheEntry>[];

  /**
   * A list of paths to files.
   */
  final List<String> files = <String>[];

  @override
  void addEntry(KytheEntry entry) {
    entries.add(entry);
  }
}
