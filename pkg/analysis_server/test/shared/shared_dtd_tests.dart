// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:dtd/dtd.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:language_server_protocol/json_parsing.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../integration/support/dart_tooling_daemon.dart';
import '../integration/support/web_sockets.dart';
import '../lsp/request_helpers_mixin.dart';
import '../tool/lsp_spec/matchers.dart';
import '../utils/test_code_extensions.dart';

/// Shared DTD tests that are used by both LSP and legacy server integration
/// tests.
mixin SharedDtdTests on LspRequestHelpersMixin {
  /// The name of the DTD service that methods will be registered under.
  static const lspServiceName = 'Lsp';

  /// The name of the DTD stream that events/notifications will be posted to.
  static const lspStreamName = 'Lsp';

  /// The `dart tooling-daemon` process we've spawned to connect to.
  late DtdProcess dtdProcess;

  /// The URI we can connect to [dtdProcess] using.
  late Uri dtdUri;

  /// The tests client connection to DTD (used to verify we can call services
  /// provided by the analysis server over DTD).
  late DartToolingDaemon dtd;

  /// A list of service/methods that the test client has seen registered (and
  /// not yet unregistered) over the DTD connection.
  final availableMethods = <(String, Method)>[];

  /// An invalid DTD URI used for testing connection failures.
  final invalidUri = Uri.parse('ws://invalid:345/invalid');

  /// Overridden by test subclasses to provide the path of a file for testing.
  String get testFile;

  /// Overridden by test subclasses to provide a URI for [testFile].
  Uri get testFileUri;

  /// Overridden by test subclasses to create a new file.
  void createFile(String path, String content);

  void expectMethod(Method method, {bool available = true}) {
    if (available) {
      expect(availableMethods, contains((lspServiceName, method)));
    } else {
      expect(availableMethods, isNot(contains((lspServiceName, method))));
    }
  }

  /// Overridden by test subclasses to initialize the server.
  Future<void> initializeServer();

  /// Sends a request to connect to DTD and captures all service methods that
  /// are registered/unregistered into [availableMethods] until the `ready`
  /// event is posted.
  ///
  /// [registerExperimentalHandlers] controls whether experimental handlers are
  /// registered.
  Future<void> sendConnectToDtdRequest({
    Uri? uri,
    bool? registerExperimentalHandlers,
  }) async {
    // Set up a completer to listen for the 'initialized' event on the Lsp
    // stream so that we know when the services have finished registering.
    var lspInitializedCompleter = Completer<void>();
    var lspEventSub = dtd.onEvent(lspStreamName).listen((e) {
      switch (e.kind) {
        case 'initialized':
          lspInitializedCompleter.complete();
      }
    });
    await dtd.streamListen(lspStreamName);

    try {
      await connectToDtd(
        uri ?? dtdUri,
        registerExperimentalHandlers: registerExperimentalHandlers,
      );

      // Wait for the event.
      await lspInitializedCompleter.future;
    } finally {
      // Unsubscribe.
      await lspEventSub.cancel();
      await dtd.streamCancel(lspStreamName);
    }
  }

  Future<void> setUpDtd() async {
    // Start the DTD process like an editor would.
    dtdProcess = await DtdProcess.start();

    // Create our own (logged) connection to it
    dtdUri = await dtdProcess.dtdUri;
    dtd = DartToolingDaemon.fromStreamChannel(
      await createLoggedWebSocketChannel(dtdUri),
    );

    // Capture service method registrations/unregistrations.
    dtd.onEvent('Service').listen((e) {
      switch (e.kind) {
        case 'ServiceRegistered':
          availableMethods.add((
            e.data['service'] as String,
            Method(e.data['method'] as String),
          ));
        case 'ServiceUnregistered':
          availableMethods.remove((
            e.data['service'] as String,
            Method(e.data['method'] as String),
          ));
      }
    });

    // Start listening to the stream.
    await dtd.streamListen('Service');
  }

  /// Overridden by test subclasses to instruct the server to shut down (which
  /// should result in DTD services being unregistered).
  Future<void> shutdownServer();

  Future<void> tearDownDtd() async {
    await dtdProcess.dispose();
  }

  test_connectToDtd_failure_alreadyRegistered() async {
    await initializeServer();
    await sendConnectToDtdRequest();
    await expectLater(
      sendConnectToDtdRequest(),
      throwsA(
        isResponseError(
          ServerErrorCodes.StateError,
          message: 'Server is already connected to DTD',
        ),
      ),
    );
  }

  test_connectToDtd_failure_invalidUri() async {
    await initializeServer();
    await expectLater(
      sendConnectToDtdRequest(uri: invalidUri),
      throwsA(
        isResponseError(
          ErrorCodes.RequestFailed,
          message: startsWith(
            'Failed to connect to DTD at ws://invalid:345/invalid\nWebSocketChannelException:',
          ),
        ),
      ),
    );
  }

  test_connectToDtd_success_afterFailureToConnect() async {
    await initializeServer();

    // Perform a failed connection.
    await expectLater(
      sendConnectToDtdRequest(uri: invalidUri),
      throwsA(
        isResponseError(
          ErrorCodes.RequestFailed,
          message: startsWith(
            'Failed to connect to DTD at ws://invalid:345/invalid\nWebSocketChannelException:',
          ),
        ),
      ),
    );

    // Expect complete with no error.
    await sendConnectToDtdRequest();
  }

  test_connectToDtd_success_afterPreviousDtdShutdown() async {
    await initializeServer();

    // Connect to the initial DTD.
    await sendConnectToDtdRequest();

    // Shut down the initial DTD process as if it crashed. Server should notice
    // this and now allow us to connect a new one.
    await tearDownDtd();

    // Start up a new DTD.
    await setUpDtd();

    // Connect to the new DTD and ensure completion with no error.
    await sendConnectToDtdRequest();
  }

  test_connectToDtd_success_doesNotRegister_connectToDtdMethod() async {
    await initializeServer();
    await sendConnectToDtdRequest();

    expectMethod(CustomMethods.connectToDtd, available: false);
  }

  test_connectToDtd_success_doesNotRegister_experimentalMethods() async {
    await initializeServer();
    await sendConnectToDtdRequest();

    expectMethod(CustomMethods.experimentalEcho, available: false);
  }

  test_connectToDtd_success_doesNotRegister_fileStateMethods() async {
    await initializeServer();
    await sendConnectToDtdRequest();

    // Methods that modify state that is owned by the server shouldn't be
    // registered.
    expectMethod(Method.textDocument_didOpen, available: false);
    expectMethod(Method.textDocument_didClose, available: false);
    expectMethod(Method.textDocument_didChange, available: false);
  }

  test_connectToDtd_success_doesNotRegister_initializationMethods() async {
    await initializeServer();
    await sendConnectToDtdRequest();

    // No initialization request/notifications should be available.
    expectMethod(Method.initialize, available: false);
    expectMethod(Method.initialized, available: false);
  }

  test_connectToDtd_success_registers_experimentalMethods() async {
    await initializeServer();
    await sendConnectToDtdRequest(registerExperimentalHandlers: true);

    expectMethod(CustomMethods.experimentalEcho);
  }

  @SkippedTest(reason: 'Shared LSP methods are currently disabled')
  test_connectToDtd_success_registers_standardLspMethods() async {
    await initializeServer();
    await sendConnectToDtdRequest();

    // Check some known methods that should be available.
    expectMethod(Method.textDocument_documentSymbol);
    expectMethod(Method.textDocument_hover);
    expectMethod(Method.textDocument_formatting);
    expectMethod(Method.textDocument_implementation);
    expectMethod(Method.textDocument_documentColor);
  }

  @SkippedTest(reason: 'Shared LSP methods are currently disabled')
  test_service_failure_hover() async {
    await initializeServer();
    await sendConnectToDtdRequest();

    // Attempt an unsuccessful request to textDocument/hover over DTD.
    expectMethod(Method.textDocument_hover);
    var nonExistantFilePath = testFile.replaceAll('.dart', '.notExist.dart');
    var call = dtd.call(
      lspServiceName,
      'textDocument/hover',
      params:
          TextDocumentPositionParams(
            textDocument: TextDocumentIdentifier(
              uri: Uri.file(nonExistantFilePath),
            ),
            position: Position(line: 1, character: 1),
          ).toJson(),
    );

    // Expect a proper RPC Exception with the standard LSP error code/message.
    var expectedException = isA<RpcException>()
        .having(
          (e) => e.code,
          'code',
          ServerErrorCodes.InvalidFilePath.toJson(),
        )
        .having((e) => e.message, 'message', 'File does not exist')
        .having((e) => e.data, 'data', nonExistantFilePath);
    await expectLater(call, throwsA(expectedException));
  }

  test_service_success_echo() async {
    await initializeServer();
    await sendConnectToDtdRequest(registerExperimentalHandlers: true);

    var response = await dtd.call(
      lspServiceName,
      CustomMethods.experimentalEcho.toString(),
      params: {'a': 'b'},
    );

    var result = response.result['result'] as Map<String, Object?>?;

    expect(result, equals({'a': 'b'}));
  }

  test_service_success_echo_nullResponse() async {
    await initializeServer();
    await sendConnectToDtdRequest(registerExperimentalHandlers: true);

    var response = await dtd.call(
      lspServiceName,
      CustomMethods.experimentalEcho.toString(),
    );

    var result = response.result['result'] as Map<String, Object?>?;

    expect(response.type, 'Null');
    expect(result, isNull);
  }

  @SkippedTest(reason: 'Shared LSP methods are currently disabled')
  test_service_success_hover() async {
    var code = TestCode.parse('''
/// A function.
void [!myFun^ction!]() {}
''');
    createFile(testFile, code.code);

    await initializeServer();
    await sendConnectToDtdRequest();

    // Attempt a successful request to textDocument/hover over DTD.
    expectMethod(Method.textDocument_hover);
    var response = await dtd.call(
      lspServiceName,
      'textDocument/hover',
      params:
          TextDocumentPositionParams(
            textDocument: TextDocumentIdentifier(uri: testFileUri),
            position: code.position.position,
          ).toJson(),
    );

    expect(response.type, equals('Hover'));
    // The LSP result is in the 'result' field, and DTD provides the whole
    // result in `response.result`.
    var result = response.result['result'] as Map<String, Object?>;

    // Verify the result.
    expect(Hover.canParse(result, nullLspJsonReporter), isTrue);
    var hoverResult = Hover.fromJson(result);
    var hoverStringContent = hoverResult.contents.map(
      (markup) => markup.value,
      (string) => string,
    );
    expect(hoverResult.range, equals(code.range.range));
    expect(hoverStringContent, contains('A function.'));
  }

  @SkippedTest(reason: 'Shared LSP methods are currently disabled')
  test_service_unregisteredOnShutdown() async {
    await initializeServer();
    await sendConnectToDtdRequest();

    expect(availableMethods, isNotEmpty);

    // Send a request to the server to connect to DTD. This will only complete
    // once all services are registered, however there's no guarantee about the
    // time DTD takes to forward those service registrations to us, so we also
    // need some delay.
    await shutdownServer();

    // Wait for the services to be unregistered.
    while (availableMethods.isNotEmpty) {
      await pumpEventQueue(times: 5000);
    }
    expect(availableMethods, isEmpty);
  }
}
