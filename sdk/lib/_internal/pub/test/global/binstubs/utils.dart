// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../test_pub.dart';

/// The buildbots do not have the Dart SDK (containing "dart" and "pub") on
/// their PATH, so we need to spawn the binstub process with a PATH that
/// explicitly includes it.
Future<Map> getEnvironment() async {
  var binDir = p.dirname(Platform.executable);
  var separator = Platform.operatingSystem == "windows" ? ";" : ":";
  var path = "${Platform.environment["PATH"]}$separator$binDir";

  var environment = await getPubTestEnvironment();
  environment["PATH"] = path;
  return environment;
}
