// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/src/analytics/analytics_manager.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/utilities/extensions/file_system.dart';
import 'package:analyzer_plugin/src/utilities/client_uri_converter.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../analysis_server_base.dart';
import '../lsp/request_helpers_mixin.dart';
import '../lsp/server_abstract.dart';
import '../services/completion/dart/text_expectations.dart';
import '../shared/mixins/analytics_test_mixin.dart';
import '../shared/shared_test_interface.dart';

class EventsCollector {
  final ContextResolutionTest test;
  List<Object> events = [];

  EventsCollector(this.test) {
    test.notificationListener = (notification) {
      switch (notification.event) {
        case ANALYSIS_NOTIFICATION_ERRORS:
          events.add(
            AnalysisErrorsParams.fromNotification(
              notification,
              clientUriConverter: test.server.uriConverter,
            ),
          );
        case ANALYSIS_NOTIFICATION_FLUSH_RESULTS:
          events.add(
            AnalysisFlushResultsParams.fromNotification(
              notification,
              clientUriConverter: test.server.uriConverter,
            ),
          );
        case LSP_NOTIFICATION_NOTIFICATION:
          var params = LspNotificationParams.fromNotification(
            notification,
            clientUriConverter: test.server.uriConverter,
          );
          events.add(params.lspNotification);
        default:
          throw StateError(notification.event);
      }
    };
  }

  List<Object> take() {
    var result = events;
    events = [];
    return result;
  }
}

class EventsPrinter {
  final EventsPrinterConfiguration configuration;
  final ResourceProvider resourceProvider;
  final TreeStringSink sink;

  EventsPrinter({
    required this.configuration,
    required this.resourceProvider,
    required this.sink,
  });

  void write(List<Object> events) {
    for (var event in events) {
      switch (event) {
        case AnalysisErrorsParams():
          sink.writelnWithIndent('AnalysisErrors');
          sink.withIndent(() {
            _writelnFile(name: 'file', event.file);
            if (event.errors.isNotEmpty) {
              sink.writelnWithIndent('errors: notEmpty');
            } else {
              sink.writelnWithIndent('errors: empty');
            }
          });
        case AnalysisFlushResultsParams():
          sink.writeElements(
            'AnalysisFlushResults',
            event.files.sorted(),
            _writelnFile,
          );
        case NotificationMessage():
          switch (event.method) {
            case CustomMethods.dartTextDocumentContentDidChange:
              sink.writelnWithIndent(event.method);
              var params =
                  event.params as DartTextDocumentContentDidChangeParams;
              sink.withIndent(() {
                _writelnUri(params.uri, name: 'uri');
              });
            default:
              throw UnimplementedError('${event.method}');
          }
        default:
          throw UnimplementedError('${event.runtimeType}');
      }
    }
  }

  void _writelnFile(String path, {String? name}) {
    sink.writeIndentedLine(() {
      if (name != null) {
        sink.write('$name: ');
      }
      var file = resourceProvider.getFile(path);
      sink.write(file.posixPath);
    });
  }

  void _writelnUri(Uri uri, {String? name}) {
    sink.writeIndentedLine(() {
      if (name != null) {
        sink.write('$name: ');
      }

      if (uri.isScheme('file') || uri.isScheme('dart-macro+file')) {
        var fileUri = uri.replace(scheme: 'file');
        var path = resourceProvider.pathContext.fromUri(fileUri);
        var file = resourceProvider.getFile(path);
        uri = uri.replace(path: file.posixPath);
      }

      sink.write(uri);
    });
  }
}

class EventsPrinterConfiguration {}

