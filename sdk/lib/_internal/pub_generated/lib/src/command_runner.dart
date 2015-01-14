// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command_runner;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;
import 'package:stack_trace/stack_trace.dart';

import 'command/build.dart';
import 'command/cache.dart';
import 'command/deps.dart';
import 'command/downgrade.dart';
import 'command/get.dart';
import 'command/global.dart';
import 'command/lish.dart';
import 'command/list_package_dirs.dart';
import 'command/run.dart';
import 'command/serve.dart';
import 'command/upgrade.dart';
import 'command/uploader.dart';
import 'command/version.dart';
import 'exceptions.dart';
import 'exit_codes.dart' as exit_codes;
import 'http.dart';
import 'io.dart';
import 'log.dart' as log;
import 'sdk.dart' as sdk;
import 'solver/version_solver.dart';
import 'utils.dart';

class PubCommandRunner extends CommandRunner {
  String get usageFooter =>
      "See http://dartlang.org/tools/pub for detailed " "documentation.";

  PubCommandRunner()
      : super("pub", "Pub is a package manager for Dart.") {
    argParser.addFlag('version', negatable: false, help: 'Print pub version.');
    argParser.addFlag(
        'trace',
        help: 'Print debugging information when an error occurs.');
    argParser.addOption(
        'verbosity',
        help: 'Control output verbosity.',
        allowed: ['normal', 'io', 'solver', 'all'],
        allowedHelp: {
      'normal': 'Show errors, warnings, and user messages.',
      'io': 'Also show IO operations.',
      'solver': 'Show steps during version resolution.',
      'all': 'Show all output including internal tracing messages.'
    });
    argParser.addFlag(
        'verbose',
        abbr: 'v',
        negatable: false,
        help: 'Shortcut for "--verbosity=all".');
    argParser.addFlag(
        'with-prejudice',
        hide: !isAprilFools,
        negatable: false,
        help: 'Execute commands with prejudice.');
    argParser.addFlag(
        'package-symlinks',
        hide: true,
        negatable: true,
        defaultsTo: true);

    addCommand(new BuildCommand());
    addCommand(new CacheCommand());
    addCommand(new DepsCommand());
    addCommand(new DowngradeCommand());
    addCommand(new GlobalCommand());
    addCommand(new GetCommand());
    addCommand(new ListPackageDirsCommand());
    addCommand(new LishCommand());
    addCommand(new RunCommand());
    addCommand(new ServeCommand());
    addCommand(new UpgradeCommand());
    addCommand(new UploaderCommand());
    addCommand(new VersionCommand());
  }

