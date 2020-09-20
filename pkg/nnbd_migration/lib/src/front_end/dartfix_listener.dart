// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:meta/meta.dart';
import 'package:nnbd_migration/src/front_end/driver_provider_impl.dart';

class DartFixListener {
  final DriverProviderImpl server;

  final SourceChange sourceChange = SourceChange('null safety migration');

  final List<DartFixSuggestion> suggestions = [];

  /// Add the given [detail] to the list of details to be returned to the
  /// client.
  final void Function(String detail) reportException;

  DartFixListener(this.server, this.reportException);

  /// Record an edit to be sent to the client.
  ///
  /// The associated suggestion should be separately added by calling
  /// [addSuggestion].
  void addEditWithoutSuggestion(Source source, SourceEdit edit) {
    sourceChange.addEdit(source.fullName, -1, edit);
  }

  /// Record a recommendation to be sent to the client.
  void addRecommendation(String description, [Location location]) {
    throw UnimplementedError('TODO(paulberry)');
  }

  /// Record a source change to be sent to the client.
  void addSourceFileEdit(
      String description, Location location, SourceFileEdit fileEdit) {
    suggestions.add(DartFixSuggestion(description, location: location));
    for (var sourceEdit in fileEdit.edits) {
      sourceChange.addEdit(fileEdit.file, fileEdit.fileStamp, sourceEdit);
    }
  }

  /// Record a suggestion to be sent to the client.
  ///
  /// The associated edits should be separately added by calling
  /// [addEditWithoutRecommendation].
  void addSuggestion(String description, Location location) {
    suggestions.add(DartFixSuggestion(description, location: location));
  }

  /// Reset this listener so that it can accrue a new set of changes.
  void reset() {
    suggestions.clear();
    sourceChange
      ..edits.clear()
      ..linkedEditGroups.clear()
      ..selection = null
      ..id = null;
  }
}

class DartFixSuggestion {
  final String description;

  final Location location;

  DartFixSuggestion(this.description, {@required this.location});
}
