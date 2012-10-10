// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http_server_runner;
import 'dart:io';
import 'http_server.dart';

main() {
  var optionsParser = getOptionParser();
  try {
    var argResults = optionsParser.parse(new Options().arguments);
    var server = new HttpTestServer(
        int.parse(argResults['port']),
        argResults['root']);
  } catch (e) {
    print(e);
    print('Usage: http_server_runner.dart <options>');
    print(optionsParser.getUsage());
  }
}
