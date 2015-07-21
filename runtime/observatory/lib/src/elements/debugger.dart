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

  String _nameAndAlias(Command cmd) {
    if (cmd.alias == null) {
      return cmd.fullName;
    } else {
      return '${cmd.fullName}, ${cmd.alias}';
    }
  }

  Future run(List<String> args) {
    var con = debugger.console;
    if (args.length == 0) {
      // Print list of all top-level commands.
      var commands = debugger.cmd.matchCommand([], false);
      commands.sort((a, b) => a.name.compareTo(b.name));
      con.print('List of commands:\n');
      for (var command in commands) {
        con.print('${_nameAndAlias(command).padRight(12)} '
                  '- ${command.helpShort}');
      }
      con.print(
          "\nFor more information on a specific command type 'help <command>'\n"
          "\n"
          "Command prefixes are accepted (e.g. 'h' for 'help')\n"
          "Hit [TAB] to complete a command (try 'is[TAB][TAB]')\n"
          "Hit [ENTER] to repeat the last command\n"
          "Use up/down arrow for command history\n");
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
        con.printBold(_nameAndAlias(command));
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

class PrintCommand extends DebuggerCommand {
  PrintCommand(Debugger debugger) : super(debugger, 'print', []) {
    alias = 'p';
  }

  Future run(List<String> args) async {
    if (args.length < 1) {
      debugger.console.print('print expects arguments');
      return;
    }
    if (debugger.currentFrame == null) {
      debugger.console.print('No stack');
      return;
    }
    var expression = args.join('');
    var response = await debugger.isolate.evalFrame(debugger.currentFrame,
                                                    expression);
    if (response is DartError) {
      debugger.console.print(response.message);
    } else {
      debugger.console.print('= ', newline:false);
      debugger.console.printRef(response);
    }
  }

  String helpShort = 'Evaluate and print an expression in the current frame';

  String helpLong =
      'Evaluate and print an expression in the current frame.\n'
      '\n'
      'Syntax: print <expression>\n'
      '        p <expression>\n';
}

class DownCommand extends DebuggerCommand {
  DownCommand(Debugger debugger) : super(debugger, 'down', []);

  Future run(List<String> args) {
    int count = 1;
    if (args.length == 1) {
      count = int.parse(args[0]);
    } else if (args.length > 1) {
      debugger.console.print('down expects 0 or 1 argument');
      return new Future.value(null);
    }
    if (debugger.currentFrame == null) {
      debugger.console.print('No stack');
      return new Future.value(null);
    }
    try {
      debugger.currentFrame -= count;
      debugger.console.print('frame = ${debugger.currentFrame}');
    } catch (e) {
      debugger.console.print('frame must be in range [${e.start},${e.end-1}]');
    }
    return new Future.value(null);
  }

  String helpShort = 'Move down one or more frames';

  String helpLong =
      'Move down one or more frames.\n'
      '\n'
      'Syntax: down\n'
      '        down <count>\n';
}

class UpCommand extends DebuggerCommand {
  UpCommand(Debugger debugger) : super(debugger, 'up', []);

  Future run(List<String> args) {
    int count = 1;
    if (args.length == 1) {
      count = int.parse(args[0]);
    } else if (args.length > 1) {
      debugger.console.print('up expects 0 or 1 argument');
      return new Future.value(null);
    }
    if (debugger.currentFrame == null) {
      debugger.console.print('No stack');
      return new Future.value(null);
    }
    try {
      debugger.currentFrame += count;
      debugger.console.print('frame = ${debugger.currentFrame}');
    } on RangeError catch (e) {
      debugger.console.print('frame must be in range [${e.start},${e.end-1}]');
    }
    return new Future.value(null);
  }

  String helpShort = 'Move up one or more frames';

  String helpLong =
      'Move up one or more frames.\n'
      '\n'
      'Syntax: up\n'
      '        up <count>\n';
}

class FrameCommand extends DebuggerCommand {
  FrameCommand(Debugger debugger) : super(debugger, 'frame', []) {
    alias = 'f';
  }

  Future run(List<String> args) {
    int frame = 1;
    if (args.length == 1) {
      frame = int.parse(args[0]);
    } else {
      debugger.console.print('frame expects 1 argument');
      return new Future.value(null);
    }
    if (debugger.currentFrame == null) {
      debugger.console.print('No stack');
      return new Future.value(null);
    }
    try {
      debugger.currentFrame = frame;
      debugger.console.print('frame = ${debugger.currentFrame}');
    } on RangeError catch (e) {
      debugger.console.print('frame must be in range [${e.start},${e.end-1}]');
    }
    return new Future.value(null);
  }

  String helpShort = 'Set the current frame';

  String helpLong =
      'Set the current frame.\n'
      '\n'
      'Syntax: frame <number>\n'
      '        f <count>\n';
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
  ContinueCommand(Debugger debugger) : super(debugger, 'continue', []) {
    alias = 'c';
  }

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
      'Syntax: continue\n'
      '        c\n';
}

class NextCommand extends DebuggerCommand {
  NextCommand(Debugger debugger) : super(debugger, 'next', []);

  Future run(List<String> args) {
    if (debugger.isolatePaused()) {
      var event = debugger.isolate.pauseEvent;
      if (event.kind == ServiceEvent.kPauseStart) {
        debugger.console.print("Type 'continue' to start the isolate");
        return new Future.value(null);
      }
      if (event.kind == ServiceEvent.kPauseExit) {
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
  StepCommand(Debugger debugger) : super(debugger, 'step', []) {
    alias = 's';
  }

  Future run(List<String> args) {
    if (debugger.isolatePaused()) {
      var event = debugger.isolate.pauseEvent;
      if (event.kind == ServiceEvent.kPauseStart) {
        debugger.console.print("Type 'continue' to start the isolate");
        return new Future.value(null);
      }
      if (event.kind == ServiceEvent.kPauseExit) {
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
      'Continue running the isolate until it reaches the next source location';

  String helpLong =
      'Continue running the isolate until it reaches the next source '
      'location.\n'
      '\n'
      'Syntax: step\n';
}

class AsyncNextCommand extends DebuggerCommand {
  AsyncNextCommand(Debugger debugger) : super(debugger, 'anext', []) {
  }

  Future run(List<String> args) async {
    if (debugger.isolatePaused()) {
      var event = debugger.isolate.pauseEvent;
      if (event.asyncContinuation == null) {
        debugger.console.print("No async continuation at this location");
        return;
      }
      var bpt = await
          debugger.isolate.addBreakOnActivation(event.asyncContinuation);
      return debugger.isolate.resume();
    } else {
      debugger.console.print('The program is already running');
    }
  }

  String helpShort =
      'Step over await or yield';

  String helpLong =
      'Continue running the isolate until control returns to the current '
      'activation of an async or async* function.\n'
      '\n'
      'Syntax: anext\n';
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

class SetCommand extends DebuggerCommand {
  SetCommand(Debugger debugger)
      : super(debugger, 'set', []);

  Future run(List<String> args) async {
    if (args.length == 2) {
      var option = args[0].trim();
      if (option == 'break-on-exceptions') {
        var result = await debugger.isolate.setExceptionPauseInfo(args[1]);
        if (result.isError) {
          debugger.console.print(result.toString());
        }
      } else {
        debugger.console.print("unknown option '$option'");
      }
    } else {
      debugger.console.print("set expects 2 arguments");
    }
  }

  String helpShort =
      'Set a debugger option';

  String helpLong =
      'Set a debugger option'
      '\n'
      'Syntax: set break-on-exceptions "all" | "none" | "unhandled"\n';
}

class BreakCommand extends DebuggerCommand {
  BreakCommand(Debugger debugger) : super(debugger, 'break', []);

  Future run(List<String> args) async {
    if (args.length > 1) {
      debugger.console.print('not implemented');
      return new Future.value(null);
    }
    var arg = (args.length == 0 ? '' : args[0]);
    var loc = await DebuggerLocation.parse(debugger, arg);
    if (loc.valid) {
      if (loc.function != null) {
        try {
          await debugger.isolate.addBreakpointAtEntry(loc.function);
        } on ServerRpcException catch(e) {
          if (e.code == ServerRpcException.kCannotAddBreakpoint) {
            debugger.console.print('Unable to set breakpoint at ${loc}');
          } else {
            rethrow;
          }
        }
      } else {
        assert(loc.script != null);
        if (loc.col != null) {
          // TODO(turnidge): Add tokenPos breakpoint support.
          debugger.console.print(
              'Ignoring column: '
              'adding breakpoint at a specific column not yet implemented');
          }
        try {
          await debugger.isolate.addBreakpoint(loc.script, loc.line);
        } on ServerRpcException catch(e) {
          if (e.code == ServerRpcException.kCannotAddBreakpoint) {
            debugger.console.print('Unable to set breakpoint at ${loc}');
          } else {
            rethrow;
          }
        }
      }
    } else {
      debugger.console.print(loc.errorMessage);
    }
  }

  Future<List<String>> complete(List<String> args) {
    if (args.length != 1) {
      return new Future.value([args.join('')]);
    }
    // TODO - fix DebuggerLocation complete
    return new Future.value(DebuggerLocation.complete(debugger, args[0]));
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
    return DebuggerLocation.parse(debugger, arg).then((loc) {
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

        for (var bpt in debugger.isolate.breakpoints.values) {
          var script = bpt.location.script;
          if (script.id == loc.script.id) {
            assert(script.loaded);
            var line = script.tokenToLine(bpt.location.tokenPos);
            if (line == loc.line) {
              return debugger.isolate.removeBreakpoint(bpt).then((result) {
                if (result is DartError) {
                  debugger.console.print(
                      'Unable to clear breakpoint at ${loc}: ${result.message}');
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
      return new Future.value([args.join('')]);
    }
    return new Future.value(DebuggerLocation.complete(debugger, args[0]));
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
    List toRemove = [];
    for (var arg in args) {
      int id = int.parse(arg);
      var bptToRemove = null;
      for (var bpt in debugger.isolate.breakpoints.values) {
        if (bpt.number == id) {
          bptToRemove = bpt;
          break;
        }
      }
      if (bptToRemove == null) {
        debugger.console.print("Invalid breakpoint id '${id}'");
        return new Future.value(null);
      }
      toRemove.add(bptToRemove);
    }
    List pending = [];
    for (var bpt in toRemove) {
      pending.add(debugger.isolate.removeBreakpoint(bpt));
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
    if (debugger.isolate.breakpoints.isEmpty) {
      debugger.console.print('No breakpoints');
    }
    List bpts = debugger.isolate.breakpoints.values.toList();
    bpts.sort((a, b) => a.number - b.number);
    for (var bpt in bpts) {
      var bpId = bpt.number;
      var script = bpt.location.script;
      var tokenPos = bpt.location.tokenPos;
      var line = script.tokenToLine(tokenPos);
      var col = script.tokenToCol(tokenPos);
      if (!bpt.resolved) {
        debugger.console.print(
            'Future breakpoint ${bpId} at ${script.name}:${line}:${col}');
      } else {
        debugger.console.print(
            'Breakpoint ${bpId} at ${script.name}:${line}:${col}');
      }
    }
    return new Future.value(null);
  }

  String helpShort = 'List all breakpoints';

  String helpLong =
      'List all breakpoints.\n'
      '\n'
      'Syntax: info breakpoints\n';
}

class InfoFrameCommand extends DebuggerCommand {
  InfoFrameCommand(Debugger debugger) : super(debugger, 'frame', []);

  Future run(List<String> args) {
    if (args.length > 0) {
      debugger.console.print('info frame expects no arguments');
      return new Future.value(null);
    }
    debugger.console.print('frame = ${debugger.currentFrame}');
    return new Future.value(null);
  }

  String helpShort = 'Show current frame';

  String helpLong =
      'Show current frame.\n'
      '\n'
      'Syntax: info frame\n';
}

class IsolateCommand extends DebuggerCommand {
  IsolateCommand(Debugger debugger) : super(debugger, 'isolate', [
    new IsolateListCommand(debugger),
    new IsolateNameCommand(debugger),
  ]) {
    alias = 'i';
  }

  Future run(List<String> args) {
    if (args.length != 1) {
      debugger.console.print('isolate expects one argument');
      return new Future.value(null);
    }
    var arg = args[0].trim();
    var num = int.parse(arg, onError:(_) => null);

    var candidate;
    for (var isolate in debugger.vm.isolates) {
      if (num != null && num == isolate.number) {
        candidate = isolate;
        break;
      } else if (arg == isolate.name) {
        if (candidate != null) {
          debugger.console.print(
              "Isolate identifier '${arg}' is ambiguous: "
              'use the isolate number instead');
          return new Future.value(null);
        }
        candidate = isolate;
      }
    }
    if (candidate == null) {
      debugger.console.print("Invalid isolate identifier '${arg}'");
    } else {
      if (candidate == debugger.isolate) {
        debugger.console.print(
            "Current isolate is already ${candidate.number} '${candidate.name}'");
      } else {
        debugger.console.print(
            "Switching to isolate ${candidate.number} '${candidate.name}'");
        debugger.isolate = candidate;
      }
    }
    return new Future.value(null);
  }

  Future<List<String>> complete(List<String> args) {
    if (args.length != 1) {
      return new Future.value([args.join('')]);
    }
    var isolates = debugger.vm.isolates.toList();
    isolates.sort((a, b) => a.startTime.compareTo(b.startTime));
    var result = [];
    for (var isolate in isolates) {
      var str = isolate.number.toString();
      if (str.startsWith(args[0])) {
        result.add('$str ');
      }
    }
    for (var isolate in isolates) {
      if (isolate.name.startsWith(args[0])) {
        result.add('${isolate.name} ');
      }
    }
    return new Future.value(result);
  }
  String helpShort = 'Switch the current isolate';

  String helpLong =
      'Switch the current isolate.\n'
      '\n'
      'Syntax: isolate <number>\n'
      '        isolate <name>\n';
}

class IsolateListCommand extends DebuggerCommand {
  IsolateListCommand(Debugger debugger) : super(debugger, 'list', []);

  Future run(List<String> args) {
    if (debugger.vm == null) {
      debugger.console.print(
          "Internal error: vm has not been set");
      return new Future.value(null);
    }
    var isolates = debugger.vm.isolates.toList();
    isolates.sort((a, b) => a.startTime.compareTo(b.startTime));
    for (var isolate in isolates) {
      String current = (isolate == debugger.isolate ? ' *' : '');
      debugger.console.print(
          "Isolate ${isolate.number} '${isolate.name}'${current}");
    }
    return new Future.value(null);
  }

  String helpShort = 'List all isolates';

  String helpLong =
      'List all isolates.\n'
      '\n'
      'Syntax: isolate list\n';
}

class IsolateNameCommand extends DebuggerCommand {
  IsolateNameCommand(Debugger debugger) : super(debugger, 'name', []);

  Future run(List<String> args) {
    if (args.length != 1) {
      debugger.console.print('isolate name expects one argument');
      return new Future.value(null);
    }
    return debugger.isolate.setName(args[0]);
  }

  String helpShort = 'Rename an isolate';

  String helpLong =
      'Rename an isolate.\n'
      '\n'
      'Syntax: isolate name <name>\n';
}

class InfoCommand extends DebuggerCommand {
  InfoCommand(Debugger debugger) : super(debugger, 'info', [
      new InfoBreakpointsCommand(debugger),
      new InfoFrameCommand(debugger)]);

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

class _VMStreamPrinter {
  ObservatoryDebugger _debugger;

  _VMStreamPrinter(this._debugger);

  String _savedStream;
  String _savedIsolate;
  String _savedLine;
  List<String> _buffer = [];

  void onEvent(String streamName, ServiceEvent event) {
    String isolateName = event.isolate.name;
    // If we get a line from a different isolate/stream, flush
    // any pending output, even if it is not newline-terminated.
    if ((_savedIsolate != null && isolateName != _savedIsolate) ||
        (_savedStream != null && streamName != _savedStream)) {
       flush();
    }
    String data = event.bytesAsString;
    bool hasNewline = data.endsWith('\n');
    if (_savedLine != null) {
       data = _savedLine + data;
      _savedIsolate = null;
      _savedStream = null;
      _savedLine = null;
    }
    var lines = data.split('\n').where((line) => line != '').toList();
    if (lines.isEmpty) {
      return;
    }
    int limit = (hasNewline ? lines.length : lines.length - 1);
    for (int i = 0; i < limit; i++) {
      _buffer.add(_format(isolateName, streamName, lines[i]));
    }
    // If there is no newline, we save the last line of output for next time.
    if (!hasNewline) {
      _savedIsolate = isolateName;
      _savedStream = streamName;
      _savedLine = lines[lines.length - 1];
    }
  }

  void flush() {
    // If there is any saved output, flush it now.
    if (_savedLine != null) {
      _buffer.add(_format(_savedIsolate, _savedStream, _savedLine));
      _savedIsolate = null;
      _savedStream = null;
      _savedLine = null;
    }
    if (_buffer.isNotEmpty) {
      _debugger.console.printStdio(_buffer);
      _buffer.clear();
    }
  }

  String _format(String isolateName, String streamName, String line) {
    return '${isolateName}:${streamName}> ${line}';
  }
}

// Tracks the state for an isolate debugging session.
class ObservatoryDebugger extends Debugger {
  RootCommand cmd;
  DebuggerPageElement page;
  DebuggerConsoleElement console;
  DebuggerInputElement input;
  DebuggerStackElement stackElement;
  ServiceMap stack;
  String exceptions = "none";  // Last known setting.

  int get currentFrame => _currentFrame;
  void set currentFrame(int value) {
    if (value != null && (value < 0 || value >= stackDepth)) {
      throw new RangeError.range(value, 0, stackDepth);
    }
    _currentFrame = value;
    if (stackElement != null) {
      stackElement.setCurrentFrame(value);
    }
  }
  int _currentFrame = null;

  int get stackDepth => stack['frames'].length;

  ObservatoryDebugger() {
    cmd = new RootCommand([
        new HelpCommand(this),
        new PrintCommand(this),
        new DownCommand(this),
        new UpCommand(this),
        new FrameCommand(this),
        new PauseCommand(this),
        new ContinueCommand(this),
        new NextCommand(this),
        new StepCommand(this),
        new AsyncNextCommand(this),
        new FinishCommand(this),
        new BreakCommand(this),
        new SetCommand(this),
        new ClearCommand(this),
        new DeleteCommand(this),
        new InfoCommand(this),
        new IsolateCommand(this),
        new RefreshCommand(this),
    ]);
    _stdioPrinter = new _VMStreamPrinter(this);
  }

  VM get vm => page.app.vm;

  void updateIsolate(Isolate iso) {
    _isolate = iso;
    if (_isolate != null) {
      if (exceptions != iso.exceptionsPauseInfo) {
        exceptions = iso.exceptionsPauseInfo;
        console.print("Now pausing for $exceptions exceptions");
      }

      _isolate.reload().then((response) {
        // TODO(turnidge): Currently the debugger relies on all libs
        // being loaded.  Fix this.
        var pending = [];
        for (var lib in _isolate.libraries) {
          if (!lib.loaded) {
            pending.add(lib.load());
          }
        }
        Future.wait(pending).then((_) {
          _refreshStack(isolate.pauseEvent).then((_) {
            reportStatus();
          });
        }).catchError((_) {
          // Error loading libraries, try and display stack.
          _refreshStack(isolate.pauseEvent).then((_) {
            reportStatus();
          });
        });
      });
    } else {
      reportStatus();
    }
  }

  set isolate(Isolate iso) {
    // Setting the page's isolate will trigger updateIsolate to be called.
    //
    // TODO(turnidge): Rework ownership of the ObservatoryDebugger in another
    // change.
    page.isolate = iso;
  }
  Isolate get isolate => _isolate;
  Isolate _isolate;

  void init() {
    console.newline();
    console.printBold("Type 'h' for help");
    // Wait a bit and if polymer still hasn't set up the isolate,
    // report this to the user.
    new Timer(const Duration(seconds:1), () {
      if (isolate == null) {
        reportStatus();
      }
    });
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
    return (isolate != null &&
            isolate.pauseEvent != null &&
            isolate.pauseEvent.kind != ServiceEvent.kResume);
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
      if (stack['frames'].length > 0) {
        currentFrame = 0;
      } else {
        currentFrame = null;
      }
      input.focus();
    });
  }

  void reportStatus() {
    flushStdio();
    if (_isolate == null) {
      console.print('No current isolate');
    } else if (_isolate.idle) {
      console.print('Isolate is idle');
    } else if (_isolate.running) {
      console.print("Isolate is running (type 'pause' to interrupt)");
    } else if (_isolate.pauseEvent != null) {
      _reportPause(_isolate.pauseEvent);
    } else {
      console.print('Isolate is in unknown state');
    }
    warnOutOfDate();
  }

  void _reportPause(ServiceEvent event) {
    if (event.kind == ServiceEvent.kPauseStart) {
      console.print(
          "Paused at isolate start (type 'continue' to start the isolate')");
    } else if (event.kind == ServiceEvent.kPauseExit) {
      console.print(
          "Paused at isolate exit (type 'continue' to exit the isolate')");
    }
    if (stack['frames'].length > 0) {
      Frame frame = stack['frames'][0];
      var script = frame.location.script;
      script.load().then((_) {
        var line = script.tokenToLine(frame.location.tokenPos);
        var col = script.tokenToCol(frame.location.tokenPos);
        if (event.breakpoint != null) {
          var bpId = event.breakpoint.number;
          console.print('Paused at breakpoint ${bpId} at '
                        '${script.name}:${line}:${col}');
        } else if (event.exception != null) {
          console.print('Paused due to exception at '
                        '${script.name}:${line}:${col}');
          // This seems to be missing if we are paused-at-exception after
          // paused-at-isolate-exit. Maybe we shutdown part of the debugger too
          // soon?
          console.printRef(event.exception);
        } else {
          console.print('Paused at ${script.name}:${line}:${col}');
        }
        if (event.asyncContinuation != null) {
          console.print("Paused in async function: 'astep' available");
        }
      });
    }
  }

  Future _reportBreakpointEvent(ServiceEvent event) {
    var bpt = event.breakpoint;
    var verb = null;
    switch (event.kind) {
      case ServiceEvent.kBreakpointAdded:
        verb = 'added';
        break;
      case ServiceEvent.kBreakpointResolved:
        verb = 'resolved';
        break;
      case ServiceEvent.kBreakpointRemoved:
        verb = 'removed';
        break;
      default:
        break;
    }
    var script = bpt.location.script;
    return script.load().then((_) {
      var bpId = bpt.number;
      var tokenPos = bpt.location.tokenPos;
      var line = script.tokenToLine(tokenPos);
      var col = script.tokenToCol(tokenPos);
      if (bpt.resolved) {
        console.print(
            'Breakpoint ${bpId} ${verb} at ${script.name}:${line}:${col}');
      } else {
        console.print(
            'Future breakpoint ${bpId} ${verb} at ${script.name}:${line}:${col}');
      }
    });
  }

  void onEvent(ServiceEvent event) {
    switch(event.kind) {
      case ServiceEvent.kIsolateStart:
        {
          var iso = event.owner;
          console.print(
              "Isolate ${iso.number} '${iso.name}' has been created");
        }
        break;

      case ServiceEvent.kIsolateExit:
        {
          var iso = event.owner;
          if (iso == isolate) {
            console.print("The current isolate has exited");
          } else {
            console.print(
                "Isolate ${iso.number} '${iso.name}' has exited");
          }
        }
        break;

      case ServiceEvent.kDebuggerSettingsUpdate:
        if (exceptions != event.exceptions) {
          exceptions = event.exceptions;
          console.print("Now pausing for $exceptions exceptions");
        }
        break;

      case ServiceEvent.kIsolateUpdate:
        var iso = event.owner;
        console.print("Isolate ${iso.number} renamed to '${iso.name}'");
        break;

      case ServiceEvent.kPauseStart:
      case ServiceEvent.kPauseExit:
      case ServiceEvent.kPauseBreakpoint:
      case ServiceEvent.kPauseInterrupted:
      case ServiceEvent.kPauseException:
        if (event.owner == isolate) {
          _refreshStack(event).then((_) {
            flushStdio();
            _reportPause(event);
          });
        }
        break;

      case ServiceEvent.kResume:
        if (event.owner == isolate) {
          flushStdio();
          console.print('Continuing...');
        }
        break;

      case ServiceEvent.kBreakpointAdded:
      case ServiceEvent.kBreakpointResolved:
      case ServiceEvent.kBreakpointRemoved:
        if (event.owner == isolate) {
          _reportBreakpointEvent(event);
        }
        break;

      case ServiceEvent.kIsolateStart:
      case ServiceEvent.kGraph:
      case ServiceEvent.kGC:
      case ServiceEvent.kInspect:
        break;

      default:
        console.print('Unrecognized event: $event');
        break;
    }
  }

  _VMStreamPrinter _stdioPrinter;

  void flushStdio() {
    _stdioPrinter.flush();
  }

  void onStdout(ServiceEvent event) {
    _stdioPrinter.onEvent('stdout', event);
  }

  void onStderr(ServiceEvent event) {
    _stdioPrinter.onEvent('stderr', event);
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
        completions = completions.map((s) => s.trimRight()).toList();
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
    }).catchError((e, s) {
      if (e is NetworkRpcException) {
        console.printRed('Unable to execute command because the connection '
                      'to the VM has been closed');
      } else {
        if (s != null) {
          console.printRed('Internal error: $e\n$s');
        } else {
          console.printRed('Internal error: $e\n');
        }
      }
    });
  }

  String historyPrev(String command) {
    return cmd.historyPrev(command);
  }

  String historyNext(String command) {
    return cmd.historyNext(command);
  }
}

@CustomTag('debugger-page')
class DebuggerPageElement extends ObservatoryElement {
  @published Isolate isolate;

  isolateChanged(oldValue) {
    if (isolate != null) {
      debugger.updateIsolate(isolate);
    }
  }
  ObservatoryDebugger debugger = new ObservatoryDebugger();

  DebuggerPageElement.created() : super.created() {
    debugger.page = this;
  }

  Future<StreamSubscription> _isolateSubscriptionFuture;
  Future<StreamSubscription> _debugSubscriptionFuture;
  Future<StreamSubscription> _stdoutSubscriptionFuture;
  Future<StreamSubscription> _stderrSubscriptionFuture;

  @override
  void attached() {
    super.attached();

    var navbarDiv = $['navbarDiv'];
    var stackDiv = $['stackDiv'];
    var splitterDiv = $['splitterDiv'];
    var cmdDiv = $['commandDiv'];

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
    debugger.input = $['commandline'];
    debugger.input.debugger = debugger;
    debugger.init();

    _isolateSubscriptionFuture =
        app.vm.listenEventStream(VM.kIsolateStream, debugger.onEvent);
    _debugSubscriptionFuture =
        app.vm.listenEventStream(VM.kDebugStream, debugger.onEvent);
    _stdoutSubscriptionFuture =
        app.vm.listenEventStream(VM.kStdoutStream, debugger.onStdout);
    _stderrSubscriptionFuture =
        app.vm.listenEventStream(VM.kStderrStream, debugger.onStderr);

    // Turn on the periodic poll timer for this page.
    pollPeriod = const Duration(milliseconds:100);

    onClick.listen((event) {
      // Random clicks should focus on the text box.  If the user selects
      // a range, don't interfere.
      var selection = window.getSelection();
      if (selection == null || selection.type == 'Caret') {
        debugger.input.focus();
      }
    });
  }

  void onPoll() {
    debugger.flushStdio();
  }

  @override
  void detached() {
    cancelFutureSubscription(_isolateSubscriptionFuture);
    _isolateSubscriptionFuture = null;
    cancelFutureSubscription(_debugSubscriptionFuture);
    _debugSubscriptionFuture = null;
    cancelFutureSubscription(_stdoutSubscriptionFuture);
    _stdoutSubscriptionFuture = null;
    cancelFutureSubscription(_stderrSubscriptionFuture);
    _stderrSubscriptionFuture = null;
    super.detached();
  }
}

@CustomTag('debugger-stack')
class DebuggerStackElement extends ObservatoryElement {
  @published Isolate isolate;
  @observable bool hasStack = false;
  @observable bool hasMessages = false;
  @observable bool isSampled = false;
  @observable int currentFrame;
  ObservatoryDebugger debugger;

  _addFrame(List frameList, Frame frameInfo) {
    DebuggerFrameElement frameElement = new Element.tag('debugger-frame');
    frameElement.frame = frameInfo;

    if (frameInfo.index == currentFrame) {
      frameElement.setCurrent(true);
    } else {
      frameElement.setCurrent(false);
    }

    var li = new LIElement();
    li.classes.add('list-group-item');
    li.children.insert(0, frameElement);

    frameList.insert(0, li);
  }

  _addMessage(List messageList, ServiceMessage messageInfo) {
    DebuggerMessageElement messageElement = new Element.tag('debugger-message');
    messageElement.message = messageInfo;

    var li = new LIElement();
    li.classes.add('list-group-item');
    li.children.insert(0, messageElement);

    messageList.add(li);
  }

  void updateStackFrames(ServiceMap newStack) {
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
        _addFrame(frameElements, newFrames[i]);
      }
    }
    assert(frameElements.length == newFrames.length);

    if (frameElements.isNotEmpty) {
      for (int i = newCount; i < frameElements.length; i++) {
        frameElements[i].children[0].updateFrame(newFrames[i]);
      }
    }

    hasStack = frameElements.isNotEmpty;
  }

  void updateStackMessages(ServiceMap newStack) {
    List messageElements = $['messageList'].children;
    List newMessages = newStack['messages'];

    // Remove any extra message elements.
    if (messageElements.length > newMessages.length) {
      // Remove old messages from the front of the queue.
      int removeCount = messageElements.length - newMessages.length;
      for (int i = 0; i < removeCount; i++) {
        messageElements.removeAt(0);
      }
    }

    // Add any new messages to the tail of the queue.
    int newStartingIndex = messageElements.length;
    if (messageElements.length < newMessages.length) {
      for (int i = newStartingIndex; i < newMessages.length; i++) {
        _addMessage(messageElements, newMessages[i]);
      }
    }
    assert(messageElements.length == newMessages.length);

    if (messageElements.isNotEmpty) {
      // Update old messages.
      for (int i = 0; i < newStartingIndex; i++) {
        messageElements[i].children[0].updateMessage(newMessages[i]);
      }
    }

    hasMessages = messageElements.isNotEmpty;
  }

  void updateStack(ServiceMap newStack, ServiceEvent pauseEvent) {
    updateStackFrames(newStack);
    updateStackMessages(newStack);
    isSampled = pauseEvent == null;
  }

  void setCurrentFrame(int value) {
    currentFrame = value;
    List frameElements = $['frameList'].children;
    for (var frameElement in frameElements) {
      var dbgFrameElement = frameElement.children[0];
      if (dbgFrameElement.frame.index == currentFrame) {
        dbgFrameElement.setCurrent(true);
      } else {
        dbgFrameElement.setCurrent(false);
      }
    }
  }

  Set<Script> activeScripts() {
    var s = new Set<Script>();
    List frameElements = $['frameList'].children;
    for (var frameElement in frameElements) {
      s.add(frameElement.children[0].script);
    }
    return s;
  }

  Future doPauseIsolate() {
    if (debugger != null) {
      return debugger.isolate.pause();
    } else {
      return new Future.value(null);
    }
  }

  Future doRefreshStack() {
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
  @published Frame frame;

  // Is this the current frame?
  bool _current = false;

  // Has this frame been pinned open?
  bool _pinned = false;

  void setCurrent(bool value) {
    busy = true;
    frame.function.load().then((func) {
      _current = value;
      var frameOuter = $['frameOuter'];
      if (_current) {
        frameOuter.classes.add('current');
        expanded = true;
        frameOuter.classes.add('shadow');
        scrollIntoView();
      } else {
        frameOuter.classes.remove('current');
        if (_pinned) {
          expanded = true;
          frameOuter.classes.add('shadow');
        } else {
          expanded = false;
          frameOuter.classes.remove('shadow');
        }
      }
      busy = false;
    });
  }

  @observable String scriptHeight;
  @observable bool expanded = false;
  @observable bool busy = false;

  DebuggerFrameElement.created() : super.created();

  bool matchFrame(Frame newFrame) {
    return newFrame.function.id == frame.function.id;
  }

  void updateFrame(Frame newFrame) {
    assert(matchFrame(newFrame));
    frame = newFrame;
  }

  Script get script => frame.location.script;

  @override
  void attached() {
    super.attached();
    int windowHeight = window.innerHeight;
    scriptHeight = '${windowHeight ~/ 1.6}px';
  }

  void toggleExpand(var a, var b, var c) {
    if (busy) {
      return;
    }
    busy = true;
    frame.function.load().then((func) {
        _pinned = !_pinned;
        var frameOuter = $['frameOuter'];
        if (_pinned) {
          expanded = true;
          frameOuter.classes.add('shadow');
        } else {
          expanded = false;
          frameOuter.classes.remove('shadow');
        }
        busy = false;
      });
  }
}

@CustomTag('debugger-message')
class DebuggerMessageElement extends ObservatoryElement {
  @published ServiceMessage message;
  @observable ServiceObject preview;

  // Is this the current message?
  bool _current = false;

  // Has this message been pinned open?
  bool _pinned = false;

  void setCurrent(bool value) {
    _current = value;
    var messageOuter = $['messageOuter'];
    if (_current) {
      messageOuter.classes.add('current');
      expanded = true;
      messageOuter.classes.add('shadow');
      scrollIntoView();
    } else {
      messageOuter.classes.remove('current');
      if (_pinned) {
        expanded = true;
        messageOuter.classes.add('shadow');
      } else {
        expanded = false;
        messageOuter.classes.remove('shadow');
      }
    }
  }

  @observable String scriptHeight;
  @observable bool expanded = false;
  @observable bool busy = false;

  DebuggerMessageElement.created() : super.created();

  void updateMessage(ServiceMessage newMessage) {
    bool messageChanged =
        (message.messageObjectId != newMessage.messageObjectId);
    message = newMessage;
    if (messageChanged) {
      // Message object id has changed: clear preview and collapse.
      preview = null;
      if (expanded) {
        toggleExpand(null, null, null);
      }
    }
  }

  @override
  void attached() {
    super.attached();
    int windowHeight = window.innerHeight;
    scriptHeight = '${windowHeight ~/ 1.6}px';
  }

  void toggleExpand(var a, var b, var c) {
    if (busy) {
      return;
    }
    busy = true;
    var function = message.handler;
    var loadedFunction;
    if (function == null) {
      // Complete immediately.
      loadedFunction = new Future.value(null);
    } else {
      loadedFunction = function.load();
    }
    loadedFunction.then((_) {
      _pinned = !_pinned;
      var messageOuter = $['messageOuter'];
      if (_pinned) {
        expanded = true;
        messageOuter.classes.add('shadow');
      } else {
        expanded = false;
        messageOuter.classes.remove('shadow');
      }
      busy = false;
    });
  }

  Future<ServiceObject> previewMessage(_) {
    return message.isolate.getObject(message.messageObjectId).then((result) {
      preview = result;
      return result;
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
    if (newline) {
      span.appendText('\n');
    }
    $['consoleText'].children.add(span);
    span.scrollIntoView();
  }

  void printRed(String line, { bool newline:true }) {
    var span = new SpanElement();
    span.classes.add('red');
    span.appendText(line);
    if (newline) {
      span.appendText('\n');
    }
    $['consoleText'].children.add(span);
    span.scrollIntoView();
  }

  void printStdio(List<String> lines) {
    var lastSpan;
    for (var line in lines) {
      var span = new SpanElement();
      span.classes.add('green');
      span.appendText(line);
      span.appendText('\n');
      $['consoleText'].children.add(span);
      lastSpan = span;
    }
    if (lastSpan != null) {
      lastSpan.scrollIntoView();
    }
  }

  void printRef(Instance ref, { bool newline:true }) {
    var refElement = new Element.tag('instance-ref');
    refElement.ref = ref;
    $['consoleText'].children.add(refElement);
    if (newline) {
      this.newline();
    }
    refElement.scrollIntoView();
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

  @override
  void ready() {
    super.ready();
    var textBox = $['textBox'];
    textBox.select();
    textBox.onKeyDown.listen((KeyboardEvent e) {
        if (busy) {
          e.preventDefault();
          return;
        }
        busy = true;
	switch (e.keyCode) {
          case KeyCode.TAB:
            e.preventDefault();
            int cursorPos = textBox.selectionStart;
            debugger.complete(text.substring(0, cursorPos)).then((completion) {
              text = completion + text.substring(cursorPos);
              // TODO(turnidge): Move the cursor to the end of the
              // completion, rather than the end of the string.
            }).whenComplete(() {
              busy = false;
            });
            break;

          case KeyCode.ENTER:
            var command = text;
            debugger.run(command).whenComplete(() {
              text = '';
              busy = false;
            });
            break;

          case KeyCode.UP:
            e.preventDefault();
            text = debugger.historyPrev(text);
            busy = false;
            break;

          case KeyCode.DOWN:
            e.preventDefault();
            text = debugger.historyNext(text);
            busy = false;
            break;

          default:
            busy = false;
            break;
	}
      });
  }

  void focus() {
    $['textBox'].focus();
  }

  DebuggerInputElement.created() : super.created();
}

