// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_runner/src/configuration.dart';
import 'package:test_runner/src/testing_servers.dart';
import 'package:test_runner/src/utils.dart';
import 'package:test_runner/src/vendored_pkg/args/args.dart';

void main(List<String> arguments) {
  var parser = ArgParser();
  parser.addOption('port',
      abbr: 'p',
      help: 'The main server port we wish to respond to requests.',
      defaultsTo: '0');
  parser.addOption('crossOriginPort',
      abbr: 'c',
      help: 'A different port that accepts request from the main server port.',
      defaultsTo: '0');
  parser.addFlag('help',
      abbr: 'h', negatable: false, help: 'Print this usage information.');
  parser.addOption('build-directory', help: 'The build directory to use.');
  parser.addOption('packages', help: 'The package spec file to use.');
  parser.addOption('network',
      help: 'The network interface to use.', defaultsTo: '0.0.0.0');
  parser.addFlag('csp',
      help: 'Use Content Security Policy restrictions.', defaultsTo: false);
  parser.addOption('runtime',
      help: 'The runtime we are using (for csp flags).', defaultsTo: 'none');

  var args = parser.parse(arguments);
  if (args['help'] as bool) {
    print(parser.getUsage());
  } else {
    var servers = TestingServers(
        args['build-directory'] as String,
        args['csp'] as bool,
        Runtime.find(args['runtime'] as String),
        null,
        args['packages'] as String);
    var port = int.parse(args['port'] as String);
    var crossOriginPort = int.parse(args['crossOriginPort'] as String);
    servers
        .startServers(args['network'] as String,
            port: port, crossOriginPort: crossOriginPort)
        .then((_) {
      DebugLogger.info('Server listening on port ${servers.port}');
      DebugLogger.info('Server listening on port ${servers.crossOriginPort}');
    });
  }
}
