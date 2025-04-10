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
import 'package:meta/meta.dart';

/// The [MessageScheduler] schedules messages received from the clients of the
/// [AnalysisServer].
///
/// Clients include IDE's (LSP and Legacy protocol), DTD, the Diagnostic server
/// and file watchers. The [MessageScheduler] acts as a hub for all incoming
/// messages and forwards the messages to the appropriate handlers.
final class MessageScheduler {
  /// A flag to allow disabling overlapping message handlers.
  static bool allowOverlappingHandlers = true;

  /// A view into the [MessageScheduler] used for testing.
  @visibleForTesting
  MessageSchedulerListener? testView;

  /// The [AnalysisServer] associated with the scheduler.
  // TODO(brianwilkerson): Make this field private.
  late final AnalysisServer server;

  /// The messages that have been received and are waiting to be handled.
  final ListQueue<ScheduledMessage> _pendingMessages =
      ListQueue<ScheduledMessage>();

  /// The messages that are currently being handled.
  final ListQueue<ScheduledMessage> _activeMessages =
      ListQueue<ScheduledMessage>();

  /// Whether the [MessageScheduler] is currently processing messages.
  bool _isProcessing = false;

  /// The completer used to indicate that message handling has been completed.
  // TODO(brianwilkerson): Make this field private.
  Completer<void> completer = Completer();

  /// Initialize a newly created message scheduler.
  ///
  /// The caller is expected to set the [server] immediately after creating the
  /// instance. The only reason the server isn't initialized by the constructor
  /// is because the analysis server and the message scheduler can't be created
  /// atomically and it was decided that it was cleaner for the scheduler to
  /// have the nullable reference to the server rather than the other way
  /// around.
  MessageScheduler({this.testView});

  /// Add the [message] to the end of the pending messages queue.
  ///
  /// Some incoming messages are handled immediately rather than being added to
  /// the queue. Specifically, those listed below.
  ///
  /// LSP Messages
  /// - Cancellation notifications are handled by the [MessageScheduler].
  ///   The current message and queued messages are looked through and the
  ///   [CancelableToken] for the request to be canceled is set.
  /// - Document change notifications are used to cancel refactors, renames
  ///   (if any) that are currently in progress or on the queue for the document
  ///   that was changed.
  /// - Incoming completion and refactor requests cancel out current and
  ///   queued requests of the same.
  ///
  /// Legacy Messages
  /// - Cancellation requests are sent immediately to the [LegacyAnalysisServer]
  ///   for processing.
  ///
  /// LSP over Legacy
  /// - The incoming [legacy.ANALYSIS_REQUEST_UPDATE_CONTENT] message cancels
  ///   any rename files request that is in progress.
  void add(ScheduledMessage message) {
    testView?.addPendingMessage(message);
    if (message is LegacyMessage) {
      var request = message.request;
      var method = request.method;
      if (method == legacy.SERVER_REQUEST_CANCEL_REQUEST) {
        var id =
            legacy.ServerCancelRequestParams.fromRequest(
              request,
              clientUriConverter: server.uriConverter,
            ).id;
        (server as LegacyAnalysisServer).cancelRequest(id);
      } else if (method == legacy.ANALYSIS_REQUEST_UPDATE_CONTENT) {
        for (var activeMessage in _activeMessages) {
          if (activeMessage is LegacyMessage) {
            var activeRequest = activeMessage.request;
            if (activeRequest.method == legacy.LSP_REQUEST_HANDLE) {
              var method = _getLspOverLegacyParams(activeRequest)?['method'];
              if (method == lsp.Method.workspace_willRenameFiles.toString()) {
                activeMessage.cancellationToken?.cancel(
                  code: lsp.ErrorCodes.ContentModified.toJson(),
                  reason: 'File content was modified',
                );
                testView?.cancelActiveMessage(activeMessage);
              }
            }
          }
          // TODO(brianwilkerson): Determine why it isn't appropriate to also
          //  cancel pending messages of the same kind.
        }
      }
    } else if (message is LspMessage) {
      var msg = message.message;
      if (msg is lsp.ResponseMessage) {
        // Responses don't go on the queue because there might be an active
        // message that can't complete until the response is received. If the
        // response was added to the queue then this process could deadlock.
        (server as LspAnalysisServer).handleMessage(msg, null);
        return;
      } else if (msg is lsp.NotificationMessage) {
        var method = msg.method;
        if (method == lsp.Method.cancelRequest) {
          // Cancellations are handled immediately in order to minimize the
          // amount of extra work that has to happen. Note that the request is
          // canceled by setting the token to the 'cancelled' state rather than
          // by removing the request from the queue. It's done this way to allow
          // a response to be sent back to the client saying that the results
          // aren't provided because the request was cancelled.
          _processCancellation(msg);
          return;
        } else if (method == lsp.Method.textDocument_didChange) {
          // Document change notifications are _not_ handled immediately, but
          // some active or pending requests can be cancelled before the normal
          // processing is done.
          _processDocumentChange(msg);
        }
      } else if (msg is lsp.RequestMessage) {
        // Cancel in progress completion and refactoring requests.
        var incomingMsgMethod = msg.method;
        if (_isCancelableRequest(msg)) {
          var reason =
              incomingMsgMethod == lsp.Method.workspace_executeCommand
                  ? 'Another workspace/executeCommand request for a refactor was started'
                  : 'Another textDocument/completion request was started';
          for (var activeMessage in _activeMessages) {
            if (activeMessage is LspMessage && activeMessage.isRequest) {
              var message = activeMessage.message as lsp.RequestMessage;
              if (message.method == incomingMsgMethod) {
                activeMessage.cancellationToken?.cancel(reason: reason);
                testView?.cancelActiveMessage(activeMessage);
              }
            }
          }
          for (var pendingMessage in _pendingMessages) {
            if (pendingMessage is LspMessage && pendingMessage.isRequest) {
              var message = pendingMessage.message as lsp.RequestMessage;
              if (message.method == msg.method) {
                pendingMessage.cancellationToken?.cancel(reason: reason);
                testView?.cancelPendingMessage(pendingMessage);
              }
            }
          }
        }
      }
    }
    _pendingMessages.addLast(message);
    if (!_isProcessing) {
      processMessages();
    }
  }

