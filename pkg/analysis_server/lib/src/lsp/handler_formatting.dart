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
  final LspAnalysisServer server;
  String get handlesMessage => 'textDocument/formatting';
  final DartFormatter formatter = new DartFormatter();
  FormattingHandler(this.server) : super(DocumentFormattingParams.fromJson);

  Future<List<TextEdit>> handle(DocumentFormattingParams params) async {
    final path = pathOf(params.textDocument);
    // TODO(dantup): Switch this to requireUnit() which is in a "future"
    // changeset.
    final result = await server.getResolvedUnit(path);
    if (result == null) {
      throw new ResponseError(
          ServerErrorCodes.InvalidFilePath, 'Invalid file path', path);
    }

    String unformattedSource;
    try {
      final source = server.resourceProvider.getFile(path).createSource();
      unformattedSource =
          server.fileContentOverlay[path] ?? source.contents.data;
    } catch (e) {
      throw new ResponseError(
          ServerErrorCodes.InvalidFilePath, 'Invalid file path', path);
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
