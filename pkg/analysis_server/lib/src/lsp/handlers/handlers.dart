// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handler_cancel_request.dart';
import 'package:analysis_server/src/lsp/handlers/handler_reject.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/request_handler_mixin.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/cancellation.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart';
import 'package:analyzer_plugin/src/utilities/client_uri_converter.dart';
import 'package:language_server_protocol/json_parsing.dart';
import 'package:path/path.dart' as path;

export 'package:analyzer/src/utilities/cancellation.dart';

/// Converts an iterable using the provided function and skipping over any
/// null values.
Iterable<T> convert<T, E>(Iterable<E> items, T? Function(E) converter) {
  // TODO(dantup): Now this is used outside of handlers, is there somewhere
  // better to put it, and/or a better name for it?
  return items.map(converter).where((item) => item != null).cast<T>();
}

abstract class CommandHandler<P, R> with Handler<R>, HandlerHelperMixin {
  @override
  final LspAnalysisServer server;

  CommandHandler(this.server);

  /// Whether this command records its own analytics and should be excluded from
  /// logging by the main command handler.
  ///
  /// This is useful if a command is generic (for example "performRefactor") and
  /// can record a more specific command name.
  bool get recordsOwnAnalytics => false;

  Future<ErrorOr<Object?>> handle(
    MessageInfo message,
    Map<String, Object?> parameters,
    ProgressReporter progress,
    CancellationToken cancellationToken,
  );
}

mixin Handler<T> {
  // TODO(dantup): Merge this into HandlerHelperMixin by converting to methods
  //  so T can be inferred.
  final fileModifiedError = error<T>(ErrorCodes.ContentModified,
      'Document was modified before operation completed');

  final serverNotInitializedError = error<T>(ErrorCodes.ServerNotInitialized,
      'Request not valid before server is initialized');
}