  /// Dispatch the first message in the queue to be executed.
  void processMessages() async {
    _isProcessing = true;
    testView?.startProcessingMessages();
    try {
      while (_pendingMessages.isNotEmpty) {
        var currentMessage = _pendingMessages.removeFirst();
        _activeMessages.addLast(currentMessage);
        testView?.addActiveMessage(currentMessage);
        completer = Completer<void>();
        unawaited(
          completer.future.then((_) {
            _activeMessages.remove(currentMessage);
          }),
        );
        switch (currentMessage) {
          case LspMessage():
            var lspMessage = currentMessage.message;
            (server as LspAnalysisServer).handleMessage(
              lspMessage,
              cancellationToken: currentMessage.cancellationToken,
              completer,
            );
          case LegacyMessage():
            var request = currentMessage.request;
            (server as LegacyAnalysisServer).handleRequest(
              request,
              completer,
              currentMessage.cancellationToken,
            );
          case DtdMessage():
            server.dtd!.processMessage(
              currentMessage.message,
              currentMessage.performance,
              currentMessage.responseCompleter,
              completer,
            );
          case WatcherMessage():
            server.contextManager.handleWatchEvent(currentMessage.event);
            // Handling a watch event is a synchronous process, so there's
            // nothing to wait for.
            completer.complete();
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
        testView?.messageCompleted(currentMessage);
      }
    } catch (error, stackTrace) {
      server.instrumentationService.logException(
        FatalException('Failed to process message', error, stackTrace),
        null,
        server.crashReportingAttachmentsBuilder.forException(error),
      );
    }
    _isProcessing = false;
    testView?.endProcessingMessages();
  }

  /// Set the [AnalysisServer].
  void setServer(AnalysisServer analysisServer) {
    server = analysisServer;
  }

  /// Returns the parameters of a cancellation [message].
  lsp.CancelParams? _getCancelParams(lsp.NotificationMessage message) {
    try {
      var cancelJsonHandler = lsp.CancelParams.jsonHandler;
      var reporter = LspJsonReporter('params');
      var paramsJson = message.params as Map<String, Object?>?;
      if (!cancelJsonHandler.validateParams(paramsJson, reporter)) {
        return null;
      }
      return paramsJson != null
          ? cancelJsonHandler.convertParams(paramsJson)
          : null;
    } catch (error, stackTrace) {
      (server as LspAnalysisServer).logException(
        'An error occured while parsing cancel parameters',
        error,
        stackTrace,
      );
    }
    return null;
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

  /// Process a cancellation notification.
  ///
  /// The notification doesn't need to be placed on the pending messages queue
  /// after it has been processed.
  void _processCancellation(lsp.NotificationMessage msg) {
    var params = _getCancelParams(msg);
    if (params == null) {
      return;
    }
    for (var activeMessage in _activeMessages) {
      if (activeMessage is LspMessage && activeMessage.isRequest) {
        var request = activeMessage.message as lsp.RequestMessage;
        if (request.id == params.id) {
          activeMessage.cancellationToken?.cancel();
          testView?.cancelActiveMessage(activeMessage);
          return;
        }
      }
    }
    for (var pendingMessage in _pendingMessages) {
      if (pendingMessage is LspMessage && pendingMessage.isRequest) {
        var request = pendingMessage.message as lsp.RequestMessage;
        if (request.id == params.id) {
          pendingMessage.cancellationToken?.cancel();
          testView?.cancelPendingMessage(pendingMessage);
          return;
        }
      }
    }
  }

  /// Cancel the current refactor, if any, for the document changed.
  /// Also check for any refactors in the queue.
  ///
  /// The notification needs to be placed on the pending messages queue so that
  /// the state of the document will be updated.
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

    void checkAndCancelRefactor(
      LspMessage lspMessage, {
      required bool isActive,
    }) {
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
          if (isActive) {
            testView?.cancelActiveMessage(lspMessage);
          } else {
            testView?.cancelPendingMessage(lspMessage);
          }
        }
      }
    }

