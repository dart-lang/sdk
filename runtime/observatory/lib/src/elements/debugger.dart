// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library debugger_page_element;

import 'dart:async';
import 'dart:html';
import 'observatory_element.dart';
import 'package:observatory/cli.dart';
import 'package:observatory/debugger.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

// TODO(turnidge): Move Debugger, DebuggerCommand to debugger library.
abstract class DebuggerCommand extends Command {
  ObservatoryDebugger debugger;

  DebuggerCommand(this.debugger, name, children)
      : super(name, children);

  String get helpShort;
  String get helpLong;
}

// TODO(turnidge): Rewrite HelpCommand so that it is a general utility
// provided by the cli library.
class HelpCommand extends DebuggerCommand {
  HelpCommand(Debugger debugger) : super(debugger, 'help', []);

  Future run(List<String> args) {
    var con = debugger.console;
    if (args.length == 0) {
      // Print list of all top-level commands.
      var commands = debugger.cmd.matchCommand([], false);
      commands.sort((a, b) => a.name.compareTo(b.name));
      con.print('List of commands:\n');
      for (var command in commands) {
        con.print('${command.name.padRight(12)} - ${command.helpShort}');
      }
      con.print(
          "\nFor more information on a specific command type 'help <command>'\n"
          "\n"
          "Command prefixes are accepted (e.g. 'h' for 'help')\n"
          "Hit [TAB] to complete a command (try 'i[TAB][TAB]')\n"
          "Hit [ENTER] to repeat the last command\n");
      return new Future.value(null);
    } else {
      // Print any matching commands.
      var commands = debugger.cmd.matchCommand(args, true);
      commands.sort((a, b) => a.name.compareTo(b.name));
      if (commands.isEmpty) {
        var line = args.join(' ');
        con.print("No command matches '${line}'");
        return new Future.value(null);
      }
      con.print('');
      for (var command in commands) {
        con.printBold(command.fullName);
        con.print(command.helpLong);

        var newArgs = [];
        newArgs.addAll(args.take(args.length - 1));
        newArgs.add(command.name);
        newArgs.add('');
        var subCommands = debugger.cmd.matchCommand(newArgs, false);
        subCommands.remove(command);
        if (subCommands.isNotEmpty) {
          subCommands.sort((a, b) => a.name.compareTo(b.name));
          con.print('Subcommands:\n');
          for (var subCommand in subCommands) {
            con.print('    ${subCommand.fullName.padRight(16)} '
                      '- ${subCommand.helpShort}');
          }
          con.print('');
        }
      }
      return new Future.value(null);
    }
  }

  Future<List<String>> complete(List<String> args) {
    var commands = debugger.cmd.matchCommand(args, false);
    var result = commands.map((command) => '${command.fullName} ');
    return new Future.value(result);
  }

  String helpShort = 'List commands or provide details about a specific command';

  String helpLong =
      'List commands or provide details about a specific command.\n'
      '\n'
      'Syntax: help            - Show a list of all commands\n'
      '        help <command>  - Help for a specific command\n';
}

class PauseCommand extends DebuggerCommand {
  PauseCommand(Debugger debugger) : super(debugger, 'pause', []);

  Future run(List<String> args) {
    if (!debugger.isolatePaused()) {
      return debugger.isolate.pause();
    } else {
      debugger.console.print('The program is already paused');
      return new Future.value(null);
    }
  }

  String helpShort = 'Pause the isolate';

  String helpLong =
      'Pause the isolate.\n'
      '\n'
      'Syntax: pause\n';
}

class ContinueCommand extends DebuggerCommand {
  ContinueCommand(Debugger debugger) : super(debugger, 'continue', []);

  Future run(List<String> args) {
    if (debugger.isolatePaused()) {
      return debugger.isolate.resume().then((_) {
          debugger.warnOutOfDate();
        });
    } else {
      debugger.console.print('The program must be paused');
      return new Future.value(null);
    }
  }

  String helpShort = 'Resume execution of the isolate';

