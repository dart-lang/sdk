// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// Information about an item that should show up in the "proposed edits" panel.
class EditListItem {
  /// Line number of this edit.
  final int line;

  /// Human-readable explanation of this edit.
  final String explanation;

  /// File offset of this edit
  final int offset;

  EditListItem(
      {@required this.line, @required this.explanation, @required this.offset});

  EditListItem.fromJson(dynamic json)
      : line = json['line'] as int,
        explanation = json['explanation'] as String,
        offset = json['offset'] as int;

  Map<String, Object> toJson() =>
      {'line': line, 'explanation': explanation, 'offset': offset};
}

/// Information about how a single file should be migrated.
class FileDetails {
  /// HTML representation of the source file with spans added to represent
  /// added, removed, and unchanged file regions.
  ///
  /// TODO(paulberry): this should be replaced by a more neutral data structure.
  final String regions;

  /// HTML representation of the source file with links added to allow
  /// navigation through source files.
  ///
  /// Also contains line number text and the anchors targeted by links that link
  /// to a specific line number.
  ///
  /// TODO(paulberry): this should be replaced by a more neutral data structure.
  final String navigationContent;

  /// Textual representation of the source file, including both added and
  /// removed text.
  final String sourceCode;

  /// Items that should show up in the "proposed edits" panel for the file.
  ///
  /// Map keys are headers, and values are the list of edits under each header.
  /// Map order is important--entries appearing earlier in the map are
  /// considered more likely to be of interest to the user.
  final Map<String, List<EditListItem>> edits;

  FileDetails(
      {@required this.regions,
      @required this.navigationContent,
      @required this.sourceCode,
      @required this.edits});

  FileDetails.empty()
      : regions = '',
        navigationContent = '',
        sourceCode = '',
        edits = const {};

  FileDetails.fromJson(dynamic json)
      : regions = json['regions'] as String,
        navigationContent = json['navigationContent'] as String,
        sourceCode = json['sourceCode'] as String,
        edits = {
          for (var entry in (json['edits'] as Map<String, Object>).entries)
            entry.key: [
              for (var edit in entry.value) EditListItem.fromJson(edit)
            ]
        };

  Map<String, Object> toJson() => {
        'regions': regions,
        'navigationContent': navigationContent,
        'sourceCode': sourceCode,
        'edits': {
          for (var entry in edits.entries)
            entry.key: [for (var edit in entry.value) edit.toJson()]
        }
      };
}
