// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.poi_test;

import 'dart:io' show
    Platform;

import 'package:try/poi/poi.dart' as poi;

import 'package:async_helper/async_helper.dart';

void main() {
  poi.main(<String>[Platform.script.toFilePath(), '339']);
  asyncTest(() => poi.doneFuture);
}
