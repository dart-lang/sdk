// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Outline;
import 'package:analysis_server/src/computer/computer_outline.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

class CiderDocumentSymbolsComputer {
  final FileResolver _fileResolver;

  CiderDocumentSymbolsComputer(this._fileResolver);

  Future<List<DocumentSymbol>> compute2(String filePath) async {
    var result = <DocumentSymbol>[];
    var resolvedUnit = await _fileResolver.resolve2(path: filePath);

    final computer = DartUnitOutlineComputer(resolvedUnit);
    final outline = computer.compute();

    final children = outline.children;
    if (children == null) {
      return result;
    }

    result.addAll(children.map((child) => _asDocumentSymbol(
        LspClientCapabilities.defaultSupportedSymbolKinds,
        resolvedUnit.lineInfo,
        child)));

    return result;
  }

  DocumentSymbol _asDocumentSymbol(
    Set<SymbolKind> supportedKinds,
    LineInfo lineInfo,
    Outline outline,
  ) {
    final codeRange = toRange(lineInfo, outline.codeOffset, outline.codeLength);
    final nameLocation = outline.element.location;
    final nameRange = nameLocation != null
        ? toRange(lineInfo, nameLocation.offset, nameLocation.length)
        : null;
    return DocumentSymbol(
      name: toElementName(outline.element),
      detail: outline.element.parameters,
      kind: elementKindToSymbolKind(supportedKinds, outline.element.kind),
      deprecated: outline.element.isDeprecated,
      range: codeRange,
      selectionRange: nameRange ?? codeRange,
      children: outline.children
          ?.map((child) => _asDocumentSymbol(supportedKinds, lineInfo, child))
          .toList(),
    );
  }
}
