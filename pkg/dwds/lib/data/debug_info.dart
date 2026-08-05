// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds/data/utils.dart';

class DebugInfo {
  static const String type = 'DebugInfo';

  final String? appEntrypointPath;
  final String? appId;
  final String? appInstanceId;
  final String? appOrigin;
  final String? appUrl;
  final String? authUrl;
  final String? dwdsVersion;
  final String? extensionUrl;
  final bool? isInternalBuild;
  final bool? isFlutterApp;
  final String? workspaceName;
  final String? tabUrl;
  final int? tabId;

  const DebugInfo({
    this.appEntrypointPath,
    this.appId,
    this.appInstanceId,
    this.appOrigin,
    this.appUrl,
    this.authUrl,
    this.dwdsVersion,
    this.extensionUrl,
    this.isInternalBuild,
    this.isFlutterApp,
    this.workspaceName,
    this.tabUrl,
    this.tabId,
  });

  /// Mimics built_value serialization for compatibility.
  ///
  /// Returns a list in the format:
  /// ['DebugInfo', 'key1', value1, 'key2', value2, ...]
  ///
  /// Null values are omitted from the list.
  List<Object?> toJson() => [
    type,
    if (appEntrypointPath != null) ...['appEntrypointPath', appEntrypointPath],
    if (appId != null) ...['appId', appId],
    if (appInstanceId != null) ...['appInstanceId', appInstanceId],
    if (appOrigin != null) ...['appOrigin', appOrigin],
    if (appUrl != null) ...['appUrl', appUrl],
    if (authUrl != null) ...['authUrl', authUrl],
    if (dwdsVersion != null) ...['dwdsVersion', dwdsVersion],
    if (extensionUrl != null) ...['extensionUrl', extensionUrl],
    if (isInternalBuild != null) ...['isInternalBuild', isInternalBuild],
    if (isFlutterApp != null) ...['isFlutterApp', isFlutterApp],
    if (workspaceName != null) ...['workspaceName', workspaceName],
    if (tabUrl != null) ...['tabUrl', tabUrl],
    if (tabId != null) ...['tabId', tabId],
  ];

  factory DebugInfo.fromJson(List<dynamic> list) {
    final map = listToMap(list, type: type);

    return DebugInfo(
      appEntrypointPath: map['appEntrypointPath'] as String?,
      appId: map['appId'] as String?,
      appInstanceId: map['appInstanceId'] as String?,
      appOrigin: map['appOrigin'] as String?,
      appUrl: map['appUrl'] as String?,
      authUrl: map['authUrl'] as String?,
      dwdsVersion: map['dwdsVersion'] as String?,
      extensionUrl: map['extensionUrl'] as String?,
      isInternalBuild: map['isInternalBuild'] as bool?,
      isFlutterApp: map['isFlutterApp'] as bool?,
      workspaceName: map['workspaceName'] as String?,
      tabUrl: map['tabUrl'] as String?,
      tabId: map['tabId'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebugInfo &&
          runtimeType == other.runtimeType &&
          appEntrypointPath == other.appEntrypointPath &&
          appId == other.appId &&
          appInstanceId == other.appInstanceId &&
          appOrigin == other.appOrigin &&
          appUrl == other.appUrl &&
          authUrl == other.authUrl &&
          dwdsVersion == other.dwdsVersion &&
          extensionUrl == other.extensionUrl &&
          isInternalBuild == other.isInternalBuild &&
          isFlutterApp == other.isFlutterApp &&
          workspaceName == other.workspaceName &&
          tabUrl == other.tabUrl &&
          tabId == other.tabId;

  @override
  int get hashCode => Object.hash(
    appEntrypointPath,
    appId,
    appInstanceId,
    appOrigin,
    appUrl,
    authUrl,
    dwdsVersion,
    extensionUrl,
    isInternalBuild,
    isFlutterApp,
    workspaceName,
    tabUrl,
    tabId,
  );

  @override
  String toString() {
    return 'DebugInfo { '
        'appEntrypointPath: $appEntrypointPath, '
        'appId: $appId, '
        'appInstanceId: $appInstanceId, '
        'appOrigin: $appOrigin, '
        'appUrl: $appUrl, '
        'authUrl: $authUrl, '
        'dwdsVersion: $dwdsVersion, '
        'extensionUrl: $extensionUrl, '
        'isInternalBuild: $isInternalBuild, '
        'isFlutterApp: $isFlutterApp, '
        'workspaceName: $workspaceName, '
        'tabUrl: $tabUrl, '
        'tabId: $tabId, '
        '}';
  }
}