  String helpLong =
      'Continue running the isolate.\n'
      '\n'
      'Syntax: continue\n';
}

class NextCommand extends DebuggerCommand {
  NextCommand(Debugger debugger) : super(debugger, 'next', []);

  Future run(List<String> args) {
    if (debugger.isolatePaused()) {
      var event = debugger.isolate.pauseEvent;
      if (event.eventType == 'IsolateCreated') {
        debugger.console.print("Type 'continue' to start the isolate");
        return new Future.value(null);
      }
      if (event.eventType == 'IsolateShutdown') {
        debugger.console.print("Type 'continue' to exit the isolate");
        return new Future.value(null);
      }
      return debugger.isolate.stepOver();
    } else {
      debugger.console.print('The program is already running');
      return new Future.value(null);
    }
  }

  String helpShort =
      'Continue running the isolate until it reaches the next source location '
      'in the current function';

  String helpLong =
      'Continue running the isolate until it reaches the next source location '
      'in the current function.\n'
      '\n'
      'Syntax: next\n';
}

class StepCommand extends DebuggerCommand {
  StepCommand(Debugger debugger) : super(debugger, 'step', []);

  Future run(List<String> args) {
    if (debugger.isolatePaused()) {
      var event = debugger.isolate.pauseEvent;
      if (event.eventType == 'IsolateCreated') {
        debugger.console.print("Type 'continue' to start the isolate");
        return new Future.value(null);
      }
      if (event.eventType == 'IsolateShutdown') {
        debugger.console.print("Type 'continue' to exit the isolate");
        return new Future.value(null);
      }
      return debugger.isolate.stepInto();
    } else {
      debugger.console.print('The program is already running');
      return new Future.value(null);
    }
  }

  String helpShort =
      'Continue running the isolate until it reaches the  next source location';

  String helpLong =
      'Continue running the isolate until it reaches the next source '
      'location.\n'
      '\n'
      'Syntax: step\n';
}

class FinishCommand extends DebuggerCommand {
  FinishCommand(Debugger debugger) : super(debugger, 'finish', []);

  Future run(List<String> args) {
    if (debugger.isolatePaused()) {
      return debugger.isolate.stepOut();
    } else {
      debugger.console.print('The program is already running');
      return new Future.value(null);
    }
  }

  String helpShort =
      'Continue running the isolate until the current function exits';

  String helpLong =
      'Continue running the isolate until the current function exits.\n'
      '\n'
      'Syntax: finish\n';
}

class BreakCommand extends DebuggerCommand {
  BreakCommand(Debugger debugger) : super(debugger, 'break', []);

  Future run(List<String> args) {
    if (args.length > 1) {
      debugger.console.print('not implemented');
      return new Future.value(null);
    }
    var arg = (args.length == 0 ? '' : args[0]);
    return SourceLocation.parse(debugger, arg).then((loc) {
      if (loc.valid) {
        if (loc.function != null) {
          debugger.console.print(
              'Ignoring breakpoint at $loc: '
              'Function entry breakpoints not yet implemented');
          return null;
        }
        if (loc.col != null) {
          // TODO(turnidge): Add tokenPos breakpoint support.
          debugger.console.print(
              'Ignoring column: '
              'adding breakpoint at a specific column not yet implemented');
        }
        return debugger.isolate.addBreakpoint(loc.script, loc.line).then((result) {
          if (result is DartError) {
            debugger.console.print('Unable to set breakpoint at ${loc}');
          } else {
            // TODO(turnidge): Adding a duplicate breakpoint is
            // currently ignored.  May want to change the protocol to
            // inform us when this happens.

            // The BreakpointResolved event prints resolved
            // breakpoints already.  Just print the unresolved ones here.
            ServiceMap bpt = result;
            if (!bpt['resolved']) {
              var script = bpt['location']['script'];
              var bpId = bpt['breakpointNumber'];
              var tokenPos = bpt['location']['tokenPos'];
              return script.load().then((_) {
                var line = script.tokenToLine(tokenPos);
                var col = script.tokenToCol(tokenPos);
                debugger.console.print(
                    'Future breakpoint ${bpId} added at '
                    '${script.name}:${line}:${col}');
              });
            }
          }
        });
      } else {
        debugger.console.print(loc.errorMessage);
      }
    });
  }

