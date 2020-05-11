// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:nnbd_migration/api_for_analysis_server/driver_provider.dart';

abstract class DartFixListenerInterface {
  DriverProvider get server;

  SourceChange get sourceChange;

  /// Add the given [detail] to the list of details to be returned to the
  /// client.
  void addDetail(String detail);

  /// Record an edit to be sent to the client.
  ///
  /// The associated suggestion should be separately added by calling
  /// [addSuggestion].
  void addEditWithoutSuggestion(Source source, SourceEdit edit);

  /// Record a recommendation to be sent to the client.
  void addRecommendation(String description, [Location location]);

  /// Record a source change to be sent to the client.
  void addSourceFileEdit(
      String description, Location location, SourceFileEdit fileEdit);

  /// Record a suggestion to be sent to the client.
  ///
  /// The associated edits should be separately added by calling
  /// [addEditWithoutRecommendation].
  void addSuggestion(String description, Location location);
}
