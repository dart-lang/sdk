// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.barback;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

import '../command.dart';
import '../io.dart';
import '../log.dart' as log;
import '../utils.dart';

final _arrow = getSpecial('\u2192', '=>');

/// The set of top level directories in the entrypoint package that are built
/// when the user does "--all".
final _allSourceDirectories = new Set<String>.from([
  "benchmark", "bin", "example", "test", "web"
]);

/// Shared base class for [BuildCommand] and [ServeCommand].
abstract class BarbackCommand extends PubCommand {
  /// The build mode.
  BarbackMode get mode => new BarbackMode(argResults["mode"]);

  /// The directories in the entrypoint package that should be added to the
  /// build environment.
  final sourceDirectories = new Set<String>();

  /// The default build mode.
  BarbackMode get defaultMode => BarbackMode.RELEASE;

  /// Override this to specify the default source directories if none are
  /// provided on the command line.
  List<String> get defaultSourceDirectories;

  BarbackCommand() {
    argParser.addOption("mode", defaultsTo: defaultMode.toString(),
        help: "Mode to run transformers in.");

    argParser.addFlag("all",
        help: "Use all default source directories.",
        defaultsTo: false, negatable: false);
  }

  Future run() {
    // Switch to JSON output if specified. We need to do this before parsing
    // the source directories so an error will be correctly reported in JSON
    // format.
    log.json.enabled = argResults.options.contains("format") &&
        argResults["format"] == "json";

    _parseSourceDirectories();
    return onRunTransformerCommand();
  }

  /// Override this to run the actual command.
  Future onRunTransformerCommand();

  /// Parses the command-line arguments to determine the set of source
  /// directories to add to the build environment.
  ///
  /// If there are no arguments, this will just be [defaultSourceDirectories].
  ///
  /// If the `--all` flag is set, then it will be all default directories
  /// that exist.
  ///
  /// Otherwise, all arguments should be the paths of directories to include.
  ///
  /// Throws an exception if the arguments are invalid.
  void _parseSourceDirectories() {
    if (argResults["all"]) {
      _addAllDefaultSources();
      return;
    }

    // If no directories were specified, use the defaults.
    if (argResults.rest.isEmpty) {
      _addDefaultSources();
      return;
    }

    sourceDirectories.addAll(argResults.rest);

    // Prohibit "lib".
    var disallowed = sourceDirectories.where((dir) {
      var parts = path.split(path.normalize(dir));
      return parts.isNotEmpty && parts.first == "lib";
    });

    if (disallowed.isNotEmpty) {
      usageException(_directorySentence(disallowed, "is", "are", "not allowed"));
    }

    // Make sure the source directories don't reach out of the package.
    var invalid = sourceDirectories.where((dir) => !path.isWithin('.', dir));
    if (invalid.isNotEmpty) {
      usageException(_directorySentence(invalid, "isn't", "aren't",
          "in this package"));
    }

    // Make sure all of the source directories exist.
    var missing = sourceDirectories.where(
        (dir) => !dirExists(entrypoint.root.path(dir)));

    if (missing.isNotEmpty) {
      dataError(_directorySentence(missing, "does", "do", "not exist"));
    }

    // Make sure the directories don't overlap.
    var sources = sourceDirectories.toList();
    var overlapping = new Set();
    for (var i = 0; i < sources.length; i++) {
      for (var j = i + 1; j < sources.length; j++) {
        if (path.isWithin(sources[i], sources[j]) ||
            path.isWithin(sources[j], sources[i])) {
          overlapping.add(sources[i]);
          overlapping.add(sources[j]);
        }
      }
    }

    if (overlapping.isNotEmpty) {
      usageException(_directorySentence(overlapping, "cannot", "cannot",
          "overlap"));
    }
  }

  /// Handles "--all" by adding all default source directories that are
  /// present.
  void _addAllDefaultSources() {
    if (argResults.rest.isNotEmpty) {
      usageException(
          'Directory names are not allowed if "--all" is passed.');
    }

    // Include every build directory that exists in the package.
    var dirs = _allSourceDirectories.where(
        (dir) => dirExists(entrypoint.root.path(dir)));

    if (dirs.isEmpty) {
      var defaultDirs = toSentence(_allSourceDirectories.map(
          (name) => '"$name"'));
      dataError('There are no source directories present.\n'
          'The default directories are $defaultDirs.');
    }

    sourceDirectories.addAll(dirs);
  }

  /// Adds the default sources that should be used if no directories are passed
  /// on the command line.
  void _addDefaultSources() {
    sourceDirectories.addAll(defaultSourceDirectories.where(
        (dir) => dirExists(entrypoint.root.path(dir))));

    // TODO(rnystrom): Hackish. Assumes there will only be one or two
    // default sources. That's true for pub build and serve, but isn't as
    // general as it could be.
    if (sourceDirectories.isEmpty) {
      var defaults;
      if (defaultSourceDirectories.length == 1) {
        defaults = 'a "${defaultSourceDirectories.first}" directory';
      } else {
        defaults = '"${defaultSourceDirectories[0]}" and/or '
            '"${defaultSourceDirectories[1]}" directories';
      }

      dataError("Your package must have $defaults,\n"
          "or you must specify the source directories.");
    }
  }

  /// Converts a list of [directoryNames] to a sentence.
  ///
  /// After the list of directories, [singularVerb] will be used if there is
  /// only one directory and [pluralVerb] will be used if there are more than
  /// one. Then [suffix] is added to the end of the sentence, and, finally, a
  /// period is added.
  String _directorySentence(Iterable<String> directoryNames,
      String singularVerb, String pluralVerb, String suffix) {
    var directories = pluralize('Directory', directoryNames.length,
        plural: 'Directories');
    var names = toSentence(directoryNames.map((dir) => '"$dir"'));
    var verb = pluralize(singularVerb, directoryNames.length,
        plural: pluralVerb);

    var result = "$directories $names $verb";
    if (suffix != null) result += " $suffix";
    result += ".";

    return result;
  }
}