  Future<List<String>> complete(List<String> args) {
    if (args.length != 1) {
      return new Future.value([]);
    }
    // TODO - fix SourceLocation complete
    return new Future.value(SourceLocation.complete(debugger, args[0]));
  }

  String helpShort = 'Add a breakpoint by source location or function name';

  String helpLong =
      'Add a breakpoint by source location or function name.\n'
      '\n'
      'Syntax: break                       '
      '- Break at the current position\n'
      '        break <line>                '
      '- Break at a line in the current script\n'
      '                                    '
      '  (e.g \'break 11\')\n'
      '        break <line>:<col>          '
      '- Break at a line:col in the current script\n'
      '                                    '
      '  (e.g \'break 11:8\')\n'
      '        break <script>:<line>       '
      '- Break at a line:col in a specific script\n'
      '                                    '
      '  (e.g \'break test.dart:11\')\n'
      '        break <script>:<line>:<col> '
      '- Break at a line:col in a specific script\n'
      '                                    '
      '  (e.g \'break test.dart:11:8\')\n'
      '        break <function>            '
      '- Break at the named function\n'
      '                                    '
      '  (e.g \'break main\' or \'break Class.someFunction\')\n';
}

class ClearCommand extends DebuggerCommand {
  ClearCommand(Debugger debugger) : super(debugger, 'clear', []);

  Future run(List<String> args) {
    if (args.length > 1) {
      debugger.console.print('not implemented');
      return new Future.value(null);
    }
    var arg = (args.length == 0 ? '' : args[0]);
    return SourceLocation.parse(debugger, arg).then((loc) {
      if (loc.valid) {
        if (loc.function != null) {
          debugger.console.print(
              'Ignoring breakpoint at $loc: '
              'Function entry breakpoints not yet implemented');
          return null;
        }
        if (loc.col != null) {
          // TODO(turnidge): Add tokenPos clear support.
          debugger.console.print(
              'Ignoring column: '
              'clearing breakpoint at a specific column not yet implemented');
        }

        for (var bpt in debugger.isolate.breakpoints) {
          var script = bpt['location']['script'];
          if (script.id == loc.script.id) {
            assert(script.loaded);
            var line = script.tokenToLine(bpt['location']['tokenPos']);
            if (line == loc.line) {
              return debugger.isolate.removeBreakpoint(bpt).then((result) {
                if (result is DartError) {
                  debugger.console.print(
                      'Unable to clear breakpoint at ${loc}: ${result.message}');
                  return;
                } else {
                  // TODO(turnidge): Add a BreakpointRemoved event to
                  // the service instead of printing here.
                  var bpId = bpt['breakpointNumber'];
                  debugger.console.print(
                      'Breakpoint ${bpId} removed at ${loc}');
                  return;
                }
              });
            }
          }
        }
        debugger.console.print('No breakpoint found at ${loc}');
      } else {
        debugger.console.print(loc.errorMessage);
      }
    });
  }

  Future<List<String>> complete(List<String> args) {
    if (args.length != 1) {
      return new Future.value([]);
    }
    return new Future.value(SourceLocation.complete(debugger, args[0]));
  }

  String helpShort = 'Remove a breakpoint by source location or function name';

