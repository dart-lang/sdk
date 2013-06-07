// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library options;

import 'package:args/args.dart';

import 'dart:io';


const _BINARY_NAME = 'dartanalyzer';

/**
 * Analyzer commandline configuration options.
 */
class CommandLineOptions {

  /** Batch mode (for unit testing) */
  final bool shouldBatch;

  /** Whether to use machine format for error display */
  final bool machineFormat;

  /** Whether to display version information */
  final bool displayVersion;

  /** Whether to ignore unrecognized flags */
  final bool ignoreUnrecognizedFlags;

  /** Whether to show package: warnings */
  final bool showPackageWarnings;

  /** Whether to show SDK warnings */
  final bool showSdkWarnings;

  /** Whether to treat warnings as fatal */
  final bool warningsAreFatal;

  /** The path to the dart SDK */
  final String dartSdkPath;

  /** The path to the package root */
  final String packageRootPath;

  /** The source files to analyze */
  final List<String> sourceFiles;

  /**
   * Initialize options from the given parsed [args].
   */
  CommandLineOptions._fromArgs(ArgResults args)
    : shouldBatch = args['batch'],
      machineFormat = args['machine'],
      displayVersion = args['version'],
      ignoreUnrecognizedFlags = args['ignore-unrecognized-flags'],
      showPackageWarnings = args['show-package-warnings'],
      showSdkWarnings = args['show-sdk-warnings'],
      warningsAreFatal = args['fatal-warnings'],
      dartSdkPath = args['dart-sdk'],
      packageRootPath = args['package-root'],
      sourceFiles = args.rest;

  /**
   * Parse [args] into [CommandLineOptions] describing the specified
   * analyzer options. In case of a format error, prints error and exists.
   */
  static CommandLineOptions parse(List<String> args) {
    CommandLineOptions options = _parse(args);
    // check SDK
    {
      var sdkPath = options.dartSdkPath;
      // check that SDK is specified
      if (sdkPath == null) {
        print('Usage: $_BINARY_NAME: no Dart SDK found.');
        exit(15);
      }
      // check that SDK is existing directory
      if (!(new Directory(sdkPath)).existsSync()) {
        print('Usage: $_BINARY_NAME: invalid Dart SDK path: $sdkPath');
        exit(15);
      }
    }
    // OK
    return options;
  }

  static CommandLineOptions _parse(List<String> args) {
    args = args.expand((String arg) => arg.split('=')).toList();
    var parser = new _CommandLineParser()
      ..addFlag('batch', abbr: 'b', help: 'Run in batch mode',
          defaultsTo: false, negatable: false)
      ..addOption('dart-sdk', help: 'The path to the Dart SDK')
      ..addOption('package-root', help: 'The path to the package root')
      ..addFlag('machine',
          help: 'Print errors in a format suitable for parsing',
          defaultsTo: false, negatable: false)
      ..addFlag('version', help: 'Print the analyzer version',
          defaultsTo: false, negatable: false)
      ..addFlag('ignore-unrecognized-flags',
          help: 'Ignore unrecognized command line flags',
          defaultsTo: false, negatable: false)
      ..addFlag('fatal-warnings', help: 'Treat non-type warnings as fatal',
          defaultsTo: false, negatable: false)
      ..addFlag('show-package-warnings',
          help: 'Show warnings from package: imports',
          defaultsTo: false, negatable: false)
      ..addFlag('show-sdk-warnings', help: 'Show warnings from SDK imports',
          defaultsTo: false, negatable: false)
      ..addFlag('help', abbr: 'h', help: 'Display this help message',
          defaultsTo: false, negatable: false);

    try {
      // TODO(scheglov) https://code.google.com/p/dart/issues/detail?id=11061
      args = args.map((String arg) => arg == '-batch' ? '--batch' : arg).toList();
      var results = parser.parse(args);
      // help requests
      if (results['help']) {
        _showUsage(parser);
        exit(0);
      }
      // batch mode and input files
      if (results['batch']) {
        if (results.rest.isNotEmpty) {
          print('No source files expected in the batch mode.');
          _showUsage(parser);
          exit(15);
        }
      } else if (results['version']) {
        print('$_BINARY_NAME version ${_getVersion()}');
        exit(0);
      } else {
        if (results.rest.isEmpty) {
          _showUsage(parser);
          exit(15);
        }
      }
      return new CommandLineOptions._fromArgs(results);
    } on FormatException catch (e) {
      print(e.message);
      _showUsage(parser);
      exit(15);
    }

  }

  static _showUsage(parser) {
    print('Usage: $_BINARY_NAME [options...] <libraries to analyze...>');
    print(parser.getUsage());
    print('');
    print('For more information, see http://www.dartlang.org/tools/analyzer.');
  }

  static String _getVersion() {
    try {
      Path path = new Path(new Options().script);
      Path versionPath = path.directoryPath.append('..').append('version');
      File versionFile = new File.fromPath(versionPath);
      return versionFile.readAsStringSync().trim();
    } catch (_) {
      // This happens when the script is not running in the context of an SDK.
      return "<unknown>";
    }
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
    _knownFlags.add(name);
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
    if (!args.contains('--ignore-unrecognized-flags')) {
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
          print('remove: $arg');
          //"eat" params by advancing to the next flag/option
          i = _getNextFlagIndex(args, i);
        } else {
          filtered.add(arg);
        }
      } else {
        filtered.add(arg);
      }
    }

    print(filtered);
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
