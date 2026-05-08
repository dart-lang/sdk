// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart'
    as lsp
    show DocumentLink;
import 'package:analysis_server/lsp_protocol/protocol.dart'
    hide Element, DocumentLink;
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/util/file_paths.dart';
import 'package:analyzer_plugin/src/utilities/navigation/document_links.dart';

class DocumentLinkHandler
    extends LspMessageHandler<DocumentLinkParams, List<lsp.DocumentLink>?>
    with LspPluginRequestHandlerMixin {
  DocumentLinkHandler(super.server);

  @override
  Method get handlesMessage => Method.textDocument_documentLink;

  @override
  LspJsonHandler<DocumentLinkParams> get jsonHandler =>
      DocumentLinkParams.jsonHandler;

  @override
  Future<ErrorOr<List<lsp.DocumentLink>?>> handle(
    DocumentLinkParams params,
    MessageInfo message,
    CancellationToken token,
  ) {
    var path = pathOfDoc(params.textDocument);
    return path.mapResult((path) async {
      if (isDartDocument(params.textDocument)) {
        return _getDartDocumentLinks(path);
      } else if (isPubspecYaml(pathContext, path)) {
        return _getPubspecDocumentLinks(path);
      } else if (isAnalysisOptionsYaml(pathContext, path)) {
        return _getAnalysisOptionsDocumentLinks(path);
      } else {
        return success(const []);
      }
    });
  }

  /// Convert a server [DocumentLink] into an LSP [lsp.DocumentLink].
  lsp.DocumentLink _convert(DocumentLink link, LineInfo lineInfo) {
    return lsp.DocumentLink(
      range: toRange(lineInfo, link.offset, link.length),
      target: link.targetUri,
    );
  }

  /// Get the [lsp.DocumentLink]s for a Analysis Options file.
  Future<ErrorOr<List<lsp.DocumentLink>>> _getAnalysisOptionsDocumentLinks(
    String filePath,
  ) async {
    // Read the current version of the document here. We need to ensure the
    // content used by 'AnalysisOptionLinkComputer' and the 'LineInfo' we use
    // to convert to LSP data are consistent.
    var analysisOptionsContent = _safelyRead(
      server.resourceProvider.getFile(filePath),
    );
    if (analysisOptionsContent == null) {
      return success([]);
    }

    /// Helper to convert using LineInfo.
    var lineInfo = LineInfo.fromContent(analysisOptionsContent);
    lsp.DocumentLink convert(DocumentLink link) {
      return _convert(link, lineInfo);
    }

    var visitor = AnalysisOptionLinkComputer(server.pubApi.pubHostedUrl);
    return success(
      visitor.findLinks(analysisOptionsContent).map(convert).toList(),
    );
  }

  /// Get the [lsp.DocumentLink]s for a Dart file.
  Future<ErrorOr<List<lsp.DocumentLink>>> _getDartDocumentLinks(
    String filePath,
  ) async {
    var parsedUnit = await requireUnresolvedUnit(filePath);

    return parsedUnit.mapResult((unit) async {
      /// Helper to convert using LineInfo.
      lsp.DocumentLink convert(DocumentLink link) {
        return _convert(link, unit.lineInfo);
      }

      var visitor = DartDocumentLinkVisitor(server.resourceProvider, unit);
      return success(visitor.findLinks(unit.unit).map(convert).toList());
    });
  }

  /// Get the [lsp.DocumentLink]s for a Pubspec file.
  Future<ErrorOr<List<lsp.DocumentLink>>> _getPubspecDocumentLinks(
    String filePath,
  ) async {
    // Read the current version of the document here. We need to ensure the
    // content used by 'PubspecDocumentLinkComputer' and the 'LineInfo' we use
    // to convert to LSP data are consistent.
    var pubspecContent = _safelyRead(server.resourceProvider.getFile(filePath));
    if (pubspecContent == null) {
      return success([]);
    }

    /// Helper to convert using LineInfo.
    var lineInfo = LineInfo.fromContent(pubspecContent);
    lsp.DocumentLink convert(DocumentLink link) {
      return _convert(link, lineInfo);
    }

    var visitor = PubspecDocumentLinkComputer(server.pubApi.pubHostedUrl);
    return success(visitor.findLinks(pubspecContent).map(convert).toList());
  }

  /// Return the contents of the [file], or `null` if the file does not exist or
  /// cannot be read.
  String? _safelyRead(File file) {
    try {
      return file.readAsStringSync();
    } on FileSystemException {
      return null;
    }
  }
}

class DocumentLinkRegistrations extends FeatureRegistration
    with SingleDynamicRegistration, StaticRegistration<DocumentLinkOptions> {
  DocumentLinkRegistrations(super.info);

  @override
  ToJsonable? get options => DocumentLinkRegistrationOptions(
    documentSelector: [...dartFiles, pubspecFile, analysisOptionsFile],
    resolveProvider: false,
  );

  @override
  Method get registrationMethod => Method.textDocument_documentLink;

  @override
  DocumentLinkOptions get staticOptions =>
      DocumentLinkOptions(resolveProvider: false);

  @override
  bool get supportsDynamic => clientDynamic.documentLink;
}
