// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// A generic producer that removes a lexeme whose name and offsets
/// are derived from the reporting diagnostic.
class RemoveLexeme extends ResolvedCorrectionProducer {
  String _lexemeName = '';
  // The kind of lexeme (e.g., 'keyword' vs. 'modifier').
  final String kind;

  RemoveLexeme.keyword({required CorrectionProducerContext context})
    : this._(context: context, kind: 'keyword');

  RemoveLexeme.modifier({required CorrectionProducerContext context})
    : this._(context: context, kind: 'modifier');

  RemoveLexeme._({required super.context, required this.kind});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  List<String> get fixArguments => [_lexemeName, kind];

  @override
  FixKind get fixKind => DartFixKind.REMOVE_LEXEME;

  @override
  List<String>? get multiFixArguments => [_lexemeName];

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_LEXEME_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var diagnostic = this.diagnostic;
    if (diagnostic == null) return;

    var problemMessage = diagnostic.problemMessage;
    String? text = _findSourceToDelete(diagnostic);
    if (text == null) return;

    _lexemeName = text;

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(
        SourceRange(
          problemMessage.offset,
          // TODO(pq): consider a CorrectionUtils utility to get first non whitespace offset.
          _lexemeName.length + 1,
        ),
      );
    });
  }

  (int start, int stop) _findLexemeOffsets(String message) {
    var start = message.indexOf(" '");
    if (start == -1) return (-1, -1);
    // Advance to the start of the lexeme.
    start += 2;
    var stop = message.indexOf("'", start);
    if (stop == -1) return (-1, -1);

    return (start, stop);
  }

  String? _findSourceToDelete(Diagnostic diagnostic) {
    // Example: "Can't have modifier 'abstract' here."
    String? message = diagnostic.problemMessage.messageText(includeUrl: false);
    var (start, stop) = _findLexemeOffsets(message);
    if (start == -1) {
      // Example: "Remove the 'get' keyword."
      message = diagnostic.correctionMessage;
      if (message == null) return null;
      (start, stop) = _findLexemeOffsets(message);
    }
    if (start == -1) return null;

    return message.substring(start, stop);
  }
}
