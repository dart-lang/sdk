// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command;

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;

import 'entrypoint.dart';
import 'log.dart' as log;
import 'global_packages.dart';
import 'system_cache.dart';

/// The base class for commands for the pub executable.
///
/// A command may either be a "leaf" command or it may be a parent for a set
/// of subcommands. Only leaf commands are ever actually invoked. If a command
/// has subcommands, then one of those must always be chosen.
abstract class PubCommand extends Command {
  SystemCache get cache {
    if (_cache == null) {
      _cache = new SystemCache.withSources(isOffline: isOffline);
    }
    return _cache;
  }
  SystemCache _cache;

  GlobalPackages get globals {
    if (_globals == null) {
      _globals = new GlobalPackages(cache);
    }
    return _globals;
  }
  GlobalPackages _globals;

  /// Gets the [Entrypoint] package for the current working directory.
  ///
  /// This will load the pubspec and fail with an error if the current directory
  /// is not a package.
  Entrypoint get entrypoint {
    // Lazy load it.
    if (_entrypoint == null) {
      _entrypoint = new Entrypoint(path.current, cache,
          packageSymlinks: globalResults['package-symlinks']);
    }
    return _entrypoint;
  }
  Entrypoint _entrypoint;

  /// The URL for web documentation for this command.
  String get docUrl => null;

  /// Override this and return `false` to disallow trailing options from being
  /// parsed after a non-option argument is parsed.
  bool get allowTrailingOptions => true;

  ArgParser get argParser {
    // Lazily initialize the parser because the superclass constructor requires
    // it but we want to initialize it based on [allowTrailingOptions].
    if (_argParser == null) {
      _argParser = new ArgParser(allowTrailingOptions: allowTrailingOptions);
    }
    return _argParser;
  }
  ArgParser _argParser;

  /// Override this to use offline-only sources instead of hitting the network.
  ///
  /// This will only be called before the [SystemCache] is created. After that,
  /// it has no effect. This only needs to be set in leaf commands.
  bool get isOffline => false;

  String get usageFooter {
    if (docUrl == null) return null;
    return "See $docUrl for detailed documentation.";
  }

  void printUsage() {
    log.message(usage);
  }

  /// Parses a user-supplied integer [intString] named [name].
  ///
  /// If the parsing fails, prints a usage message and exits.
  int parseInt(String intString, String name) {
    try {
      return int.parse(intString);
    } on FormatException catch (_) {
      usageException('Could not parse $name "$intString".');
    }
  }
}