/// Provides some helpers for request handlers to produce common errors or
/// obtain resolved results after waiting for in-progress analysis.
mixin HandlerHelperMixin<S extends AnalysisServer> {
  path.Context get pathContext => server.resourceProvider.pathContext;

  S get server;

  ClientUriConverter get uriConverter => server.uriConverter;

  /// A [Future] that completes when both the client has finished initializing
  /// and any in-progress context rebuilds are complete.
  Future<void> get _initializedWithContexts =>
      Future.value(server.lspInitialized)
          .then((_) => server.analysisContextsRebuilt);

  ErrorOr<T> analysisFailedError<T>(String path) => error<T>(
      ServerErrorCodes.FileAnalysisFailed, 'Analysis failed for file', path);

  ErrorOr<T> fileNotAnalyzedError<T>(String path) => error<T>(
      ServerErrorCodes.FileNotAnalyzed, 'File is not being analyzed', path);

  /// Returns whether [doc] is a user-editable document or not.
  ///
  /// Only editable documents have overlays and can be modified by the client.
  bool isEditableDocument(Uri uri) {
    // Currently, only file:// URIs are editable documents.
    return uri.isScheme('file');
  }

  /// Returns the file system path (or internal analyzer file reference) for a
  /// TextDocumentIdentifier.
  ErrorOr<String> pathOfDoc(TextDocumentIdentifier doc) => pathOfUri(doc.uri);

  /// Returns the file system path (or internal analyzer file reference) for a
  /// TextDocumentItem.
  ErrorOr<String> pathOfDocItem(TextDocumentItem doc) => pathOfUri(doc.uri);

  /// Returns the file system path (or internal analyzer file reference) for a
  /// file URI.
  ErrorOr<String> pathOfUri(Uri? uri) {
    if (uri == null) {
      return ErrorOr<String>.error(ResponseError(
        code: ServerErrorCodes.InvalidFilePath,
        message: 'Document URI was not supplied',
      ));
    }

    // For URIs with no scheme, assume it was a relative path and provide a
    // better message than "scheme '' is not supported".
    if (uri.scheme.isEmpty) {
      return ErrorOr<String>.error(ResponseError(
        code: ServerErrorCodes.InvalidFilePath,
        message: 'URI is not a valid file:// URI',
        data: uri.toString(),
      ));
    }

    var supportedSchemes = server.uriConverter.supportedSchemes;
    var isValidScheme = supportedSchemes.contains(uri.scheme);
    if (!isValidScheme) {
      var supportedSchemesString = supportedSchemes.isEmpty
          ? '(none)'
          : supportedSchemes.map((scheme) => "'$scheme'").join(', ');
      return ErrorOr<String>.error(ResponseError(
        code: ServerErrorCodes.InvalidFilePath,
        message: "URI scheme '${uri.scheme}' is not supported. "
            'Allowed schemes are $supportedSchemesString.',
        data: uri.toString(),
      ));
    }
    try {
      var context = server.resourceProvider.pathContext;
      var isWindows = context.style == path.Style.windows;

      // Use toFilePath() here and not context.fromUri() because they're not
      // quite the same. `toFilePath()` will throw for some kinds of invalid
      // file URIs (such as those with fragments) that context.fromUri() does
      // not. We want to validate using the stricter handling.
      var filePath = uri
          .replace(scheme: 'file') // We can only use toFilePath() with file://
          .toFilePath(windows: isWindows);

      // On Windows, paths that start with \ and not a drive letter are not
      // supported but will return `true` from `path.isAbsolute` so check for them
      // specifically.
      if (isWindows && filePath.startsWith(r'\')) {
        return ErrorOr<String>.error(ResponseError(
          code: ServerErrorCodes.InvalidFilePath,
          message: 'URI does not contain an absolute file path '
              '(missing drive letter)',
          data: uri.toString(),
        ));
      }
      // Use the proper converter for the return value.
      return ErrorOr<String>.success(uriConverter.fromClientUri(uri));
    } catch (e) {
      // Even if tryParse() works and file == scheme, fromUri() can throw on
      // Windows if there are invalid characters.
      return ErrorOr<String>.error(ResponseError(
          code: ServerErrorCodes.InvalidFilePath,
          message: 'URI does not contain a valid file path',
          data: uri.toString()));
    }
  }

  /// Attempts to get a [ResolvedLibraryResult] for the library the includes the
  /// file at [path] or an error.
  ///
  /// When [waitForInProgressContextRebuilds] is `true` and the file appears to
  /// not be analyzed but analysis roots are currently being discovered, will
  /// wait for discovery to complete and then try again (once) to get a result.
  Future<ErrorOr<ResolvedLibraryResult>> requireResolvedLibrary(
    String path, {
    bool waitForInProgressContextRebuilds = true,
  }) async {
    var result = await server.getResolvedLibrary(path);
    if (result == null) {
      // Handle retry if allowed.
      if (waitForInProgressContextRebuilds) {
        await _initializedWithContexts;
        return requireResolvedLibrary(path,
            waitForInProgressContextRebuilds: false);
      }

      // If the file was being analyzed and we got a null result, that usually
      // indicates a parser or analysis failure, so provide a more specific
      // message.
      return server.isAnalyzed(path)
          ? analysisFailedError(path)
          : fileNotAnalyzedError(path);
    }
    return success(result);
  }

  /// Attempts to get a [ResolvedUnitResult] for [path] or an error.
  ///
  /// When [waitForInProgressContextRebuilds] is `true` and the file appears to
  /// not be analyzed but analysis roots are currently being discovered, will
  /// wait for discovery to complete and then try again (once) to get a result.
  Future<ErrorOr<ResolvedUnitResult>> requireResolvedUnit(
    String path, {
    bool waitForInProgressContextRebuilds = true,
  }) async {
    var result = await server.getResolvedUnit(path);
    if (result == null) {
      // Handle retry if allowed.
      if (waitForInProgressContextRebuilds) {
        await _initializedWithContexts;
        return requireResolvedUnit(path,
            waitForInProgressContextRebuilds: false);
      }

      // If the file was being analyzed and we got a null result, that usually
      // indicates a parser or analysis failure, so provide a more specific
      // message.
      return server.isAnalyzed(path)
          ? analysisFailedError(path)
          : fileNotAnalyzedError(path);
    } else if (!result.exists) {
      return error(
          ServerErrorCodes.InvalidFilePath, 'File does not exist', path);
    }
    return success(result);
  }

  Future<ErrorOr<ParsedUnitResult>> requireUnresolvedUnit(
    String path, {
    bool waitForInProgressContextRebuilds = true,
  }) async {
    var result = await server.getParsedUnit(path);
    if (result == null) {
      // Handle retry if allowed.
      if (waitForInProgressContextRebuilds) {
        await _initializedWithContexts;
        return requireUnresolvedUnit(path,
            waitForInProgressContextRebuilds: false);
      }

      // If the file was being analyzed and we got a null result, that usually
      // indicates a parser or analysis failure, so provide a more specific
      // message.
      return server.isAnalyzed(path)
          ? analysisFailedError(path)
          : fileNotAnalyzedError(path);
    }
    return success(result);
  }
}

/// Provides some helpers for request handlers to produce common errors or
/// obtain resolved results after waiting for in-progress analysis.
mixin LspHandlerHelperMixin {
  LspAnalysisServer get server;

  /// Extracts the current document version from [textDocument] if available,
  /// or uses the version that the server has via
  /// [LspAnalysisServer.getVersionedDocumentIdentifier].
  OptionalVersionedTextDocumentIdentifier extractDocumentVersion(
    TextDocumentIdentifier textDocument,
    String path,
  ) {
    return switch (textDocument) {
      OptionalVersionedTextDocumentIdentifier() => textDocument,
      VersionedTextDocumentIdentifier() =>
        OptionalVersionedTextDocumentIdentifier(
            uri: textDocument.uri, version: textDocument.version),
      _ => server.getVersionedDocumentIdentifier(path),
    };
  }

  bool fileHasBeenModified(String path, int? clientVersion) {
    var serverDocumentVersion = server.getDocumentVersion(path);
    return clientVersion != null && clientVersion != serverDocumentVersion;
  }

  ErrorOr<LineInfo> getLineInfo(String path) {
    var lineInfo = server.getLineInfo(path);

    if (lineInfo == null) {
      return error(ServerErrorCodes.InvalidFilePath,
          'Unable to obtain line information for file', path);
    } else {
      return success(lineInfo);
    }
  }
}

/// A base class for LSP handlers that require an LSP analysis server and are
/// not supported over the legacy protocol.
abstract class LspMessageHandler<P, R>
    extends MessageHandler<P, R, LspAnalysisServer> {
  LspMessageHandler(super.server);

  /// All strict LSP handlers implicitly require a trusted handler because they
  /// either modify state (eg. `textDocument/didOpen`) or otherwise require an
  /// LSP server (and not a legacy server).
  @override
  bool get requiresTrustedCaller => true;
}

mixin LspPluginRequestHandlerMixin<T extends AnalysisServer>
    on RequestHandlerMixin<T> {
  Future<List<Response>> requestFromPlugins(
    String path,
    RequestParams params, {
    Duration timeout = const Duration(milliseconds: 500),
  }) {
    var driver = server.getAnalysisDriver(path);
    var pluginFutures = server.broadcastRequestToPlugins(params, driver);
    return waitForResponses(pluginFutures,
        requestParameters: params, timeout: timeout);
  }
}

/// An object that can handle messages and produce responses for requests.
///
/// Clients may not extend, implement or mix-in this class.
abstract class MessageHandler<P, R, S extends AnalysisServer>
    with Handler<R>, HandlerHelperMixin, RequestHandlerMixin<S> {
  @override
  final S server;

  MessageHandler(this.server);

  /// The method that this handler can handle.
  Method get handlesMessage;

  /// A handler that can parse and validate JSON params.
  LspJsonHandler<P> get jsonHandler;

  /// Whether or not this handler can only be called by the owner of the
  /// analysis server process (for example the editor).
  ///
  /// All LSP-only handlers implicitly require a trusted caller because they
  /// can only be called over the stdin/stdout stream. However, shared message
  /// handlers must explicitly indicate if they can be called by untrusted
  /// clients (such as over DTD).
  ///
  /// For example, the request to change the DTD connection is _not_ callable
  /// by a DTD client and only by the editor.
  bool get requiresTrustedCaller;

  FutureOr<ErrorOr<R>> handle(
      P params, MessageInfo message, CancellationToken token);

  /// Handle the given [message]. If the [message] is a [RequestMessage], then the
  /// return value will be sent back in a [ResponseMessage].
  /// [NotificationMessage]s are not expected to return results.
  FutureOr<ErrorOr<R>> handleMessage(IncomingMessage message,
      MessageInfo messageInfo, CancellationToken token) {
    var reporter = LspJsonReporter('params');
    var paramsJson = message.params as Map<String, Object?>?;
    if (!jsonHandler.validateParams(paramsJson, reporter)) {
      return error(
        ErrorCodes.InvalidParams,
        'Invalid params for ${message.method}:\n'
                '${reporter.errors.isNotEmpty ? reporter.errors.first : ''}'
            .trim(),
      );
    }

    var params =
        paramsJson != null ? jsonHandler.convertParams(paramsJson) : null as P;
    return handle(params, messageInfo, token);
  }
}

/// Additional information about an incoming message (request or notification)
/// provided to a handler.
class MessageInfo {
  /// Returns the amount of time (in milliseconds) since the client sent this
  /// request or `null` if the client did not provide [clientRequestTime].
  final int? timeSinceRequest;

  OperationPerformanceImpl performance;

  MessageInfo({required this.performance, this.timeSinceRequest});
}

mixin PositionalArgCommandHandler {
  /// Parses "legacy" arguments passed a list, rather than in a map as a single
  /// argument.
  ///
  /// This is provided for backwards compatibility and may not be provided by
  /// all command handlers.
  Map<String, Object?> parseArgList(List<Object?> arguments);
}

/// A message handler that handles all messages for a given server state.
abstract class ServerStateMessageHandler {
  final AnalysisServer server;
  final Map<Method, MessageHandler<Object?, Object?, AnalysisServer>>
      messageHandlers = {};
  final CancelRequestHandler _cancelHandler;
  final NotCancelableToken _notCancelableToken = NotCancelableToken();

  ServerStateMessageHandler(this.server)
      : _cancelHandler = CancelRequestHandler(server) {
    registerHandler(_cancelHandler);
  }

  /// Handle the given [message]. If the [message] is a [RequestMessage], then the
  /// return value will be sent back in a [ResponseMessage].
  /// [NotificationMessage]s are not expected to return results.
  FutureOr<ErrorOr<Object?>> handleMessage(
    IncomingMessage message,
    MessageInfo messageInfo, {
    CancellationToken? cancellationToken,
  }) async {
    var handler = messageHandlers[message.method];
    if (handler == null) {
      return handleUnknownMessage(message);
    }

    if (message is! RequestMessage) {
      return handler.handleMessage(message, messageInfo, _notCancelableToken);
    }

    // If we weren't provided an existing cancellation token (eg. by the legacy
    // server), create a new cancellation token that will allow us to cancel
    // this request if requested. This saves some processing but the handler
    // will need to specifically check the token after `await`s.
    cancellationToken ??= _cancelHandler.createToken(message);
    try {
      var result =
          await handler.handleMessage(message, messageInfo, cancellationToken);
      // Do a final check before returning the result, because if the request was
      // cancelled we can save the overhead of serializing everything to JSON
      // and the client to deserializing the same in order to read the ID to see
      // that it was a request it didn't need (in the case of completions this
      // can be quite large).
      await Future.delayed(Duration.zero);
      return cancellationToken.isCancellationRequested ? cancelled() : result;
    } finally {
      _cancelHandler.clearToken(message);
    }
  }

  FutureOr<ErrorOr<Object?>> handleUnknownMessage(IncomingMessage message) {
    // If it's an optional *Notification* we can ignore it (return success).
    // Otherwise respond with failure. Optional Requests must still be responded
    // to so they don't leave open requests on the client.
    return _isOptionalNotification(message)
        ? success(null)
        : error(ErrorCodes.MethodNotFound, 'Unknown method ${message.method}');
  }

  void registerHandler(
      MessageHandler<Object?, Object?, AnalysisServer> handler) {
    messageHandlers[handler.handlesMessage] = handler;
  }

  void reject(Method method, ErrorCodes code, String message) {
    registerHandler(RejectMessageHandler(server, method, code, message));
  }

  bool _isOptionalNotification(IncomingMessage message) {
    // Not a notification.
    if (message is! NotificationMessage) {
      return false;
    }

    // Messages that start with $/ are optional.
    var stringValue = message.method.toJson();
    return stringValue.startsWith(r'$/');
  }
}

/// A base class for LSP handlers that work with any [AnalysisServer].
abstract class SharedMessageHandler<P, R>
    extends MessageHandler<P, R, AnalysisServer> {
  SharedMessageHandler(super.server);
}
