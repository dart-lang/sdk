// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';

/// When set, this function is executed just before the Analysis Server starts.
void Function(
  String cmdName,
  List<FileSystemEntity> analysisRoots,
  ArgResults? argResults,
)?
preAnalysisServerStart;
