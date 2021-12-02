// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'driver.dart';
import 'input_converter.dart';
import 'operation.dart';

/// Launch and interact with the analysis server.
void main(List<String> rawArgs) {
  var logger = Logger('Performance Measurement Client');
  logger.onRecord.listen((LogRecord rec) {
    print(rec.message);
  });
  var args = parseArgs(rawArgs);

  var driver = Driver(diagnosticPort: args.diagnosticPort);
  var stream = openInput(args);
  late StreamSubscription<Operation?> subscription;
  subscription = stream.listen((Operation? op) {
    var future = driver.perform(op!);
    if (future != null) {
      logger.log(Level.FINE, 'pausing operations for ${op.runtimeType}');
      subscription.pause(future.then((_) {
        logger.log(Level.FINE, 'resuming operations');
      }));
    }
  }, onDone: () {
    subscription.cancel();
    driver.stopServer(SHUTDOWN_TIMEOUT);
  }, onError: (e, s) {
    subscription.cancel();
    logger.log(Level.SEVERE, '$e\n$s');
    driver.stopServer(SHUTDOWN_TIMEOUT);
  });
  driver.runComplete.then((Results results) {
    results.printResults();
  }).whenComplete(() {
    return subscription.cancel();
  });
}

const DIAGNOSTIC_PORT_OPTION = 'diagnosticPort';
const HELP_CMDLINE_OPTION = 'help';
const INPUT_CMDLINE_OPTION = 'input';
const MAP_OPTION = 'map';

/// The amount of time to give the server to respond to a shutdown request
/// before forcibly terminating it.
const Duration SHUTDOWN_TIMEOUT = Duration(seconds: 25);

const TMP_SRC_DIR_OPTION = 'tmpSrcDir';
const VERBOSE_CMDLINE_OPTION = 'verbose';
const VERY_VERBOSE_CMDLINE_OPTION = 'vv';

late final ArgParser argParser = () {
  var argParser = ArgParser();

  argParser.addOption(INPUT_CMDLINE_OPTION,
      abbr: 'i',
      help: '<filePath>\n'
          'The input file specifying how this client should interact with the server.\n'
          'If the input file name is "stdin", then the instructions are read from standard input.');
  argParser.addMultiOption(MAP_OPTION,
      abbr: 'm',
      splitCommas: false,
      help: '<oldSrcPath>,<newSrcPath>\n'
          'This option defines a mapping from the original source directory <oldSrcPath>\n'
          'when the instrumentation or log file was generated\n'
          'to the target source directory <newSrcPath> used during performance testing.\n'
          'Multiple mappings can be specified.\n'
          'WARNING: The contents of the target directory will be modified');
  argParser.addOption(TMP_SRC_DIR_OPTION,
      abbr: 't',
      help: '<dirPath>\n'
          'The temporary directory containing source used during performance measurement.\n'
          'WARNING: The contents of the target directory will be modified');
  argParser.addOption(DIAGNOSTIC_PORT_OPTION,
      abbr: 'd',
      help: 'localhost port on which server will provide diagnostic web pages');
  argParser.addFlag(VERBOSE_CMDLINE_OPTION,
      abbr: 'v', help: 'Verbose logging', negatable: false);
  argParser.addFlag(VERY_VERBOSE_CMDLINE_OPTION,
      help: 'Extra verbose logging', negatable: false);
  argParser.addFlag(HELP_CMDLINE_OPTION,
      abbr: 'h', help: 'Print this help information', negatable: false);
  return argParser;
}();

/// Open and return the input stream specifying how this client
/// should interact with the analysis server.
Stream<Operation?> openInput(PerfArgs args) {
  var logger = Logger('openInput');
  Stream<List<int>> inputRaw;
  if (args.inputPath == 'stdin') {
    inputRaw = stdin;
  } else {
    inputRaw = File(args.inputPath).openRead();
  }
  for (var entry in args.srcPathMap.entries) {
    logger.log(
        Level.INFO,
        'mapping source path\n'
        '  from ${entry.oldSrcPrefix}\n  to   ${entry.newSrcPrefix}');
  }
  logger.log(Level.INFO, 'tmpSrcDir: ${args.tmpSrcDirPath}');
  return inputRaw
      .cast<List<int>>()
      .transform(systemEncoding.decoder)
      .transform(LineSplitter())
      .transform(InputConverter(args.tmpSrcDirPath, args.srcPathMap));
}

