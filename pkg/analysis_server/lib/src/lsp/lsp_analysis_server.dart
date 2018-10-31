// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/channel/lsp_channel.dart';
import 'package:analysis_server/src/lsp/handler_initialization.dart';
import 'package:analyzer/file_system/file_system.dart';

/**
 * Instances of the class [LspAnalysisServer] implement an LSP-based server that
 * listens on a [CommunicationChannel] for analysis requests and process them.
 */
class LspAnalysisServer {
  /**
   * The channel from which requests are received and to which responses should
   * be sent.
   */
  final LspServerCommunicationChannel channel;

  /**
   * The [ResourceProvider] using which paths are converted into [Resource]s.
   */
  final ResourceProvider resourceProvider;

  /**
   * A list of the request handlers used to handle the requests sent to this
   * server.
   */
  Map<String, MessageHandler> handlers = {};

  /**
   * Initialize a newly created server to receive requests from and send
   * responses to the given [channel].
   *
   * If [rethrowExceptions] is true, then any exceptions thrown by analysis are
   * propagated up the call stack.  The default is true to allow analysis
   * exceptions to show up in unit tests, but it should be set to false when
   * running a full analysis server.
   */
  LspAnalysisServer(
    this.channel,
    this.resourceProvider,
  ) {
    _registerHandler(new InitializationHandler(this));
    channel.listen(handleMessage, onDone: done, onError: error);
  }

  _registerHandler(MessageHandler handler) {
    for (final message in handler.handlesMessages) {
      handlers[message] = handler;
    }
  }

  /**
   * The socket from which requests are being read has been closed.
   */
  void done() {
    // TODO(dantup): Do we need to do anything here?
  }

  /**
   * There was an error related to the socket from which requests are being
   * read.
   */
  void error(error, stack) {
    print(error);
    print(stack);
  }

  /**
   * Handle a [request] that was read from the communication channel.
   */
  void handleMessage(IncomingMessage message) {
    // TODO(dantup): Put in all the things this server is missing, like:
    //     _performance.logRequest(request);
    runZoned(() {
      ServerPerformanceStatistics.serverRequests.makeCurrentWhile(() {
        final handler = handlers[message.method];
        if (handler == null) {
          sendErrorResponse(
              message,
              new ResponseError(ErrorCodes.MethodNotFound,
                  'Unknown method ${message.method}', null));
          return;
        }
        try {
          final result = handler.handleMessage(message);
          if (message is RequestMessage && result != null) {
            channel.sendResponse(
                new ResponseMessage(message.id, result, null, "2.0"));
          }
        } on ResponseError catch (error) {
          sendErrorResponse(message, error);
        } catch (error, stackTrace) {
          sendErrorResponse(
              message,
              new ResponseError(ServerErrorCodes.UnhandledError, error,
                  stackTrace?.toString()));
        }
      });
    }, onError: (error, stackTrace) {
      print(error);
      sendErrorResponse(
          message,
          new ResponseError(
              ServerErrorCodes.UnhandledError, error, stackTrace?.toString()));
      return;
    });
  }

  void sendErrorResponse(IncomingMessage message, ResponseError error) {
    if (message is RequestMessage) {
      channel.sendResponse(new ResponseMessage(message.id, null, error, "2.0"));
    } else {
      channel.sendNotification(new NotificationMessage(
          'showMessage',
          Either2<List<dynamic>, dynamic>.t2(
              new ShowMessageParams(MessageType.Error, error.message)),
          "2.0"));
    }
  }

  /**
   * Send the given [response] to the client.
   */
  void sendResponse(ResponseMessage response) {
    channel.sendResponse(response);
  }

  Future<void> shutdown() {
    // Defer closing the channel so that the shutdown response can be sent and
    // logged.
    new Future(() {
      channel.close();
    });

    return new Future.value();
  }

  void sendServerErrorNotification(String message, exception, stackTrace,
      {bool fatal = false}) {
    // TODO(dantup): Fix this; we can't just write to stdout.
    print(message);
    print(exception);
    print(stackTrace);
  }
}

/**
 * An object that can handle messages and produce responses for requests.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class MessageHandler {
  /**
   * The messages that this handler can handle.
   */
  List<String> get handlesMessages;

  /**
   * Attempt to handle the given [message]. If the message is not recognized by
   * this handler, return `null` so that other handlers will be given a chance
   * to handle it. Otherwise, return the response that should be passed back to
   * the client.
   */
  Object handleMessage(IncomingMessage message);

  T convertParams<T>(
      IncomingMessage message, T Function(Map<String, dynamic>) constructor) {
    return message.params.map(
      (_) => throw 'Expected dynamic, got List<dynamic>',
      (params) => constructor(params),
    );
  }

  List<T> convertParamsList<T>(
      IncomingMessage message, T Function(Map<String, dynamic>) constructor) {
    return message.params.map(
      (params) => params.map((p) => constructor(p)).toList(),
      (_) => throw 'Expected List<dynamic>, got dynamic',
    );
  }
}
