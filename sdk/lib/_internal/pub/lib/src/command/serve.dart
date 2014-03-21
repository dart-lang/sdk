// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.serve;

import 'dart:async';
import 'dart:math' as math;

import 'package:barback/barback.dart';
import 'package:path/path.dart' as p;

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
  String get description =>
      'Run a local web development server.\n\n'
      'By default, this serves "web/" and "test/", but an explicit list of \n'
      'directories to serve can be provided as well.';
  String get usage => "pub serve [directories...]";
  final takesArguments = true;

  PubPackageProvider _provider;

  String get hostname => commandOptions['hostname'];

  /// `true` if Dart entrypoints should be compiled to JavaScript.
  bool get useDart2JS => commandOptions['dart2js'];

  /// `true` if the admin server URL should be displayed on startup.
  bool get logAdminUrl => commandOptions['log-admin-url'];

  /// The build mode.
  BarbackMode get mode => new BarbackMode(commandOptions['mode']);

  /// This completer is used to keep pub running (by not completing) and to
  /// pipe fatal errors to pub's top-level error-handling machinery.
  final _completer = new Completer();

  ServeCommand() {
    commandParser.addOption('port', defaultsTo: '8080',
        help: 'The base port to listen on.');

    // A hidden option for the tests to work around a bug in some of the OS X
    // bots where "localhost" very rarely resolves to the IPv4 loopback address
    // instead of IPv6 (or vice versa). The tests will always set this to
    // 127.0.0.1.
    commandParser.addOption('hostname',
                            defaultsTo: 'localhost',
                            hide: true);

    // TODO(rnystrom): A hidden option to print the URL that the admin server
    // is bound to on startup. Since this is currently only used for the Web
    // Socket interface, we don't want to show it to users, but the tests and
    // Editor need this logged to know what port to bind to.
    // Remove this (and always log) when #16954 is fixed.
    commandParser.addFlag('log-admin-url', defaultsTo: false, hide: true);

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

    var directories = _parseDirectoriesToServe();

    var watcherType = commandOptions['force-poll'] ?
        WatcherType.POLLING : WatcherType.AUTO;

    return BuildEnvironment.create(entrypoint, hostname, port, mode,
        watcherType, useDart2JS: useDart2JS).then((environment) {

      var directoryLength = directories.map((dir) => dir.length)
          .reduce(math.max);

      return environment.startAdminServer().then((server) {
        server.results.listen((_) {
          // The admin server produces no result values.
          assert(false);
        }, onError: _fatalError);

        if (logAdminUrl) {
          log.message("Running admin server on "
              "${log.bold('http://$hostname:${server.port}')}");
        }

        // Start up the servers. We pause updates while this is happening so
        // that we don't log spurious build results in the middle of listing
        // out the bound servers.
        environment.pauseUpdates();
        return Future.forEach(directories, (directory) {
          return _startServer(environment, directory, directoryLength);
        });
      }).then((_) {
        // Now that the servers are up and logged, send them to barback.
        environment.barback.errors.listen((error) {
          log.error(log.red("Build error:\n$error"));
        });

        environment.barback.results.listen((result) {
          if (result.succeeded) {
            // TODO(rnystrom): Report using growl/inotify-send where available.
            log.message("Build completed ${log.green('successfully')}");
          } else {
            log.message("Build completed with "
                "${log.red(result.errors.length)} errors.");
          }
        }, onError: _fatalError);

        environment.resumeUpdates();
        return _completer.future;
      });
    });
  }

  Future _startServer(BuildEnvironment environment, String rootDirectory,
      int directoryLength) {
    return environment.serveDirectory(rootDirectory).then((server) {
      // In release mode, strip out .dart files since all relevant ones have
      // been compiled to JavaScript already.
      if (mode == BarbackMode.RELEASE) {
        server.allowAsset = (url) => !url.path.endsWith(".dart");
      }

      // Add two characters to account for "[" and "]".
      var prefix = log.gray(
          padRight("[${server.rootDirectory}]", directoryLength + 2));

      server.results.listen((result) {
        var buffer = new StringBuffer();
        buffer.write("$prefix ");

        if (result.isSuccess) {
          buffer.write(
              "${log.green('GET')} ${result.url.path} $_arrow ${result.id}");
        } else {
          buffer.write("${log.red('GET')} ${result.url.path} $_arrow");

          var error = result.error.toString();
          if (error.contains("\n")) {
            buffer.write("\n${prefixLines(error)}");
          } else {
            buffer.write(" $error");
          }
        }

        log.message(buffer);
      }, onError: _fatalError);

      log.message("Serving ${entrypoint.root.name} "
          "${padRight(server.rootDirectory, directoryLength)} "
          "on ${log.bold('http://$hostname:${server.port}')}");
    });
  }

  /// Returns the set of directories that will be served from servers exposed
  /// to the user.
  ///
  /// Throws a [UsageException] if the command-line arguments are invalid.
  List<String> _parseDirectoriesToServe() {
    if (commandOptions.rest.isEmpty) {
      var directories = ['web', 'test'].where(dirExists).toList();
      if (directories.isNotEmpty) return directories;
      usageError(
          'Your package must have "web" and/or "test" directories to serve,\n'
          'or you must pass in directories to serve explicitly.');
    }

    var directories = commandOptions.rest.map(p.normalize).toList();
    var invalid = directories.where((dir) => !p.isWithin('.', dir));
    if (invalid.isNotEmpty) {
      usageError("${_directorySentence(invalid, "isn't", "aren't")} in this "
          "package.");
    }

    var nonExistent = directories.where((dir) => !dirExists(dir));
    if (nonExistent.isNotEmpty) {
      usageError("${_directorySentence(nonExistent, "doesn't", "don't")} "
          "exist.");
    }

    return directories;
  }

  /// Converts a list of [directoryNames] to a sentence.
  ///
  /// After the list of directories, [singularVerb] will be used if there is
  /// only one directory and [pluralVerb] will be used if there are more than
  /// one.
  String _directorySentence(Iterable<String> directoryNames,
      String singularVerb, String pluralVerb) {
    var directories = pluralize('Directory', directoryNames.length,
        plural: 'Directories');
    var names = toSentence(ordered(directoryNames).map((dir) => '"$dir"'));
    var verb = pluralize(singularVerb, directoryNames.length,
        plural: pluralVerb);
    return "$directories $names $verb";
  }

  /// Reports [error] and exits the server.
  void _fatalError(error, [stackTrace]) {
    if (_completer.isCompleted) return;
    _completer.completeError(error, stackTrace);
  }
}
