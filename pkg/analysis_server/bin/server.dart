// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/starter.dart';

/// Create and run an analysis server.
void main(List<String> args) async {
  var starter = ServerStarter();
  starter.start(args);
}
