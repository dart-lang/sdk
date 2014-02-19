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

  /// The build mode.
  BarbackMode get mode => new BarbackMode(commandOptions['mode']);

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
        watcherType, _directoriesToServe,
        useDart2JS: useDart2JS).then((environment) {

      // In release mode, strip out .dart files since all relevant ones have
      // been compiled to JavaScript already.
      if (mode == BarbackMode.RELEASE) {
        for (var server in environment.servers) {
          server.allowAsset = (url) => !url.path.endsWith(".dart");
        }
      }

      /// This completer is used to keep pub running (by not completing) and
      /// to pipe fatal errors to pub's top-level error-handling machinery.
      var completer = new Completer();

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
      }, onError: (error, [stackTrace]) {
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
      });

      var directoryLength = environment.servers
          .map((server) => server.rootDirectory.length)
          .reduce(math.max);
      for (var server in environment.servers) {
        // Add two characters to account for "[" and "]".
        var directoryPrefix = log.gray(
            padRight("[${server.rootDirectory}]", directoryLength + 2));
        server.results.listen((result) {
          if (result.isSuccess) {
            log.message("$directoryPrefix ${log.green('GET')} "
                "${result.url.path} $_arrow ${result.id}");
            return;
          }

          var msg = "$directoryPrefix ${log.red('GET')} ${result.url.path} "
              "$_arrow";
          var error = result.error.toString();
          if (error.contains("\n")) {
            log.message("$msg\n${prefixLines(error)}");
          } else {
            log.message("$msg $error");
          }
        }, onError: (error, [stackTrace]) {
          if (completer.isCompleted) return;
          completer.completeError(error, stackTrace);
        });

        log.message("Serving ${entrypoint.root.name} "
            "${padRight(server.rootDirectory, directoryLength)} "
            "on ${log.bold('http://$hostname:${server.port}')}");
      }

      return completer.future;
    });
  }

  /// Returns the set of directories that will be served from servers exposed to
  /// the user.
  ///
  /// Throws a [UsageException] if the command-line arguments are invalid.
  List<String> get _directoriesToServe {
    if (commandOptions.rest.isEmpty) {
      var directories = ['web', 'test'].where(dirExists).toList();
      if (directories.isNotEmpty) return directories;
      usageError(
          'Your package must have "web" and/or "test" directories to serve,\n'
          'or you must pass in directories to serve explicitly.');
    }

    var directories = commandOptions.rest.map(p.normalize).toList();
    var invalid = directories.where((dir) => !isBeneath(dir, '.'));
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
}