  String helpLong =
      'Remove a breakpoint by source location or function name.\n'
      '\n'
      'Syntax: clear                       '
      '- Clear at the current position\n'
      '        clear <line>                '
      '- Clear at a line in the current script\n'
      '                                    '
      '  (e.g \'clear 11\')\n'
      '        clear <line>:<col>          '
      '- Clear at a line:col in the current script\n'
      '                                    '
      '  (e.g \'clear 11:8\')\n'
      '        clear <script>:<line>       '
      '- Clear at a line:col in a specific script\n'
      '                                    '
      '  (e.g \'clear test.dart:11\')\n'
      '        clear <script>:<line>:<col> '
      '- Clear at a line:col in a specific script\n'
      '                                    '
      '  (e.g \'clear test.dart:11:8\')\n'
      '        clear <function>            '
      '- Clear at the named function\n'
      '                                    '
      '  (e.g \'clear main\' or \'clear Class.someFunction\')\n';
}

// TODO(turnidge): Add argument completion.
class DeleteCommand extends DebuggerCommand {
  DeleteCommand(Debugger debugger) : super(debugger, 'delete', []);

  Future run(List<String> args) {
    if (args.length < 1) {
      debugger.console.print('delete expects one or more arguments');
      return new Future.value(null);
    }
    List toDelete = [];
    for (var arg in args) {
      int id = int.parse(arg);
      var bpt = null;
      for (var candidate in debugger.isolate.breakpoints) {
        if (candidate['breakpointNumber'] == id) {
          bpt = candidate;
          break;
        }
      }
      if (bpt == null) {
        debugger.console.print("Invalid breakpoint id '${id}'");
        return new Future.value(null);
      }
      toDelete.add(bpt);
    }
    List pending = [];
    for (var bpt in toDelete) {
      pending.add(debugger.isolate.removeBreakpoint(bpt).then((_) {
            var id = bpt['breakpointNumber'];
            debugger.console.print("Removed breakpoint $id");
          }));
    }
    return Future.wait(pending);
  }

  String helpShort = 'Remove a breakpoint by breakpoint id';

  String helpLong =
      'Remove a breakpoint by breakpoint id.\n'
      '\n'
      'Syntax: delete <bp-id>\n'
      '        delete <bp-id> <bp-id> ...\n';
}

class InfoBreakpointsCommand extends DebuggerCommand {
  InfoBreakpointsCommand(Debugger debugger)
      : super(debugger, 'breakpoints', []);

  Future run(List<String> args) {
    return debugger.isolate.reloadBreakpoints().then((_) {
      if (debugger.isolate.breakpoints.isEmpty) {
        debugger.console.print('No breakpoints');
      }
      for (var bpt in debugger.isolate.breakpoints) {
        var bpId = bpt['breakpointNumber'];
        var script = bpt['location']['script'];
        var tokenPos = bpt['location']['tokenPos'];
        var line = script.tokenToLine(tokenPos);
        var col = script.tokenToCol(tokenPos);
        var extras = new StringBuffer();
        if (!bpt['resolved']) {
          extras.write(' unresolved');
        }
        if (!bpt['enabled']) {
          extras.write(' disabled');
        }
        debugger.console.print(
            'Breakpoint ${bpId} at ${script.name}:${line}:${col}${extras}');
      }
    });
  }

  String helpShort = 'List all breakpoints';

  String helpLong =
      'List all breakpoints.\n'
      '\n'
      'Syntax: info breakpoints\n';
}

class InfoIsolatesCommand extends DebuggerCommand {
  InfoIsolatesCommand(Debugger debugger) : super(debugger, 'isolates', []);

  Future run(List<String> args) {
    for (var isolate in debugger.isolate.vm.isolates) {
      String current = (isolate == debugger.isolate ? ' *' : '');
      debugger.console.print(
          "Isolate ${isolate.id} '${isolate.name}'${current}");
    }
    return new Future.value(null);
  }

  String helpShort = 'List all isolates';

  String helpLong =
      'List all isolates.\n'
      '\n'
      'Syntax: info isolates\n';
}

class InfoCommand extends DebuggerCommand {
  InfoCommand(Debugger debugger) : super(debugger, 'info', [
      new InfoBreakpointsCommand(debugger),
      new InfoIsolatesCommand(debugger),
  ]);

  Future run(List<String> args) {
    debugger.console.print("'info' expects a subcommand (see 'help info')");
    return new Future.value(null);
  }

