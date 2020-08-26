// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dds/dds.dart';

/// A simple program which starts a [DartDevelopmentService] instance with a
/// basic configuration.
///
/// Takes the VM service URI as its single argument.
Future<void> main(List<String> args) async {
  if (args.isEmpty) return;
  final remoteVmServiceUri = Uri.parse(args.first);
  await DartDevelopmentService.startDartDevelopmentService(remoteVmServiceUri);
  stderr.write('DDS started');
}