    void checkAndCancelRename(LspMessage lspMessage, {required bool isActive}) {
      var request = lspMessage.message as lsp.RequestMessage;
      var renameParams = _getRenameParams(request);
      if (renameParams != null) {
        var renameUri = renameParams.textDocument.uri;
        if (renameUri == documentChangeUri) {
          lspMessage.cancellationToken?.cancel(
            code: lsp.ErrorCodes.ContentModified.toJson(),
          );
          if (isActive) {
            testView?.cancelActiveMessage(lspMessage);
          } else {
            testView?.cancelPendingMessage(lspMessage);
          }
        }
      }
    }

    for (var activeMessage in _activeMessages) {
      if (activeMessage is LspMessage && activeMessage.isRequest) {
        var request = activeMessage.message as lsp.RequestMessage;
        if (request.method == lsp.Method.workspace_executeCommand) {
          checkAndCancelRefactor(activeMessage, isActive: true);
        } else if (request.method == lsp.Method.textDocument_rename) {
          checkAndCancelRename(activeMessage, isActive: true);
        }
      }
    }
    for (var pendingMessage in _pendingMessages) {
      if (pendingMessage is LspMessage && pendingMessage.isRequest) {
        var request = pendingMessage.message as lsp.RequestMessage;
        if (request.method == lsp.Method.workspace_executeCommand) {
          checkAndCancelRefactor(pendingMessage, isActive: false);
        } else if (request.method == lsp.Method.textDocument_rename) {
          checkAndCancelRename(pendingMessage, isActive: false);
        }
      }
    }
  }
}

abstract class MessageSchedulerListener {
  /// Report that the [message] was added to the active message queue.
  void addActiveMessage(ScheduledMessage message);

  /// Report that the [message] was added to the pending message queue.
  void addPendingMessage(ScheduledMessage message);

  /// Report that an active [message] was cancelled.
  void cancelActiveMessage(ScheduledMessage message);

  /// Report that a pending [message] was cancelled.
  void cancelPendingMessage(ScheduledMessage message);

  /// Report that the loop that processes messages has stopped running.
  void endProcessingMessages();

  /// Report that the [message] has been completed.
  void messageCompleted(ScheduledMessage message);

  /// Report that the loop that processes messages has started to run.
  void startProcessingMessages();
}