  String helpShort = 'Show information on a variety of topics';

  String helpLong =
      'Show information on a variety of topics.\n'
      '\n'
      'Syntax: info <subcommand>\n';
}

class RefreshCoverageCommand extends DebuggerCommand {
  RefreshCoverageCommand(Debugger debugger) : super(debugger, 'coverage', []);

  Future run(List<String> args) {
    Set<Script> scripts = debugger.stackElement.activeScripts();
    List pending = [];
    for (var script in scripts) {
      pending.add(script.refreshCoverage().then((_) {
          debugger.console.print('Refreshed coverage for ${script.name}');
        }));
    }
    return Future.wait(pending);
  }

  String helpShort = 'Refresh code coverage information for current frames';

  String helpLong =
      'Refresh code coverage information for current frames.\n'
      '\n'
      'Syntax: refresh coverage\n\n';
}

class RefreshStackCommand extends DebuggerCommand {
  RefreshStackCommand(Debugger debugger) : super(debugger, 'stack', []);

  Future run(List<String> args) {
    Set<Script> scripts = debugger.stackElement.activeScripts();
    List pending = [];
    return debugger.refreshStack();
  }

  String helpShort = 'Refresh isolate stack';

  String helpLong =
      'Refresh isolate stack.\n'
      '\n'
      'Syntax: refresh stack\n';
}

class RefreshCommand extends DebuggerCommand {
  RefreshCommand(Debugger debugger) : super(debugger, 'refresh', [
      new RefreshCoverageCommand(debugger),
      new RefreshStackCommand(debugger),
  ]);

  Future run(List<String> args) {
    debugger.console.print("'refresh' expects a subcommand (see 'help refresh')");
    return new Future.value(null);
  }

  String helpShort = 'Refresh debugging information of various sorts';

  String helpLong =
      'Refresh debugging information of various sorts.\n'
      '\n'
      'Syntax: refresh <subcommand>\n';
}

// Tracks the state for an isolate debugging session.
class ObservatoryDebugger extends Debugger {
  RootCommand cmd;
  DebuggerConsoleElement console;
  DebuggerStackElement stackElement;
  ServiceMap stack;
  int currentFrame = 0;

  ObservatoryDebugger() {
    cmd = new RootCommand([
        new HelpCommand(this),
        new PauseCommand(this),
        new ContinueCommand(this),
        new NextCommand(this),
        new StepCommand(this),
        new FinishCommand(this),
        new BreakCommand(this),
        new ClearCommand(this),
        new DeleteCommand(this),
        new InfoCommand(this),
        new RefreshCommand(this),
    ]);
  }

  void set isolate(Isolate iso) {
    _isolate = iso;
    if (_isolate != null) {
      _isolate.reload().then((_) {
        // TODO(turnidge): Currently the debugger relies on all libs
        // being loaded.  Fix this.
        var pending = [];
        for (var lib in _isolate.libraries) {
          if (!lib.loaded) {
            pending.add(lib.load());
          }
        }
        Future.wait(pending).then((_) {
          _isolate.vm.events.stream.listen(_onEvent);
          _refreshStack(isolate.pauseEvent).then((_) {
            reportStatus();
          });
        });
      });
    }
  }
  Isolate get isolate => _isolate;
  Isolate _isolate;

  void init() {
    console.newline();
    console.printBold("Type 'h' for help");
  }

  Future refreshStack() {
    return _refreshStack(isolate.pauseEvent).then((_) {
        reportStatus();
      });
  }

  bool isolatePaused() {
    // TODO(turnidge): Stop relying on the isolate to track the last
    // pause event.  Since we listen to events directly in the
    // debugger, this could introduce a race.
    return isolate.pauseEvent != null;
  }

  void warnOutOfDate() {
    // Wait a bit, then tell the user that the stack may be out of date.
    new Timer(const Duration(seconds:2), () {
      if (!isolatePaused()) {
        stackElement.isSampled = true;
      }
    });
  }

