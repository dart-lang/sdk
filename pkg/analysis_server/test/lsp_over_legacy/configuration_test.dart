// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/instrumentation/noop_service.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConfigurationTest);
  });
}

/// Tests for fetching client configuration over the legacy protocol.
///
/// Configuration is requested from the client with a `workspace/configuration`
/// reverse-request (wrapped in `lsp.handle`) once after the client has told us
/// its capabilities, and again whenever the client sends a
/// `workspace/didChangeConfiguration` notification. LSP messages received after
/// `server.setClientCapabilities` are not handled until the client has provided
/// its configuration.
///
/// Also includes tests for how the server handles LSP *notifications* generally
/// (which, unlike requests, have no `id` and therefore no response), using
/// `workspace/didChangeConfiguration` as the motivating example.
@reflectiveTest
class ConfigurationTest extends LspOverLegacyTest {
  /// Code with both a variable declaration (which produces a type hint) and an
  /// argument (which produces a parameter name hint) inside the marked range.
  static final testCode = TestCode.parse('''
void f(int a) {}

void g() {
  [!final x = 1;
  f(2);!]
}
''');

  /// A `workspace/didChangeConfiguration` notification to tell the server that
  /// the client's configuration has changed.
  NotificationMessage get didChangeConfigurationNotification =>
      NotificationMessage(
        method: Method.workspace_didChangeConfiguration,
        params: DidChangeConfigurationParams().toJson(),
        jsonrpc: jsonRpcVersion,
      );

  /// Returns the inlay hints for the marked range of [testCode].
  ///
  /// Which hints are produced depends on the client configuration, so this is
  /// used to observe which configuration a request was handled with.
  Future<List<InlayHint>> getTestFileInlayHints() =>
      getInlayHints(testFileUri, testCode.range.range);

  /// Calls [f] and responds to the `workspace/configuration` request that it
  /// triggers with [globalConfig].
  ///
  /// Returns once the response has been sent. The server applies the
  /// configuration while processing that response and messages are processed in
  /// the order they are sent, so any request sent afterwards will see the new
  /// configuration.
  Future<void> provideConfig(
    FutureOr<void> Function() f,
    Map<String, Object?> globalConfig,
  ) async {
    // Configuration is only requested from a client that says it supports it.
    // Setting this once the capabilities have been sent has no effect, which is
    // what we want for the calls that provide an updated configuration.
    setConfigurationSupport();

    var configRequest = await expectRequest(Method.workspace_configuration, f);

    var params = ConfigurationParams.fromJson(
      configRequest.params as Map<String, Object?>,
    );
    // The legacy server has no workspace folders, so it only ever asks for the
    // global 'dart' configuration.
    expect(params.items, hasLength(1));
    expect(params.items.single.section, 'dart');
    expect(params.items.single.scopeUri, isNull);

    respondTo(configRequest, [globalConfig]);
  }

  /// Sends the currently configured LSP client capabilities to the server in a
  /// `server.setClientCapabilities` request.
  ///
  /// Unlike [sendClientCapabilities] this can be used after the analysis roots
  /// have been set and more than once per test, which is what a client that
  /// sends its capabilities late or repeatedly does.
  Future<void> sendClientCapabilitiesRequest() async {
    await handleSuccessfulRequest(
      ServerSetClientCapabilitiesParams(
        [],
        lspCapabilities: ClientCapabilities(
          workspace: workspaceCapabilities,
          textDocument: textDocumentCapabilities,
          window: windowCapabilities,
          experimental: experimentalCapabilities,
        ),
      ).toRequest('${nextRequestId++}', clientUriConverter: uriConverter),
    );
  }

  @override
  Future<void> setUp() async {
    await super.setUp();
    newFile(testFilePath, testCode.code);
  }

  Future<void> test_didChangeConfiguration_appliesNewConfiguration() async {
    // The initial configuration is fetched once the client has told us its
    // capabilities.
    await provideConfig(sendClientCapabilities, {
      'inlayHints': {'parameterNames': 'none'},
    });
    await initializeServer();

    // Only the variable type hint, because the initial configuration disabled
    // parameter name hints.
    var hints = await getTestFileInlayHints();
    expect(hints.map((hint) => hint.kind), [InlayHintKind.Type]);

    // Telling the server the configuration changed must make it re-request the
    // configuration and replace the previous values.
    await provideConfig(
      () => sendNotificationToServer(didChangeConfigurationNotification),
      {
        'inlayHints': {
          'variableTypes': {'enabled': false},
        },
      },
    );

    hints = await getTestFileInlayHints();
    expect(hints.map((hint) => hint.kind), [InlayHintKind.Parameter]);
  }

