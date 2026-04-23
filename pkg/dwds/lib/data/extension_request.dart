// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:dwds/data/utils.dart';

const authenticationPath = '\$dwdsExtensionAuthentication';

/// A request to run a command in the Dart Debug Extension.
class ExtensionRequest {
  static const type = 'ExtensionRequest';

  /// Used to associate a request with an [ExtensionResponse].
  final int id;

  final String command;

  /// Contains JSON-encoded parameters, if available.
  final String? commandParams;

  ExtensionRequest({
    required this.id,
    required this.command,
    this.commandParams,
  });

  factory ExtensionRequest.fromJson(List<dynamic> jsonList) {
    final json = listToMap(jsonList, type: type);
    return ExtensionRequest(
      id: json['id'] as int,
      command: json['command'] as String,
      commandParams: json['commandParams'] as String?,
    );
  }

  List<Object?> toJson() {
    return [
      type,
      'id',
      id,
      'command',
      command,
      if (commandParams != null) ...['commandParams', commandParams],
    ];
  }

  @override
  String toString() =>
      'ExtensionRequest { id=$id, command=$command, commandParams=$commandParams }';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtensionRequest &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          command == other.command &&
          commandParams == other.commandParams;

  @override
  int get hashCode => Object.hash(id, command, commandParams);
}

/// A response to an [ExtensionRequest].
class ExtensionResponse {
  static const type = 'ExtensionResponse';

  /// Used to associate a response with an [ExtensionRequest].
  final int id;

  final bool success;

  /// Contains a JSON-encoded payload.
  final String result;

  /// Contains an error, if available.
  final String? error;

  ExtensionResponse({
    required this.id,
    required this.success,
    required this.result,
    this.error,
  });

  factory ExtensionResponse.fromJson(List<dynamic> jsonList) {
    final json = listToMap(jsonList, type: type);
    return ExtensionResponse(
      id: json['id'] as int,
      success: json['success'] as bool,
      result: json['result'] as String,
      error: json['error'] as String?,
    );
  }

  List<Object?> toJson() {
    return [
      type,
      'id',
      id,
      'success',
      success,
      'result',
      result,
      if (error != null) ...['error', error],
    ];
  }

  @override
  String toString() =>
      'ExtensionResponse { id=$id, success=$success, result=$result, error=$error }';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtensionResponse &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          success == other.success &&
          result == other.result &&
          error == other.error;

  @override
  int get hashCode => Object.hash(id, success, result, error);
}

/// An event for Dart Debug Extension.
class ExtensionEvent {
  static const type = 'ExtensionEvent';

  /// Contains a JSON-encoded payload.
  final String params;

  final String method;

  ExtensionEvent({required this.params, required this.method});

  factory ExtensionEvent.fromJson(List<dynamic> jsonList) {
    final firstElement = jsonList.isEmpty ? null : jsonList.first;
    final json = listToMap(jsonList, type: firstElement == type ? type : null);
    final params = json['params'];
    return ExtensionEvent(
      params: params is String ? params : jsonEncode(params),
      method: json['method'] as String,
    );
  }

  List<Object?> toJson() {
    return [type, 'params', params, 'method', method];
  }

  @override
  String toString() => 'ExtensionEvent { params=$params, method=$method }';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtensionEvent &&
          runtimeType == other.runtimeType &&
          params == other.params &&
          method == other.method;

  @override
  int get hashCode => Object.hash(params, method);
}

/// A batched group of events, currently always Debugger.scriptParsed
class BatchedEvents {
  static const type = 'BatchedEvents';
  final List<ExtensionEvent> events;

  BatchedEvents({required this.events});

  factory BatchedEvents.fromJson(List<dynamic> jsonList) {
    final json = listToMap(jsonList, type: type);
    return BatchedEvents(
      events: (json['events'] as List)
          .map((e) => ExtensionEvent.fromJson(e as List))
          .toList(),
    );
  }

  List<Object?> toJson() {
    return [type, 'events', events.map((e) => e.toJson()).toList()];
  }

  @override
  String toString() => 'BatchedEvents { events=$events }';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatchedEvents &&
          runtimeType == other.runtimeType &&
          const ListEquality().equals(events, other.events);

  @override
  int get hashCode => Object.hashAll(events);
}
