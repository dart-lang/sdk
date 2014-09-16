// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library debugger;

import "dart:async";
import "dart:io";

import "package:ddbg/commando.dart";
import "package:observatory/service_io.dart";

class Debugger {
  Commando cmdo;
  var _cmdoSubscription;

  VM _vm;
  VM get vm => _vm;
  set vm(VM vm) {
    if (_vm == vm) {
      // Do nothing.
      return;
    }
    if (_vm != null) {
      _vm.disconnect();
    }
    if (vm != null) {
      vm.onConnect.then(_vmConnected);
      vm.onDisconnect.then(_vmDisconnected);
      vm.errors.stream.listen(_onServiceError);
      vm.exceptions.stream.listen(_onServiceException);
      vm.events.stream.listen(_onServiceEvent);
    }
    _vm = vm;
  }

  _vmConnected(VM vm) {
    cmdo.print('Connected to vm');
  }

  _vmDisconnected(VM vm) {
    cmdo.print('Disconnected from vm');
  }

  _onServiceError(ServiceError error) {
    cmdo.print('error $error');
  }

  _onServiceException(ServiceException exception) {
    cmdo.print('${exception.message}');
  }

  _onServiceEvent(ServiceEvent event) {
    switch (event.eventType) {
      case 'GC':
        // Ignore GC events for now.
        break;
      default:
        cmdo.print('event $event');
        break;
    }
  }

  VM _isolate;
  VM get isolate => _isolate;
  set isolate(Isolate isolate) {
    _isolate = isolate;
    cmdo.print('Current isolate is now isolate ${getIsolateIndex(_isolate)}');
  }

  Map _isolateIndexMap = new Map();
  int _nextIsolateIndex = 0;
  int getIsolateIndex(Isolate isolate) {
    var index = _isolateIndexMap[isolate.id];
    if (index == null) {
      index = _nextIsolateIndex++;
      _isolateIndexMap[isolate.id] = index;
    }
    return index;
  }

  void onUncaughtError(error, StackTrace trace) {
    if (error is ServiceException ||
        error is ServiceError) {
      // These are handled elsewhere.  Ignore.
      return;
    }
    cmdo.print('\n--------\nExiting due to unexpected error:\n'
                '  $error\n$trace\n');
    quit();
  }

  Debugger() {
    cmdo = new Commando(completer: completeCommand);
    _cmdoSubscription = cmdo.commands.listen(_processCommand,
                                             onError: _cmdoError,
                                             onDone: _cmdoDone);
  }

  Future _closeCmdo() {
    var sub = _cmdoSubscription;
    _cmdoSubscription = null;
    cmdo = null;

    var future = sub.cancel();
    if (future != null) {
      return future;
    } else {
      return new Future.value();
    }
  }

  Future quit() {
    return Future.wait([_closeCmdo()]).then((_) {
        exit(0);
      });
  }

  void _cmdoError(self, parent, zone, error, StackTrace trace) {
    cmdo.print('\n--------\nExiting due to unexpected error:\n'
               '  $error\n$trace\n');
    quit();
  }

  void _cmdoDone() {
    quit();
  }

  void _processCommand(String cmdLine) {
    void huh() {
      cmdo.print("'$cmdLine' not understood, try 'help' for help.");
    }

    cmdo.hide();
    cmdLine = cmdLine.trim();
    var args = cmdLine.split(' ');
    if (args.length == 0) {
      return;
    }
    var command = args[0];
    var matches = matchCommand(command, true);
    if (matches.length == 0) {
      huh();
      cmdo.show();
    } else if (matches.length == 1) {
      matches[0].run(this, args).then((_) {
          cmdo.show();
        });
    } else {
      var matchNames = matches.map((handler) => handler.name);
      cmdo.print("Ambigous command '$command' : ${matchNames.toList()}");
      cmdo.show();
    }
  }

}

// Every debugger command extends this base class.
abstract class Command {
  String get name;
  String get helpShort;
  void printHelp(Debugger debugger, List<String> args);
  Future run(Debugger debugger, List<String> args);
}

class AttachCommand extends Command {
  final name = 'attach';
  final helpShort = 'Attach to a running Dart VM';
  void printHelp(Debugger debugger, List<String> args) {
    debugger.cmdo.print('''
----- attach -----

Attach to the Dart VM running at the indicated host:port. If no
host:port is provided, attach to the VM running on the default port.

Usage:
  attach
  attach <host:port>
''');
  }

  Future run(Debugger debugger, List<String> args) {
    var cmdo = debugger.cmdo;
    if (args.length > 2) {
      cmdo.print('$name expects 0 or 1 arguments');
      return new Future.value();
    }
    String hostPort = 'localhost:8181';
    if (args.length > 1) {
      hostPort = args[1];
    }

    debugger.vm = new WebSocketVM(new WebSocketVMTarget('ws://${hostPort}/ws'));
    return debugger.vm.load().then((vm) {
        if (debugger.isolate == null) {
          for (var isolate in vm.isolates) {
            if (isolate.name == 'root') {
              debugger.isolate = isolate;
            }
          }
        }
      });
  }
}

class DetachCommand extends Command {
  final name = 'detach';
  final helpShort = 'Detach from a running Dart VM';
  void printHelp(Debugger debugger, List<String> args) {
    cmdo.print('''
----- detach -----

Detach from the Dart VM.

Usage:
  detach
''');
  }

