// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/computer/computer_hover.dart';
import 'package:analysis_server/src/lsp/dartdoc.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';

class HoverHandler extends MessageHandler {
  final LspAnalysisServer server;
  HoverHandler(this.server);

  @override
  List<String> get handlesMessages => const ['textDocument/hover'];

  Future<Hover> handleHover(TextDocumentPositionParams params) async {
    // TODO(dantup): Look at clientCapabilities.hover.contentFormat to decide what
    // format to send back?

    final path = pathOf(params.textDocument);
    ResolvedUnitResult result = await server.getResolvedUnit(path);
    // TODO(dantup): Handle bad paths/offsets.
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
    if (hover == null) {
      return null;
    }

    // Import prefix tooltips are not useful currently.
    // https://github.com/dart-lang/sdk/issues/32735
    if (hover.elementKind == 'import prefix') {
      return null;
    }

    final content = new StringBuffer();

    // Description.
    if (hover.elementDescription != null) {
      content.writeln('```dart');
      if (hover.isDeprecated) {
        content.write('(deprecated) ');
      }
      content..writeln(hover.elementDescription)..writeln('```')..writeln();
    }

    // Source library.
    if (hover.containingLibraryName != null &&
        hover.containingLibraryName.isNotEmpty) {
      content..writeln('*${hover.containingLibraryName}*')..writeln();
    } else if (hover.containingLibraryPath != null) {
      // TODO(dantup): Support displaying the package name (probably by adding
      // containingPackageName to the main hover?) once the analyzer work to
      // support this (inc Bazel/Gn) is done.
      // content..writeln('*${hover.containingPackageName}*')..writeln();
    }

    // Doc comments.
    if (hover.dartdoc != null) {
      content.writeln(cleanDartdoc(hover.dartdoc));
    }

    return new Hover(
      asMarkdown(content.toString().trimRight()),
      toRange(lineInfo, hover.offset, hover.length),
    );
  }
}
