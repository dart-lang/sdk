// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';

/**
 * Commandline argument parser.
 *
 * TODO(pq): when the args package supports ignoring unrecognized options/flags,
 * this class can be replaced with a simple [ArgParser] instance.
 */
class CommandLineParser {
  static const String IGNORE_UNRECOGNIZED_FLAG = 'ignore-unrecognized-flags';

  final List<String> _knownFlags;
  final bool _alwaysIgnoreUnrecognized;
  final ArgParser _parser;

  /// Creates a new command line parser.
  CommandLineParser({bool alwaysIgnoreUnrecognized: false})
      : _knownFlags = <String>[],
        _alwaysIgnoreUnrecognized = alwaysIgnoreUnrecognized,
        _parser = new ArgParser(allowTrailingOptions: true) {
    addFlag(IGNORE_UNRECOGNIZED_FLAG,
        help: 'Ignore unrecognized command line flags.',
        defaultsTo: false,
        negatable: false);
  }

  ArgParser get parser => _parser;

  /// Defines a flag.
  /// See [ArgParser.addFlag()].
  void addFlag(String name,
      {String abbr,
      String help,
      bool defaultsTo: false,
      bool negatable: true,
      void callback(bool value),
      bool hide: false}) {
    _knownFlags.add(name);
    _parser.addFlag(name,
        abbr: abbr,
        help: help,
        defaultsTo: defaultsTo,
        negatable: negatable,
        callback: callback,
        hide: hide);
  }

  /// Defines a value-taking option.
  /// See [ArgParser.addOption()].
  void addOption(String name,
      {String abbr,
      String help,
      List<String> allowed,
      Map<String, String> allowedHelp,
      String defaultsTo,
      void callback(value),
      bool allowMultiple: false,
      bool splitCommas,
      bool hide: false}) {
    _knownFlags.add(name);
    _parser.addOption(name,
        abbr: abbr,
        help: help,
        allowed: allowed,
        allowedHelp: allowedHelp,
        defaultsTo: defaultsTo,
        callback: callback,
        allowMultiple: allowMultiple,
        splitCommas: splitCommas,
        hide: hide);
  }

  /// Parses [args], a list of command-line arguments, matches them against the
  /// flags and options defined by this parser, and returns the result.
  /// See [ArgParser].
  ArgResults parse(List<String> args) => _parser.parse(_filterUnknowns(args));

  List<String> _filterUnknowns(List<String> args) {
    if (!_alwaysIgnoreUnrecognized &&
        !args.contains('--$IGNORE_UNRECOGNIZED_FLAG')) {
      return args;
    }

    //TODO(pquitslund): replace w/ the following once library skew issues are
    // sorted out
    //return args.where((arg) => !arg.startsWith('--') ||
    //  _knownFlags.contains(arg.substring(2)));

    // Filter all unrecognized flags and options.
    List<String> filtered = <String>[];
    for (int i = 0; i < args.length; ++i) {
      String arg = args[i];
      if (arg.startsWith('--') && arg.length > 2) {
        String option = arg.substring(2);
        // strip the last '=value'
        int equalsOffset = option.lastIndexOf('=');
        if (equalsOffset != -1) {
          option = option.substring(0, equalsOffset);
        }
        // Check the option
        if (!_knownFlags.contains(option)) {
          //"eat" params by advancing to the next flag/option
          i = _getNextFlagIndex(args, i);
        } else {
          filtered.add(arg);
        }
      } else {
        filtered.add(arg);
      }
    }

    return filtered;
  }

  int _getNextFlagIndex(args, i) {
    for (; i < args.length; ++i) {
      if (args[i].startsWith('--')) {
        return i;
      }
    }
    return i;
  }
}
