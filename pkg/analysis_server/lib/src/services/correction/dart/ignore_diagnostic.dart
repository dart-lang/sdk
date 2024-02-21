// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/ignore_comments/ignore_info.dart';
import 'package:analyzer/src/test_utilities/platform.dart';
import 'package:analyzer/src/workspace/blaze.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart' show YamlEditor;

abstract class AbstractIgnoreDiagnostic extends ResolvedCorrectionProducer {
  AnalysisError get error => diagnostic as AnalysisError;

  @override
  List<Object>? get fixArguments => [_code];

  String get _code => error.errorCode.name.toLowerCase();

  Future<void> _computeEdit(
    ChangeBuilder builder,
    InsertionLocation insertDesc,
    RegExp existingIgnorePattern,
    String ignoreCommentType,
  ) async {
    final lineInfo = unit.lineInfo;

    await builder.addDartFileEdit(file, (builder) {
      final offset = insertDesc.offset;

      // Work out the offset of the start of the line so we can insert the new
      // line there.
      final location = lineInfo.getLocation(offset);
      final zeroBasedLineNumber = location.lineNumber - 1;
      final lineOffset = lineInfo.getOffsetOfLine(zeroBasedLineNumber);

      if (zeroBasedLineNumber > 0) {
        final previousLineOffset =
            lineInfo.getOffsetOfLine(zeroBasedLineNumber - 1);

        // If the line above already has an ignore comment, we need to append to
        // it like "ignore: foo, bar".
        final previousLineText = utils
            .getText(previousLineOffset, lineOffset - previousLineOffset)
            .trimRight();
        if (previousLineText.trim().startsWith(existingIgnorePattern)) {
          final offset = previousLineOffset + previousLineText.length;
          builder.addSimpleInsertion(offset, ', $_code');
          return;
        }
      }

      final indent = utils.getLinePrefix(offset);
      final prefix = insertDesc.prefix;
      final comment = '// $ignoreCommentType: $_code';
      final suffix = insertDesc.suffix;
      builder.addSimpleInsertion(
          lineOffset, '$prefix$indent$comment$eol$suffix');
    });
  }

  /// Returns `true` if any of the following is `true`:
  /// - [error.code] is present in the `cannot-ignore` list.
  /// - [error.code] is already ignored in the `errors` list.
  bool _isCodeUnignorable() {
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
    var explicitlyIgnored = analysisOptions.errorProcessors.any((element) =>
        element.severity == null && element.code == error.errorCode.name);

    return explicitlyIgnored;
  }
}

class IgnoreDiagnosticInAnalysisOptionsFile extends AbstractIgnoreDiagnostic {
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

    if (_isCodeUnignorable()) return;

    final analysisOptionsFile = analysisOptions.file;

    // TODO(osaxma): should an `analysis_options.yaml` be created when
    //               it doesn't exists?
    if (analysisOptionsFile == null) {
      return;
    }

    final content = _safelyReadFile(analysisOptionsFile);
    if (content == null) {
      return;
    }

    await builder.addYamlFileEdit(analysisOptionsFile.path, (builder) {
      final editor = YamlEditor(content);
      final options = loadYamlNode(content);
      final List<String> path;
      final Object value;
      if (options is! YamlMap) {
        path = [];
        value = {
          'analyzer': {
            'errors': {_code: 'ignore'}
          }
        };
      } else {
        final analyzerMap = options['analyzer'];
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
        // If the `analysis_options.yaml` does not have a valid format,
        // a `YamlException` is thrown (e.g. a label without a value).
        // In such case, do not suggest a fix.
        //
        // TODO(osaxma): check if the `analysis_options.yaml` is a valid
        //  before calling the builder to avoid unnecessary processing.
        return;
      }

      var edit = editor.edits.single;
      var replacement = edit.replacement;

      // TODO(dantup): The YAML editor currently produces inconsistent line
      //  endings in edits when the source file contains '\r\n'.
      // https://github.com/dart-lang/yaml_edit/issues/65
      var analysisOptionsEol = content.contains('\r')
          ? '\r\n'
          : content.contains('\n')
              ? '\n'
              : platformEol;
      replacement =
          replacement.replaceAll('\r', '').replaceAll('\n', analysisOptionsEol);

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

class IgnoreDiagnosticInFile extends AbstractIgnoreDiagnostic {
  @override
  FixKind get fixKind => DartFixKind.IGNORE_ERROR_FILE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (_isCodeUnignorable()) return;

    final insertDesc = utils.getInsertionLocationIgnoreForFile();
    await _computeEdit(
      builder,
      insertDesc,
      IgnoreInfo.ignoreForFileMatcher,
      'ignore_for_file',
    );
  }
}

class IgnoreDiagnosticOnLine extends AbstractIgnoreDiagnostic {
  @override
  FixKind get fixKind => DartFixKind.IGNORE_ERROR_LINE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (_isCodeUnignorable()) return;

    final diagnostic = this.diagnostic!; // Enforced by _isCodeUnignorable
    final insertDesc = InsertionLocation(
        prefix: '', offset: diagnostic.problemMessage.offset, suffix: '');
    await _computeEdit(
      builder,
      insertDesc,
      IgnoreInfo.ignoreMatcher,
      'ignore',
    );
  }
}
