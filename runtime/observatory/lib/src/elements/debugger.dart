// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library debugger_page_element;

import 'dart:async';
import 'dart:html';
import 'dart:math';
import 'observatory_element.dart';
import 'nav_bar.dart';
import 'package:observatory/app.dart';
import 'package:observatory/cli.dart';
import 'package:observatory/debugger.dart';
import 'package:observatory/service.dart';
import 'package:logging/logging.dart';
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
  HelpCommand(Debugger debugger) : super(debugger, 'help', [
    new HelpHotkeysCommand(debugger),
  ]);

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
          "For a list of hotkeys type 'help hotkeys'\n"
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

class HelpHotkeysCommand extends DebuggerCommand {
  HelpHotkeysCommand(Debugger debugger) : super(debugger, 'hotkeys', []);

  Future run(List<String> args) {
    var con = debugger.console;
    con.print("List of hotkeys:\n"
              "\n"
              "[TAB]        - complete a command\n"
              "[Up Arrow]   - history previous\n"
              "[Down Arrow] - history next\n"
              "\n"
              "[Page Up]    - move up one frame\n"
              "[Page Down]  - move down one frame\n"
              "\n"
              "[F7]         - continue execution of the current isolate\n"
              "[Ctrl ;]     - pause execution of the current isolate\n"
              "\n"
              "[F8]         - toggle breakpoint at current location\n"
              "[F9]         - next\n"
              "[F10]        - step\n"
              "\n");
    return new Future.value(null);
  }

  String helpShort = 'Provide a list of hotkeys';

  String helpLong =
      'Provide a list of key hotkeys.\n'
      '\n'
      'Syntax: help hotkeys\n';
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
      debugger.downFrame(count);
      debugger.console.print('frame = ${debugger.currentFrame}');
    } catch (e) {
      debugger.console.print('frame must be in range [${e.start},${e.end-1}]');
    }
    return new Future.value(null);
  }

  String helpShort = 'Move down one or more frames (hotkey: [Page Down])';

  String helpLong =
      'Move down one or more frames.\n'
      '\n'
      'Hotkey: [Page Down]\n'
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
      debugger.upFrame(count);
      debugger.console.print('frame = ${debugger.currentFrame}');
    } on RangeError catch (e) {
      debugger.console.print('frame must be in range [${e.start},${e.end-1}]');
    }
    return new Future.value(null);
  }

  String helpShort = 'Move up one or more frames (hotkey: [Page Up])';

  String helpLong =
      'Move up one or more frames.\n'
      '\n'
      'Hotkey: [Page Up]\n'
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
    return debugger.pause();
  }

  String helpShort = 'Pause the isolate (hotkey: [Ctrl ;])';

  String helpLong =
      'Pause the isolate.\n'
      '\n'
      'Hotkey: [Ctrl ;]\n'
      '\n'
      'Syntax: pause\n';
}

class ContinueCommand extends DebuggerCommand {
  ContinueCommand(Debugger debugger) : super(debugger, 'continue', []) {
    alias = 'c';
  }

  Future run(List<String> args) {
    return debugger.resume();
  }

  String helpShort = 'Resume execution of the isolate (hotkey: [F7])';

  String helpLong =
      'Continue running the isolate.\n'
      '\n'
      'Hotkey: [F7]\n'
      '\n'
      'Syntax: continue\n'
      '        c\n';
}

class SmartNextCommand extends DebuggerCommand {
  SmartNextCommand(Debugger debugger) : super(debugger, 'next', []) {
    alias = 'n';
  }

  Future run(List<String> args) async {
    return debugger.smartNext();
  }

  String helpShort =
      'Continue running the isolate until it reaches the next source location '
      'in the current function (hotkey: [F9])';

  String helpLong =
      'Continue running the isolate until it reaches the next source location '
      'in the current function.\n'
      '\n'
      'Hotkey: [F9]\n'
      '\n'
      'Syntax: next\n';
}

class SyncNextCommand extends DebuggerCommand {
  SyncNextCommand(Debugger debugger) : super(debugger, 'next-sync', []);

  Future run(List<String> args) {
    return debugger.syncNext();
  }

  String helpShort =
      'Run until return/unwind to current activation.';

  String helpLong =
      'Continue running the isolate until control returns to the current '
      'activation or one of its callers.\n'
      '\n'
      'Syntax: next-sync\n';
}

class AsyncNextCommand extends DebuggerCommand {
  AsyncNextCommand(Debugger debugger) : super(debugger, 'next-async', []);

  Future run(List<String> args) {
    return debugger.asyncNext();
  }

  String helpShort =
      'Step over await or yield';

  String helpLong =
      'Continue running the isolate until control returns to the current '
      'activation of an async or async* function.\n'
      '\n'
      'Syntax: next-async\n';
}

class StepCommand extends DebuggerCommand {
  StepCommand(Debugger debugger) : super(debugger, 'step', []) {
    alias = 's';
  }

  Future run(List<String> args) {
    return debugger.step();
  }

  String helpShort =
      'Continue running the isolate until it reaches the next source location'
      ' (hotkey: [F10]';

  String helpLong =
      'Continue running the isolate until it reaches the next source '
      'location.\n'
      '\n'
      'Hotkey: [F10]\n'
      '\n'
      'Syntax: step\n';
}

class ClsCommand extends DebuggerCommand {
  ClsCommand(Debugger debugger) : super(debugger, 'cls', []) {}

  Future run(List<String> args) {
    debugger.console.clear();
    debugger.console.newline();
    return new Future.value(null);
  }

  String helpShort = 'Clear the console';

  String helpLong =
      'Clear the console.\n'
      '\n'
      'Syntax: cls\n';
}

class LogCommand extends DebuggerCommand {
  LogCommand(Debugger debugger) : super(debugger, 'log', []);