  Future<ServiceMap> _refreshStack(ServiceEvent pauseEvent) {
    return isolate.getStack().then((result) {
      stack = result;
      // TODO(turnidge): Replace only the changed part of the stack to
      // reduce flicker.
      stackElement.updateStack(stack, pauseEvent);
    });
  }

  void reportStatus() {
    if (_isolate.idle) {
      console.print('Isolate is idle');
    } else if (_isolate.running) {
      console.print("Isolate is running (type 'pause' to interrupt)");
    } else if (_isolate.pauseEvent != null) {
      _reportPause(_isolate.pauseEvent);
    } else {
      console.print('Isolate is in unknown state');
    }
  }

  void _reportPause(ServiceEvent event) {
    if (event.eventType == 'IsolateCreated') {
      console.print(
          "Paused at isolate start (type 'continue' to start the isolate')");
    } else if (event.eventType == 'IsolateShutdown') {
      console.print(
          "Paused at isolate exit (type 'continue' to exit the isolate')");
    }
    if (stack['frames'].length > 0) {
      var frame = stack['frames'][0];
      var script = frame['script'];
      script.load().then((_) {
        var line = script.tokenToLine(frame['tokenPos']);
        var col = script.tokenToCol(frame['tokenPos']);
        if (event.breakpoint != null) {
          var bpId = event.breakpoint['breakpointNumber'];
          console.print('Breakpoint ${bpId} at ${script.name}:${line}:${col}');
        } else if (event.exception != null) {
          // TODO(turnidge): Test this.
          console.print(
              'Exception ${event.exception} at ${script.name}:${line}:${col}');
        } else {
          console.print('Paused at ${script.name}:${line}:${col}');
        }
      });
    }
  }

  void _onEvent(ServiceEvent event) {
    if (event.owner != isolate) {
      return;
    }
    switch(event.eventType) {
      case 'IsolateShutdown':
        console.print('Isolate shutdown');
        isolate = null;
        break;

      case 'BreakpointReached':
      case 'IsolateInterrupted':
      case 'ExceptionThrown':
        _refreshStack(event).then((_) {
          _reportPause(event);
        });
        break;

      case 'IsolateResumed':
        console.print('Continuing...');
        break;

      case 'BreakpointResolved':
        var bpId = event.breakpoint['breakpointNumber'];
        var script = event.breakpoint['location']['script'];
        var tokenPos = event.breakpoint['location']['tokenPos'];
        var line = script.tokenToLine(tokenPos);
        var col = script.tokenToCol(tokenPos);
        console.print(
            'Breakpoint ${bpId} added at ${script.name}:${line}:${col}');
        break;

      case '_Graph':
      case 'IsolateCreated':
      case 'GC':
        // Ignore these events for now.
        break;

      default:
        console.print('Unrecognized event: $event');
        break;
    }
  }

  static String _commonPrefix(String a, String b) {
    int pos = 0;
    while (pos < a.length && pos < b.length) {
      if (a.codeUnitAt(pos) != b.codeUnitAt(pos)) {
        break;
      }
      pos++;
    }
    return a.substring(0, pos);
  }

  static String _foldCompletions(List<String> values) {
    if (values.length == 0) {
      return '';
    }
    var prefix = values[0];
    for (int i = 1; i < values.length; i++) {
      prefix = _commonPrefix(prefix, values[i]);
    }
    return prefix;
  }

  Future<String> complete(String line) {
    return cmd.completeCommand(line).then((completions) {
      if (completions.length == 0) {
        // No completions.  Leave the line alone.
        return line;
      } else if (completions.length == 1) {
        // Unambiguous completion.
        return completions[0];
      } else {
        // Ambigous completion.
        completions = completions.map((s )=> s.trimRight()).toList();
        console.printBold(completions.toString());
        return _foldCompletions(completions);
      }
    });
  }

  // TODO(turnidge): Implement real command line history.
  String lastCommand;

