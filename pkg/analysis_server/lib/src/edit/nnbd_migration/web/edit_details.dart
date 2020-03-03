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

  EditDetails(
      {@required this.details,
      this.edits,
      @required this.explanation,
      @required this.line,
      @required this.path});

  EditDetails.fromJson(dynamic json)
      : details = [
          for (var detail in json['details']) EditRationale.fromJson(detail)
        ],
        edits = _decodeEdits(json['edits']),
        explanation = json['explanation'],
        line = json['line'],
        path = json['path'];

  Map<String, Object> toJson() => {
        'details': [for (var detail in details) detail.toJson()],
        if (edits != null) 'edits': [for (var edit in edits) edit.toJson()],
        'explanation': explanation,
        'line': line,
        'path': path,
      };

  static List<EditLink> _decodeEdits(dynamic json) =>
      json == null ? null : [for (var edit in json) EditLink.fromJson(edit)];
}

/// Information about a single link that should be included in the
/// "Edit Details" view of the migration preview tool.
///
/// TODO(paulberry): consider splitting this into two classes corresponding to
/// its two use cases.
class EditLink {
  /// The href to link to.
  final String href;

  /// The line number of the link.  May be null.
  final int line;

  /// The link text.
  final String text;

  EditLink({@required this.href, this.line, @required this.text});

  EditLink.fromJson(dynamic json)
      : href = json['href'],
        line = json['line'],
        text = json['text'];

  Map<String, Object> toJson() => {
        'href': href,
        if (line != null) 'line': line,
        'text': text,
      };
}

/// Information about what should be populated into a single "rational" bullet
/// item in the "Edit Details" view of the migration preview tool.
class EditRationale {
  /// Description of the rationale.
  final String description;

  /// Link the user may click to see the source code in question.  May be null.
  final EditLink link;

  EditRationale({@required this.description, this.link});

  EditRationale.fromJson(dynamic json)
      : description = json['description'],
        link = _decodeLink(json['link']);

  Map<String, Object> toJson() => {
        'description': description,
        if (link != null) 'link': link.toJson(),
      };

  static EditLink _decodeLink(dynamic json) =>
      json == null ? null : EditLink.fromJson(json);
}
