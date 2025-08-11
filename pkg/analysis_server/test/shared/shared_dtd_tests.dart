// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:dtd/dtd.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:test/test.dart';

import '../../integration_test/support/dart_tooling_daemon.dart';
import '../../integration_test/support/web_sockets.dart';
import '../lsp/request_helpers_mixin.dart';
import '../tool/lsp_spec/matchers.dart';
import '../utils/lsp_protocol_extensions.dart';
import '../utils/test_code_extensions.dart';

/// The name of the DTD service that LSP methods are registered against.
const lspServiceName = 'Lsp';

/// The name of the DTD stream that events/notifications will be posted to.
const lspStreamName = 'Lsp';

/// A wrapper around [DartToolingDaemon] that allows using the
/// [LspRequestHelpersMixin] methods to send requests over DTD.
class DtdHelper with LspRequestHelpersMixin {
  final DartToolingDaemon connection;

  DtdHelper(this.connection);

  @override
  Future<T> expectSuccessfulResponseTo<T, R>(
    RequestMessage request,
    T Function(R) fromJson,
  ) async {
    var response = await sendRequestToServer(request);
    var error = response.error;
    if (error != null) {
      throw error;
    } else {
      // response.result should only be null when error != null if T allows null.
      return response.result == null
          ? null as T
          : fromJson(response.result as R);
    }
  }

  @override
  Future<ResponseMessage> sendRequestToServer(RequestMessage request) async {
    var response = await connection.call(
      lspServiceName,
      request.method.toString(),
      params: request.params as Map<String, Object?>,
    );

    return ResponseMessage(
      jsonrpc: jsonRpcVersion,
      // The LSP result is in the 'result' field, and DTD provides the whole
      // result in `response.result`.
      result: response.result['result'],
    );
  }
}

