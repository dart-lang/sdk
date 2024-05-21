// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/ignore_comments/ignore_info.dart';
import 'package:analyzer/src/workspace/blaze.dart';
import 'package:analyzer_plugin/src/utilities/extensions/resolved_unit_result.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart' show YamlEditor;

class IgnoreDiagnosticInAnalysisOptionsFile extends _BaseIgnoreDiagnostic {
  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.IGNORE_ERROR_ANALYSIS_FILE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (sessionHelper.session.analysisContext.contextRoot.workspace
        is BlazeWorkspace) {
      // The lint is disabled for Blaze workspace as the analysis options file
      // may be shared across all packages.
      // See discussion at: https://dart-review.googlesource.com/c/sdk/+/352220/
      return;
    }

    if (_isCodeUnignorable) return;

    var analysisOptionsFile = analysisOptions.file;

    // TODO(osaxma): should an `analysis_options.yaml` be created when
    //               it doesn't exists?
    if (analysisOptionsFile == null) {
      return;
    }

    var content = _safelyReadFile(analysisOptionsFile);
    if (content == null) {
      return;
    }

    await builder.addYamlFileEdit(analysisOptionsFile.path, (builder) {
      var editor = YamlEditor(content);
      var options = loadYamlNode(content);
      List<String> path;
      Object value;
      if (options is! YamlMap) {
        path = [];
        value = {
          'analyzer': {
            'errors': {_code: 'ignore'}
          }
        };
      } else {
        var analyzerMap = options['analyzer'];
        if (analyzerMap is! YamlMap || !analyzerMap.containsKey('errors')) {
          path = ['analyzer'];
          value = {
            'errors': {_code: 'ignore'}
          };
        } else {
          path = ['analyzer', 'errors', _code];
          value = 'ignore';
        }
      }

      try {
        editor.update(path, value);
      } on YamlException {
        // If the `analysis_options.yaml` does not have a valid format, a
        // `YamlException` is thrown (e.g. a label without a value). In such
        // case, do not suggest a fix.
        //
        // TODO(osaxma): check if the `analysis_options.yaml` is a valid before
        // calling the builder to avoid unnecessary processing.
        return;
      }

      var edit = editor.edits.single;
      var replacement = edit.replacement;
      builder.addSimpleInsertion(edit.offset, replacement);
    });
  }

  String? _safelyReadFile(File file) {
    try {
      return file.readAsStringSync();
    } on FileSystemException {
      return null;
    }
  }
}

class IgnoreDiagnosticInFile extends _DartIgnoreDiagnostic {
  @override
  String get commentPrefix => 'ignore_for_file';

  @override
  FixKind get fixKind => DartFixKind.IGNORE_ERROR_FILE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (_isCodeUnignorable) return;

    await builder.addDartFileEdit(file, (builder) {
      var source = unitResult.content;

      // Look for the last blank line in any leading comments (to insert after
      // all header comments but not after any "comment-attached" code). If an
      // existing `ignore_for_file` comment is found while looking, then insert
      // after that.

      var lineCount = unitResult.lineInfo.lineCount;
      if (lineCount == 1) {
        insertAt(builder, 0, insertEmptyLineAfter: true);
        return;
      }

      int? lastBlankLineOffset;
      late int lineStart;
      for (var lineNumber = 0; lineNumber < lineCount - 1; lineNumber++) {
        lineStart = unitResult.lineInfo.getOffsetOfLine(lineNumber);
        var nextLineStart = unitResult.lineInfo.getOffsetOfLine(lineNumber + 1);
        var line = source.substring(lineStart, nextLineStart).trim();

        if (line.startsWith('// $commentPrefix:')) {
          // Found an existing ignore; insert at the end of this line.
          builder.addSimpleInsertion(nextLineStart - eol.length, ', $_code');
          return;
        }

        if (line.isEmpty) {
          // Track last blank line, as we will insert there.
          lastBlankLineOffset = lineStart;
          continue;
        }

        if (line.startsWith('#!') || line.startsWith('//')) {
          // Skip comment/hash-bang.
          continue;
        }

        // We found some code.
        break;
      }

      if (lastBlankLineOffset != null) {
        // If we found a blank line, insert right after that.
        insertAt(builder, lastBlankLineOffset, insertEmptyLineBefore: true);
      } else {
        // Otherwise, insert right before the first line of code.
        insertAt(builder, lineStart, insertEmptyLineAfter: true);
      }
    });
  }
}

class IgnoreDiagnosticOnLine extends _DartIgnoreDiagnostic {
  @override
  String get commentPrefix => 'ignore';

  @override
  FixKind get fixKind => DartFixKind.IGNORE_ERROR_LINE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (_isCodeUnignorable) return;

    await builder.addDartFileEdit(file, (builder) {
      var offset = error.problemMessage.offset;
      var lineNumber = unitResult.lineInfo.getLocation(offset).lineNumber - 1;

      if (lineNumber == 0) {
        // The error is on the first line; no chance of a previous line already
        // containing an ignore comment.
        insertAt(builder, 0);
        return;
      }

      var previousLineStart =
          unitResult.lineInfo.getOffsetOfLine(lineNumber - 1);
      var lineStart = unitResult.lineInfo.getOffsetOfLine(lineNumber);
      var line =
          unitResult.content.substring(previousLineStart, lineStart).trim();

      if (line.startsWith(IgnoreInfo.ignoreMatcher)) {
        builder.addSimpleInsertion(lineStart - eol.length, ', $_code');
      } else {
        insertAt(builder, lineStart);
      }
    });
  }
}

abstract class _BaseIgnoreDiagnostic extends ResolvedCorrectionProducer {
  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  AnalysisError get error => diagnostic as AnalysisError;

  @override
  List<String> get fixArguments => [_code];

  String get _code => error.errorCode.name.toLowerCase();

  /// Returns `true` if any of the following is `true`:
  /// - `error.code` is present in the `cannot-ignore` list.
  /// - `error.code` is already ignored in the `errors` list.
  bool get _isCodeUnignorable {
    var cannotIgnore =
        analysisOptions.unignorableNames.contains(error.errorCode.name);

    if (cannotIgnore) {
      return true;
    }

    // This will prevent showing a `fix` when the `error` is already ignored in
    // `analysis_options.yaml`.
    //
    // Note: both `ignore` and `false` severity are set to `null` when parsed.
    //       See `ErrorConfig` in `pkg/analyzer/source/error_processor.dart`.
    return analysisOptions.errorProcessors.any((element) =>
        element.severity == null && element.code == error.errorCode.name);
  }
}

abstract class _DartIgnoreDiagnostic extends _BaseIgnoreDiagnostic {
  /// The ignore-comment prefix (either 'ignore' or 'ignore_for_file').
  String get commentPrefix;

  /// Inserts a properly indented ignore-comment at [offset].
  ///
  /// Additionally, [eol] is inserted before the comment if
  /// [insertEmptyLineBefore], and [eol] is inserted after the comment if
  /// [insertEmptyLineAfter].
  void insertAt(
    DartFileEditBuilder builder,
    int offset, {
    bool insertEmptyLineBefore = false,
    bool insertEmptyLineAfter = false,
  }) {
    var prefix = insertEmptyLineBefore ? eol : '';
    var indent = unitResult.linePrefix(offset);
    var comment = '// $commentPrefix: $_code';
    var suffix = insertEmptyLineAfter ? eol : '';
    builder.addSimpleInsertion(offset, '$prefix$indent$comment$eol$suffix');
  }
}