  Future run(List<String> args) async {
    if (args.length == 0) {
      debugger.console.print(
          'Current log level: '
          '${debugger._consolePrinter._minimumLogLevel.name}');
      return new Future.value(null);
    }
    if (args.length > 1) {
      debugger.console.print("log expects zero or one arguments");
      return new Future.value(null);
    }
    var level = _findLevel(args[0]);
    if (level == null) {
      debugger.console.print('No such log level: ${args[0]}');
      return new Future.value(null);
    }
    debugger._consolePrinter._minimumLogLevel = level;
    debugger.console.print('Set log level to: ${level.name}');
    return new Future.value(null);
  }

  Level _findLevel(String levelName) {
    levelName = levelName.toUpperCase();
    for (var level in Level.LEVELS) {
      if (level.name == levelName) {
        return level;
      }
    }
    return null;
  }

  Future<List<String>> complete(List<String> args) {
    if (args.length != 1) {
      return new Future.value([args.join('')]);
    }
    var prefix = args[0].toUpperCase();
    var result = <String>[];
    for (var level in Level.LEVELS) {
      if (level.name.startsWith(prefix)) {
        result.add(level.name);
      }
    }
    return new Future.value(result);
  }

  String helpShort =
      'Control which log messages are displayed';

  String helpLong =
      'Get or set the minimum log level that should be displayed.\n'
      '\n'
      'Log levels (in ascending order): ALL, FINEST, FINER, FINE, CONFIG, '
      'INFO, WARNING, SEVERE, SHOUT, OFF\n'
      '\n'
      'Default: OFF\n'
      '\n'
      'Syntax: log          '
      '# Display the current minimum log level.\n'
      '        log <level>  '
      '# Set the minimum log level to <level>.\n'
      '        log OFF      '
      '# Display no log messages.\n'
      '        log ALL      '
      '# Display all log messages.\n';
}

class FinishCommand extends DebuggerCommand {
  FinishCommand(Debugger debugger) : super(debugger, 'finish', []);