  Future<void> test_didChangeConfiguration_doesNotBlockRequests() async {
    await provideConfig(sendClientCapabilities, {
      'inlayHints': {'parameterNames': 'none'},
    });
    await initializeServer();

    // Subscribe before sending the notification so the request can't be missed.
    var configRequestFuture = requestsFromServer.firstWhere(
      (request) => request.method == Method.workspace_configuration,
    );
    sendNotificationToServer(didChangeConfigurationNotification);
    var configRequest = await configRequestFuture;

    // Unlike the initial fetch, a re-fetch does not hold LSP requests back. The
    // server already has a configuration to handle them with, which is the
    // previous one until the client provides the new one.
    var hints = await getTestFileInlayHints();
    expect(hints.map((hint) => hint.kind), [InlayHintKind.Type]);

    respondTo(configRequest, [
      {
        'inlayHints': {
          'variableTypes': {'enabled': false},
        },
      },
    ]);

    hints = await getTestFileInlayHints();
    expect(hints.map((hint) => hint.kind), [InlayHintKind.Parameter]);
  }

  Future<void> test_handle_rejectsNotification() async {
    await initializeServer();

    // `lsp.handle` is for LSP requests. Notifications have no `id` and no
    // response, so they are sent as `lsp.notification` notifications instead.
    var legacyRequest = createLegacyRequest(
      LspHandleParams(didChangeConfigurationNotification.toJson()),
    );

    var response = await handleRequest(legacyRequest);

    assertResponseFailure(
      response,
      requestId: legacyRequest.id,
      errorCode: RequestErrorCode.INVALID_PARAMETER,
    );
  }

  Future<void> test_lspRequestBeforeClientCapabilities_usesDefaults() async {
    // This client never sends `server.setClientCapabilities`, so there is no
    // configuration to wait for and the defaults are used.
    await initializeServer();

    var hints = await getTestFileInlayHints();
    expect(hints.map((hint) => hint.kind), [
      InlayHintKind.Type,
      InlayHintKind.Parameter,
    ]);
  }

  Future<void> test_notification_invalidParams_logged() async {
    await initializeServer();
    var instrumentationService = _RecordingInstrumentationService();
    server.instrumentationService = instrumentationService;

    // Not a valid `lsp.notification`, because it has no `lspNotification`.
    serverChannel.simulateNotificationFromClient(
      Notification(lspNotificationNotification, {}),
    );
    await pumpEventQueue(times: 5000);

    // The server keeps serving requests.
    await handleSuccessfulRequest(
      createLegacyRequest(ServerGetVersionParams()),
    );

    // A client error rather than a server failure, so it is logged as an error
    // and not as an exception (which would also be sent to the client as a
    // `server.error` notification and reported to crash reporting).
    expect(instrumentationService.loggedExceptions, isEmpty);
    expect(instrumentationService.loggedErrors, hasLength(1));
    expect(
      instrumentationService.loggedErrors.single,
      startsWith("The 'lsp.notification' notification was not valid:"),
    );
  }

  Future<void> test_notification_malformed_logged() async {
    await initializeServer();
    var instrumentationService = _RecordingInstrumentationService();
    server.instrumentationService = instrumentationService;

    // Not a valid LSP NotificationMessage, because it has no `method`.
    serverChannel.simulateNotificationFromClient(
      LspNotificationParams(<String, Object?>{'jsonrpc': jsonRpcVersion})
          .toNotification(clientUriConverter: uriConverter),
    );
    await pumpEventQueue(times: 5000);

    // The server keeps serving requests.
    await handleSuccessfulRequest(
      createLegacyRequest(ServerGetVersionParams()),
    );

    // There is no response to report the failure in, so it is only logged.
    expect(instrumentationService.loggedExceptions, isEmpty);
    expect(instrumentationService.loggedErrors, hasLength(1));
    expect(
      instrumentationService.loggedErrors.single,
      startsWith(
        "The 'lspNotification' parameter was not a valid LSP notification:",
      ),
    );
  }

