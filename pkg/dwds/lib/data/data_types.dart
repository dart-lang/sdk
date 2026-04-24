// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds/data/utils.dart';

class ConnectFailure {
  static const type = 'ConnectFailure';
  final int tabId;
  final String? reason;

  ConnectFailure({required this.tabId, this.reason});

  List<Object?> toJson() => [
    type,
    'tabId',
    tabId,
    if (reason != null) ...['reason', reason],
  ];

  factory ConnectFailure.fromJson(List<dynamic> jsonList) {
    final json = listToMap(jsonList, type: type);
    return ConnectFailure(
      tabId: json['tabId'] as int,
      reason: json['reason'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectFailure &&
          runtimeType == other.runtimeType &&
          tabId == other.tabId &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(tabId, reason);

  @override
  String toString() => 'ConnectFailure(tabId: $tabId, reason: $reason)';
}

class DevToolsOpener {
  static const type = 'DevToolsOpener';
  final bool newWindow;

  DevToolsOpener({required this.newWindow});

  List<Object?> toJson() => [type, 'newWindow', newWindow];

  factory DevToolsOpener.fromJson(List<dynamic> jsonList) {
    final json = listToMap(jsonList, type: type);
    return DevToolsOpener(newWindow: json['newWindow'] as bool);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DevToolsOpener &&
          runtimeType == other.runtimeType &&
          newWindow == other.newWindow;

  @override
  int get hashCode => newWindow.hashCode;

  @override
  String toString() => 'DevToolsOpener(newWindow: $newWindow)';
}

class DevToolsUrl {
  static const type = 'DevToolsUrl';
  final int tabId;
  final String url;

  DevToolsUrl({required this.tabId, required this.url});

  List<Object?> toJson() => [type, 'tabId', tabId, 'url', url];

  factory DevToolsUrl.fromJson(List<dynamic> jsonList) {
    final json = listToMap(jsonList, type: type);
    return DevToolsUrl(tabId: json['tabId'] as int, url: json['url'] as String);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DevToolsUrl &&
          runtimeType == other.runtimeType &&
          tabId == other.tabId &&
          url == other.url;

  @override
  int get hashCode => Object.hash(tabId, url);

  @override
  String toString() => 'DevToolsUrl(tabId: $tabId, url: $url)';
}

class DebugStateChange {
  static const type = 'DebugStateChange';
  static const startDebugging = 'start-debugging';
  static const stopDebugging = 'stop-debugging';
  static const failedToConnect = 'failed-to-connect';

  final int tabId;

  /// Can only be [startDebugging] or [stopDebugging].
  final String newState;
  final String? reason;

  DebugStateChange({required this.tabId, required this.newState, this.reason});

  List<Object?> toJson() => [
    type,
    'tabId',
    tabId,
    'newState',
    newState,
    if (reason != null) ...['reason', reason],
  ];

  factory DebugStateChange.fromJson(List<dynamic> jsonList) {
    final json = listToMap(jsonList, type: type);
    return DebugStateChange(
      tabId: json['tabId'] as int,
      newState: json['newState'] as String,
      reason: json['reason'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebugStateChange &&
          runtimeType == other.runtimeType &&
          tabId == other.tabId &&
          newState == other.newState &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(tabId, newState, reason);

  @override
  String toString() =>
      'DebugStateChange(tabId: $tabId, newState: $newState, reason: $reason)';
}
