// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.uploader;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:pathos/path.dart' as path;

import '../command.dart';
import '../entrypoint.dart';
import '../exit_codes.dart' as exit_codes;
import '../http.dart';
import '../io.dart';
import '../log.dart' as log;
import '../oauth2.dart' as oauth2;
import '../source/hosted.dart';
import '../utils.dart';

/// Handles the `uploader` pub command.
class UploaderCommand extends PubCommand {
  final description = "Manage uploaders for a package on pub.dartlang.org.";
  final usage = "pub uploader [options] {add/remove} <email>";
  final requiresEntrypoint = false;

  /// The URL of the package hosting server.
  Uri get server => Uri.parse(commandOptions['server']);

  UploaderCommand() {
    commandParser.addOption('server', defaultsTo: HostedSource.DEFAULT_URL,
        help: 'The package server on which the package is hosted.');
    commandParser.addOption('package',
        help: 'The package whose uploaders will be modified.\n'
              '(defaults to the current package)');
  }

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

    return new Future.sync(() {
      var package = commandOptions['package'];
      if (package != null) return package;
      return new Entrypoint(path.current, cache).root.name;
    }).then((package) {
      var uploader = commandOptions.rest[0];
      return oauth2.withClient(cache, (client) {
        if (command == 'add') {
          var url = server.resolve("/api/packages/"
              "${Uri.encodeComponent(package)}/uploaders");
          return client.post(url,
              headers: PUB_API_HEADERS,
              fields: {"email": uploader});
        } else { // command == 'remove'
          var url = server.resolve("/api/packages/"
              "${Uri.encodeComponent(package)}/uploaders/"
              "${Uri.encodeComponent(uploader)}");
          return client.delete(url, headers: PUB_API_HEADERS);
        }
      });
    }).then(handleJsonSuccess)
      .catchError((error) => handleJsonError(error.response),
                  test: (e) => e is PubHttpException);
  }
}
