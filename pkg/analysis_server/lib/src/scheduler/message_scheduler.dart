// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/lsp_protocol/protocol.dart' as lsp;
import 'package:analysis_server/protocol/protocol.dart' as legacy;
import 'package:analysis_server/protocol/protocol_constants.dart' as legacy;
import 'package:analysis_server/protocol/protocol_generated.dart' as legacy;
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/scheduler/scheduled_message.dart';
import 'package:analysis_server/src/server/error_notifier.dart';
import 'package:analyzer/src/utilities/cancellation.dart';
import 'package:language_server_protocol/json_parsing.dart';

/// The [MessageScheduler] receives messages from all clients of the
/// [AnalysisServer]. Clients can include IDE's (LSP and Legacy protocol), DTD,
/// and the Diagnostic server. The [MessageScheduler] acts as a hub for all
/// incoming messages and forwards the messages to the appropriate handlers.
final class MessageScheduler {
  /// A flag to allow disabling overlapping message handlers.
  static bool allowOverlappingHandlers = true;

  /// The [AnalysisServer] associated with the scheduler.
  late final AnalysisServer server;

  /// The messages that have been received and are waiting to be handled.
  final ListQueue<ScheduledMessage> _pendingMessages =
      ListQueue<ScheduledMessage>();

  /// Whether the [MessageScheduler] is idle or is processing messages.
  bool isActive = false;

  /// The completer used to indicate that message handling has been completed.
  Completer<void> completer = Completer();

  /// A view into the [MessageScheduler] used for testing.
  MessageSchedulerTestView? testView;

  /// The message that is currently being processed, and null when there is
  /// no message being processed.
  ScheduledMessage? _currentMessage;

  MessageScheduler({this.testView}) {
    testView?.messageScheduler = this;
  }

  /// Add a message to the end of the incoming messages queue.
  ///
  /// Some of the incoming messages are used to cancel other messages before
  /// they are added to the queue.
  ///
  /// LSP Messages
  /// - Cancellation notifications are handled by the [MessageScheduler].
  /// The current message and queued messages are looked through and the
  /// [CancelableToken] for the request to be canceled is set.
  /// - Document change notifications are used to cancel refactors, renames
  /// (if any) that are currently in progress or on the queue for the document
  /// that was changed.
  /// - Incoming completion and refactor requests cancel out current and
  /// queued requests of the same.
  ///
  /// Legacy Messages
  /// - Cancellation requests are sent immediately to the [LegacyAnalysisServer]
  /// for processing.
  ///
  /// LSP over Legacy
  /// - The incoming [legacy.ANALYSIS_REQUEST_UPDATE_CONTENT] message cancels
  /// any rename files request that is in progress.
  void add(ScheduledMessage message) {
    testView?.logAddMessage(message);
    if (message is LegacyMessage) {
      var request = message.request;
      if (request.method == legacy.SERVER_REQUEST_CANCEL_REQUEST) {
        var id =
            legacy.ServerCancelRequestParams.fromRequest(
              request,
              clientUriConverter: server.uriConverter,
            ).id;
        (server as LegacyAnalysisServer).cancelRequest(id);
      }
      if (request.method == legacy.ANALYSIS_REQUEST_UPDATE_CONTENT) {
        if (_currentMessage is LegacyMessage) {
          var current = _currentMessage as LegacyMessage;
          var request = current.request;
          if (request.method == legacy.LSP_REQUEST_HANDLE) {
            var method = _getLspOverLegacyParams(request)?['method'];
            if (method == lsp.Method.workspace_willRenameFiles.toString()) {
              current.cancellationToken?.cancel(
                code: lsp.ErrorCodes.ContentModified.toJson(),
                reason: 'File content was modified',
              );
              testView?.messageLog.add(
                'Canceled current request ${request.method}',
              );
            }
          }
        }
      }
    }
    if (message is LspMessage) {
      var msg = message.message;
      // Responses do not go on the queue because there might be an active
      // message that can't complete until the response is received. If the
      // response was added to the queue then this process could deadlock.
      if (msg is lsp.ResponseMessage) {
        (server as LspAnalysisServer).handleMessage(msg, null);
        return;
      }
      // If a cancellation is requested, check to see if the
      // the current request is cancelled. If not, also check
      // to see if a cancelled request is on the queue.
      if (msg is lsp.NotificationMessage) {
        if (msg.method == lsp.Method.cancelRequest) {
          lsp.CancelParams? params;
          try {
            params = _getCancelParams(msg);
          } catch (error, stackTrace) {
            (server as LspAnalysisServer).logException(
              'An error occured while parsing cancel parameters',
              error,
              stackTrace,
            );
          }
          if (params == null) {
            return;
          }
          if (_currentMessage is LspMessage &&
              (_currentMessage! as LspMessage).isRequest) {
            var current = _currentMessage as LspMessage;
            var request = current.message as lsp.RequestMessage;
            if (request.id == params.id) {
              current.cancellationToken?.cancel();
              testView?.messageLog.add(
                'Canceled current request ${request.method}',
              );
              return;
            }
          }
          var lspRequests = _pendingMessages.whereType<LspMessage>().where(
            (m) => m.isRequest,
          );
          if (lspRequests.isNotEmpty) {
            for (var request in lspRequests) {
              var req = request.message as lsp.RequestMessage;
              if (req.id == params.id) {
                request.cancellationToken?.cancel();
                testView?.messageLog.add(
                  'Canceled request on queue ${req.method}',
                );
                return;
              }
            }
          }
        } else if (msg.method == lsp.Method.textDocument_didChange) {
          _processDocumentChange(msg);
        }
      }
      if (msg is lsp.RequestMessage) {
        // Cancel in progress completion and refactoring requests.
        var incomingMsgMethod = msg.method;
        if (_isCancelableRequest(msg)) {
          var reason =
              incomingMsgMethod == lsp.Method.workspace_executeCommand
                  ? 'Another workspace/executeCommand request for a refactor was started'
                  : 'Another textDocument/completion request was started';
          var current = _currentMessage;
          if (current is LspMessage && current.isRequest) {
            var message = current.message as lsp.RequestMessage;
            if (message.method == incomingMsgMethod) {
              current.cancellationToken?.cancel(reason: reason);
              testView?.messageLog.add(
                'Canceled in progress request ${message.method}',
              );
            }
          }
          // Cancel any other similar requests that are in the queue.
          var lspRequests = _pendingMessages.whereType<LspMessage>().where(
            (m) => m.isRequest,
          );
          for (var queueMsg in lspRequests) {
            if ((queueMsg.message as lsp.RequestMessage).method == msg.method) {
              queueMsg.cancellationToken?.cancel(reason: reason);
              testView?.messageLog.add(
                'Canceled request on queue ${msg.method}',
              );
            }
          }
        }
      }
    }
    _pendingMessages.addLast(message);
    if (_currentMessage == null) {
      testView?.messageLog.add('Entering process messages loop');
      _currentMessage = _pendingMessages.removeFirst();
      processMessages();
    }
  }

