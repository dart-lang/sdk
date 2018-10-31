// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_client/server.dart';
import 'package:cli_util/cli_logging.dart';

class VerboseServer extends Server {
  final Logger logger;

  VerboseServer(this.logger);

  @override
  void logMessage(String prefix, String details) {
    logger.trace('$currentElapseTime: $prefix $details');
  }
}