  Future<void> test_notification_unknownMethod_logged() async {
    await initializeServer();
    var instrumentationService = _RecordingInstrumentationService();
    server.instrumentationService = instrumentationService;

    // Unlike the optional `$/` notifications, a notification for an unknown
    // method that is not optional is an error for the handler.
    sendNotificationToServer(
      NotificationMessage(
        method: Method.fromJson('randomNotification'),
        jsonrpc: jsonRpcVersion,
      ),
    );
    await pumpEventQueue(times: 5000);

    // The server keeps serving requests.
    await handleSuccessfulRequest(
      createLegacyRequest(ServerGetVersionParams()),
    );

    // A notification has no LSP response to carry the error back, so the
    // failure is only logged. It is an expected LSP error and not a crash, so
    // it must be logged as an error and not as an exception (which would also
    // be sent to the client as a `server.error` notification and reported to
    // crash reporting).
    expect(instrumentationService.loggedExceptions, isEmpty);
    expect(instrumentationService.loggedErrors, hasLength(1));
    expect(
      instrumentationService.loggedErrors.single,
      'An error occurred while handling randomNotification notification: '
      'Unknown method randomNotification',
    );
  }

  Future<void> test_notification_unknownOptionalMethod_ignored() async {
    await initializeServer();
    var instrumentationService = _RecordingInstrumentationService();
    server.instrumentationService = instrumentationService;

    // Methods starting with `$/` are optional notifications per the LSP spec;
    // unregistered ones are silently accepted rather than reported as errors
    // (see `ServerStateMessageHandler._isOptionalNotification`).
    sendNotificationToServer(
      NotificationMessage(
        method: Method.fromJson(r'$/randomNotification'),
        jsonrpc: jsonRpcVersion,
      ),
    );
    await pumpEventQueue(times: 5000);

    // The server keeps serving requests.
    await handleSuccessfulRequest(
      createLegacyRequest(ServerGetVersionParams()),
    );

    expect(instrumentationService.loggedExceptions, isEmpty);
    expect(instrumentationService.loggedErrors, isEmpty);
  }

  Future<void> test_setClientCapabilities_afterLspRequest() async {
    // An LSP request from a client that has not (yet) sent its capabilities
    // completes LSP initialization using the defaults.
    await initializeServer();

    var hints = await getTestFileInlayHints();
    expect(hints.map((hint) => hint.kind), [
      InlayHintKind.Type,
      InlayHintKind.Parameter,
    ]);

    var instrumentationService = _RecordingInstrumentationService();
    server.instrumentationService = instrumentationService;

    // Capabilities that arrive afterwards must still have their configuration
    // fetched and applied, and completing the already-completed initialization
    // again must not fail.
    await provideConfig(sendClientCapabilitiesRequest, {
      'inlayHints': {'parameterNames': 'none'},
    });

    hints = await getTestFileInlayHints();
    expect(hints.map((hint) => hint.kind), [InlayHintKind.Type]);
    expect(instrumentationService.loggedExceptions, isEmpty);
  }

  Future<void> test_setClientCapabilities_invalidCapabilities() async {
    // Capabilities that are rejected mean no configuration will be requested,
    // so LSP requests must not be left waiting for one.
    var request = ServerSetClientCapabilitiesParams(
      [],
      lspCapabilities: {
        'textDocument': 1, // Not valid
      },
    ).toRequest('${nextRequestId++}', clientUriConverter: uriConverter);

    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: request.id,
      errorCode: RequestErrorCode.INVALID_PARAMETER,
    );

    await initializeServer();

