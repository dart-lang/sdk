// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/computer/computer_hover.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/dartdoc.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/source/line_info.dart';

typedef StaticOptions = Either2<bool, HoverOptions>;

class HoverHandler
    extends SharedMessageHandler<TextDocumentPositionParams, Hover?> {
  HoverHandler(super.server);

  @override
  Method get handlesMessage => Method.textDocument_hover;

  @override
  LspJsonHandler<TextDocumentPositionParams> get jsonHandler =>
      TextDocumentPositionParams.jsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<Hover?>> handle(TextDocumentPositionParams params,
      MessageInfo message, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    var clientCapabilities = message.clientCapabilities;
    if (clientCapabilities == null) {
      return serverNotInitializedError;
    }

    var pos = params.position;
    var path = pathOfDoc(params.textDocument);
    var unit = await path.mapResult(requireResolvedUnit);
    var offset = unit.mapResultSync((unit) => toOffset(unit.lineInfo, pos));
    return (success(clientCapabilities), unit, offset)
        .mapResultsSync(_getHover);
  }

  Hover? toHover(
    LspClientCapabilities clientCapabilities,
    LineInfo lineInfo,
    HoverInformation? hover,
  ) {
    if (hover == null) {
      return null;
    }

    var content = StringBuffer();
    const divider = '---';

    // Description + Types.
    var elementDescription = hover.elementDescription;
    var staticType = hover.staticType;
    var isDeprecated = hover.isDeprecated ?? false;
    if (elementDescription != null) {
      content.writeln('```dart');
      if (isDeprecated) {
        content.write('(deprecated) ');
      }
      content
        ..writeln(elementDescription)
        ..writeln('```');
    }
    if (staticType != null) {
      content
        ..writeln('Type: `$staticType`')
        ..writeln();
    }

    // Source library.
    var containingLibraryName = hover.containingLibraryName;
    if (containingLibraryName != null && containingLibraryName.isNotEmpty) {
      content
        ..writeln('*$containingLibraryName*')
        ..writeln();
    }

    // Doc comments.
    if (hover.dartdoc != null) {
      if (content.length != 0) {
        content.writeln(divider);
      }
      content.writeln(cleanDartdoc(hover.dartdoc));
    }

    var formats = clientCapabilities.hoverContentFormats;
    return Hover(
      contents:
          asMarkupContentOrString(formats, content.toString().trimRight()),
      range: toRange(lineInfo, hover.offset, hover.length),
    );
  }

  ErrorOr<Hover?> _getHover(LspClientCapabilities clientCapabilities,
      ResolvedUnitResult unit, int offset) {
    var compilationUnit = unit.unit;
    var computer = DartUnitHoverComputer(
      server.getDartdocDirectiveInfoFor(unit),
      compilationUnit,
      offset,
      documentationPreference:
          server.lspClientConfiguration.global.preferredDocumentation,
    );
    var hover = computer.compute();
    return success(toHover(clientCapabilities, unit.lineInfo, hover));
  }
}

class HoverRegistrations extends FeatureRegistration
    with SingleDynamicRegistration, StaticRegistration<StaticOptions> {
  HoverRegistrations(super.info);

  @override
  ToJsonable? get options =>
      TextDocumentRegistrationOptions(documentSelector: fullySupportedTypes);

  @override
  Method get registrationMethod => Method.textDocument_hover;

  @override
  StaticOptions get staticOptions => Either2.t1(true);

  @override
  bool get supportsDynamic => clientDynamic.hover;
}
