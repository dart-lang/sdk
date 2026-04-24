// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A request to open DevTools.
class ConnectRequest {
  /// Identifies a given application, across tabs/windows.
  final String appId;

  /// Identifies a given instance of an application, unique per tab/window.
  final String instanceId;

  /// The entrypoint for the Dart application.
  final String entrypointPath;

  ConnectRequest({
    required this.appId,
    required this.instanceId,
    required this.entrypointPath,
  });

  Map<String, dynamic> toJson() => {
    'appId': appId,
    'instanceId': instanceId,
    'entrypointPath': entrypointPath,
  };

  factory ConnectRequest.fromJson(Map<String, dynamic> json) {
    return ConnectRequest(
      appId: json['appId'] as String,
      instanceId: json['instanceId'] as String,
      entrypointPath: json['entrypointPath'] as String,
    );
  }
}
