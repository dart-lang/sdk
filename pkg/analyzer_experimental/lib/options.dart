// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library options;

import 'package:args/args.dart';

import 'dart:io';


const _BINARY_NAME = 'analyzer';
const _SDK_ENV = 'com.google.dart.sdk';
final _DEFAULT_SDK_LOCATION = Platform.environment[_SDK_ENV];

/**
 * Analyzer commandline configuration options.
 */
class CommandLineOptions {

  /** Batch mode (for unit testing) */
  final bool shouldBatch;

  /** Whether to use machine format for error display */
  final bool machineFormat;

  /** Whether to ignore unrecognized flags */
  final bool ignoreUnrecognizedFlags;

  /** Whether to print metrics */
  final bool showMetrics;

  /** Whether to treat warnings as fatal */
  final bool warningsAreFatal;

  /** The path to the dart SDK */
  final String dartSdkPath;

  /** The source files to analyze */
  final List<String> sourceFiles;

  /**
   * Initialize options from the given parsed [args].
   */
  CommandLineOptions._fromArgs(ArgResults args)
    : shouldBatch = args['batch'],
      machineFormat = args['machine_format'],
      ignoreUnrecognizedFlags = args['ignore_unrecognized_flags'],
      showMetrics = args['metrics'],
      warningsAreFatal = args['fatal_warnings'],
      dartSdkPath = args['dart_sdk'],
      sourceFiles = args.rest;

  /**
   * Parse [args] into [CommandLineOptions] describing the specified
   * analyzer options.  In case of a format error, [null] is returned.
   */
  factory CommandLineOptions.parse(List<String> args) {

    var parser = new _CommandLineParser()
      ..addFlag('batch', abbr: 'b', help: 'Run in batch mode',
          defaultsTo: false, negatable: false)
      ..addOption('dart_sdk', help: 'Specify path to the Dart sdk',
          defaultsTo: _DEFAULT_SDK_LOCATION)
      ..addFlag('machine_format', help: 'Specify whether errors '
        'should be in machine format',
          defaultsTo: false, negatable: false)
      ..addFlag('ignore_unrecognized_flags',
          help: 'Ignore unrecognized command line flags',
          defaultsTo: false, negatable: false)
      ..addFlag('fatal_warnings', help: 'Treat non-type warnings as fatal',
          defaultsTo: false, negatable: false)
       ..addFlag('metrics', help: 'Print metrics',
          defaultsTo: false, negatable: false)
      ..addFlag('help', abbr: 'h', help: 'Display this help message',
          defaultsTo: false, negatable: false);

    try {
      var results = parser.parse(args);
      if (results['help'] || results.rest.length == 0) {
        _showUsage(parser);
        return null;
      }
      return new CommandLineOptions._fromArgs(results);
    } on FormatException catch (e) {
      print(e.message);
      _showUsage(parser);
      return null;
    }

  }

  static _showUsage(parser) {
    print('Usage: ${_BINARY_NAME} [options...] '
      '<libraries to analyze...>');
    print(parser.getUsage());
  }

}

/**
 * Commandline argument parser.
 *
 * TODO(pquitslund): when the args package supports ignoring unrecognized
 * options/flags, this class can be replaced with a simple [ArgParser] instance.
 */
class _CommandLineParser {

  final List<String> _knownFlags;
  final ArgParser _parser;

  /** Creates a new command line parser */
  _CommandLineParser()
    : _knownFlags = <String>[],
      _parser = new ArgParser();


  /**
   * Defines a flag.
   *
   * See [ArgParser.addFlag()].
   */
  void addFlag(String name, {String abbr, String help, bool defaultsTo: false,
      bool negatable: true, void callback(bool value)}) {
    _knownFlags.add(name);
    _parser.addFlag(name, abbr: abbr, help: help, defaultsTo: defaultsTo,
        negatable: negatable, callback: callback);
  }

  /**
   * Defines a value-taking option.
   *
   * See [ArgParser.addOption()].
   */
  void addOption(String name, {String abbr, String help, List<String> allowed,
      Map<String, String> allowedHelp, String defaultsTo,
      void callback(value), bool allowMultiple: false}) {
    _parser.addOption(name, abbr: abbr, help: help, allowed: allowed,
        allowedHelp: allowedHelp, defaultsTo: defaultsTo, callback: callback,
        allowMultiple: allowMultiple);
  }


  /**
   * Generates a string displaying usage information for the defined options.
   *
   * See [ArgParser.getUsage()].
   */
  String getUsage() => _parser.getUsage();

  /**
   * Parses [args], a list of command-line arguments, matches them against the
   * flags and options defined by this parser, and returns the result.
   *
   * See [ArgParser].
   */
  ArgResults parse(List<String> args) => _parser.parse(_filterUnknowns(args));

  List<String> _filterUnknowns(args) {

    // Only filter args if the ignore flag is specified.
    if (!args.contains('--ignore_unrecognized_flags')) {
      return args;
    }

    //TODO(pquitslund): replace w/ the following once library skew issues are sorted out
    //return args.where((arg) => !arg.startsWith('--') ||
    //  _knownFlags.contains(arg.substring(2)));

    // Filter all unrecognized flags and options.
    var filtered = <String>[];
    for (var i=0; i < args.length; ++i) {
      var arg = args[i];
      if (arg.startsWith('--') && arg.length > 2) {
        if (!_knownFlags.contains(arg.substring(2))) {
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

  _getNextFlagIndex(args, i) {
    for ( ; i < args.length; ++i) {
      if (args[i].startsWith('--')) {
        return i;
      }
    }
    return i;
  }

}

