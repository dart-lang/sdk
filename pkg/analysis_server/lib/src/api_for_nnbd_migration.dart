// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/// Abstract interface formerly used by NNBD migration to report changes to the
/// analysis server.  Now that the analysis server no longer integrates with
/// NNBD migration, this exists only to support some tests that haven't yet been
/// modified to use the new NNBD migration infrastructure.
///
/// TODO(paulberry): remove this interface once it's no longer needed.
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

/// Abstract interface formerly used by NNBD migration to access the resource
/// provider and the analysis session.  Now that the analysis server no longer
/// integrates with NNBD migration, this exists only to support some tests that
/// haven't yet been modified to use the new NNBD migration infrastructure.
///
/// TODO(paulberry): remove this interface once it's no longer needed.
abstract class DriverProvider {
  ResourceProvider get resourceProvider;

  /// Return the appropriate analysis session for the file with the given
  /// [path].
  AnalysisSession getAnalysisSession(String path);
}
