// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library args;

import 'package:collection/wrappers.dart';

import 'src/parser.dart';
import 'src/usage.dart';
import 'src/options.dart';
export 'src/options.dart';

/// A class for taking a list of raw command line arguments and parsing out
/// options and flags from them.
class ArgParser {
  final Map<String, Option> _options;
  final Map<String, ArgParser> _commands;

  /// The options that have been defined for this parser.
  final Map<String, Option> options;

  /// The commands that have been defined for this parser.
  final Map<String, ArgParser> commands;

  /// Whether or not this parser parses options that appear after non-option
  /// arguments.
  final bool allowTrailingOptions;

  /// Creates a new ArgParser.
  ///
  /// If [allowTrailingOptions] is set, the parser will continue parsing even
  /// after it finds an argument that is neither an option nor a command.
  /// This allows options to be specified after regular arguments. Defaults to
  /// `false`.
  factory ArgParser({bool allowTrailingOptions}) =>
      new ArgParser._(<String, Option>{}, <String, ArgParser>{},
          allowTrailingOptions: allowTrailingOptions);

  ArgParser._(Map<String, Option> options, Map<String, ArgParser> commands,
      {bool allowTrailingOptions}) :
    this._options = options,
    this.options = new UnmodifiableMapView(options),
    this._commands = commands,
    this.commands = new UnmodifiableMapView(commands),
    this.allowTrailingOptions = allowTrailingOptions != null ?
        allowTrailingOptions : false;

  /// Defines a command.
  ///
  /// A command is a named argument which may in turn define its own options and
  /// subcommands using the given parser. If [parser] is omitted, implicitly
  /// creates a new one. Returns the parser for the command.
  ArgParser addCommand(String name, [ArgParser parser]) {
    // Make sure the name isn't in use.
    if (_commands.containsKey(name)) {
      throw new ArgumentError('Duplicate command "$name".');
    }

    if (parser == null) parser = new ArgParser();
    _commands[name] = parser;
    return parser;
  }

  /// Defines a flag. Throws an [ArgumentError] if:
  ///
  /// * There is already an option named [name].
  /// * There is already an option using abbreviation [abbr].
  void addFlag(String name, {String abbr, String help, bool defaultsTo: false,
      bool negatable: true, void callback(bool value), bool hide: false}) {
    _addOption(name, abbr, help, null, null, null, defaultsTo, callback,
        isFlag: true, negatable: negatable, hide: hide);
  }

  /// Defines a value-taking option. Throws an [ArgumentError] if:
  ///
  /// * There is already an option with name [name].
  /// * There is already an option using abbreviation [abbr].
  void addOption(String name, {String abbr, String help, String valueHelp,
      List<String> allowed, Map<String, String> allowedHelp, String defaultsTo,
      void callback(value), bool allowMultiple: false, bool hide: false}) {
    _addOption(name, abbr, help, valueHelp, allowed, allowedHelp, defaultsTo,
        callback, isFlag: false, allowMultiple: allowMultiple,
        hide: hide);
  }

  void _addOption(String name, String abbr, String help, String valueHelp,
      List<String> allowed, Map<String, String> allowedHelp, defaultsTo,
      void callback(value), {bool isFlag, bool negatable: false,
      bool allowMultiple: false, bool hide: false}) {
    // Make sure the name isn't in use.
    if (_options.containsKey(name)) {
      throw new ArgumentError('Duplicate option "$name".');
    }

    // Make sure the abbreviation isn't too long or in use.
    if (abbr != null) {
      var existing = findByAbbreviation(abbr);
      if (existing != null) {
        throw new ArgumentError(
            'Abbreviation "$abbr" is already used by "${existing.name}".');
      }
    }

    _options[name] = new Option(name, abbr, help, valueHelp, allowed,
        allowedHelp, defaultsTo, callback, isFlag: isFlag, negatable: negatable,
        allowMultiple: allowMultiple, hide: hide);
  }

  /// Parses [args], a list of command-line arguments, matches them against the
  /// flags and options defined by this parser, and returns the result.
  ArgResults parse(List<String> args) =>
      new Parser(null, this, args.toList(), null, null).parse();

  /// Generates a string displaying usage information for the defined options.
  ///
  /// This is basically the help text shown on the command line.
  String getUsage() => new Usage(this).generate();

  /// Get the default value for an option. Useful after parsing to test if the
  /// user specified something other than the default.
  getDefault(String option) {
    if (!options.containsKey(option)) {
      throw new ArgumentError('No option named $option');
    }
    return options[option].defaultValue;
  }

  /// Finds the option whose abbreviation is [abbr], or `null` if no option has
  /// that abbreviation.
  Option findByAbbreviation(String abbr) {
    return options.values.firstWhere((option) => option.abbreviation == abbr,
        orElse: () => null);
  }
}

/// The results of parsing a series of command line arguments using
/// [ArgParser.parse()].
///
/// Includes the parsed options and any remaining unparsed command line
/// arguments.
class ArgResults {
  final Map<String, dynamic> _options;

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
  ArgResults(this._options, this.name, this.command, List<String> rest)
    : this.rest = new UnmodifiableListView(rest);

  /// Gets the parsed command-line option named [name].
  operator [](String name) {
    if (!_options.containsKey(name)) {
      throw new ArgumentError(
          'Could not find an option named "$name".');
    }

    return _options[name];
  }

  /// Get the names of the options as an [Iterable].
  Iterable<String> get options => _options.keys;
}

