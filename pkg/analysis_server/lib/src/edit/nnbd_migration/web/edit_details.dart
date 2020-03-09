// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// Information about what should be populated into the "Edit Details" view of
/// the migration preview tool.
class EditDetails {
  /// A list of the bulleted items that should be displayed as rationale for the
  /// edit.
  final List<EditRationale> details;

  /// A list of edits that can be offered to the user related to this source
  /// location (e.g. adding/removing hints).  `null` if this feature is
  /// disabled.
  final List<EditLink> edits;

  /// A string explanation of the edit.
  final String explanation;

  /// The line number of the edit.
  final int line;

  /// The path of the file that was edited.
  final String path;

  /// A list of traces representing stacktrace-like views of why the change was
  /// made, or the empty list if there are no traces for this change.
  final List<Trace> traces;

  EditDetails(
      {@required this.details,
      this.edits,
      @required this.explanation,
      @required this.line,
      @required this.path,
      this.traces = const []});

  EditDetails.fromJson(dynamic json)
      : details = [
          for (var detail in json['details']) EditRationale.fromJson(detail)
        ],
        edits = _decodeEdits(json['edits']),
        explanation = json['explanation'],
        line = json['line'],
        path = json['path'],
        traces = _decodeTraces(json['traces']);

  Map<String, Object> toJson() => {
        'details': [for (var detail in details) detail.toJson()],
        if (edits != null) 'edits': [for (var edit in edits) edit.toJson()],
        'explanation': explanation,
        'line': line,
        'path': path,
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
      : description = json['description'],
        href = json['href'];

  Map<String, Object> toJson() => {
        'description': description,
        'href': href,
      };
}

/// Information about what should be populated into a single "rational" bullet
/// item in the "Edit Details" view of the migration preview tool.
class EditRationale {
  /// Description of the rationale.
  final String description;

  /// Link the user may click to see the source code in question.  May be null.
  final TargetLink link;

  EditRationale({@required this.description, this.link});

  EditRationale.fromJson(dynamic json)
      : description = json['description'],
        link = _decodeLink(json['link']);

  Map<String, Object> toJson() => {
        'description': description,
        if (link != null) 'link': link.toJson(),
      };

  static TargetLink _decodeLink(dynamic json) =>
      json == null ? null : TargetLink.fromJson(json);
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
      : href = json['href'],
        line = json['line'],
        path = json['path'];

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
      : description = json['description'],
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

  TraceEntry({@required this.description, this.function, this.link});

  TraceEntry.fromJson(dynamic json)
      : description = json['description'],
        function = json['function'],
        link = _decodeLink(json['link']);

  Map<String, Object> toJson() => {
        'description': description,
        if (function != null) 'function': function,
        if (link != null) 'link': link.toJson()
      };

  static TargetLink _decodeLink(dynamic json) =>
      json == null ? null : TargetLink.fromJson(json);
}
