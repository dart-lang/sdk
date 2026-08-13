// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;

/// Normalized diagnostic entry used for set comparison and persistence.
class HarnessDiagnostic {
  final String path;
  final String code;
  final String severity;
  final int offset;
  final int length;
  final String message;

  HarnessDiagnostic({
    required this.path,
    required this.code,
    required this.severity,
    required this.offset,
    required this.length,
    required this.message,
  });

  /// Stable comparison key.
  String key() {
    return '$path|$code|$severity|$offset|$length|'
        '${message.replaceAll("\n", " ")}';
  }

  Map<String, Object?> toJson(String repo) => {
    'file': p.relative(path, from: repo),
    'code': code,
    'severity': severity,
    'offset': offset,
    'length': length,
    'message': message,
  };
}

/// Text edit to apply to a file.
class MutationEdit {
  final int offset;
  final int length;
  final String replacement;

  MutationEdit(this.offset, this.length, this.replacement);

  Map<String, Object?> toJson() => {
    'offset': offset,
    'length': length,
    'replacement_preview': replacement.length > 120
        ? '${replacement.substring(0, 120)}...'
        : replacement,
  };
}

/// Successful mutation application: the [edit] plus any auxiliary [notes].
class MutationResult {
  final MutationEdit edit;
  final Map<String, Object?> notes;

  MutationResult(this.edit, [this.notes = const {}]);
}