  Future run(String command) {
    if (command == '' && lastCommand != null) {
      command = lastCommand;
    }
    console.printBold('\$ $command');
    return cmd.runCommand(command).then((_) {
      lastCommand = command;
    }).catchError((e) {
      console.print('ERROR $e');
    });
  }
}

@CustomTag('debugger-page')
class DebuggerPageElement extends ObservatoryElement {
  @published Isolate isolate;

  isolateChanged(oldValue) {
    if (isolate != null) {
      debugger.isolate = isolate;
    }
  }
  ObservatoryDebugger debugger = new ObservatoryDebugger();

  DebuggerPageElement.created() : super.created();

  @override
  void attached() {
    super.attached();

    var navbarDiv = $['navbarDiv'];
    var stackDiv = $['stackDiv'];
    var splitterDiv = $['splitterDiv'];
    var cmdDiv = $['commandDiv'];
    var consoleDiv = $['consoleDiv'];

    int navbarHeight = navbarDiv.clientHeight;
    int splitterHeight = splitterDiv.clientHeight;
    int cmdHeight = cmdDiv.clientHeight;

    int windowHeight = window.innerHeight;
    int fixedHeight = navbarHeight + splitterHeight + cmdHeight;
    int available = windowHeight - fixedHeight;
    int stackHeight = available ~/ 1.6;
    stackDiv.style.setProperty('height', '${stackHeight}px');

    // Wire the debugger object to the stack, console, and command line.
    var stackElement = $['stackElement'];
    debugger.stackElement = stackElement;
    stackElement.debugger = debugger;
    debugger.console = $['console'];
    $['commandline'].debugger = debugger;
    debugger.init();
  }

}

@CustomTag('debugger-stack')
class DebuggerStackElement extends ObservatoryElement {
  @published Isolate isolate;
  @observable bool hasStack = false;
  @observable bool isSampled = false;
  ObservatoryDebugger debugger;

  _addFrame(List frameList, ObservableMap frameInfo, bool expand) {
    DebuggerFrameElement frameElement = new Element.tag('debugger-frame');
    frameElement.expand = expand;
    frameElement.frame = frameInfo;

    var li = new LIElement();
    li.classes.add('list-group-item');
    li.children.insert(0, frameElement);

    frameList.insert(0, li);
  }

  void updateStack(ServiceMap newStack, ServiceEvent pauseEvent) {
    List frameElements = $['frameList'].children;
    List newFrames = newStack['frames'];

    // Remove any frames whose functions don't match, starting from
    // bottom of stack.
    int oldPos = frameElements.length - 1;
    int newPos = newFrames.length - 1;
    while (oldPos >= 0 && newPos >= 0) {
      if (!frameElements[oldPos].children[0].matchFrame(newFrames[newPos])) {
        // The rest of the frame elements no longer match.  Remove them.
        for (int i = 0; i <= oldPos; i++) {
          // NOTE(turnidge): removeRange is missing, sadly.
          frameElements.removeAt(0);
        }
        break;
      }
      oldPos--;
      newPos--;
    }

    // Remove any extra frames.
    if (frameElements.length > newFrames.length) {
      // Remove old frames from the top of stack.
      int removeCount = frameElements.length - newFrames.length;
      for (int i = 0; i < removeCount; i++) {
        frameElements.removeAt(0);
      }
    }

    // Add any new frames.
    int newCount = 0;
    if (frameElements.length < newFrames.length) {
      // Add new frames to the top of stack.
      newCount = newFrames.length - frameElements.length;
      for (int i = newCount-1; i >= 0; i--) {
        _addFrame(frameElements, newFrames[i], i == 0);
      }
    }
    assert(frameElements.length == newFrames.length);

    if (frameElements.isNotEmpty) {
      frameElements[0].children[0].expand = true;
      for (int i = newCount; i < frameElements.length; i++) {
        frameElements[i].children[0].updateFrame(newFrames[i]);
      }
    }

    isSampled = pauseEvent == null;
    hasStack = frameElements.isNotEmpty;
  }

