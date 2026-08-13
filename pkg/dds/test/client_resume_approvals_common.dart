// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

Future<VmService> createClient({
  required VmService service,
  required String clientName,
  bool onPauseStart = false,
  bool onPauseExit = false,
  bool onPauseReload = false,
}) async {
  final client = await vmServiceConnectUri(service.wsUri!);
  await client.setClientName(clientName);
  await client.requirePermissionToResume(
    onPauseStart: onPauseStart,
    onPauseExit: onPauseExit,
    onPauseReload: onPauseReload,
  );
  return client;
}
