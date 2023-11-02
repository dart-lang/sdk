// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Element;
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/utilities/navigation/document_links.dart';

class DocumentLinkHandler
    extends LspMessageHandler<DocumentLinkParams, List<DocumentLink>?>
    with LspPluginRequestHandlerMixin {
  DocumentLinkHandler(super.server);

  @override
  Method get handlesMessage => Method.textDocument_documentLink;

  @override
  LspJsonHandler<DocumentLinkParams> get jsonHandler =>
      DocumentLinkParams.jsonHandler;

  @override
  Future<ErrorOr<List<DocumentLink>?>> handle(DocumentLinkParams params,
      MessageInfo message, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(const []);
    }

    final path = pathOfDoc(params.textDocument);
    final parsedUnit = await path.mapResult(requireUnresolvedUnit);

    return parsedUnit.mapResult((unit) async {
      /// Helper to convert using LineInfo.
      DocumentLink convert(DartDocumentLink link) {
        return _convert(link, unit.lineInfo);
      }

      final visitor = DartDocumentLinkVisitor(server.resourceProvider, unit);
      final links = visitor.findLinks(unit.unit);

      return success(links.map(convert).toList());
    });
  }

  DocumentLink _convert(DartDocumentLink link, LineInfo lineInfo) {
    return DocumentLink(
      range: toRange(lineInfo, link.offset, link.length),
      target: Uri.file(link.targetPath).toString(),
    );
  }
}

class DocumentLinkRegistrations extends FeatureRegistration
    with SingleDynamicRegistration, StaticRegistration<DocumentLinkOptions> {
  DocumentLinkRegistrations(super.info);

  @override
  ToJsonable? get options => DocumentLinkRegistrationOptions(
        documentSelector: [dartFiles],
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