abstract class LspOverLegacyTest extends PubPackageAnalysisServerTest
    with
        LspRequestHelpersMixin,
        LspReverseRequestHelpersMixin,
        LspNotificationHelpersMixin,
        LspEditHelpersMixin,
        ClientCapabilitiesHelperMixin,
        LspVerifyEditHelpersMixin,
        AnalyticsTestMixin {
  /// The last ID that was used for a legacy request.
  late String lastSentLegacyRequestId;

  /// A controller for [notificationsFromServer].
  final StreamController<NotificationMessage> _notificationsFromServer =
      StreamController<NotificationMessage>.broadcast();

  LspOverLegacyTest() {
    // Ensure the base fields for the tests are populated with the same default
    // client caapbilities that the server uses. This ensures if a test does not
    // explicitly set capabilities, they match on the client+server (so we can -
    // for example - make assumptions about what kind of edits the server will
    // return).
    if (fixedBasicLspClientCapabilities.raw.textDocument
        case var textDocument?) {
      textDocumentCapabilities = textDocument;
    }
    if (fixedBasicLspClientCapabilities.raw.workspace case var workspace?) {
      workspaceCapabilities = workspace;
    }
    if (fixedBasicLspClientCapabilities.raw.window case var window?) {
      windowCapabilities = window;
    }
    if (fixedBasicLspClientCapabilities.raw.experimental
        case Map<String, Object?>? experimental?) {
      experimentalCapabilities = experimental;
    }
  }

  @override
  AnalyticsManager get analyticsManager => server.analyticsManager;

  @override
  LspClientCapabilities get editorClientCapabilities =>
      server.editorClientCapabilities;

  /// A stream of [NotificationMessage]s from the server.
  @override
  Stream<NotificationMessage> get notificationsFromServer =>
      _notificationsFromServer.stream;

  @override
  path.Context get pathContext => resourceProvider.pathContext;

  @override
  String get projectFolderPath => convertPath(testPackageRootPath);

  Uri get pubspecFileUri => toUri(convertPath(pubspecFilePath));

  @override
  Stream<RequestMessage> get requestsFromServer => serverChannel
      .serverToClientRequests
      .where((request) => request.method == LSP_REQUEST_HANDLE)
      .map((request) {
        var params = LspHandleParams.fromRequest(
          request,
          clientUriConverter: uriConverter,
        );
        return RequestMessage.fromJson(
          params.lspMessage as Map<String, Object?>,
        );
      });

  /// The URI for the macro-generated content for [testFileUri].
  Uri get testFileMacroUri =>
      toUri(convertPath(testFilePath)).replace(scheme: macroClientUriScheme);

  Uri get testFileUri => toUri(convertPath(testFilePath));

  @override
  ClientUriConverter get uriConverter => server.uriConverter;

  Future<void> addOverlay(String filePath, String content, [int? version]) {
    return handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        convertPath(filePath): AddContentOverlay(content, version: version),
      }).toRequest(
        '${nextRequestId++}',
        clientUriConverter: server.uriConverter,
      ),
    );
  }

  Future<void> assertEventsText(
    EventsCollector collector,
    String expected,
  ) async {
    await pumpEventQueue(times: 5000);

    var buffer = StringBuffer();
    var sink = TreeStringSink(sink: buffer, indent: '');

    var events = collector.take();
    EventsPrinter(
      configuration: EventsPrinterConfiguration(),
      resourceProvider: resourceProvider,
      sink: sink,
    ).write(events);

    var actual = buffer.toString();
    if (actual != expected) {
      print('-------- Actual --------');
      print('$actual------------------------');
      TextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  /// Creates a legacy request with an auto-assigned ID.
  Request createLegacyRequest(RequestParams params) {
    return params.toRequest(
      '${nextRequestId++}',
      clientUriConverter: server.uriConverter,
    );
  }

  @override
  Future<T> expectSuccessfulResponseTo<T, R>(
    RequestMessage message,
    T Function(R) fromJson,
  ) async {
    var lspResponse = await sendRequestToServer(message);
    var error = lspResponse.error;
    if (error != null) {
      throw error;
    } else {
      return lspResponse.result == null
          ? null as T
          : fromJson(lspResponse.result as R);
    }
  }

  @override
  String? getCurrentFileContent(Uri uri) {
    try {
      return server.resourceProvider.getFile(fromUri(uri)).readAsStringSync();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Response> handleRequest(Request request) {
    lastSentLegacyRequestId = request.id;
    return super.handleRequest(request);
  }

  /// Gets the number of recorded responses for [method].
  int numberOfRecordedResponses(String method) {
    return server.analyticsManager
        .getRequestData(method)
        .responseTimes
        .valueCount;
  }

  @override
  void processNotification(Notification notification) {
    super.processNotification(notification);
    if (notification.event == LSP_NOTIFICATION_NOTIFICATION) {
      var params = LspNotificationParams.fromNotification(
        notification,
        clientUriConverter: server.uriConverter,
      );
      // Round-trip response via JSON because this doesn't happen automatically
      // when we're bypassing the streams (running in-process) and we want to
      // validate everything.
      var lspNotificationJson =
          jsonDecode(jsonEncode(params.lspNotification))
              as Map<String, Object?>;
      var lspNotificationMessage = NotificationMessage.fromJson(
        lspNotificationJson,
      );
      _notificationsFromServer.add(lspNotificationMessage);
    }
  }

  Future<void> removeOverlay(String filePath) {
    return handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        convertPath(filePath): RemoveContentOverlay(),
      }).toRequest(
        '${nextRequestId++}',
        clientUriConverter: server.uriConverter,
      ),
    );
  }

  /// Send the configured LSP client capabilities to the server in a
  /// `server.setClientCapabilities` request.
  Future<void> sendClientCapabilities() async {
    var clientCapabilities = ClientCapabilities(
      workspace: workspaceCapabilities,
      textDocument: textDocumentCapabilities,
      window: windowCapabilities,
      experimental: experimentalCapabilities,
    );
    var request = ServerSetClientCapabilitiesParams(
      [],
      lspCapabilities: clientCapabilities,
    ).toRequest('${nextRequestId++}', clientUriConverter: server.uriConverter);

    await handleSuccessfulRequest(request);
  }

  Future<ResponseMessage> sendLspRequest(Method method, Object params) {
    return server.sendLspRequest(method, params);
  }

  @override
  Future<ResponseMessage> sendRequestToServer(RequestMessage message) async {
    var messageJson = message.toJson();

    var legacyRequest = createLegacyRequest(LspHandleParams(messageJson));
    var legacyResponse = await handleSuccessfulRequest(legacyRequest);
    var legacyResult = LspHandleResult.fromResponse(
      legacyResponse,
      clientUriConverter: server.uriConverter,
    );

    var lspResponseJson = legacyResult.lspResponse as Map<String, Object?>;

    // Unwrap the LSP response.
    return ResponseMessage.fromJson(lspResponseJson);
  }

  @override
  void sendResponseToServer(ResponseMessage response) {
    serverChannel.simulateResponseFromClient(
      Response(
        // Convert the LSP int-or-string ID to always a string for legacy.
        response.id!.map((i) => i.toString(), (s) => s),
        // A client-provided response to an LSP reverse-request is always
        // a full LSP result payload as the "result". The legacy request should
        // always succeed and any errors handled as LSP error responses within.
        result: LspHandleResult(
          response,
        ).toJson(clientUriConverter: uriConverter),
      ),
    );
  }

  @override
  Future<void> setUp() async {
    super.setUp();
    await setRoots(included: [testPackageRootPath], excluded: []);
  }

  Future<void> updateOverlay(String filePath, SourceEdit edit) {
    return handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        convertPath(filePath): ChangeContentOverlay([edit]),
      }).toRequest(
        '${nextRequestId++}',
        clientUriConverter: server.uriConverter,
      ),
    );
  }
}

