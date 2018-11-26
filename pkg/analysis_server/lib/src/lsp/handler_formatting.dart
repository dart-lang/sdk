// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:dart_style/dart_style.dart';

class FormattingHandler
    extends MessageHandler<DocumentFormattingParams, List<TextEdit>> {
  final DartFormatter formatter = new DartFormatter();
  FormattingHandler(LspAnalysisServer server) : super(server);
  Method get handlesMessage => Method.textDocument_formatting;

  @override
  DocumentFormattingParams convertParams(Map<String, dynamic> json) =>
      DocumentFormattingParams.fromJson(json);

  Future<List<TextEdit>> handle(DocumentFormattingParams params) async {
    final path = pathOf(params.textDocument);
    final result = await requireUnit(path);

    final unformattedSource = server.fileContentOverlay[path];

    // If the file has not been opened (added to the overlay) we should not have
    // been asked to format it.
    if (unformattedSource == null) {
      throw new ResponseError(ServerErrorCodes.FileNotOpen,
          'Cannot format a file that is not open', path);
    }

    final code =
        new SourceCode(unformattedSource, uri: null, isCompilationUnit: true);
    SourceCode formattedResult;
    try {
      formattedResult = formatter.formatSource(code);
    } on FormatterException {
      // If the document fails to parse, just return no edits to avoid the the
      // use seeing edits on every save with invalid code (if LSP gains the
      // ability to pass a context to know if the format was manually invoked
      // we may wish to change this to return an error for that case).
      return null;
    }
    final formattedSource = formattedResult.text;

    if (formattedSource == unformattedSource) {
      return null;
    }

    // We don't currently support returning "minimal" edits, we just replace
    // entire document.
    final end = result.lineInfo.getLocation(unformattedSource.length);
    return [
      new TextEdit(
        new Range(new Position(0, 0), toPosition(end)),
        formattedSource,
      )
    ];
  }
}