/// Shared DTD tests that are used by both LSP and legacy server integration
/// tests.
mixin SharedDtdTests
    on LspRequestHelpersMixin, LspEditHelpersMixin, LspVerifyEditHelpersMixin {
  /// The name of the DTD service that methods will be registered under.

  /// The `dart tooling-daemon` process we've spawned to connect to.
  late DtdProcess dtdProcess;

  /// The URI we can connect to [dtdProcess] using.
  late Uri dtdUri;

  /// A helper wrapping the tests connection to DTD which can be used to
  /// interact with DTD and send LSP requests using the shared request helper
  /// methods.
  ///
  /// Calling methods like `getHover` on this instance will send the request
  /// DTD whereas calling [getHover] would send the request directly to the
  /// server (via the real or simulated stdin/stdout streams).
  late DtdHelper dtd;

  /// A list of service/methods that the test client has seen registered (and
  /// not yet unregistered) over the DTD connection.
  ///
  /// The service name is a nullable String because DTD-internal methods and
  /// services do not have a service name.
  final availableMethods = <(String?, Method)>[];

  /// An invalid DTD URI used for testing connection failures.
  final invalidUri = Uri.parse('ws://invalid:345/invalid');

  // TODO(dantup): Support this for LSP-over-Legacy shared tests.
  set failTestOnErrorDiagnostic(bool value);

  /// Overridden by test subclasses to provide the path of a file for testing.
  String get testFile;

  /// Overridden by test subclasses to provide a URI for [testFile].
  Uri get testFileUri;

  /// Overridden by test subclasses to create a new file.
  void createFile(String path, String content);

  /// Sets up a file with [code] and expects/returns the [Command] code action
  /// with [title].
  Future<Command> expectCommandCodeAction(TestCode code, String title) async {
    createFile(testFile, code.code);
    await initializeServer();
    await sendConnectToDtdRequest();

    // Ensure the codeAction service is available.
    expectMethod(Method.textDocument_codeAction);

    // Fetch code actions at the marked location.
    var actions = await dtd.getCodeActions(
      testFileUri,
      range: code.range.range,
    );

    // Ensure all returned actions are Commands (not CodeActionLiterals).
    var commands = actions.map((action) => action.asCommand).toList();

    // Find the one with the matching title.
    expect(commands.map((command) => command.title), contains(title));
    return commands.singleWhere((command) => command.title == title);
  }

  Future<void> expectedCommandCodeActionEdits(
    TestCode code,
    String title,
    String expected,
  ) async {
    var command = await expectCommandCodeAction(code, title);

    // Invoke the command over DTD, expecting edits to be sent back to us
    // (not over DTD).
    var verifier = await executeForEdits(() => dtd.executeCommand(command));

    verifier.verifyFiles(expected);
  }

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
    var lspEventSub = dtd.connection.onEvent(lspStreamName).listen((e) {
      switch (e.kind) {
        case 'initialized':
          lspInitializedCompleter.complete();
      }
    });
    await dtd.connection.streamListen(lspStreamName);

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
      await dtd.connection.streamCancel(lspStreamName);
    }
  }

  Future<void> setUpDtd() async {
    // Start the DTD process like an editor would.
    dtdProcess = await DtdProcess.start();

    // Create our own (logged) connection to it
    dtdUri = await dtdProcess.dtdUri;
    dtd = DtdHelper(
      DartToolingDaemon.fromStreamChannel(
        await createLoggedWebSocketChannel(dtdUri),
      ),
    );

    // Capture service method registrations/unregistrations.
    dtd.connection.onEvent('Service').listen((e) {
      switch (e.kind) {
        case 'ServiceRegistered':
          availableMethods.add((
            e.data['service'] as String?,
            Method(e.data['method'] as String),
          ));
        case 'ServiceUnregistered':
          availableMethods.remove((
            e.data['service'] as String?,
            Method(e.data['method'] as String),
          ));
      }
    });

    // Start listening to the stream.
    await dtd.connection.streamListen('Service');
  }

  /// Overridden by test subclasses to instruct the server to shut down (which
  /// should result in DTD services being unregistered).
  Future<void> shutdownServer();

  Future<void> tearDownDtd() async {
    await dtdProcess.dispose();
  }

  Future<void> test_connectToDtd_failure_alreadyRegistered() async {
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

  Future<void> test_connectToDtd_failure_invalidUri() async {
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

  Future<void> test_connectToDtd_success_afterFailureToConnect() async {
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

  Future<void> test_connectToDtd_success_afterPreviousDtdShutdown() async {
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

  Future<void>
  test_connectToDtd_success_doesNotRegister_connectToDtdMethod() async {
    await initializeServer();
    await sendConnectToDtdRequest();

    expectMethod(CustomMethods.connectToDtd, available: false);
  }

  Future<void>
  test_connectToDtd_success_doesNotRegister_experimentalMethods() async {
    await initializeServer();
    await sendConnectToDtdRequest();

    expectMethod(CustomMethods.experimentalEcho, available: false);
  }

  Future<void>
  test_connectToDtd_success_doesNotRegister_fileStateMethods() async {
    await initializeServer();
    await sendConnectToDtdRequest();

    // Methods that modify state that is owned by the server shouldn't be
    // registered.
    expectMethod(Method.textDocument_didOpen, available: false);
    expectMethod(Method.textDocument_didClose, available: false);
    expectMethod(Method.textDocument_didChange, available: false);
  }

  Future<void>
  test_connectToDtd_success_doesNotRegister_initializationMethods() async {
    await initializeServer();
    await sendConnectToDtdRequest();

    // No initialization request/notifications should be available.
    expectMethod(Method.initialize, available: false);
    expectMethod(Method.initialized, available: false);
  }

  Future<void> test_connectToDtd_success_registers_experimentalMethods() async {
    await initializeServer();
    await sendConnectToDtdRequest(registerExperimentalHandlers: true);

    expectMethod(CustomMethods.experimentalEcho);
  }

  Future<void> test_connectToDtd_success_registers_standardLspMethods() async {
    await initializeServer();
    await sendConnectToDtdRequest();

    // Check some known methods that should be available.
    expectMethod(Method.textDocument_documentSymbol);
    expectMethod(Method.textDocument_hover);
    expectMethod(Method.textDocument_formatting);
    expectMethod(Method.textDocument_implementation);
    expectMethod(Method.textDocument_documentColor);
  }

  Future<void> test_service_codeAction_assist() async {
    setApplyEditSupport();

    var code = TestCode.parse('''
var a = [!''!];
''');

    var title = 'Convert to double quoted string';
    var expected = r'''
>>>>>>>>>> lib/main.dart
var a = "";
''';

    await expectedCommandCodeActionEdits(code, title, expected);
  }

  Future<void> test_service_codeAction_fix() async {
    failTestOnErrorDiagnostic = false;
    setApplyEditSupport();

    var code = TestCode.parse('''
Future<void> [!f!]() {}
''');

    var title = "Add 'async' modifier";
    var expected = r'''
>>>>>>>>>> lib/main.dart
Future<void> f() async {}
''';

    await expectedCommandCodeActionEdits(code, title, expected);
  }

  Future<void> test_service_codeAction_refactor() async {
    setApplyEditSupport();

    var code = TestCode.parse('''
void f() {
  [!print('');!]
}
''');

    var title = 'Extract Method';
    var expected = r'''
>>>>>>>>>> lib/main.dart
void f() {
  newMethod();
}

void newMethod() {
  print('');
}
''';

    await expectedCommandCodeActionEdits(code, title, expected);
  }

  Future<void> test_service_codeAction_source() async {
    setApplyEditSupport();

    var code = TestCode.parse('''
[!!]import 'dart:async';
import 'dart:io';

FutureOr<void>? a;
''');

    var title = 'Organize Imports';
    var expected = r'''
>>>>>>>>>> lib/main.dart
import 'dart:async';

FutureOr<void>? a;
''';

    await expectedCommandCodeActionEdits(code, title, expected);
  }

  Future<void> test_service_failure_hover() async {
    await initializeServer();
    await sendConnectToDtdRequest();

    // Attempt an unsuccessful request to textDocument/hover over DTD.
    expectMethod(Method.textDocument_hover);
    var nonExistantFilePath = testFile.replaceAll('.dart', '.notExist.dart');
    var call = dtd.getHover(
      Uri.file(nonExistantFilePath),
      Position(line: 1, character: 1),
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

  Future<void> test_service_success_echo() async {
    await initializeServer();
    await sendConnectToDtdRequest(registerExperimentalHandlers: true);

    var response = await dtd.connection.call(
      lspServiceName,
      CustomMethods.experimentalEcho.toString(),
      params: {'a': 'b'},
    );

    var result = response.result['result'] as Map<String, Object?>?;

    expect(result, equals({'a': 'b'}));
  }

  Future<void>
  test_service_success_echo_nullResponse_with_empty_params() async {
    await initializeServer();
    await sendConnectToDtdRequest(registerExperimentalHandlers: true);

    var response = await dtd.connection.call(
      lspServiceName,
      CustomMethods.experimentalEcho.toString(),
      params: const <String, Object?>{},
    );

    var result = response.result['result'] as Map<String, Object?>?;

    expect(response.type, 'Null');
    expect(result, isNull);
  }

  Future<void> test_service_success_echo_nullResponse_with_null_params() async {
    await initializeServer();
    await sendConnectToDtdRequest(registerExperimentalHandlers: true);

    var response = await dtd.connection.call(
      lspServiceName,
      CustomMethods.experimentalEcho.toString(),
    );

    var result = response.result['result'] as Map<String, Object?>?;

    expect(response.type, 'Null');
    expect(result, isNull);
  }

  Future<void> test_service_success_hover() async {
    var code = TestCode.parse('''
/// A function.
void [!myFun^ction!]() {}
''');
    createFile(testFile, code.code);

    await initializeServer();
    await sendConnectToDtdRequest();

    // Attempt a successful request to textDocument/hover over DTD.
    expectMethod(Method.textDocument_hover);
    var hoverResult = await dtd.getHover(testFileUri, code.position.position);

    // Verify the result.
    var hoverStringContent = hoverResult!.contents.map(
      (markup) => markup.value,
      (string) => string,
    );
    expect(hoverResult.range, equals(code.range.range));
    expect(hoverStringContent, contains('A function.'));
  }

  Future<void> test_service_unregisteredOnShutdown() async {
    await initializeServer();
    await sendConnectToDtdRequest();

    var lspMethods = availableMethods.where(
      (serviceMethod) => serviceMethod.$1 == 'Lsp',
    );
    expect(lspMethods, isNotEmpty);

    // Send a request to the server to connect to DTD. This will only complete
    // once all services are registered, however there's no guarantee about the
    // time DTD takes to forward those service registrations to us, so we also
    // need some delay.
    await shutdownServer();

    // Wait for the services to be unregistered.
    while (lspMethods.isNotEmpty) {
      await pumpEventQueue(times: 5000);
    }
    expect(lspMethods, isEmpty);
  }
}