  Set<Script> activeScripts() {
    var s = new Set<Script>();
    List frameElements = $['frameList'].children;
    for (var frameElement in frameElements) {
      s.add(frameElement.children[0].script);
    }
    return s;
  }

  doPauseIsolate(_) {
    if (debugger != null) {
      return debugger.isolate.pause();
    } else {
      return new Future.value(null);
    }
  }

  doRefreshStack(_) {
    if (debugger != null) {
      return debugger.refreshStack();
    } else {
      return new Future.value(null);
    }
  }

  DebuggerStackElement.created() : super.created();
}

@CustomTag('debugger-frame')
class DebuggerFrameElement extends ObservatoryElement {
  @published ObservableMap frame;

  // When true, the frame will start out expanded.
  @published bool expand = false;

  @observable String scriptHeight;
  @observable bool expanded = false;
  @observable bool busy = false;

  DebuggerFrameElement.created() : super.created();

  bool matchFrame(ObservableMap newFrame) {
    return newFrame['function'].id == frame['function'].id;
  }

  void updateFrame(ObservableMap newFrame) {
    assert(matchFrame(newFrame));
    frame['depth'] = newFrame['depth'];
    frame['tokenPos'] = newFrame['tokenPos'];
    frame['vars'] = newFrame['vars'];
  }

  Script get script => frame['script'];

  @override
  void attached() {
    super.attached();
    int windowHeight = window.innerHeight;
    scriptHeight = '${windowHeight ~/ 1.6}px';
  }

  void expandChanged(oldValue) {
    if (expand != expanded) {
      toggleExpand(null, null, null);
    }
  }

  void toggleExpand(var a, var b, var c) {
    if (busy) {
      return;
    }
    busy = true;
    frame['function'].load().then((func) {
        expanded = !expanded;
        var frameOuter = $['frameOuter'];
        if (expanded) {
          frameOuter.classes.add('shadow');
        } else {
          frameOuter.classes.remove('shadow');
        }
        busy = false;
      });
  }
}

@CustomTag('debugger-console')
class DebuggerConsoleElement extends ObservatoryElement {
  @published Isolate isolate;

  DebuggerConsoleElement.created() : super.created();

  void print(String line, { bool newline:true }) {
    var span = new SpanElement();
    span.classes.add('normal');
    span.appendText(line);
    if (newline) {
      span.appendText('\n');
    }
    $['consoleText'].children.add(span);
    span.scrollIntoView();
  }

  void printBold(String line, { bool newline:true }) {
    var span = new SpanElement();
    span.classes.add('bold');
    span.appendText(line);
    span.appendText('\n');
    $['consoleText'].children.add(span);
    span.scrollIntoView();
  }

  void newline() {
    var br = new BRElement();
    $['consoleText'].children.add(br);
    br.scrollIntoView();
  }
}

@CustomTag('debugger-input')
class DebuggerInputElement extends ObservatoryElement {
  @published Isolate isolate;
  @published String text = '';
  @observable ObservatoryDebugger debugger;
  @observable bool busy = false;

  void _notBusy() {
    busy = false;
  }

  @override
  void ready() {
    super.ready();
    var textBox = $['textBox'];
    textBox.select();
    textBox.onKeyDown.listen((KeyboardEvent e) {
        // TODO(turnidge): Ignore *all* key events while busy.
	switch (e.keyCode) {
          case KeyCode.TAB:
            e.preventDefault();
            if (!busy) {
              busy = true;
              int cursorPos = textBox.selectionStart;
              debugger.complete(text.substring(0, cursorPos)).then((completion) {
                text = completion + text.substring(cursorPos);
                // TODO(turnidge): Move the cursor to the end of the
                // completion, rather than the end of the string.
              }).whenComplete(_notBusy);
            }
            break;
          case KeyCode.ENTER:
            if (!busy) {
              busy = true;
              var command = text;
              text = '';
              debugger.run(command).whenComplete(_notBusy);
            }
            break;
	}
      });
  }

  DebuggerInputElement.created() : super.created();
}

