// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dtd_impl/dart_tooling_daemon.dart';

void main(List<String> args) async {
  await DartToolingDaemon.startService(
    args,
    shouldLogRequests: true,
  ); // TODO(@danchevalier): turn off logging
}
