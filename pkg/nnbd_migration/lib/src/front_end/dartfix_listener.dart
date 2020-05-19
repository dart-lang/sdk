// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/api_for_nnbd_migration.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:meta/meta.dart';

class DartFixListener implements DartFixListenerInterface {
  @override
  final DriverProvider server;

  @override
  final SourceChange sourceChange = SourceChange('null safety migration');

  final List<DartFixSuggestion> suggestions = [];

  DartFixListener(this.server);

  @override
  void addDetail(String detail) {
    throw UnimplementedError('TODO(paulberry)');
  }

  @override
  void addEditWithoutSuggestion(Source source, SourceEdit edit) {
    sourceChange.addEdit(source.fullName, -1, edit);
  }

  @override
  void addRecommendation(String description, [Location location]) {
    throw UnimplementedError('TODO(paulberry)');
  }

  @override
  void addSourceFileEdit(
      String description, Location location, SourceFileEdit fileEdit) {
    suggestions.add(DartFixSuggestion(description, location: location));
    for (var sourceEdit in fileEdit.edits) {
      sourceChange.addEdit(fileEdit.file, fileEdit.fileStamp, sourceEdit);
    }
  }

  @override
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