  Future run(List<String> args) {
    if (debugger.isolatePaused()) {
      var event = debugger.isolate.pauseEvent;
      if (event.kind == ServiceEvent.kPauseStart) {
        debugger.console.print(
            "Type 'continue' [F7] or 'step' [F10] to start the isolate");
        return new Future.value(null);
      }
      if (event.kind == ServiceEvent.kPauseExit) {
        debugger.console.print("Type 'continue' [F7] to exit the isolate");
        return new Future.value(null);
      }
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

  static var _boeValues = ['All', 'None', 'Unhandled'];
  static var _boolValues = ['false', 'true'];

  static var _options = {
    'break-on-exception': [_boeValues,
                           _setBreakOnException,
                           (debugger, _) => debugger.breakOnException],
    'up-is-down': [_boolValues,
                   _setUpIsDown,
                   (debugger, _) => debugger.upIsDown],
  };

  static Future _setBreakOnException(debugger, name, value) async {
    var result = await debugger.isolate.setExceptionPauseMode(value);
    if (result.isError) {
      debugger.console.print(result.toString());
    } else {
      // Printing will occur elsewhere.
      debugger.breakOnException = value;
    }
  }

  static Future _setUpIsDown(debugger, name, value) async {
    if (value == 'true') {
      debugger.upIsDown = true;
    } else {
      debugger.upIsDown = false;
    }
    debugger.console.print('${name} = ${value}');
  }

  Future run(List<String> args) async {
    if (args.length == 0) {
      for (var name in _options.keys) {
        var getHandler = _options[name][2];
        var value = await getHandler(debugger, name);
        debugger.console.print("${name} = ${value}");
      }
    } else if (args.length == 1) {
      var name = args[0].trim();
      var optionInfo = _options[name];
      if (optionInfo == null) {
        debugger.console.print("unrecognized option: $name");
        return;
      } else {
        var getHandler = optionInfo[2];
        var value = await getHandler(debugger, name);
        debugger.console.print("${name} = ${value}");
      }
    } else if (args.length == 2) {
      var name = args[0].trim();
      var value = args[1].trim();
      var optionInfo = _options[name];
      if (optionInfo == null) {
        debugger.console.print("unrecognized option: $name");
        return;
      }
      var validValues = optionInfo[0];
      if (!validValues.contains(value)) {
        debugger.console.print("'${value}' is not in ${validValues}");
        return;
      }
      var setHandler = optionInfo[1];
      await setHandler(debugger, name, value);
    } else {
      debugger.console.print("set expects 0, 1, or 2 arguments");
    }
  }

  Future<List<String>> complete(List<String> args) {
    if (args.length < 1 || args.length > 2) {
      return new Future.value([args.join('')]);
    }
    var result = [];
    if (args.length == 1) {
      var prefix = args[0];
      for (var option in _options.keys) {
        if (option.startsWith(prefix)) {
          result.add('${option} ');
        }
      }
    }
    if (args.length == 2) {
      var name = args[0].trim();
      var prefix = args[1];
      var optionInfo = _options[name];
      if (optionInfo != null) {
        var validValues = optionInfo[0];
        for (var value in validValues) {
          if (value.startsWith(prefix)) {
            result.add('${args[0]}${value} ');
          }
        }
      }
    }
    return new Future.value(result);
  }

  String helpShort =
      'Set a debugger option';

  String helpLong =
      'Set a debugger option.\n'
      '\n'
      'Known options:\n'
      '  break-on-exception    # Should the debugger break on exceptions?\n'
      "                        # ${_boeValues}\n"
      '  up-is-down            # Reverse meaning of up/down commands?\n'
      "                        # ${_boolValues}\n"
      '\n'
      'Syntax: set                    # Display all option settings\n'
      '        set <option>           # Get current value for option\n'
      '        set <option> <value>   # Set value for option';
}

class BreakCommand extends DebuggerCommand {
  BreakCommand(Debugger debugger) : super(debugger, 'break', []);

  Future run(List<String> args) async {
    if (args.length > 1) {
      debugger.console.print('not implemented');
      return;
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
        var script = loc.script;
        await script.load();
        if (loc.line < 1 || loc.line > script.lines.length) {
          debugger.console.print(
              'line number must be in range [1,${script.lines.length}]');
          return;
        }
        try {
          await debugger.isolate.addBreakpoint(script, loc.line, loc.col);
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

  String helpShort = 'Add a breakpoint by source location or function name'
      ' (hotkey: [F8])';

  String helpLong =
      'Add a breakpoint by source location or function name.\n'
      '\n'
      'Hotkey: [F8]\n'
      '\n'
      'Syntax: break                       '
      '# Break at the current position\n'
      '        break <line>                '
      '# Break at a line in the current script\n'
      '                                    '
      '  (e.g \'break 11\')\n'
      '        break <line>:<col>          '
      '# Break at a line:col in the current script\n'
      '                                    '
      '  (e.g \'break 11:8\')\n'
      '        break <script>:<line>       '
      '# Break at a line:col in a specific script\n'
      '                                    '
      '  (e.g \'break test.dart:11\')\n'
      '        break <script>:<line>:<col> '
      '# Break at a line:col in a specific script\n'
      '                                    '
      '  (e.g \'break test.dart:11:8\')\n'
      '        break <function>            '
      '# Break at the named function\n'
      '                                    '
      '  (e.g \'break main\' or \'break Class.someFunction\')\n';
}

class ClearCommand extends DebuggerCommand {
  ClearCommand(Debugger debugger) : super(debugger, 'clear', []);

  Future run(List<String> args) async {
    if (args.length > 1) {
      debugger.console.print('not implemented');
      return;
    }
    var arg = (args.length == 0 ? '' : args[0]);
    var loc = await DebuggerLocation.parse(debugger, arg);
    if (!loc.valid) {
      debugger.console.print(loc.errorMessage);
      return;
    }
    if (loc.function != null) {
      debugger.console.print(
          'Ignoring breakpoint at $loc: '
          'Clearing function breakpoints not yet implemented');
      return;
    }

    var script = loc.script;
    if (loc.line < 1 || loc.line > script.lines.length) {
      debugger.console.print(
          'line number must be in range [1,${script.lines.length}]');
      return;
    }
    var lineInfo = script.getLine(loc.line);
    var bpts = lineInfo.breakpoints;
    var foundBreakpoint = false;
    if (bpts != null) {
      var bptList = bpts.toList();
      for (var bpt in bptList) {
        if (loc.col == null ||
            loc.col == script.tokenToCol(bpt.location.tokenPos)) {
          foundBreakpoint = true;
          var result = await debugger.isolate.removeBreakpoint(bpt);
          if (result is DartError) {
            debugger.console.print(
                'Error clearing breakpoint ${bpt.number}: ${result.message}');
          }
        }
      }
    }
    if (!foundBreakpoint) {
      debugger.console.print('No breakpoint found at ${loc}');
    }
  }

  Future<List<String>> complete(List<String> args) {
    if (args.length != 1) {
      return new Future.value([args.join('')]);
    }
    return new Future.value(DebuggerLocation.complete(debugger, args[0]));
  }

  String helpShort = 'Remove a breakpoint by source location or function name'
      ' (hotkey: [F8])';

  String helpLong =
      'Remove a breakpoint by source location or function name.\n'
      '\n'
      'Hotkey: [F8]\n'
      '\n'
      'Syntax: clear                       '
      '# Clear at the current position\n'
      '        clear <line>                '
      '# Clear at a line in the current script\n'
      '                                    '
      '  (e.g \'clear 11\')\n'
      '        clear <line>:<col>          '
      '# Clear at a line:col in the current script\n'
      '                                    '
      '  (e.g \'clear 11:8\')\n'
      '        clear <script>:<line>       '
      '# Clear at a line:col in a specific script\n'
      '                                    '
      '  (e.g \'clear test.dart:11\')\n'
      '        clear <script>:<line>:<col> '
      '# Clear at a line:col in a specific script\n'
      '                                    '
      '  (e.g \'clear test.dart:11:8\')\n'
      '        clear <function>            '
      '# Clear at the named function\n'
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

  Future run(List<String> args) async {
    if (debugger.isolate.breakpoints.isEmpty) {
      debugger.console.print('No breakpoints');
    }
    List bpts = debugger.isolate.breakpoints.values.toList();
    bpts.sort((a, b) => a.number - b.number);
    for (var bpt in bpts) {
      var bpId = bpt.number;
      var locString = await bpt.location.toUserString();
      if (!bpt.resolved) {
        debugger.console.print(
            'Future breakpoint ${bpId} at ${locString}');
      } else {
        debugger.console.print(
            'Breakpoint ${bpId} at ${locString}');
      }
    }
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
    var result = [];
    for (var isolate in debugger.vm.isolates) {
      var str = isolate.number.toString();
      if (str.startsWith(args[0])) {
        result.add('$str ');
      }
    }
    for (var isolate in debugger.vm.isolates) {
      if (isolate.name.startsWith(args[0])) {
        result.add('${isolate.name} ');
      }
    }
    return new Future.value(result);
  }
  String helpShort = 'Switch the current isolate';

  String helpLong =
      'Switch, list, or rename isolates.\n'
      '\n'
      'Syntax: isolate <number>\n'
      '        isolate <name>\n';
}

String _isolateRunState(Isolate isolate) {
  if (isolate.paused) {
    return 'paused';
  } else if (isolate.running) {
    return 'running';
  } else if (isolate.idle) {
    return 'idle';
  } else {
    return 'unknown';
  }
}

class IsolateListCommand extends DebuggerCommand {
  IsolateListCommand(Debugger debugger) : super(debugger, 'list', []);

  Future run(List<String> args) async {
    if (debugger.vm == null) {
      debugger.console.print(
          "Internal error: vm has not been set");
      return;
    }

    // Refresh all isolates first.
    var pending = [];
    for (var isolate in debugger.vm.isolates) {
      pending.add(isolate.reload());
    }
    await Future.wait(pending);

    const maxIdLen = 10;
    const maxRunStateLen = 7;
    var maxNameLen = 'NAME'.length;
    for (var isolate in debugger.vm.isolates) {
      maxNameLen = max(maxNameLen, isolate.name.length);
    }
    debugger.console.print("${'ID'.padLeft(maxIdLen, ' ')} "
                           "${'ORIGIN'.padLeft(maxIdLen, ' ')} "
                           "${'NAME'.padRight(maxNameLen, ' ')} "
                           "${'STATE'.padRight(maxRunStateLen, ' ')} "
                           "CURRENT");
    for (var isolate in debugger.vm.isolates) {
      String current = (isolate == debugger.isolate ? '*' : '');
      debugger.console.print(
          "${isolate.number.toString().padLeft(maxIdLen, ' ')} "
          "${isolate.originNumber.toString().padLeft(maxIdLen, ' ')} "
          "${isolate.name.padRight(maxNameLen, ' ')} "
          "${_isolateRunState(isolate).padRight(maxRunStateLen, ' ')} "
          "${current}");
    }
    debugger.console.newline();
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

class VmListCommand extends DebuggerCommand {
  VmListCommand(Debugger debugger) : super(debugger, 'list', []);

  Future run(List<String> args) async {
    if (args.length > 0) {
      debugger.console.print('vm list expects no arguments');
      return;
    }
    if (debugger.vm == null) {
      debugger.console.print("No connected VMs");
      return;
    }
    // TODO(turnidge): Right now there is only one vm listed.
    var vmList = [debugger.vm];

    var maxAddrLen = 'ADDRESS'.length;
    var maxNameLen = 'NAME'.length;

    for (var vm in vmList) {
      maxAddrLen = max(maxAddrLen, vm.target.networkAddress.length);
      maxNameLen = max(maxNameLen, vm.name.length);
    }

    debugger.console.print("${'ADDRESS'.padRight(maxAddrLen, ' ')} "
                           "${'NAME'.padRight(maxNameLen, ' ')} "
                           "CURRENT");
    for (var vm in vmList) {
      String current = (vm == debugger.vm ? '*' : '');
      debugger.console.print(
          "${vm.target.networkAddress.padRight(maxAddrLen, ' ')} "
          "${vm.name.padRight(maxNameLen, ' ')} "
          "${current}");
    }
  }

  String helpShort = 'List all connected Dart virtual machines';

  String helpLong =
      'List all connected Dart virtual machines..\n'
      '\n'
      'Syntax: vm list\n';
}

class VmNameCommand extends DebuggerCommand {
  VmNameCommand(Debugger debugger) : super(debugger, 'name', []);

  Future run(List<String> args) async {
    if (args.length != 1) {
      debugger.console.print('vm name expects one argument');
      return;
    }
    if (debugger.vm == null) {
      debugger.console.print('There is no current vm');
      return;
    }
    await debugger.vm.setName(args[0]);
  }

  String helpShort = 'Rename the current Dart virtual machine';

  String helpLong =
      'Rename the current Dart virtual machine.\n'
      '\n'
      'Syntax: vm name <name>\n';
}

class VmRestartCommand extends DebuggerCommand {
  VmRestartCommand(Debugger debugger) : super(debugger, 'restart', []);

  Future handleModalInput(String line) async {
    if (line == 'yes') {
      debugger.console.printRed('Restarting VM...');
      await debugger.vm.restart();
      debugger.input.exitMode();
    } else if (line == 'no') {
      debugger.console.printRed('VM restart canceled.');
      debugger.input.exitMode();
    } else {
      debugger.console.printRed("Please type 'yes' or 'no'");
    }
  }

  Future run(List<String> args) async {
    debugger.input.enterMode('Restart vm? (yes/no)', handleModalInput);
  }

  String helpShort = 'Restart a Dart virtual machine';

  String helpLong =
      'Restart a Dart virtual machine.\n'
      '\n'
      'Syntax: vm restart\n';
}

class VmCommand extends DebuggerCommand {
  VmCommand(Debugger debugger) : super(debugger, 'vm', [
      new VmListCommand(debugger),
      new VmNameCommand(debugger),
      new VmRestartCommand(debugger),
  ]);

  Future run(List<String> args) async {
    debugger.console.print("'vm' expects a subcommand (see 'help vm')");
  }

  String helpShort = 'Manage a Dart virtual machine';

  String helpLong =
      'Manage a Dart virtual machine.\n'
      '\n'
      'Syntax: vm <subcommand>\n';
}

class _ConsoleStreamPrinter {
  ObservatoryDebugger _debugger;

  _ConsoleStreamPrinter(this._debugger);
  Level _minimumLogLevel = Level.OFF;
  String _savedStream;
  String _savedIsolate;
  String _savedLine;
  List<String> _buffer = [];

  void onEvent(String streamName, ServiceEvent event) {
    if (event.kind == ServiceEvent.kLogging) {
      // Check if we should print this log message.
      if (event.logRecord['level'].value < _minimumLogLevel.value) {
        return;
      }
    }
    String isolateName = event.isolate.name;
    // If we get a line from a different isolate/stream, flush
    // any pending output, even if it is not newline-terminated.
    if ((_savedIsolate != null && isolateName != _savedIsolate) ||
        (_savedStream != null && streamName != _savedStream)) {
       flush();
    }
    String data;
    bool hasNewline;
    if (event.kind == ServiceEvent.kLogging) {
      data = event.logRecord["message"].valueAsString;
      hasNewline = true;
    } else {
      data = event.bytesAsString;
      hasNewline = data.endsWith('\n');
    }
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
  final SettingsGroup settings = new SettingsGroup('debugger');
  RootCommand cmd;
  DebuggerPageElement page;
  DebuggerConsoleElement console;
  DebuggerInputElement input;
  DebuggerStackElement stackElement;
  ServiceMap stack;
  String breakOnException = "none";  // Last known setting.

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

  bool get upIsDown => _upIsDown;
  void set upIsDown(bool value) {
    settings.set('up-is-down', value);
    _upIsDown = value;
  }
  bool _upIsDown;

  void upFrame(int count) {
    if (_upIsDown) {
      currentFrame += count;
    } else {
      currentFrame -= count;
    }
  }

  void downFrame(int count) {
    if (_upIsDown) {
      currentFrame -= count;
    } else {
      currentFrame += count;
    }
  }

  int get stackDepth => stack['frames'].length;

  ObservatoryDebugger() {
    _loadSettings();
    cmd = new RootCommand([
        new AsyncNextCommand(this),
        new BreakCommand(this),
        new ClearCommand(this),
        new ClsCommand(this),
        new ContinueCommand(this),
        new DeleteCommand(this),
        new DownCommand(this),
        new FinishCommand(this),
        new FrameCommand(this),
        new HelpCommand(this),
        new InfoCommand(this),
        new IsolateCommand(this),
        new LogCommand(this),
        new PauseCommand(this),
        new PrintCommand(this),
        new RefreshCommand(this),
        new SetCommand(this),
        new SmartNextCommand(this),
        new StepCommand(this),
        new SyncNextCommand(this),
        new UpCommand(this),
        new VmCommand(this),
    ]);
    _consolePrinter = new _ConsoleStreamPrinter(this);
  }

  void _loadSettings() {
    _upIsDown = settings.get('up-is-down');
  }

  VM get vm => page.app.vm;

  void updateIsolate(Isolate iso) {
    _isolate = iso;
    if (_isolate != null) {
      if ((breakOnException != iso.exceptionsPauseInfo) &&
          (iso.exceptionsPauseInfo != null)) {
        breakOnException = iso.exceptionsPauseInfo;
      }

      _isolate.reload().then((response) {
        if (response.isSentinel) {
          // The isolate has gone away.  The IsolateExit event will
          // clear the isolate for the debugger page.
          return;
        }
        // TODO(turnidge): Currently the debugger relies on all libs
        // being loaded.  Fix this.
        var pending = [];
        for (var lib in response.libraries) {
          if (!lib.loaded) {
            pending.add(lib.load());
          }
        }
        Future.wait(pending).then((_) {
          refreshStack();
        }).catchError((e) {
          print("UNEXPECTED ERROR $e");
          reportStatus();
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

  Future refreshStack() async {
    try {
      if (_isolate != null) {
        await _refreshStack(_isolate.pauseEvent);
      }
      flushStdio();
      reportStatus();
    } catch (e, st) {
      console.printRed("Unexpected error in refreshStack: $e\n$st");
    }
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
      if (result.isSentinel) {
        // The isolate has gone away.  The IsolateExit event will
        // clear the isolate for the debugger page.
        return;
      }
      stack = result;
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

  void _reportIsolateError(Isolate isolate, String eventKind) {
    if (isolate == null) {
      return;
    }
    DartError error = isolate.error;
    if (error == null) {
      return;
    }
    console.newline();
    if (eventKind == ServiceEvent.kPauseException) {
      console.printBold('Isolate will exit due to an unhandled exception:');
    } else {
      console.printBold('Isolate has exited due to an unhandled exception:');
    }
    console.print(error.message);
    console.newline();
    if (eventKind == ServiceEvent.kPauseException &&
        (error.exception.isStackOverflowError ||
         error.exception.isOutOfMemoryError)) {
      console.printBold(
          'When an unhandled stack overflow or OOM exception occurs, the VM '
          'has run out of memory and cannot keep the stack alive while '
          'paused.');
    } else {
      console.printBold("Type 'set break-on-exception Unhandled' to pause the"
                        " isolate when an unhandled exception occurs.");
      console.printBold("You can make this the default by running with "
                        "--pause-isolates-on-unhandled-exceptions");
    }
  }

  void _reportPause(ServiceEvent event) {
    if (event.kind == ServiceEvent.kNone) {
      console.print("Paused until embedder makes the isolate runnable.");
    } else if (event.kind == ServiceEvent.kPauseStart) {
      console.print(
          "Paused at isolate start "
          "(type 'continue' [F7] or 'step' [F10] to start the isolate')");
    } else if (event.kind == ServiceEvent.kPauseExit) {
      console.print(
          "Paused at isolate exit "
          "(type 'continue' or [F7] to exit the isolate')");
      _reportIsolateError(isolate, event.kind);
    } else if (event.kind == ServiceEvent.kPauseException) {
      console.print(
          "Paused at an unhandled exception "
          "(type 'continue' or [F7] to exit the isolate')");
      _reportIsolateError(isolate, event.kind);
    } else if (stack['frames'].length > 0) {
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
      });
    } else {
      console.print("Paused in message loop (type 'continue' or [F7] "
                    "to resume processing messages)");
    }
  }

  Future _reportBreakpointEvent(ServiceEvent event) async {
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
    await script.load();

    var bpId = bpt.number;
    var locString = await bpt.location.toUserString();
    if (bpt.resolved) {
      console.print(
          'Breakpoint ${bpId} ${verb} at ${locString}');
    } else {
      console.print(
          'Future breakpoint ${bpId} ${verb} at ${locString}');
    }
  }

  void onEvent(ServiceEvent event) {
    switch(event.kind) {
      case ServiceEvent.kVMUpdate:
        var vm = event.owner;
        console.print("VM ${vm.target.networkAddress} renamed to '${vm.name}'");
        break;

      case ServiceEvent.kIsolateStart:
        {
          var iso = event.owner;
          console.print(
              "Isolate ${iso.number} '${iso.name}' has been created");
          if (isolate == null) {
            console.print("Switching to isolate ${iso.number} '${iso.name}'");
            isolate = iso;
          }
        }
        break;

      case ServiceEvent.kIsolateExit:
        {
          var iso = event.owner;
          if (iso == isolate) {
            console.print("The current isolate ${iso.number} '${iso.name}' "
                          "has exited");
            var isolates = vm.isolates;
            if (isolates.length > 0) {
              var newIsolate = isolates.first;
              console.print("Switching to isolate "
                            "${newIsolate.number} '${newIsolate.name}'");
              isolate = newIsolate;
            } else {
              isolate = null;
            }
          } else {
            console.print(
                "Isolate ${iso.number} '${iso.name}' has exited");
          }
        }
        break;

      case ServiceEvent.kDebuggerSettingsUpdate:
        if (breakOnException != event.exceptions) {
          breakOnException = event.exceptions;
          console.print("Now pausing for exceptions: $breakOnException");
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
          _refreshStack(event).then((_) async {
            flushStdio();
            if (isolate != null) {
              await isolate.reload();
            }
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

      case ServiceEvent.kIsolateRunnable:
      case ServiceEvent.kGraph:
      case ServiceEvent.kGC:
      case ServiceEvent.kInspect:
        // Ignore.
        break;

      case ServiceEvent.kLogging:
        _consolePrinter.onEvent(event.logRecord['level'].name, event);
        break;

      default:
        console.print('Unrecognized event: $event');
        break;
    }
  }

  _ConsoleStreamPrinter _consolePrinter;

  void flushStdio() {
    _consolePrinter.flush();
  }

  void onStdout(ServiceEvent event) {
    _consolePrinter.onEvent('stdout', event);
  }

  void onStderr(ServiceEvent event) {
    _consolePrinter.onEvent('stderr', event);
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
        // Ambiguous completion.
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

  Future pause() {
    if (!isolatePaused()) {
      return isolate.pause();
    } else {
      console.print('The program is already paused');
      return new Future.value(null);
    }
  }

  Future resume() {
    if (isolatePaused()) {
      return isolate.resume().then((_) {
          warnOutOfDate();
        });
    } else {
      console.print('The program must be paused');
      return new Future.value(null);
    }
  }

  Future toggleBreakpoint() async {
    var loc = await DebuggerLocation.parse(this, '');
    var script = loc.script;
    var line = loc.line;
    if (script != null && line != null) {
      var bpts = script.getLine(line).breakpoints;
      if (bpts == null || bpts.isEmpty) {
        // Set a new breakpoint.
        // TODO(turnidge): Set this breakpoint at current column.
        await isolate.addBreakpoint(script, line);
      } else {
        // TODO(turnidge): Clear this breakpoint at current column.
        var pending = [];
        for (var bpt in bpts) {
          pending.add(isolate.removeBreakpoint(bpt));
        }
        await Future.wait(pending);
      }
    }
    return new Future.value(null);
  }


  Future smartNext() async {
    if (isolatePaused()) {
      var event = isolate.pauseEvent;
      if (event.atAsyncSuspension) {
        return asyncNext();
      } else {
        return syncNext();
      }
    } else {
      console.print('The program is already running');
    }
  }

  Future asyncNext() async {
    if (isolatePaused()) {
      var event = isolate.pauseEvent;
      if (!event.atAsyncSuspension) {
        console.print("No async continuation at this location");
      } else {
        return isolate.stepOverAsyncSuspension();
      }
    } else {
      console.print('The program is already running');
    }
  }

  Future syncNext() async {
    if (isolatePaused()) {
      var event = isolate.pauseEvent;
      if (event.kind == ServiceEvent.kPauseStart) {
        console.print("Type 'continue' [F7] or 'step' [F10] to start the isolate");
        return null;
      }
      if (event.kind == ServiceEvent.kPauseExit) {
        console.print("Type 'continue' [F7] to exit the isolate");
        return null;
      }
      return isolate.stepOver();
    } else {
      console.print('The program is already running');
      return null;
    }
  }

  Future step() {
    if (isolatePaused()) {
      var event = isolate.pauseEvent;
      if (event.kind == ServiceEvent.kPauseExit) {
        console.print("Type 'continue' [F7] to exit the isolate");
        return new Future.value(null);
      }
      return isolate.stepInto();
    } else {
      console.print('The program is already running');
      return new Future.value(null);
    }
  }
}

@CustomTag('debugger-page')
class DebuggerPageElement extends ObservatoryElement {
  @published Isolate isolate;

  isolateChanged(oldValue) {
    debugger.updateIsolate(isolate);
  }
  ObservatoryDebugger debugger = new ObservatoryDebugger();

  DebuggerPageElement.created() : super.created() {
    debugger.page = this;
  }

  StreamSubscription _resizeSubscription;
  Future<StreamSubscription> _vmSubscriptionFuture;
  Future<StreamSubscription> _isolateSubscriptionFuture;
  Future<StreamSubscription> _debugSubscriptionFuture;
  Future<StreamSubscription> _stdoutSubscriptionFuture;
  Future<StreamSubscription> _stderrSubscriptionFuture;
  Future<StreamSubscription> _logSubscriptionFuture;

  @override
  void attached() {
    super.attached();
    _onResize(null);

    // Wire the debugger object to the stack, console, and command line.
    var stackElement = $['stackElement'];
    debugger.stackElement = stackElement;
    stackElement.debugger = debugger;
    stackElement.scroller = $['stackDiv'];
    debugger.console = $['console'];
    debugger.input = $['commandline'];
    debugger.input.debugger = debugger;
    debugger.init();

    _resizeSubscription = window.onResize.listen(_onResize);
    _vmSubscriptionFuture =
        app.vm.listenEventStream(VM.kVMStream, debugger.onEvent);
    _isolateSubscriptionFuture =
        app.vm.listenEventStream(VM.kIsolateStream, debugger.onEvent);
    _debugSubscriptionFuture =
        app.vm.listenEventStream(VM.kDebugStream, debugger.onEvent);
    _stdoutSubscriptionFuture =
        app.vm.listenEventStream(VM.kStdoutStream, debugger.onStdout);
    if (_stdoutSubscriptionFuture != null) {
      // TODO(turnidge): How do we want to handle this in general?
      _stdoutSubscriptionFuture.catchError((e, st) {
        Logger.root.info('Failed to subscribe to stdout: $e\n$st\n');
        _stdoutSubscriptionFuture = null;
      });
    }
    _stderrSubscriptionFuture =
        app.vm.listenEventStream(VM.kStderrStream, debugger.onStderr);
    if (_stderrSubscriptionFuture != null) {
      // TODO(turnidge): How do we want to handle this in general?
      _stderrSubscriptionFuture.catchError((e, st) {
        Logger.root.info('Failed to subscribe to stderr: $e\n$st\n');
        _stderrSubscriptionFuture = null;
      });
    }
    _logSubscriptionFuture =
        app.vm.listenEventStream(Isolate.kLoggingStream, debugger.onEvent);
    // Turn on the periodic poll timer for this page.
    pollPeriod = const Duration(milliseconds:100);

    onClick.listen((event) {
      // Random clicks should focus on the text box.  If the user selects
      // a range, don't interfere.
      var selection = window.getSelection();
      if (selection == null ||
          (selection.type != 'Range' && selection.type != 'text')) {
        debugger.input.focus();
      }
    });
  }

  void onPoll() {
    debugger.flushStdio();
  }

  void _onResize(_) {
    var navbarDiv = $['navbarDiv'];
    var stackDiv = $['stackDiv'];
    var splitterDiv = $['splitterDiv'];
    var cmdDiv = $['commandDiv'];

    // For now, force navbar height to 40px in the debugger.
    int navbarHeight = NavBarElement.height;
    int splitterHeight = splitterDiv.clientHeight;
    int cmdHeight = cmdDiv.clientHeight;

    int windowHeight = window.innerHeight;
    int fixedHeight = navbarHeight + splitterHeight + cmdHeight;
    int available = windowHeight - fixedHeight;
    int stackHeight = available ~/ 1.6;
    navbarDiv.style.setProperty('height', '${navbarHeight}px');
    stackDiv.style.setProperty('height', '${stackHeight}px');
  }

  @override
  void detached() {
    debugger.isolate = null;
    _resizeSubscription.cancel();
    _resizeSubscription = null;
    cancelFutureSubscription(_vmSubscriptionFuture);
    _vmSubscriptionFuture = null;
    cancelFutureSubscription(_isolateSubscriptionFuture);
    _isolateSubscriptionFuture = null;
    cancelFutureSubscription(_debugSubscriptionFuture);
    _debugSubscriptionFuture = null;
    cancelFutureSubscription(_stdoutSubscriptionFuture);
    _stdoutSubscriptionFuture = null;
    cancelFutureSubscription(_stderrSubscriptionFuture);
    _stderrSubscriptionFuture = null;
    cancelFutureSubscription(_logSubscriptionFuture);
    _logSubscriptionFuture = null;
    super.detached();
  }
}

@CustomTag('debugger-stack')
class DebuggerStackElement extends ObservatoryElement {
  @published Isolate isolate;
  @published Element scroller;
  @observable bool hasStack = false;
  @observable bool hasMessages = false;
  @observable bool isSampled = false;
  @observable int currentFrame;
  ObservatoryDebugger debugger;

  _addFrame(List frameList, Frame frameInfo) {
    DebuggerFrameElement frameElement = new Element.tag('debugger-frame');
    frameElement.frame = frameInfo;
    frameElement.scroller = scroller;

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
  @published Element scroller;

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
        _expand();
        scrollIntoView();
      } else {
        frameOuter.classes.remove('current');
        if (_pinned) {
          _expand();
        } else {
          _unexpand();
        }
      }
      busy = false;
    });
  }

  @observable String scriptHeight;
  @observable bool expanded = false;
  @observable bool busy = false;

  DebuggerFrameElement.created() : super.created();

  String makeExpandKey(String key) {
    return '${frame.function.qualifiedName}/${key}';
  }

  bool matchFrame(Frame newFrame) {
    return newFrame.function.id == frame.function.id;
  }

  void updateFrame(Frame newFrame) {
    assert(matchFrame(newFrame));
    frame = newFrame;
  }

  Script get script => frame.location.script;

  int _varsTop(varsDiv) {
    const minTop = 5;
    if (varsDiv == null) {
      return minTop;
    }
    const navbarHeight = NavBarElement.height;
    const bottomPad = 6;
    var parent = varsDiv.parent.getBoundingClientRect();
    var varsHeight = varsDiv.clientHeight;
    var maxTop = parent.height - (varsHeight + bottomPad);
    var adjustedTop = navbarHeight - parent.top;
    return (max(minTop, min(maxTop, adjustedTop)));
  }

  void _onScroll(event) {
    if (!expanded) {
      return;
    }
    var varsDiv = shadowRoot.querySelector('#vars');
    if (varsDiv == null) {
      return;
    }
    var currentTop = varsDiv.style.top;
    var newTop = _varsTop(varsDiv);
    if (currentTop != newTop) {
      varsDiv.style.top = '${newTop}px';
    }
  }

  void _expand() {
    var frameOuter = $['frameOuter'];
    expanded = true;
    frameOuter.classes.add('shadow');
    _subscribeToScroll();
  }

  void _unexpand() {
    var frameOuter = $['frameOuter'];
    expanded = false;
    _unsubscribeToScroll();
    frameOuter.classes.remove('shadow');
  }

  StreamSubscription _scrollSubscription;
  StreamSubscription _resizeSubscription;

  void _subscribeToScroll() {
    if (scroller != null) {
      if (_scrollSubscription == null) {
        _scrollSubscription = scroller.onScroll.listen(_onScroll);
      }
      if (_resizeSubscription == null) {
        _resizeSubscription = window.onResize.listen(_onScroll);
      }
    }
  }

  void _unsubscribeToScroll() {
    if (_scrollSubscription != null) {
      _scrollSubscription.cancel();
      _scrollSubscription = null;
    }
    if (_resizeSubscription != null) {
      _resizeSubscription.cancel();
      _resizeSubscription = null;
    }
  }

  @override
  void attached() {
    super.attached();
    int windowHeight = window.innerHeight;
    scriptHeight = '${windowHeight ~/ 1.6}px';
    if (expanded) {
      _subscribeToScroll();
    }
  }

  void detached() {
    _unsubscribeToScroll();
    super.detached();
  }

  void toggleExpand(var a, var b, var c) {
    if (busy) {
      return;
    }
    busy = true;
    frame.function.load().then((func) {
        _pinned = !_pinned;
        if (_pinned) {
          _expand();
        } else {
          _unexpand();
        }
        busy = false;
      });
  }

  @observable
  get properLocals {
    var locals = new List();
    var homeMethod = frame.function.homeMethod;
    if (homeMethod.dartOwner is Class && homeMethod.isStatic) {
      locals.add(
          {'name' : '<class>',
           'value' : homeMethod.dartOwner});
    } else if (homeMethod.dartOwner is Library) {
      locals.add(
          {'name' : '<library>',
           'value' : homeMethod.dartOwner});
    }
    locals.addAll(frame.variables);
    return locals;
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

  /// Is [container] scrolled to the within [threshold] pixels of the bottom?
  static bool _isScrolledToBottom(DivElement container, [int threshold = 2]) {
    if (container == null) {
      return false;
    }
    // scrollHeight -> complete height of element including scrollable area.
    // clientHeight -> height of element on page.
    // scrollTop -> how far is an element scrolled (from 0 to scrollHeight).
    final distanceFromBottom =
        container.scrollHeight - container.clientHeight - container.scrollTop;
    const threshold = 2;  // 2 pixel slop.
    return distanceFromBottom <= threshold;
  }

  /// Scroll [container] so the bottom content is visible.
  static _scrollToBottom(DivElement container) {
    if (container == null) {
      return;
    }
    // Adjust scroll so that the bottom of the content is visible.
    container.scrollTop = container.scrollHeight - container.clientHeight;
  }

  void _append(HtmlElement span) {
    var consoleTextElement = $['consoleText'];
    bool autoScroll = _isScrolledToBottom(parent);
    consoleTextElement.children.add(span);
    if (autoScroll) {
      _scrollToBottom(parent);
    }
  }

  void print(String line, { bool newline:true }) {
    var span = new SpanElement();
    span.classes.add('normal');
    span.appendText(line);
    if (newline) {
      span.appendText('\n');
    }
    _append(span);
  }

  void printBold(String line, { bool newline:true }) {
    var span = new SpanElement();
    span.classes.add('bold');
    span.appendText(line);
    if (newline) {
      span.appendText('\n');
    }
    _append(span);
  }

  void printRed(String line, { bool newline:true }) {
    var span = new SpanElement();
    span.classes.add('red');
    span.appendText(line);
    if (newline) {
      span.appendText('\n');
    }
    _append(span);
  }

  void printStdio(List<String> lines) {
    var consoleTextElement = $['consoleText'];
    bool autoScroll = _isScrolledToBottom(parent);
    for (var line in lines) {
      var span = new SpanElement();
      span.classes.add('green');
      span.appendText(line);
      span.appendText('\n');
      consoleTextElement.children.add(span);
    }
    if (autoScroll) {
      _scrollToBottom(parent);
    }
  }

  void printRef(Instance ref, { bool newline:true }) {
    var refElement = new Element.tag('instance-ref');
    refElement.ref = ref;
    _append(refElement);
    if (newline) {
      this.newline();
    }
  }

  void newline() {
    _append(new BRElement());
  }

  void clear() {
    var consoleTextElement = $['consoleText'];
    consoleTextElement.children.clear();
  }
}

@CustomTag('debugger-input')
class DebuggerInputElement extends ObservatoryElement {
  @published Isolate isolate;
  @published String text = '';
  @observable ObservatoryDebugger debugger;
  @observable bool busy = false;
  @observable String modalPrompt = null;
  var modalCallback = null;

  void enterMode(String prompt, callback) {
    assert(modalPrompt == null);
    modalPrompt = prompt;
    modalCallback = callback;
  }

  void exitMode() {
    assert(modalPrompt != null);
    modalPrompt = null;
    modalCallback = null;
  }

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
        if (modalCallback != null) {
          if (e.keyCode == KeyCode.ENTER) {
            var response = text;
            modalCallback(response).whenComplete(() {
              text = '';
              busy = false;
            });
          } else {
            busy = false;
          }
          return;
        }
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

          case KeyCode.PAGE_UP:
            e.preventDefault();
            try {
              debugger.upFrame(1);
            } on RangeError catch (_) {
              // Ignore.
            }
            busy = false;
            break;

          case KeyCode.PAGE_DOWN:
            e.preventDefault();
            try {
              debugger.downFrame(1);
            } on RangeError catch (_) {
              // Ignore.
            }
            busy = false;
            break;

          case KeyCode.F7:
            e.preventDefault();
            debugger.resume().whenComplete(() {
              busy = false;
            });
            break;

          case KeyCode.F8:
            e.preventDefault();
            debugger.toggleBreakpoint().whenComplete(() {
              busy = false;
            });
            break;

          case KeyCode.F9:
            e.preventDefault();
            debugger.smartNext().whenComplete(() {
              busy = false;
            });
            break;

          case KeyCode.F10:
            e.preventDefault();
            debugger.step().whenComplete(() {
              busy = false;
            });
            break;

          case KeyCode.SEMICOLON:
            if (e.ctrlKey) {
              e.preventDefault();
              debugger.console.printRed('^;');
              debugger.pause().whenComplete(() {
                busy = false;
              });
            } else {
              busy = false;
            }
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
