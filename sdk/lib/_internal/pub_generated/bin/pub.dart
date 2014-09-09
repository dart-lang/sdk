import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';
import '../lib/src/command.dart';
import '../lib/src/exceptions.dart';
import '../lib/src/exit_codes.dart' as exit_codes;
import '../lib/src/http.dart';
import '../lib/src/io.dart';
import '../lib/src/log.dart' as log;
import '../lib/src/sdk.dart' as sdk;
import '../lib/src/solver/version_solver.dart';
import '../lib/src/utils.dart';
void main(List<String> arguments) {
  ArgResults options;
  try {
    options = PubCommand.pubArgParser.parse(arguments);
  } on FormatException catch (e) {
    log.error(e.message);
    log.error('Run "pub help" to see available options.');
    flushThenExit(exit_codes.USAGE);
    return;
  }
  log.withPrejudice = options['with-prejudice'];
  if (options['version']) {
    log.message('Pub ${sdk.version}');
    return;
  }
  if (options['help']) {
    PubCommand.printGlobalUsage();
    return;
  }
  if (options['trace']) {
    log.recordTranscript();
  }
  switch (options['verbosity']) {
    case 'normal':
      log.verbosity = log.Verbosity.NORMAL;
      break;
    case 'io':
      log.verbosity = log.Verbosity.IO;
      break;
    case 'solver':
      log.verbosity = log.Verbosity.SOLVER;
      break;
    case 'all':
      log.verbosity = log.Verbosity.ALL;
      break;
    default:
      if (options['verbose']) {
        log.verbosity = log.Verbosity.ALL;
      }
      break;
  }
  log.fine('Pub ${sdk.version}');
  var cacheDir;
  if (Platform.environment.containsKey('PUB_CACHE')) {
    cacheDir = Platform.environment['PUB_CACHE'];
  } else if (Platform.operatingSystem == 'windows') {
    var appData = Platform.environment['APPDATA'];
    cacheDir = path.join(appData, 'Pub', 'Cache');
  } else {
    cacheDir = '${Platform.environment['HOME']}/.pub-cache';
  }
  validatePlatform().then((_) => runPub(cacheDir, options, arguments));
}
void runPub(String cacheDir, ArgResults options, List<String> arguments) {
  var captureStackChains =
      options['trace'] ||
      options['verbose'] ||
      options['verbosity'] == 'all';
  captureErrors(
      () => invokeCommand(cacheDir, options),
      captureStackChains: captureStackChains).catchError((error, Chain chain) {
    log.exception(error, chain);
    if (options['trace']) {
      log.dumpTranscript();
    } else if (!isUserFacingException(error)) {
      log.error("""
This is an unexpected error. Please run

    pub --trace ${arguments.map((arg) => "'$arg'").join(' ')}

and include the results in a bug report on http://dartbug.com/new.
""");
    }
    return flushThenExit(chooseExitCode(error));
  }).then((_) {
    return flushThenExit(exit_codes.SUCCESS);
  });
}
int chooseExitCode(exception) {
  while (exception is WrappedException) exception = exception.innerError;
  if (exception is HttpException ||
      exception is http.ClientException ||
      exception is SocketException ||
      exception is PubHttpException ||
      exception is DependencyNotFoundException) {
    return exit_codes.UNAVAILABLE;
  } else if (exception is FormatException || exception is DataException) {
    return exit_codes.DATA;
  } else if (exception is UsageException) {
    return exit_codes.USAGE;
  } else {
    return 1;
  }
}
Future invokeCommand(String cacheDir, ArgResults mainOptions) {
  final completer0 = new Completer();
  scheduleMicrotask(() {
    try {
      var commands = PubCommand.mainCommands;
      var command;
      var commandString = "pub";
      var options = mainOptions;
      break0(x2) {
        join0() {
          join1(x0) {
            completer0.complete(null);
          }
          finally0(cont0, v0) {
            command.cache.deleteTempDir();
            cont0(v0);
          }
          catch0(e0) {
            finally0(join1, null);
          }
          try {
            finally0((v1) {
              completer0.complete(v1);
            }, command.run(cacheDir, mainOptions, options));
          } catch (e1) {
            catch0(e1);
          }
        }
        if (!command.takesArguments && options.rest.isNotEmpty) {
          command.usageError(
              'Command "${options.name}" does not take any arguments.');
          join0();
        } else {
          join0();
        }
      }
      continue0(x3) {
        if (commands.isNotEmpty) {
          Future.wait([]).then((x1) {
            join2() {
              options = options.command;
              command = commands[options.name];
              commands = command.subcommands;
              commandString += " ${options.name}";
              join3() {
                continue0(null);
              }
              if (options['help']) {
                command.printUsage();
                completer0.complete(new Future.value());
              } else {
                join3();
              }
            }
            if (options.command == null) {
              join4() {
                join2();
              }
              if (options.rest.isEmpty) {
                join5() {
                  command.usageError(
                      'Missing subcommand for "${commandString}".');
                  join4();
                }
                if (command == null) {
                  PubCommand.printGlobalUsage();
                  completer0.complete(new Future.value());
                } else {
                  join5();
                }
              } else {
                join6() {
                  command.usageError(
                      'Could not find a subcommand named '
                          '"${options.rest[0]}" for "${commandString}".');
                  join4();
                }
                if (command == null) {
                  PubCommand.usageErrorWithCommands(
                      commands,
                      'Could not find a command named "${options.rest[0]}".');
                  join6();
                } else {
                  join6();
                }
              }
            } else {
              join2();
            }
          });
        } else {
          break0(null);
        }
      }
      continue0(null);
    } catch (e2) {
      completer0.completeError(e2);
    }
  });
  return completer0.future;
}
Future validatePlatform() {
  final completer0 = new Completer();
  scheduleMicrotask(() {
    try {
      join0() {
        runProcess('ver', []).then((x0) {
          try {
            var result = x0;
            join1() {
              completer0.complete(null);
            }
            if (result.stdout.join('\n').contains('XP')) {
              log.error('Sorry, but pub is not supported on Windows XP.');
              flushThenExit(exit_codes.USAGE).then((x1) {
                try {
                  x1;
                  join1();
                } catch (e1) {
                  completer0.completeError(e1);
                }
              }, onError: (e2) {
                completer0.completeError(e2);
              });
            } else {
              join1();
            }
          } catch (e0) {
            completer0.completeError(e0);
          }
        }, onError: (e3) {
          completer0.completeError(e3);
        });
      }
      if (Platform.operatingSystem != 'windows') {
        completer0.complete(null);
      } else {
        join0();
      }
    } catch (e4) {
      completer0.completeError(e4);
    }
  });
  return completer0.future;
}
