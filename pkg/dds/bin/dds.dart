// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dds/dds.dart';

/// A simple program which starts a [DartDevelopmentService] instance with a
/// basic configuration.
///
/// Takes the following positional arguments:
///   - VM service URI
///   - DDS bind address
///   - DDS port
///   - Disable service authentication codes
Future<void> main(List<String> args) async {
  if (args.isEmpty) return;

  // This URI is provided by the VM service directly so don't bother doing a
  // lookup.
  final remoteVmServiceUri = Uri.parse(args.first);

  // Resolve the address which is potentially provided by the user.
  InternetAddress address;
  final addresses = await InternetAddress.lookup(args[1]);
  // Prefer IPv4 addresses.
  for (int i = 0; i < addresses.length; i++) {
    address = addresses[i];
    if (address.type == InternetAddressType.IPv4) break;
  }
  final serviceUri = Uri(
    scheme: 'http',
    host: address.address,
    port: int.parse(args[2]),
  );
  final disableServiceAuthCodes = args[3] == 'true';
  try {
    // TODO(bkonyi): add retry logic similar to that in vmservice_server.dart
    // See https://github.com/dart-lang/sdk/issues/43192.
    await DartDevelopmentService.startDartDevelopmentService(
      remoteVmServiceUri,
      serviceUri: serviceUri,
      enableAuthCodes: !disableServiceAuthCodes,
    );
    stderr.write('DDS started');
  } catch (e) {
    stderr.writeln('Failed to start DDS:\n$e');
  }
}
