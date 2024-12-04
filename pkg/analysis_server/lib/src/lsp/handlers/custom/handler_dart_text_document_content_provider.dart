// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analyzer/dart/analysis/results.dart';

typedef StaticOptions = DartTextDocumentContentProviderRegistrationOptions?;

class DartTextDocumentContentProviderHandler
    extends
        SharedMessageHandler<
          DartTextDocumentContentParams,
          DartTextDocumentContent
        > {
  DartTextDocumentContentProviderHandler(super.server);

  @override
  Method get handlesMessage => CustomMethods.dartTextDocumentContent;

  @override
  LspJsonHandler<DartTextDocumentContentParams> get jsonHandler =>
      DartTextDocumentContentParams.jsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<DartTextDocumentContent>> handle(
    DartTextDocumentContentParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    var allowedSchemes = server.uriConverter.supportedNonFileSchemes;
    var uri = params.uri;

    if (!allowedSchemes.contains(uri.scheme)) {
      var supportedSchemesString =
          allowedSchemes.isEmpty
              ? '(none)'
              : allowedSchemes.map((scheme) => "'$scheme'").join(', ');
      return error(
        ErrorCodes.InvalidParams,
        "Fetching content for scheme '${uri.scheme}' is not supported. "
        'Supported schemes are $supportedSchemesString.',
      );
    }

    return pathOfUri(uri).mapResult((filePath) async {
      var file = server.getAnalysisDriver(filePath)?.getFileSync(filePath);
      var content = file is FileResult ? file.content : null;

      return success(DartTextDocumentContent(content: content));
    });
  }
}

class DartTextDocumentContentProviderRegistrations extends FeatureRegistration
    with SingleDynamicRegistration, StaticRegistration<StaticOptions> {
  @override
  final DartTextDocumentContentProviderRegistrationOptions options;

  DartTextDocumentContentProviderRegistrations(super.info)
    : options = DartTextDocumentContentProviderRegistrationOptions(
        schemes: info.customDartSchemes.toList(),
      );

  @override
  Method get registrationMethod => CustomMethods.dartTextDocumentContent;

  @override
  StaticOptions get staticOptions => options;

  @override
  bool get supportsDynamic => false;

  @override
  bool get supportsStatic => true;
}
