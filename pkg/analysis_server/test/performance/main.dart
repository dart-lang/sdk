library server.performance;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';

import 'driver.dart';
import 'input_converter.dart';
import 'operation.dart';

/**
 * Launch and interact with the analysis server.
 */
main(List<String> rawArgs) {
  Logger logger = new Logger('Performance Measurement Client');
  logger.onRecord.listen((LogRecord rec) {
    print(rec.message);
  });
  Driver driver = new Driver(logger);

  ArgResults args = parseArgs(rawArgs);
  Stream<Operation> stream = openInput(args);
  StreamSubscription<Operation> subscription;
  subscription = stream.listen((Operation op) {
    Future future = driver.perform(op);
    if (future != null) {
      logger.log(Level.FINE, 'pausing operations for ${op.runtimeType}');
      subscription.pause(future.then((_) {
        logger.log(Level.FINE, 'resuming operations');
      }));
    }
  }, onDone: () {
    subscription.cancel();
    driver.stopServer();
  }, onError: (e, s) {
    subscription.cancel();
    logger.log(Level.WARNING, '$e\n$s');
    driver.stopServer();
    throw e;
  });
  driver.runComplete.then((Results results) {
    results.printResults();
  }).whenComplete(() {
    return subscription.cancel();
  });
}

const HELP_CMDLINE_OPTION = 'help';
const INPUT_CMDLINE_OPTION = 'input';
const VERBOSE_CMDLINE_OPTION = 'verbose';
const VERY_VERBOSE_CMDLINE_OPTION = 'vv';

/**
 * Open and return the input stream specifying how this client
 * should interact with the analysis server.
 */
Stream<Operation> openInput(ArgResults args) {
  Stream<List<int>> inputRaw;
  String inputPath = args[INPUT_CMDLINE_OPTION];
  if (inputPath == null) {
    return null;
  }
  if (inputPath == 'stdin') {
    inputRaw = stdin;
  } else {
    inputRaw = new File(inputPath).openRead();
  }
  return inputRaw
      .transform(SYSTEM_ENCODING.decoder)
      .transform(new LineSplitter())
      .transform(new InputConverter());
}

/**
 * Parse the command line arguments.
 */
ArgResults parseArgs(List<String> rawArgs) {
  ArgParser parser = new ArgParser();

  parser.addOption(INPUT_CMDLINE_OPTION,
      abbr: 'i',
      help: 'The input file specifying how this client should interact '
      'with the server. If the input file name is "stdin", '
      'then the instructions are read from standard input.');
  parser.addFlag(VERBOSE_CMDLINE_OPTION,
      abbr: 'v', help: 'Verbose logging', negatable: false);
  parser.addFlag(VERY_VERBOSE_CMDLINE_OPTION,
      help: 'Extra verbose logging', negatable: false);
  parser.addFlag(HELP_CMDLINE_OPTION,
      abbr: 'h', help: 'Print this help information', negatable: false);

  ArgResults args = parser.parse(rawArgs);
  bool showHelp = args[HELP_CMDLINE_OPTION] || args.rest.isNotEmpty;

  if (args[INPUT_CMDLINE_OPTION] == null ||
      args[INPUT_CMDLINE_OPTION].isEmpty) {
    print('missing "input" argument');
    showHelp = true;
  }
  
  if (args[VERY_VERBOSE_CMDLINE_OPTION] || rawArgs.contains('-vv')) {
    Logger.root.level = Level.FINE;
  } else if (args[VERBOSE_CMDLINE_OPTION]) {
    Logger.root.level = Level.INFO;
  } else {
    Logger.root.level = Level.WARNING;
  }

  if (showHelp) {
    print('');
    print('Launch and interact with the AnalysisServer');
    print(parser.usage);
    exit(1);
  }

  return args;
}