  /// Dispatch the first message in the queue to be executed.
  void processMessages() async {
    try {
      while (_currentMessage != null) {
        completer = Completer<void>();
        var message = _currentMessage!;
        testView?.logHandleMessage(message);
        switch (message) {
          case LspMessage():
            var lspMessage = message.message;
            (server as LspAnalysisServer).handleMessage(
              lspMessage,
              cancellationToken: message.cancellationToken,
              completer,
            );
          case LegacyMessage():
            var request = message.request;
            (server as LegacyAnalysisServer).handleRequest(
              request,
              completer,
              message.cancellationToken,
            );
          case DtdMessage():
            server.dtd!.processMessage(
              message.message,
              message.performance,
              message.responseCompleter,
              completer,
            );
        }

        // Blocking here with an await on the future was intended to prevent
        // unwanted interleaving but was found to cause a significant
        // performance regression. For more context see:
        // https://github.com/dart-lang/sdk/issues/60440. To re-disable
        // interleaving, set [allowOverlappingHandlers] to `false`.
        if (!allowOverlappingHandlers) {
          await completer.future;
        }

        // This message is not accurate if [allowOverlappingHandlers] is `true`
        // because in that case we're not blocking anymore and the future might
        // not be complete.
        // TODO(pq): if not awaited, consider adding a `then` so we can track
        // when the future completes. But note that we may see some flakiness in
        // tests as message handling gets non-deterministically interleaved.
        testView?.messageLog.add(
          '  Complete ${message.runtimeType}: ${message.toString()}',
        );
        if (_pendingMessages.isEmpty) {
          _currentMessage = null;
          testView?.messageLog.add('Exit process messages loop');
        } else {
          _currentMessage = _pendingMessages.removeFirst();
        }
      }
    } catch (error, stackTrace) {
      server.instrumentationService.logException(
        FatalException('Failed to process message', error, stackTrace),
        null,
        server.crashReportingAttachmentsBuilder.forException(error),
      );
    }
  }

  /// Set the [AnalysisServer].
  void setServer(AnalysisServer analysisServer) {
    server = analysisServer;
  }

  lsp.CancelParams? _getCancelParams(lsp.IncomingMessage message) {
    var cancelJsonHandler = lsp.CancelParams.jsonHandler;
    var reporter = LspJsonReporter('params');
    var paramsJson = message.params as Map<String, Object?>?;
    if (!cancelJsonHandler.validateParams(paramsJson, reporter)) {
      return null;
    }
    return paramsJson != null
        ? cancelJsonHandler.convertParams(paramsJson)
        : null;
  }

  lsp.DidChangeTextDocumentParams? _getChangeTextParams(
    lsp.NotificationMessage message,
  ) {
    var changeTextJsonHandler = lsp.DidChangeTextDocumentParams.jsonHandler;

    var msg = message as lsp.IncomingMessage;
    var reporter = LspJsonReporter('params');
    var paramsJson = msg.params as Map<String, Object?>?;
    if (!changeTextJsonHandler.validateParams(paramsJson, reporter)) {
      return null;
    }
    return paramsJson != null
        ? changeTextJsonHandler.convertParams(paramsJson)
        : null;
  }