  Future run(Debugger debugger, List<String> args) {
    var cmdo = debugger.cmdo;
    if (args.length > 1) {
      cmdo.print('$name expects no arguments');
      return new Future.value();
    }
    if (debugger.vm == null) {
      cmdo.print('No VM is attached');
    } else {
      debugger.vm = null;
    }
    return new Future.value();
  }
}

class HelpCommand extends Command {
  final name = 'help';
  final helpShort = 'Show a list of debugger commands';
  void printHelp(Debugger debugger, List<String> args) {
    debugger.cmdo.print('''
----- help -----

Show a list of debugger commands or get more information about a
particular command.

Usage:
  help
  help <command>
''');
  }

  Future run(Debugger debugger, List<String> args) {
    var cmdo = debugger.cmdo;
    if (args.length <= 1) {
      cmdo.print("\nDebugger commands:\n");
      for (var command in commandList) {
        cmdo.print('  ${command.name.padRight(11)} ${command.helpShort}');
      }
      cmdo.print("For more information about a particular command, type:\n\n"
                  "  help <command>\n");

      cmdo.print("Commands may be abbreviated: e.g. type 'h' for 'help.\n");
    } else {
      var commandName = args[1];
      var matches = matchCommand(commandName, true);
      if (matches.length == 0) {
        cmdo.print("Command '$commandName' not recognized.  "
                    "Try 'help' for a list of commands.");
      } else {
        for (var command in matches) {
          command.printHelp(debugger, args);
        }
      }
    }

    return new Future.value();
  }
}

class IsolateCommand extends Command {
  final name = 'isolate';
  final helpShort = 'Isolate control';
  void printHelp(Debugger debugger, List<String> args) {
    debugger.cmdo.print('''
----- isolate -----

List all isolates.

Usage:
  isolate
  isolate list

Set current isolate.

Usage:
  isolate <id>
''');
  }

  Future run(Debugger debugger, List<String> args) {
    var cmdo = debugger.cmdo;
    if (args.length == 1 ||
        (args.length == 2 && args[1] == 'list')) {
      return _listIsolates(debugger);
    } else if (args.length == 2) {
      cmdo.print('UNIMPLEMENTED');
      return new Future.value();
    } else {
      if (args.length > 1) {
        cmdo.print('Unrecognized isolate command');
        printHelp(debugger, []);
        return new Future.value();
      }
    }
  }
    
  Future _listIsolates(Debugger debugger) {
    var cmdo = debugger.cmdo;
    if (debugger.vm == null) {
      cmdo.print('No VM is attached');
      return new Future.value();
    }
    return debugger.vm.reload().then((vm) {
        // Sort the isolates by their indices.
        var isolates = vm.isolates.toList();
        isolates.sort((iso1, iso2) {
            return (debugger.getIsolateIndex(iso1) -
                    debugger.getIsolateIndex(iso2));
          });

        StringBuffer sb = new StringBuffer();
        cmdo.print('  ID       NAME         STATE');
        cmdo.print('-----------------------------------------------');
        for (var isolate in isolates) {
          if (isolate == debugger.isolate) {
            sb.write('* ');
          } else {
            sb.write('  ');
          }
          sb.write(debugger.getIsolateIndex(isolate).toString().padRight(8));
          sb.write(' ');
          sb.write(isolate.name.padRight(12));
          sb.write(' ');
          if (isolate.pauseEvent != null) {
            switch (isolate.pauseEvent.eventType) {
              case 'IsolateCreated':
                sb.write('paused at isolate start');
                break;
              case 'IsolateShutdown':
                sb.write('paused at isolate exit');
                break;
              case 'IsolateInterrupted':
                sb.write('paused');
                break;
              case 'BreakpointReached':
                sb.write('paused by breakpoint');
                break;
              case 'ExceptionThrown':
                sb.write('paused by exception');
                break;
              default:
                sb.write('paused by unknown cause');
                break;
            }
          } else if (isolate.running) {
            sb.write('running');
          } else if (isolate.idle) {
            sb.write('idle');
          } else if (isolate.loading) {
            // TODO(turnidge): This is weird in a command line debugger.
            sb.write('(not available)');
          }
          sb.write('\n');
        }
        cmdo.print(sb);
      });
    return new Future.value();
  }
}

class QuitCommand extends Command {
  final name = 'quit';
  final helpShort = 'Quit the debugger.';
  void printHelp(Debugger debugger, List<String> args) {
    debugger.cmdo.print('''
----- quit -----

Quit the debugger.

Usage:
  quit
''');
  }

  Future run(Debugger debugger, List<String> args) {
    var cmdo = debugger.cmdo;
    if (args.length > 1) {
      cmdo.print("Unexpected arguments to $name command.");
      return new Future.value();
    }
    return debugger.quit();
  }
}

List<Command> commandList =
    [ new AttachCommand(),
      new DetachCommand(),
      new HelpCommand(),
      new IsolateCommand(),
      new QuitCommand() ];

List<Command> matchCommand(String commandName, bool exactMatchWins) {
  var matches = [];
  for (var command in commandList) {
    if (command.name.startsWith(commandName)) {
      if (exactMatchWins && command.name == commandName) {
        // Exact match
        return [command];
      } else {
        matches.add(command);
      }
    }
  }
  return matches;
}

List<String> completeCommand(List<String> commandParts) {
  var completions = new List<String>();
  if (commandParts.length == 1) {
    String prefix = commandParts[0];
    for (var command in commandList) {
      if (command.name.startsWith(prefix)) {
        completions.add(command.name);
      }
    }
  }
  return completions;
}
