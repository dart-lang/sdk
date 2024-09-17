// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Outline;
import 'package:analysis_server/src/computer/computer_outline.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analysis_server/src/protocol_server.dart' show Outline;
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/source/line_info.dart';

typedef StaticOptions = Either2<bool, DocumentSymbolOptions>;

class DocumentSymbolHandler extends SharedMessageHandler<DocumentSymbolParams,
    TextDocumentDocumentSymbolResult> {
  DocumentSymbolHandler(super.server);
  @override
  Method get handlesMessage => Method.textDocument_documentSymbol;

  @override
  LspJsonHandler<DocumentSymbolParams> get jsonHandler =>
      DocumentSymbolParams.jsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<TextDocumentDocumentSymbolResult>> handle(
      DocumentSymbolParams params,
      MessageInfo message,
      CancellationToken token) async {
    var clientCapabilities = message.clientCapabilities;
    if (clientCapabilities == null || !isDartDocument(params.textDocument)) {
      return success(
        TextDocumentDocumentSymbolResult.t2([]),
      );
    }

    var path = pathOfDoc(params.textDocument);
    var unit = await path.mapResult(requireResolvedUnit);
    return unit.mapResultSync(
        (unit) => _getSymbols(clientCapabilities, unit.path, unit));
  }

  DocumentSymbol _asDocumentSymbol(
    Set<SymbolKind> supportedKinds,
    LineInfo lineInfo,
    Outline outline,
  ) {
    var codeRange = toRange(lineInfo, outline.codeOffset, outline.codeLength);
    var nameLocation = outline.element.location;
    var nameRange = nameLocation != null
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

  SymbolInformation? _asSymbolInformation(
    String? containerName,
    Set<SymbolKind> supportedKinds,
    Uri documentUri,
    LineInfo lineInfo,
    Outline outline,
  ) {
    var location = outline.element.location;
    if (location == null) {
      return null;
    }

    return SymbolInformation(
      name: toElementName(outline.element),
      kind: elementKindToSymbolKind(supportedKinds, outline.element.kind),
      deprecated: outline.element.isDeprecated,
      location: Location(
        uri: documentUri,
        range: toRange(lineInfo, location.offset, location.length),
      ),
      containerName: containerName,
    );
  }

  ErrorOr<TextDocumentDocumentSymbolResult> _getSymbols(
    LspClientCapabilities capabilities,
    String path,
    ResolvedUnitResult unit,
  ) {
    var computer = DartUnitOutlineComputer(unit);
    var outline = computer.compute();

    if (capabilities.hierarchicalSymbols) {
      // Return a tree of DocumentSymbol only if the client shows explicit support
      // for it.
      var children = outline.children;
      if (children == null) {
        return success(null);
      }
      return success(
        TextDocumentDocumentSymbolResult.t1(
          children
              .map((child) => _asDocumentSymbol(
                  capabilities.documentSymbolKinds, unit.lineInfo, child))
              .toList(),
        ),
      );
    } else {
      // Otherwise, we need to use the original flat SymbolInformation.
      var allSymbols = <SymbolInformation>[];
      var documentUri = uriConverter.toClientUri(path);

      // Adds a symbol and it's children recursively, supplying the parent
      // name as required by SymbolInformation.
      void addSymbol(Outline outline, {String? parentName}) {
        var symbol = _asSymbolInformation(
          parentName,
          capabilities.documentSymbolKinds,
          documentUri,
          unit.lineInfo,
          outline,
        );
        if (symbol != null) {
          allSymbols.add(symbol);
        }
        outline.children?.forEach(
          (c) => addSymbol(c, parentName: outline.element.name),
        );
      }

      outline.children?.forEach(addSymbol);

      return success(TextDocumentDocumentSymbolResult.t2(allSymbols));
    }
  }
}

class DocumentSymbolsRegistrations extends FeatureRegistration
    with SingleDynamicRegistration, StaticRegistration<StaticOptions> {
  DocumentSymbolsRegistrations(super.info);

  @override
  ToJsonable? get options =>
      TextDocumentRegistrationOptions(documentSelector: fullySupportedTypes);

  @override
  Method get registrationMethod => Method.textDocument_documentSymbol;

  @override
  StaticOptions get staticOptions => Either2.t1(true);

  @override
  bool get supportsDynamic => clientDynamic.documentSymbol;
}