  lsp.ExecuteCommandParams? _getCommandParams(lsp.RequestMessage message) {
    var commandJsonHandler = lsp.ExecuteCommandParams.jsonHandler;
    var reporter = LspJsonReporter('params');
    var paramsJson = message.params as Map<String, Object?>?;
    if (!commandJsonHandler.validateParams(paramsJson, reporter)) {
      return null;
    }
    return paramsJson != null
        ? commandJsonHandler.convertParams(paramsJson)
        : null;
  }

  Map<String, Object?>? _getLspOverLegacyParams(legacy.Request request) {
    var params = legacy.LspHandleParams.fromRequest(
      request,
      clientUriConverter: server.uriConverter,
    );
    return params.lspMessage as Map<String, Object?>;
  }

  lsp.RenameParams? _getRenameParams(lsp.RequestMessage message) {
    var jsonHandler = lsp.RenameParams.jsonHandler;
    var reporter = LspJsonReporter('params');
    var paramsJson = message.params as Map<String, Object?>?;
    if (!jsonHandler.validateParams(paramsJson, reporter)) {
      return null;
    }
    return paramsJson != null ? jsonHandler.convertParams(paramsJson) : null;
  }

  bool _isCancelableRequest(lsp.RequestMessage message) {
    if (message.method == lsp.Method.textDocument_completion) {
      return true;
    }
    if (message.method == lsp.Method.workspace_executeCommand) {
      lsp.ExecuteCommandParams? params;
      params = _getCommandParams(message);
      if (params?.command == Commands.performRefactor) {
        return true;
      }
    }
    return false;
  }

  /// Cancel current refactor, if any, for the document changed.
  /// Also check for any refactors in the queue.
  void _processDocumentChange(lsp.NotificationMessage msg) {
    lsp.DidChangeTextDocumentParams? params;
    params = _getChangeTextParams(msg);
    if (params == null) {
      return;
    }
    var documentChangeUri = params.textDocument.uri;

    Uri? getRefactorUri(List<lsp.LSPAny?> args) {
      // TODO(keertip): extract method in AbstractRefactorCommandHandler
      // and use that instead.
      String? path;
      if (args.length == 6) {
        path = args[1] as String?;
      } else if (args.length == 1 && args[0] is Map<String, Object?>) {
        path = (args.single as Map<String, Object?>)['path'] as String?;
      }

      return path != null ? Uri.file(path) : null;
    }

    void checkAndCancelRefactor(LspMessage lspMessage) {
      var request = lspMessage.message as lsp.RequestMessage;
      var execParams = _getCommandParams(request);
      if (execParams != null &&
          execParams.command == Commands.performRefactor) {
        var args = execParams.arguments ?? [];
        var refactorUri = getRefactorUri(args);
        if (refactorUri == documentChangeUri) {
          lspMessage.cancellationToken?.cancel(
            code: lsp.ErrorCodes.ContentModified.toJson(),
          );
          testView?.messageLog.add(
            'Canceled in progress request ${request.method}',
          );
        }
      }
    }

    void checkAndCancelRename(LspMessage lspMessage) {
      var request = lspMessage.message as lsp.RequestMessage;
      var renameParams = _getRenameParams(request);
      if (renameParams != null) {
        var renameUri = renameParams.textDocument.uri;
        if (renameUri == documentChangeUri) {
          lspMessage.cancellationToken?.cancel(
            code: lsp.ErrorCodes.ContentModified.toJson(),
          );
          testView?.messageLog.add(
            'Canceled in progress request ${request.method}',
          );
        }
      }
    }

    var current = _currentMessage;
    if (current is LspMessage && current.isRequest) {
      var request = current.message as lsp.RequestMessage;
      if (request.method == lsp.Method.workspace_executeCommand) {
        checkAndCancelRefactor(current);
      } else if (request.method == lsp.Method.textDocument_rename) {
        checkAndCancelRename(current);
      }
    }
    // Cancel any other refactor requests that are in the queue.
    var lspRequests = _pendingMessages.whereType<LspMessage>().where(
      (m) =>
          m.isRequest &&
          (m.message as lsp.RequestMessage).method ==
              lsp.Method.workspace_executeCommand,
    );
    for (var queueMsg in lspRequests) {
      checkAndCancelRefactor(queueMsg);
    }
    var renameRequests = _pendingMessages.whereType<LspMessage>().where(
      (m) =>
          m.isRequest &&
          (m.message as lsp.RequestMessage).method ==
              lsp.Method.textDocument_rename,
    );
    for (var queueMsg in renameRequests) {
      checkAndCancelRename(queueMsg);
    }
  }
}

class MessageSchedulerTestView {
  late final MessageScheduler messageScheduler;

  List<String> messageLog = <String>[];

  void logAddMessage(ScheduledMessage message) {
    messageLog.add(
      'Incoming ${message is LspMessage ? message.message.runtimeType : message.runtimeType}: ${message.toString()}',
    );
  }

  void logHandleMessage(ScheduledMessage message) {
    messageLog.add('  Start ${message.runtimeType}: ${message.toString()}');
  }
}
