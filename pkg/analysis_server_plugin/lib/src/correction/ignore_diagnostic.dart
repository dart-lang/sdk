// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/ignore_comments/ignore_info.dart';
import 'package:analyzer/src/workspace/blaze.dart';
import 'package:analyzer_plugin/src/utilities/extensions/resolved_unit_result.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart' show YamlEditor;

const ignoreErrorAnalysisFileKind = FixKind(
  'dart.fix.ignore.analysis',
  DartFixKindPriority.ignore - 2,
  "Ignore '{0}' in `analysis_options.yaml`",
);
const ignoreErrorFileKind = FixKind(
  'dart.fix.ignore.file',
  DartFixKindPriority.ignore - 1,
  "Ignore '{0}' for the whole file",
);
const ignoreErrorLineKind = FixKind(
  'dart.fix.ignore.line',
  DartFixKindPriority.ignore,
  "Ignore '{0}' for this line",
);

class IgnoreDiagnosticInAnalysisOptionsFile extends _BaseIgnoreDiagnostic {
  IgnoreDiagnosticInAnalysisOptionsFile({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => ignoreErrorAnalysisFileKind;

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

    var analysisOptionsFile = (analysisOptions as AnalysisOptionsImpl).file;

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
            'errors': {_code: 'ignore'},
          },
        };
      } else {
        var analyzerMap = options['analyzer'];
        if (analyzerMap is! YamlMap || !analyzerMap.containsKey('errors')) {
          path = ['analyzer'];
          value = {
            'errors': {_code: 'ignore'},
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
  IgnoreDiagnosticInFile({required super.context});

  @override
  String get commentPrefix => 'ignore_for_file';

  @override
  FixKind get fixKind => ignoreErrorFileKind;

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
        var line = source.substring(lineStart, nextLineStart);
        var trimmedLine = line.trim();

        if (trimmedLine.startsWith(IgnoreInfo.ignoreForFileMatcher)) {
          // Found an existing ignore; insert after `// ignore_for_file: `
          // before any existing codes.
          var insertOffset = lineStart + line.indexOf(':') + 1;
          builder.addSimpleInsertion(insertOffset, ' $_code,');
          return;
        }

        if (trimmedLine.isEmpty) {
          // Track last blank line, as we will insert there.
          lastBlankLineOffset = lineStart;
          continue;
        }

        if (trimmedLine.startsWith('#!') || trimmedLine.startsWith('//')) {
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
  IgnoreDiagnosticOnLine({required super.context});

  @override
  String get commentPrefix => 'ignore';

  @override
  FixKind get fixKind => ignoreErrorLineKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (_isCodeUnignorable) return;

    await builder.addDartFileEdit(file, (builder) {
      var offset = diagnostic.problemMessage.offset;
      var lineNumber = unitResult.lineInfo.getLocation(offset).lineNumber - 1;

      if (lineNumber == 0) {
        // The error is on the first line; no chance of a previous line already
        // containing an ignore comment.
        insertAt(builder, 0);
        return;
      }

      var previousLineStart = unitResult.lineInfo.getOffsetOfLine(
        lineNumber - 1,
      );
      var lineStart = unitResult.lineInfo.getOffsetOfLine(lineNumber);
      var line = unitResult.content.substring(previousLineStart, lineStart);

      if (line.trim().startsWith(IgnoreInfo.ignoreMatcher)) {
        // Add after the `// ignore: ` before any existing codes.
        var insertOffset = previousLineStart + line.indexOf(':') + 1;
        builder.addSimpleInsertion(insertOffset, ' $_code,');
      } else {
        insertAt(builder, lineStart);
      }
    });
  }
}

abstract class _BaseIgnoreDiagnostic extends ResolvedCorrectionProducer {
  _BaseIgnoreDiagnostic({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  Diagnostic get diagnostic => super.diagnostic!;

  @override
  List<String> get fixArguments => [_code];

  String get _code => diagnostic.diagnosticCode.name.toLowerCase();

  /// Returns `true` if any of the following is `true`:
  /// - `error.code` is present in the `cannot-ignore` list.
  /// - `error.code` is already ignored in the `errors` list.
  bool get _isCodeUnignorable {
    var cannotIgnore = (analysisOptions as AnalysisOptionsImpl)
        .unignorableDiagnosticCodeNames
        .contains(diagnostic.diagnosticCode.name);

    if (cannotIgnore) {
      return true;
    }

    // This will prevent showing a `fix` when the `error` is already ignored in
    // `analysis_options.yaml`.
    //
    // Note: both `ignore` and `false` severity are set to `null` when parsed.
    //       See `ErrorConfig` in `pkg/analyzer/source/error_processor.dart`.
    return analysisOptions.errorProcessors.any(
      (e) => e.severity == null && e.code == diagnostic.diagnosticCode.name,
    );
  }
}

abstract class _DartIgnoreDiagnostic extends _BaseIgnoreDiagnostic {
  _DartIgnoreDiagnostic({required super.context});

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
    var eol = builder.eol;
    var prefix = insertEmptyLineBefore ? eol : '';
    var indent = unitResult.linePrefix(offset);
    var comment = '// $commentPrefix: $_code';
    var suffix = insertEmptyLineAfter ? eol : '';
    builder.addSimpleInsertion(offset, '$prefix$indent$comment$eol$suffix');
  }
}
