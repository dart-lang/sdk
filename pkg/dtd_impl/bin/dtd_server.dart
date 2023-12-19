// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart_tooling_daemon.dart';

void main(List<String> args) async {
  final dartToolingDaemon = await DartToolingDaemon.startService(
    shouldLogRequests: true,
  ); // TODO(@danchevalier): turn off logging

  print(
    'The Dart Tooling Daemon is listening on ${dartToolingDaemon.uri?.host}:${dartToolingDaemon.uri?.port}',
  );
}