/// Parse the command line arguments.
PerfArgs parseArgs(List<String> rawArgs) {
  ArgResults args;
  var perfArgs = PerfArgs();
  try {
    args = argParser.parse(rawArgs);
  } on Exception catch (e) {
    print(e);
    printHelp();
    exit(1);
  }
  var helpArg = args[HELP_CMDLINE_OPTION] as bool;
  var showHelp = helpArg || args.rest.isNotEmpty;

  var inputArg = args[INPUT_CMDLINE_OPTION];
  if (inputArg is! String || inputArg.isEmpty) {
    print('missing $INPUT_CMDLINE_OPTION argument');
    showHelp = true;
  } else {
    perfArgs.inputPath = inputArg;
  }

  var mapArg = args[MAP_OPTION] as List<Object?>;
  for (var pair in mapArg) {
    if (pair is String) {
      var index = pair.indexOf(',');
      if (index != -1 && !pair.contains(',', index + 1)) {
        var oldSrcPrefix = _withTrailingSeparator(pair.substring(0, index));
        var newSrcPrefix = _withTrailingSeparator(pair.substring(index + 1));
        if (Directory(newSrcPrefix).existsSync()) {
          perfArgs.srcPathMap.add(oldSrcPrefix, newSrcPrefix);
          continue;
        }
      }
    }
    print('must specify $MAP_OPTION <oldSrcPath>,<newSrcPath>');
    showHelp = true;
  }

  var tmpSrcDirPathArg = args[TMP_SRC_DIR_OPTION];
  if (tmpSrcDirPathArg is! String || tmpSrcDirPathArg.isEmpty) {
    print('missing $TMP_SRC_DIR_OPTION argument');
    showHelp = true;
  } else {
    perfArgs.tmpSrcDirPath = _withTrailingSeparator(tmpSrcDirPathArg);
  }

  var portText = args[DIAGNOSTIC_PORT_OPTION];
  if (portText is String) {
    if (int.tryParse(portText) == null) {
      print('invalid $DIAGNOSTIC_PORT_OPTION: $portText');
      showHelp = true;
    } else {
      perfArgs.diagnosticPort = int.tryParse(portText);
    }
  }

  var verboseArg = args[VERY_VERBOSE_CMDLINE_OPTION] as bool;
  if (verboseArg || rawArgs.contains('-vv')) {
    Logger.root.level = Level.FINE;
  } else if (verboseArg) {
    Logger.root.level = Level.INFO;
  } else {
    Logger.root.level = Level.WARNING;
  }

  if (showHelp) {
    printHelp();
    exit(1);
  }

  return perfArgs;
}

void printHelp() {
  print('');
  print('Launch and interact with the AnalysisServer');
  print('');
  print(argParser.usage);
}

/// Ensure that the given path has a trailing separator
String _withTrailingSeparator(String dirPath) {
  if (dirPath.length > 4) {
    if (!dirPath.endsWith(path.separator)) {
      return '$dirPath${path.separator}';
    }
  }
  return dirPath;
}

/// The performance measurement arguments specified on the command line.
class PerfArgs {
  /// The file path of the instrumentation or log file
  /// used to drive performance measurement,
  /// or 'stdin' if this information should be read from standard input.
  late String inputPath;

  /// A mapping from the original source directory
  /// when the instrumentation or log file was generated
  /// to the target source directory used during performance testing.
  final PathMap srcPathMap = PathMap();

  /// The temporary directory containing source used during performance
  /// measurement.
  late String tmpSrcDirPath;

  /// The diagnostic port for Analysis Server or `null` if none.
  int? diagnosticPort;
}
