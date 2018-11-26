// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/computer/computer_hover.dart';
import 'package:analysis_server/src/lsp/dartdoc.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';

class HoverHandler extends MessageHandler<TextDocumentPositionParams, Hover> {
  final LspAnalysisServer server;
  String get handlesMessage => 'textDocument/hover';
  HoverHandler(this.server) : super(TextDocumentPositionParams.fromJson);

  Future<Hover> handle(TextDocumentPositionParams params) async {
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

    final formats =
        server?.clientCapabilities?.textDocument?.hover?.contentFormat;
    return new Hover(
      asStringOrMarkupContent(formats, content.toString().trimRight()),
      toRange(lineInfo, hover.offset, hover.length),
    );
  }
}
