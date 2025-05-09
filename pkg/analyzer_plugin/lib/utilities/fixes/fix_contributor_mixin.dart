// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// A partial implementation of a [FixContributor] that iterates over the list of
/// errors and provides a utility method to make it easier to add fixes.
///
/// Clients may not extend or implement this class, but are allowed to use it as
/// a mix-in when creating a subclass of [FixContributor].
abstract class FixContributorMixin implements FixContributor {
  /// The request that specifies the fixes that are to be built.
  DartFixesRequest? request;

  /// The collector to which fixes should be added.
  FixCollector? collector;

  /// Adds a fix for the given [diagnostic]. Use the [kind] of the fix to get
  /// the message and priority, and use the change [builder] to get the edits
  /// that comprise the fix. If the message has parameters, then use the list of
  /// [args] to populate the message.
  void addFix(Diagnostic diagnostic, FixKind kind, ChangeBuilder builder,
      {List<Object>? args}) {
    var change = builder.sourceChange;
    if (change.edits.isEmpty) {
      return;
    }
    change.id = kind.id;
    change.message = formatList(kind.message, args);
    collector?.addFix(
        diagnostic, PrioritizedSourceChange(kind.priority, change));
  }

  @override
  Future<void> computeFixes(
      DartFixesRequest request, FixCollector collector) async {
    this.request = request;
    this.collector = collector;
    try {
      for (var error in request.errorsToFix) {
        await computeFixesForError(error);
      }
    } finally {
      this.request = null;
      this.collector = null;
    }
  }

  /// Computes the fixes that are appropriate for the given [diagnostic] and add
  /// them to the fix [collector].
  Future<void> computeFixesForError(Diagnostic diagnostic);
}
