// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds/data/utils.dart';

/// A request to open DevTools.
class DevToolsRequest {
  static const type = 'DevToolsRequest';

  /// Identifies a given application, across tabs/windows.
  final String appId;

  /// Identifies a given instance of an application, unique per tab/window.
  final String instanceId;

  /// Identifies the context in which evaluations should occur.
  ///
  /// Defines execution context for the debug service that connects
  /// to chrome via the extension debugger.
  /// Can be `null` for local debug service, which gets the execution
  /// context from the Chrome runtime.
  final int? contextId;

  /// Belongs to the tab that requests the DevTools.
  ///
  /// Defines the tab being debugged for the debug service that connects
  /// to chrome via the extension debugger.
  /// Can be `null` for local debug service, which finds the tab with the
  /// correct `dartAppInstanceId` automatically.
  final String? tabUrl;

  /// Designates this as a request to send back the DevTools URI instead of
  /// opening DevTools in a new tab or window.
  ///
  /// Only available on requests coming from the Dart Debug Extension. Is `null`
  /// for local debug service.
  final bool? uriOnly;

  /// Identifies the client that DWDS is attaching to.
  ///
  /// This could be Cider, DevTools (as a standalone app), or DevTools (embedded
  /// in Chrome DevTools).
  final String? client;

  DevToolsRequest({
    required this.appId,
    required this.instanceId,
    this.contextId,
    this.tabUrl,
    this.uriOnly,
    this.client,
  });

  factory DevToolsRequest.fromJson(List<dynamic> jsonList) {
    final json = listToMap(jsonList, type: type);
    return DevToolsRequest(
      appId: json['appId'] as String,
      instanceId: json['instanceId'] as String,
      contextId: json['contextId'] as int?,
      tabUrl: json['tabUrl'] as String?,
      uriOnly: json['uriOnly'] as bool?,
      client: json['client'] as String?,
    );
  }

  List<Object?> toJson() {
    return [
      type,
      'appId',
      appId,
      'instanceId',
      instanceId,
      if (contextId != null) ...['contextId', contextId],
      if (tabUrl != null) ...['tabUrl', tabUrl],
      if (uriOnly != null) ...['uriOnly', uriOnly],
      if (client != null) ...['client', client],
    ];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DevToolsRequest &&
        other.appId == appId &&
        other.instanceId == instanceId &&
        other.contextId == contextId &&
        other.tabUrl == tabUrl &&
        other.uriOnly == uriOnly &&
        other.client == client;
  }

  @override
  int get hashCode =>
      Object.hash(appId, instanceId, contextId, tabUrl, uriOnly, client);

  @override
  String toString() {
    return 'DevToolsRequest { '
        'appId: $appId, '
        'instanceId: $instanceId, '
        'contextId: $contextId, '
        'tabUrl: $tabUrl, '
        'uriOnly: $uriOnly, '
        'client: $client, '
        '}';
  }
}

/// A response to a [DevToolsRequest].
class DevToolsResponse {
  static const type = 'DevToolsResponse';
  final bool success;
  final bool promptExtension;
  final String? error;

  DevToolsResponse({
    required this.success,
    required this.promptExtension,
    this.error,
  });

  factory DevToolsResponse.fromJson(List<dynamic> jsonList) {
    final json = listToMap(jsonList, type: type);
    return DevToolsResponse(
      success: json['success'] as bool,
      promptExtension: json['promptExtension'] as bool,
      error: json['error'] as String?,
    );
  }

  List<Object?> toJson() {
    return [
      type,
      'success',
      success,
      'promptExtension',
      promptExtension,
      if (error != null) ...['error', error],
    ];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DevToolsResponse &&
        other.success == success &&
        other.promptExtension == promptExtension &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(success, promptExtension, error);

  @override
  String toString() {
    return 'DevToolsResponse { '
        'success: $success, '
        'promptExtension: $promptExtension, '
        'error: $error }';
  }
}
