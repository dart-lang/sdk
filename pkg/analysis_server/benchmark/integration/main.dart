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
  subscription = stream.listen(
    (Operation? op) {
      var future = driver.perform(op!);
      if (future != null) {
        logger.log(Level.FINE, 'pausing operations for ${op.runtimeType}');
        subscription.pause(
          future.then((_) {
            logger.log(Level.FINE, 'resuming operations');
          }),
        );
      }
    },
    onDone: () {
      subscription.cancel();
      driver.stopServer(shutdownTimeout);
    },
    onError: (e, s) {
      subscription.cancel();
      logger.log(Level.SEVERE, '$e\n$s');
      driver.stopServer(shutdownTimeout);
    },
  );
  driver.runComplete
      .then((Results results) {
        results.printResults();
      })
      .whenComplete(() {
        return subscription.cancel();
      });
}

const diagnosticPortOption = 'diagnosticPort';
const helpOption = 'help';
const inputOption = 'input';
const mapOption = 'map';

/// The amount of time to give the server to respond to a shutdown request
/// before forcibly terminating it.
const Duration shutdownTimeout = Duration(seconds: 25);

const tmpSrcDirOption = 'tmpSrcDir';
const verboseOption = 'verbose';
const veryVerboseOption = 'vv';

final argParser = ArgParser()
  ..addOption(
    inputOption,
    abbr: 'i',
    help:
        '<filePath>\n'
        'The input file specifying how this client should interact with the server.\n'
        'If the input file name is "stdin", then the instructions are read from standard input.',
  )
  ..addMultiOption(
    mapOption,
    abbr: 'm',
    splitCommas: false,
    help:
        '<oldSrcPath>,<newSrcPath>\n'
        'This option defines a mapping from the original source directory <oldSrcPath>\n'
        'when the instrumentation or log file was generated\n'
        'to the target source directory <newSrcPath> used during performance testing.\n'
        'Multiple mappings can be specified.\n'
        'WARNING: The contents of the target directory will be modified',
  )
  ..addOption(
    tmpSrcDirOption,
    abbr: 't',
    help:
        '<dirPath>\n'
        'The temporary directory containing source used during performance measurement.\n'
        'WARNING: The contents of the target directory will be modified',
  )
  ..addOption(
    diagnosticPortOption,
    abbr: 'd',
    help: 'localhost port on which server will provide diagnostic web pages',
  )
  ..addFlag(verboseOption, abbr: 'v', help: 'Verbose logging', negatable: false)
  ..addFlag(veryVerboseOption, help: 'Extra verbose logging', negatable: false)
  ..addFlag(
    helpOption,
    abbr: 'h',
    help: 'Print this help information',
    negatable: false,
  );

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
      '  from ${entry.oldSrcPrefix}\n  to   ${entry.newSrcPrefix}',
    );
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
  var helpArg = args.flag(helpOption);
  var showHelp = helpArg || args.rest.isNotEmpty;

  var inputArg = args.option(inputOption);
  if (inputArg == null || inputArg.isEmpty) {
    print('missing $inputOption argument');
    showHelp = true;
  } else {
    perfArgs.inputPath = inputArg;
  }

  var mapArg = args.multiOption(mapOption);
  for (var pair in mapArg) {
    var index = pair.indexOf(',');
    if (index != -1 && !pair.contains(',', index + 1)) {
      var oldSrcPrefix = _withTrailingSeparator(pair.substring(0, index));
      var newSrcPrefix = _withTrailingSeparator(pair.substring(index + 1));
      if (Directory(newSrcPrefix).existsSync()) {
        perfArgs.srcPathMap.add(oldSrcPrefix, newSrcPrefix);
        continue;
      }
    }
    print('must specify $mapOption <oldSrcPath>,<newSrcPath>');
    showHelp = true;
  }

  var tmpSrcDirPathArg = args.option(tmpSrcDirOption);
  if (tmpSrcDirPathArg == null || tmpSrcDirPathArg.isEmpty) {
    print('missing $tmpSrcDirOption argument');
    showHelp = true;
  } else {
    perfArgs.tmpSrcDirPath = _withTrailingSeparator(tmpSrcDirPathArg);
  }

  var portText = args.option(diagnosticPortOption);
  if (portText != null) {
    var port = int.tryParse(portText);
    if (port == null) {
      print('invalid $diagnosticPortOption: $portText');
      showHelp = true;
    } else {
      perfArgs.diagnosticPort = port;
    }
  }

  var verboseArg = args.flag(veryVerboseOption);
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
