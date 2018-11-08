// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/computer/computer_hover.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';

final _dartDocBracketedButNotLinks = new RegExp(r'\[(\S+)\](?!\()');
final _dartDocCodeBlockSections = new RegExp(r'(```\w+) +\w+');
final _dartDocDirectives =
    new RegExp(r'(\n *{@.*?}$)|(^{@.*?}\n)', multiLine: true);

class HoverHandler extends MessageHandler {
  final LspAnalysisServer server;
  HoverHandler(this.server);
  List<String> get handlesMessages => const ['textDocument/hover'];

  Future<Hover> handleHover(TextDocumentPositionParams params) async {
    // TODO(dantup): Look at clientCapabilities.hover.contentFormat to decide what
    // format to send back?

    final path = pathOf(params.textDocument);
    ResolvedUnitResult result = await server.getResolvedUnit(path);
    CompilationUnit unit = result?.unit;

    if (unit == null) {
      return null;
    }

    final pos = params.position;
    final offset = result.lineInfo.getOffsetOfLine(pos.line) + pos.character;
    final hover = new DartUnitHoverComputer(unit, offset).compute();
    return toHover(result.lineInfo, hover);
  }

  @override
  FutureOr<Object> handleMessage(IncomingMessage message) {
    if (message is RequestMessage && message.method == 'textDocument/hover') {
      final params =
          convertParams(message, TextDocumentPositionParams.fromJson);
      return handleHover(params);
    } else {
      throw 'Unexpected message';
    }
  }

  Hover toHover(LineInfo lineInfo, HoverInformation hover) {
    return hover == null || hover.dartdoc == null
        ? null
        : new Hover(
            asMarkdown(_cleanDartdoc(hover.dartdoc)),
            toRange(lineInfo, hover.offset, hover.length),
          );
  }

  String _cleanDartdoc(String doc) {
    // Change any links without hyperlinks to just code syntax.
    // That is, anything in `[brackets]` that isn't a `[link](http://blah)`.
    doc = doc.replaceAllMapped(
      _dartDocBracketedButNotLinks,
      (match) => '`${match.group(1)}`',
    );

    // Remove any dartdoc directives like {@template xxx}
    doc = doc.replaceAll(_dartDocDirectives, '');

    // Remove any code block section names like ```dart preamble that Flutter
    // docs contain.
    doc = doc.replaceAllMapped(
      _dartDocCodeBlockSections,
      (match) => match.group(1),
    );

    return doc;
  }
}
