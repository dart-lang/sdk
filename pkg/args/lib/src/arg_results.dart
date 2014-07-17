// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library args.src.arg_results;

import 'package:collection/wrappers.dart';

import 'arg_parser.dart';

/// Creates a new [ArgResults].
///
/// Since [ArgResults] doesn't have a public constructor, this lets [Parser]
/// get to it. This function isn't exported to the public API of the package.
ArgResults newArgResults(ArgParser parser, Map<String, dynamic> parsed,
      String name, ArgResults command, List<String> rest) {
  return new ArgResults._(parser, parsed, name, command, rest);
}

/// The results of parsing a series of command line arguments using
/// [ArgParser.parse()].
///
/// Includes the parsed options and any remaining unparsed command line
/// arguments.
class ArgResults {
  /// The [ArgParser] whose options were parsed for these results.
  final ArgParser _parser;

  /// The option values that were parsed from arguments.
  final Map<String, dynamic> _parsed;

  /// If these are the results for parsing a command's options, this will be the
  /// name of the command. For top-level results, this returns `null`.
  final String name;

  /// The command that was selected, or `null` if none was.
  ///
  /// This will contain the options that were selected for that command.
  final ArgResults command;

  /// The remaining command-line arguments that were not parsed as options or
  /// flags.
  ///
  /// If `--` was used to separate the options from the remaining arguments,
  /// it will not be included in this list unless parsing stopped before the
  /// `--` was reached.
  final List<String> rest;

  /// Creates a new [ArgResults].
  ArgResults._(this._parser, this._parsed, this.name, this.command,
      List<String> rest)
      : this.rest = new UnmodifiableListView(rest);

  /// Gets the parsed command-line option named [name].
  operator [](String name) {
    if (!_parser.options.containsKey(name)) {
      throw new ArgumentError('Could not find an option named "$name".');
    }

    return _parser.options[name].getOrDefault(_parsed[name]);
  }

  /// Get the names of the available options as an [Iterable].
  ///
  /// This includes the options whose values were parsed or that have defaults.
  /// Options that weren't present and have no default will be omitted.
  Iterable<String> get options {
    var result = new Set.from(_parsed.keys);

    // Include the options that have defaults.
    _parser.options.forEach((name, option) {
      if (option.defaultValue != null) result.add(name);
    });

    return result;
  }

  /// Returns `true` if the option with [name] was parsed from an actual
  /// argument.
  ///
  /// Returns `false` if it wasn't provided and the default value or no default
  /// value would be used instead.
  bool wasParsed(String name) {
    var option = _parser.options[name];
    if (option == null) {
      throw new ArgumentError('Could not find an option named "$name".');
    }

    return _parsed.containsKey(name);
  }
}
