// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.serve;

import 'dart:async';

import 'package:barback/barback.dart';

import '../barback/build_environment.dart';
import '../barback/pub_package_provider.dart';
import '../command.dart';
import '../exit_codes.dart' as exit_codes;
import '../io.dart';
import '../log.dart' as log;
import '../utils.dart';

final _arrow = getSpecial('\u2192', '=>');

/// Handles the `serve` pub command.
class ServeCommand extends PubCommand {
  String get description => "Run a local web development server.";
  String get usage => "pub serve";

  PubPackageProvider _provider;

  String get hostname => commandOptions['hostname'];

  /// `true` if Dart entrypoints should be compiled to JavaScript.
  bool get useDart2JS => commandOptions['dart2js'];

  /// The build mode.
  BarbackMode get mode => new BarbackMode(commandOptions['mode']);

  ServeCommand() {
    commandParser.addOption('port', defaultsTo: '8080',
        help: 'The port to listen on.');

    // A hidden option for the tests to work around a bug in some of the OS X
    // bots where "localhost" very rarely resolves to the IPv4 loopback address
    // instead of IPv6 (or vice versa). The tests will always set this to
    // 127.0.0.1.
    commandParser.addOption('hostname',
                            defaultsTo: 'localhost',
                            hide: true);
    commandParser.addFlag('dart2js', defaultsTo: true,
        help: 'Compile Dart to JavaScript.');
    commandParser.addFlag('force-poll', defaultsTo: false,
        help: 'Force the use of a polling filesystem watcher.');
    commandParser.addOption('mode', defaultsTo: BarbackMode.DEBUG.toString(),
        help: 'Mode to run transformers in.');
  }

  Future onRun() {
    var port;
    try {
      port = int.parse(commandOptions['port']);
    } on FormatException catch (_) {
      log.error('Could not parse port "${commandOptions['port']}"');
      this.printUsage();
      return flushThenExit(exit_codes.USAGE);
    }

    var watcherType = commandOptions['force-poll'] ?
        WatcherType.POLLING : WatcherType.AUTO;

    return BuildEnvironment.create(entrypoint, hostname, port, mode,
        watcherType, ["web"].toSet(),
        useDart2JS: useDart2JS).then((environment) {

      // In release mode, strip out .dart files since all relevant ones have
      // been compiled to JavaScript already.
      if (mode == BarbackMode.RELEASE) {
        environment.server.allowAsset = (url) => !url.path.endsWith(".dart");
      }

      /// This completer is used to keep pub running (by not completing) and
      /// to pipe fatal errors to pub's top-level error-handling machinery.
      var completer = new Completer();

      environment.server.barback.errors.listen((error) {
        log.error(log.red("Build error:\n$error"));
      });

      environment.server.barback.results.listen((result) {
        if (result.succeeded) {
          // TODO(rnystrom): Report using growl/inotify-send where available.
          log.message("Build completed ${log.green('successfully')}");
        } else {
          log.message("Build completed with "
              "${log.red(result.errors.length)} errors.");
        }
      }, onError: (error, [stackTrace]) {
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
      });

      environment.server.results.listen((result) {
        if (result.isSuccess) {
          log.message("${log.green('GET')} ${result.url.path} $_arrow "
              "${result.id}");
          return;
        }

        var msg = "${log.red('GET')} ${result.url.path} $_arrow";
        var error = result.error.toString();
        if (error.contains("\n")) {
          log.message("$msg\n${prefixLines(error)}");
        } else {
          log.message("$msg $error");
        }
      }, onError: (error, [stackTrace]) {
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
      });

      log.message("Serving ${entrypoint.root.name} "
          "on http://$hostname:${environment.server.port}");

      return completer.future;
    });
  }
}
