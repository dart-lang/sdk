// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/ignore_comments/ignore_info.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

abstract class AbstractIgnoreDiagnostic extends CorrectionProducer {
  AnalysisError get error => diagnostic as AnalysisError;

  @override
  List<Object>? get fixArguments => [_code];

  String get _code => error.errorCode.name.toLowerCase();

  Future<void> _computeEdit(
    ChangeBuilder builder,
    CorrectionUtils_InsertDesc insertDesc,
    RegExp existingIgnorePattern,
    String ignoreCommentType,
  ) async {
    final lineInfo = unit.lineInfo;
    if (lineInfo == null) {
      return;
    }

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
}

class IgnoreDiagnosticInFile extends AbstractIgnoreDiagnostic {
  @override
  FixKind get fixKind => DartFixKind.IGNORE_ERROR_FILE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final insertDesc = utils.getInsertDescIgnoreForFile();
    await _computeEdit(
      builder,
      insertDesc,
      IgnoreInfo.IGNORE_FOR_FILE_MATCHER,
      'ignore_for_file',
    );
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static IgnoreDiagnosticInFile newInstance() => IgnoreDiagnosticInFile();
}

class IgnoreDiagnosticOnLine extends AbstractIgnoreDiagnostic {
  @override
  FixKind get fixKind => DartFixKind.IGNORE_ERROR_LINE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final insertDesc = CorrectionUtils_InsertDesc();
    insertDesc.offset = node.offset;
    await _computeEdit(
      builder,
      insertDesc,
      IgnoreInfo.IGNORE_MATCHER,
      'ignore',
    );
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static IgnoreDiagnosticOnLine newInstance() => IgnoreDiagnosticOnLine();
}