/// A [LspOverLegacyTest] that provides an implementation of
/// [SharedTestInterface] to allow tests to be shared between server/test kinds.
abstract class SharedLspOverLegacyTest extends LspOverLegacyTest
    implements SharedTestInterface {
  // TODO(dantup): Support this for LSP-over-Legacy shared tests.
  var failTestOnErrorDiagnostic = false;

  /// The current set of priority files. This is the same as the set of
  /// currently-open files (see [openFile]/[closeFile]).
  final Set<String> _priorityFiles = {};

  @override
  Future<void> get currentAnalysis => waitForTasksFinished();

  @override
  Future<void> closeFile(Uri uri) async {
    // closeFile should both remove the overlay and remove from priority files,
    // since that's equivalent of what the LSP document handlers do and shared
    // tests need to have the same behaviour.
    var filePath = fromUri(uri);
    await removeOverlay(filePath);
    _priorityFiles.remove(filePath);
    _updatePriorityFiles();
  }

  @override
  void createFile(String path, String content) {
    newFile(path, content);
  }

  @override
  Future<void> initializeServer() async {
    await waitForTasksFinished();
  }

  @override
  Future<void> openFile(Uri uri, String content, {int version = 1}) async {
    // closeFile should both add an overlay and add to priority files,
    // since that's equivalent of what the LSP document handlers do and shared
    // tests need to have the same behaviour.
    var filePath = fromUri(uri);
    await addOverlay(filePath, content, version);
    _priorityFiles.add(filePath);
    _updatePriorityFiles();
  }

  /// Opens a file content without providing a version number.
  ///
  /// This method should be used only for specifically testing unversioned
  /// changes and [openFile] used by default since going forwards, we expect
  /// all clients to start providing version numbers.
  Future<void> openFileUnversioned(Uri uri, String content) async {
    await addOverlay(fromUri(uri), content);
  }

  @override
  Future<void> replaceFile(int newVersion, Uri uri, String content) async {
    // For legacy, we can use addOverlay to replace the whole file.
    await addOverlay(fromUri(uri), content, newVersion);
  }

  /// Replaces a file content without providing a version number.
  ///
  /// This method should be used only for specifically testing unversioned
  /// changes and [replaceFile] used by default since going forwards, we expect
  /// all clients to start providing version numbers.
  Future<void> replaceFileUnversioned(Uri uri, String content) async {
    // For legacy, we can use addOverlay to replace the whole file.
    await addOverlay(fromUri(uri), content);
  }

  void _updatePriorityFiles() {
    setPriorityFiles(_priorityFiles.map(getFile).toList());
  }
}
