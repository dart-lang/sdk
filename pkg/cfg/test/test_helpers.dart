// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/api_unstable/vm.dart'
    show computePlatformBinariesLocation;
import 'package:kernel/ast.dart' as ast;
import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;

ast.Component readVmPlatformKernelFile() {
  final platformUri = computePlatformBinariesLocation().resolve(
    'vm_platform.dill',
  );
  final platformBytes = File(platformUri.toFilePath()).readAsBytesSync();
  final component = ast.Component();
  BinaryBuilder(platformBytes).readComponent(component);
  return component;
}