    var hints = await getTestFileInlayHints();
    expect(hints.map((hint) => hint.kind), [
      InlayHintKind.Type,
      InlayHintKind.Parameter,
    ]);
  }

  Future<void> test_setClientCapabilities_malformedConfiguration() async {
    setConfigurationSupport();
    var instrumentationService = _RecordingInstrumentationService();
    server.instrumentationService = instrumentationService;

    var configRequest = await expectRequest(
      Method.workspace_configuration,
      sendClientCapabilities,
    );
    var capabilitiesRequestId = lastSentLegacyRequestId;

    // Respond with something that is not a valid LSP ResponseMessage (it has no
    // `jsonrpc` field) so that parsing the response throws. The fetch was
    // started - but not awaited - by a request that has already been answered,
    // so the failure must not escape into that request's error handling.
    serverChannel.simulateResponseFromClient(
      Response(
        configRequest.id.map((id) => id.toString(), (id) => id),
        result: LspHandleResult(<String, Object?>{})
            .toJson(clientUriConverter: uriConverter),
      ),
    );
    await initializeServer();

    // The server keeps serving requests.
    await handleSuccessfulRequest(
      createLegacyRequest(ServerGetVersionParams()),
    );

    // And `server.setClientCapabilities` was answered exactly once.
    expect(
      serverChannel.responsesReceived.where(
        (response) => response.id == capabilitiesRequestId,
      ),
      hasLength(1),
    );
    expect(instrumentationService.loggedExceptions, hasLength(1));
    expect(
      instrumentationService.loggedExceptions.single.toString(),
      contains('An error occurred while fetching the client configuration'),
    );

    // A configuration that never arrived must not hold LSP requests back
    // forever, they are handled using the defaults.
    var hints = await getTestFileInlayHints();
    expect(hints.map((hint) => hint.kind), [
      InlayHintKind.Type,
      InlayHintKind.Parameter,
    ]);
  }

  Future<void> test_setClientCapabilities_noConfigurationSupport() async {
    // The default client capabilities do not include
    // `workspace.configuration`.
    var requestsFromServerReceived = <RequestMessage>[];
    var subscription = requestsFromServer.listen(
      requestsFromServerReceived.add,
    );

    await sendClientCapabilities();
    await initializeServer();

    // There is no configuration to wait for, so LSP requests are handled using
    // the defaults.
    var hints = await getTestFileInlayHints();
    expect(hints.map((hint) => hint.kind), [
      InlayHintKind.Type,
      InlayHintKind.Parameter,
    ]);

    await subscription.cancel();

    expect(requestsFromServerReceived, isEmpty);
  }

  Future<void> test_setClientCapabilities_requestsWaitForConfiguration() async {
    setConfigurationSupport();

    // Awaiting `sendClientCapabilities` here shows that
    // `server.setClientCapabilities` is answered without waiting for the client
    // to respond to `workspace/configuration`, which a client may not do until
    // it has had the response to its own request.
    var configRequest = await expectRequest(
      Method.workspace_configuration,
      sendClientCapabilities,
    );
    await initializeServer();

    // An LSP request must not be handled until the configuration has arrived,
    // otherwise it would be answered using the defaults.
    var hintsCompleted = false;
    var hintsFuture = getTestFileInlayHints();
    unawaited(hintsFuture.then((_) => hintsCompleted = true));
    await pumpEventQueue(times: 5000);
    expect(hintsCompleted, isFalse);

    // Requests that are not LSP requests are not held back.
    await handleSuccessfulRequest(
      createLegacyRequest(ServerGetVersionParams()),
    );

    respondTo(configRequest, [
      {
        'inlayHints': {'parameterNames': 'none'},
      },
    ]);

    // Only the variable type hint, because the request waited for the
    // configuration that disabled parameter name hints.
    var hints = await hintsFuture;
    expect(hints.map((hint) => hint.kind), [InlayHintKind.Type]);
  }

  Future<void> test_setClientCapabilities_twice() async {
    // The first set of capabilities does not support configuration, so it
    // completes LSP initialization immediately.
    await sendClientCapabilities();
    await initializeServer();

    var instrumentationService = _RecordingInstrumentationService();
    server.instrumentationService = instrumentationService;

    // A client may send its capabilities again. The configuration is fetched
    // for the new capabilities and completing the already-completed
    // initialization again must not fail.
    await provideConfig(sendClientCapabilitiesRequest, {
      'inlayHints': {'parameterNames': 'none'},
    });

    var hints = await getTestFileInlayHints();
    expect(hints.map((hint) => hint.kind), [InlayHintKind.Type]);
    expect(instrumentationService.loggedExceptions, isEmpty);
  }
}

/// An [InstrumentationService] that records the errors and exceptions logged
/// to it.
class _RecordingInstrumentationService extends NoopInstrumentationService {
  final List<String> loggedErrors = [];
  final List<Object> loggedExceptions = [];

  @override
  void logError(String message) {
    loggedErrors.add(message);
  }

  @override
  void logException(
    Object exception, [
    StackTrace? stackTrace,
    List<InstrumentationServiceAttachment>? attachments,
  ]) {
    loggedExceptions.add(exception);
  }
}
