// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library command_uploader;

import 'dart:async';
import 'dart:io';
import 'dart:uri';

import '../../pkg/args/lib/args.dart';
import '../../pkg/path/lib/path.dart' as path;
import 'entrypoint.dart';
import 'exit_codes.dart' as exit_codes;
import 'http.dart';
import 'io.dart';
import 'log.dart' as log;
import 'oauth2.dart' as oauth2;
import 'pub.dart';
import 'utils.dart';

/// Handles the `uploader` pub command.
class UploaderCommand extends PubCommand {
  final description = "Manage uploaders for a package on pub.dartlang.org.";
  final usage = "pub uploader [options] {add/remove} <email>";
  final requiresEntrypoint = false;

  ArgParser get commandParser {
    var parser = new ArgParser();
    // TODO(nweiz): Use HostedSource.defaultUrl as the default value once we use
    // dart:io for HTTPS requests.
    parser.addOption('server', defaultsTo: 'https://pub.dartlang.org',
        help: 'The package server on which the package is hosted');
    parser.addOption('package', help: 'The package whose uploaders will be '
        'modified\n'
        '(defaults to the current package)');
    return parser;
  }

  /// The URL of the package hosting server.
  Uri get server => Uri.parse(commandOptions['server']);

  Future onRun() {
    if (commandOptions.rest.isEmpty) {
      log.error('No uploader command given.');
      this.printUsage();
      exit(exit_codes.USAGE);
    }

    var command = commandOptions.rest.removeAt(0);
    if (!['add', 'remove'].contains(command)) {
      log.error('Unknown uploader command "$command".');
      this.printUsage();
      exit(exit_codes.USAGE);
    } else if (commandOptions.rest.isEmpty) {
      log.error('No uploader given for "pub uploader $command".');
      this.printUsage();
      exit(exit_codes.USAGE);
    }

    return new Future.immediate(null).then((_) {
      var package = commandOptions['package'];
      if (package != null) return package;
      return Entrypoint.load(path.current, cache)
          .then((entrypoint) => entrypoint.root.name);
    }).then((package) {
      var uploader = commandOptions.rest[0];
      return oauth2.withClient(cache, (client) {
        if (command == 'add') {
          var url = server.resolve("/packages/${encodeUriComponent(package)}"
              "/uploaders.json");
          return client.post(url, fields: {"email": uploader});
        } else { // command == 'remove'
          var url = server.resolve("/packages/${encodeUriComponent(package)}"
              "/uploaders/${encodeUriComponent(uploader)}.json");
          return client.delete(url);
        }
      });
    }).then(handleJsonSuccess).catchError((asyncError) {
      if (asyncError.error is! PubHttpException) throw asyncError;
      handleJsonError(asyncError.error.response);
    });
  }
}
