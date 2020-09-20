// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:nnbd_migration/src/front_end/migration_info.dart';

/// Information about what should be populated into the "Edit Details" view of
/// the migration preview tool.
class EditDetails {
  /// A list of edits that can be offered to the user related to this source
  /// location (e.g. adding/removing hints).  `null` if this feature is
  /// disabled.
  final List<EditLink> edits;

  /// A string explanation of the edit.
  final String explanation;

  /// The line number of the edit.
  final int line;

  /// The path of the file that was edited, to be shown to the user.
  final String displayPath;

  /// The path of the file that was edited, as a URI.
  final String uriPath;

  /// A list of traces representing stacktrace-like views of why the change was
  /// made, or the empty list if there are no traces for this change.
  final List<Trace> traces;

  EditDetails(
      {this.edits,
      @required this.explanation,
      @required this.line,
      @required this.displayPath,
      @required this.uriPath,
      this.traces = const []});

  EditDetails.fromJson(dynamic json)
      : edits = _decodeEdits(json['edits']),
        explanation = json['explanation'] as String,
        line = json['line'] as int,
        displayPath = json['displayPath'] as String,
        uriPath = json['uriPath'] as String,
        traces = _decodeTraces(json['traces']);

  Map<String, Object> toJson() => {
        if (edits != null) 'edits': [for (var edit in edits) edit.toJson()],
        'explanation': explanation,
        'line': line,
        'displayPath': displayPath,
        'uriPath': uriPath,
        if (traces != null)
          'traces': [for (var trace in traces) trace.toJson()],
      };

  static List<EditLink> _decodeEdits(dynamic json) =>
      json == null ? null : [for (var edit in json) EditLink.fromJson(edit)];

  static List<Trace> _decodeTraces(dynamic json) =>
      json == null ? null : [for (var trace in json) Trace.fromJson(trace)];
}

/// Information about a single link that should be included in the
/// "Edit Details" view of the migration preview tool, where the purpose of the
/// link is to allow the user to make a change to the source file (e.g. to add
/// or remove a hint).
class EditLink {
  /// Description of the change to be performed.
  final String description;

  /// The href to link to.
  final String href;

  EditLink({@required this.description, @required this.href});

  EditLink.fromJson(dynamic json)
      : description = json['description'] as String,
        href = json['href'] as String;

  Map<String, Object> toJson() => {
        'description': description,
        'href': href,
      };
}

/// Information about a single link that should be included in the
/// "Edit Details" view of the migration preview tool, where the purpose of the
/// link is to allow the user to navigate to a source file containing
/// information about the rationale for a change.
class TargetLink {
  /// The href to link to.
  final String href;

  /// The line number of the link.
  final int line;

  /// Relative path to the source file (intended for display).
  final String path;

  TargetLink({@required this.href, @required this.line, @required this.path});

  TargetLink.fromJson(dynamic json)
      : href = json['href'] as String,
        line = json['line'] as int,
        path = json['path'] as String;

  Map<String, Object> toJson() => {
        'href': href,
        'line': line,
        'path': path,
      };
}

/// A trace of why a nullability decision was made.
class Trace {
  /// Text description of the trace.
  final String description;

  /// List of trace entries.
  final List<TraceEntry> entries;

  Trace({@required this.description, @required this.entries});

  Trace.fromJson(dynamic json)
      : description = json['description'] as String,
        entries = [
          for (var entry in json['entries']) TraceEntry.fromJson(entry)
        ];

  Map<String, Object> toJson() => {
        'description': description,
        'entries': [for (var entry in entries) entry.toJson()]
      };
}

/// Information about a single entry in a nullability trace.
class TraceEntry {
  /// Text description of the entry.
  final String description;

  /// The function associated with the entry.  We display this before the link
  /// so that the trace has the familiar appearance of a stacktrace.
  ///
  /// Null if not known.
  final String function;

  /// Source code location associated with the entry, or `null` if no source
  /// code location is known.
  final TargetLink link;

  /// The hint actions available to affect this entry of the trace, or `[]` if
  /// none.
  final List<HintAction> hintActions;

  TraceEntry(
      {@required this.description,
      this.function,
      this.link,
      this.hintActions = const []});

  TraceEntry.fromJson(dynamic json)
      : description = json['description'] as String,
        function = json['function'] as String,
        link = _decodeLink(json['link']),
        hintActions = (json['hintActions'] as List)
                ?.map((value) =>
                    HintAction.fromJson(value as Map<String, Object>))
                ?.toList() ??
            const [];

  Map<String, Object> toJson() => {
        'description': description,
        if (function != null) 'function': function,
        if (link != null) 'link': link.toJson(),
        if (hintActions.isNotEmpty)
          'hintActions': hintActions.map((action) => action.toJson()).toList()
      };

  static TargetLink _decodeLink(dynamic json) =>
      json == null ? null : TargetLink.fromJson(json);
}