  Future run(List<String> arguments) {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        var options;
        join0() {
          new Future.value(runCommand(options)).then((x0) {
            try {
              x0;
              completer0.complete();
            } catch (e0, s0) {
              completer0.completeError(e0, s0);
            }
          }, onError: completer0.completeError);
        }
        catch0(error, s1) {
          try {
            if (error is UsageException) {
              log.error(error.message);
              new Future.value(flushThenExit(exit_codes.USAGE)).then((x1) {
                try {
                  x1;
                  join0();
                } catch (e1, s2) {
                  completer0.completeError(e1, s2);
                }
              }, onError: completer0.completeError);
            } else {
              throw error;
            }
          } catch (error, s1) {
            completer0.completeError(error, s1);
          }
        }
        try {
          options = super.parse(arguments);
          join0();
        } catch (e2, s3) {
          catch0(e2, s3);
        }
      } catch (e, s) {
        completer0.completeError(e, s);
      }
    });
    return completer0.future;
  }

  Future runCommand(ArgResults options) {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        log.withPrejudice = options['with-prejudice'];
        join0() {
          join1() {
            break0() {
              log.fine('Pub ${sdk.version}');
              new Future.value(_validatePlatform()).then((x0) {
                try {
                  x0;
                  var captureStackChains =
                      options['trace'] ||
                      options['verbose'] ||
                      options['verbosity'] == 'all';
                  join2() {
                    completer0.complete();
                  }
                  catch0(error, chain) {
                    try {
                      log.exception(error, chain);
                      join3() {
                        new Future.value(
                            flushThenExit(_chooseExitCode(error))).then((x1) {
                          try {
                            x1;
                            join2();
                          } catch (e0, s0) {
                            completer0.completeError(e0, s0);
                          }
                        }, onError: completer0.completeError);
                      }
                      if (options['trace']) {
                        log.dumpTranscript();
                        join3();
                      } else {
                        join4() {
                          join3();
                        }
                        if (!isUserFacingException(error)) {
                          log.error("""
This is an unexpected error. Please run

    pub --trace ${options.arguments.map(((arg) {
                          return "'$arg'";
                        })).join(' ')}

and include the results in a bug report on http://dartbug.com/new.
""");
                          join4();
                        } else {
                          join4();
                        }
                      }
                    } catch (error, chain) {
                      completer0.completeError(error, chain);
                    }
                  }
                  try {
                    new Future.value(captureErrors((() {
                      return super.runCommand(options);
                    }), captureStackChains: captureStackChains)).then((x2) {
                      try {
                        x2;
                        new Future.value(
                            flushThenExit(exit_codes.SUCCESS)).then((x3) {
                          try {
                            x3;
                            join2();
                          } catch (e1, s1) {
                            catch0(e1, s1);
                          }
                        }, onError: catch0);
                      } catch (e2, s2) {
                        catch0(e2, s2);
                      }
                    }, onError: catch0);
                  } catch (e3, s3) {
                    catch0(e3, s3);
                  }
                } catch (e4, s4) {
                  completer0.completeError(e4, s4);
                }
              }, onError: completer0.completeError);
            }
            switch (options['verbosity']) {
              case 'normal':
                log.verbosity = log.Verbosity.NORMAL;
                break0();
              case 'io':
                log.verbosity = log.Verbosity.IO;
                break0();
              case 'solver':
                log.verbosity = log.Verbosity.SOLVER;
                break0();
              case 'all':
                log.verbosity = log.Verbosity.ALL;
                break0();
              default:
                join5() {
                  break0();
                }
                if (options['verbose']) {
                  log.verbosity = log.Verbosity.ALL;
                  join5();
                } else {
                  join5();
                }
            }
          }
          if (options['trace']) {
            log.recordTranscript();
            join1();
          } else {
            join1();
          }
        }
        if (options['version']) {
          log.message('Pub ${sdk.version}');
          completer0.complete(null);
        } else {
          join0();
        }
      } catch (e, s) {
        completer0.completeError(e, s);
      }
    });
    return completer0.future;
  }

  void printUsage() {
    log.message(usage);
  }

  /// Returns the appropriate exit code for [exception], falling back on 1 if no
  /// appropriate exit code could be found.
  int _chooseExitCode(exception) {
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

  /// Checks that pub is running on a supported platform.
  ///
  /// If it isn't, it prints an error message and exits. Completes when the
  /// validation is done.
  Future _validatePlatform() {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        join0() {
          new Future.value(runProcess('ver', [])).then((x0) {
            try {
              var result = x0;
              join1() {
                completer0.complete();
              }
              if (result.stdout.join('\n').contains('XP')) {
                log.error('Sorry, but pub is not supported on Windows XP.');
                new Future.value(flushThenExit(exit_codes.USAGE)).then((x1) {
                  try {
                    x1;
                    join1();
                  } catch (e0, s0) {
                    completer0.completeError(e0, s0);
                  }
                }, onError: completer0.completeError);
              } else {
                join1();
              }
            } catch (e1, s1) {
              completer0.completeError(e1, s1);
            }
          }, onError: completer0.completeError);
        }
        if (Platform.operatingSystem != 'windows') {
          completer0.complete(null);
        } else {
          join0();
        }
      } catch (e, s) {
        completer0.completeError(e, s);
      }
    });
    return completer0.future;
  }
}
