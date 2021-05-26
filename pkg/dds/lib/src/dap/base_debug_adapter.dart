// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'logging.dart';
import 'protocol_common.dart';
import 'protocol_generated.dart';
import 'protocol_stream.dart';

/// A base class for debug adapters.
///
/// Communicates over a [ByteStreamServerChannel] and turns messages into
/// appropriate method calls/events.
///
/// This class does not implement any DA functionality, only message handling.
abstract class BaseDebugAdapter<TLaunchArgs extends LaunchRequestArguments> {
  int _sequence = 1;
  final ByteStreamServerChannel _channel;
  final Logger? logger;

  BaseDebugAdapter(this._channel, this.logger) {
    _channel.listen(_handleIncomingMessage);
  }

  /// Parses arguments for [launchRequest] into a type of [TLaunchArgs].
  ///
  /// This method must be implemented by the implementing class using a class
  /// that corresponds to the arguments it expects (these may differ between
  /// Dart CLI, Dart tests, Flutter, Flutter tests).
  TLaunchArgs Function(Map<String, Object?>) get parseLaunchArgs;

  FutureOr<void> configurationDoneRequest(
    Request request,
    ConfigurationDoneArguments? args,
    void Function(void) sendResponse,
  );

  FutureOr<void> disconnectRequest(
    Request request,
    DisconnectArguments? args,
    void Function(void) sendResponse,
  );

  /// Calls [handler] for an incoming request, using [fromJson] to parse its
  /// arguments from the request.
  ///
  /// [handler] will be provided a function [sendResponse] that it can use to
  /// sends its response without needing to build a [Response] from fields on
  /// the request.
  ///
  /// [handler] must _always_ call [sendResponse], even if the response does not
  /// require a body.
  ///
  /// If [handler] throws, its exception will be sent as an error response.
  FutureOr<void> handle<TArg, TResp>(
    Request request,
    FutureOr<void> Function(Request, TArg, void Function(TResp)) handler,
    TArg Function(Map<String, Object?>) fromJson,
  ) async {
    final args = request.arguments != null
        ? fromJson(request.arguments as Map<String, Object?>)
        // arguments are only valid to be null then TArg is nullable.
        : null as TArg;

    // Because handlers may need to send responses before they have finished
    // executing (for example, initializeRequest needs to send its response
    // before sending InitializedEvent()), we pass in a function `sendResponse`
    // rather than using a return value.
    var sendResponseCalled = false;
    void sendResponse(TResp responseBody) {
      assert(!sendResponseCalled,
          'sendResponse was called multiple times by ${request.command}');
      sendResponseCalled = true;
      final response = Response(
        success: true,
        requestSeq: request.seq,
        seq: _sequence++,
        command: request.command,
        body: responseBody,
      );
      _channel.sendResponse(response);
    }

    try {
      await handler(request, args, sendResponse);
      assert(sendResponseCalled,
          'sendResponse was not called in ${request.command}');
    } catch (e, s) {
      final response = Response(
        success: false,
        requestSeq: request.seq,
        seq: _sequence++,
        command: request.command,
        message: '$e',
        body: '$s',
      );
      _channel.sendResponse(response);
    }
  }

  FutureOr<void> initializeRequest(
    Request request,
    InitializeRequestArguments args,
    void Function(Capabilities) sendResponse,
  );

  FutureOr<void> launchRequest(
      Request request, TLaunchArgs args, void Function(void) sendResponse);

  /// Sends an event, lookup up the event type based on the runtimeType of
  /// [body].
  void sendEvent(EventBody body) {
    final event = Event(
      seq: _sequence++,
      event: eventTypes[body.runtimeType]!,
      body: body,
    );
    _channel.sendEvent(event);
  }

  /// Sends a request to the client, looking up the request type based on the
  /// runtimeType of [arguments].
  void sendRequest(RequestArguments arguments) {
    final request = Request(
      seq: _sequence++,
      command: commandTypes[arguments.runtimeType]!,
      arguments: arguments,
    );
    _channel.sendRequest(request);
  }

  FutureOr<void> terminateRequest(
    Request request,
    TerminateArguments? args,
    void Function(void) sendResponse,
  );

  /// Wraps a fromJson handler for requests that allow null arguments.
  T? Function(Map<String, Object?>?) _allowNullArg<T extends RequestArguments>(
    T Function(Map<String, Object?>) fromJson,
  ) {
    return (data) => data == null ? null : fromJson(data);
  }

  /// Handles incoming messages from the client editor.
  void _handleIncomingMessage(ProtocolMessage message) {
    if (message is Request) {
      _handleIncomingRequest(message);
    } else if (message is Response) {
      _handleIncomingResponse(message);
    } else {
      throw Exception('Unknown Protocol message ${message.type}');
    }
  }

  /// Handles an incoming request, calling the appropriate method to handle it.
  void _handleIncomingRequest(Request request) {
    if (request.command == 'initialize') {
      handle(request, initializeRequest, InitializeRequestArguments.fromJson);
    } else if (request.command == 'launch') {
      handle(request, launchRequest, parseLaunchArgs);
    } else if (request.command == 'terminate') {
      handle(
        request,
        terminateRequest,
        _allowNullArg(TerminateArguments.fromJson),
      );
    } else if (request.command == 'disconnect') {
      handle(
        request,
        disconnectRequest,
        _allowNullArg(DisconnectArguments.fromJson),
      );
    } else if (request.command == 'configurationDone') {
      handle(
        request,
        configurationDoneRequest,
        _allowNullArg(ConfigurationDoneArguments.fromJson),
      );
    } else {
      final response = Response(
        success: false,
        requestSeq: request.seq,
        seq: _sequence++,
        command: request.command,
        message: 'Unknown command: ${request.command}',
      );
      _channel.sendResponse(response);
    }
  }

  void _handleIncomingResponse(Response response) {
    // TODO(dantup): Implement this when the server sends requests to the client
    // (for example runInTerminalRequest).
  }
}
