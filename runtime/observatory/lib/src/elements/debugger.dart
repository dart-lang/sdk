// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library debugger_page_element;

import 'dart:async';
import 'dart:html';
import 'dart:math';
import 'dart:svg';

import 'package:logging/logging.dart';
import 'package:observatory/app.dart';
import 'package:observatory/cli.dart';
import 'package:observatory/debugger.dart';
import 'package:observatory/event.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/service.dart' as S;
import 'package:observatory/service_common.dart';
import 'package:observatory/src/elements/function_ref.dart';
import 'package:observatory/src/elements/helpers/any_ref.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/instance_ref.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/src/elements/source_inset.dart';
import 'package:observatory/src/elements/source_link.dart';

// TODO(turnidge): Move Debugger, DebuggerCommand to debugger library.
abstract class DebuggerCommand extends Command {
  ObservatoryDebugger debugger;

  DebuggerCommand(this.debugger, name, children) : super(name, children);

  String get helpShort;
  String get helpLong;
}

// TODO(turnidge): Rewrite HelpCommand so that it is a general utility
// provided by the cli library.
class HelpCommand extends DebuggerCommand {
  HelpCommand(Debugger debugger)
      : super(debugger, 'help', [
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

  String helpShort =
      'List commands or provide details about a specific command';

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

  String helpLong = 'Provide a list of key hotkeys.\n'
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
    var response =
        await debugger.isolate.evalFrame(debugger.currentFrame, expression);
    if (response is S.DartError) {
      debugger.console.print(response.message);
    } else {
      debugger.console.print('= ', newline: false);
      debugger.console.printRef(debugger.isolate, response, debugger.objects);
    }
  }

  String helpShort = 'Evaluate and print an expression in the current frame';

  String helpLong = 'Evaluate and print an expression in the current frame.\n'
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
      debugger.console.print('frame must be in range [${e.start}..${e.end-1}]');
    }
    return new Future.value(null);
  }

  String helpShort = 'Move down one or more frames (hotkey: [Page Down])';

  String helpLong = 'Move down one or more frames.\n'
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
      debugger.console.print('frame must be in range [${e.start}..${e.end-1}]');
    }
    return new Future.value(null);
  }

  String helpShort = 'Move up one or more frames (hotkey: [Page Up])';

  String helpLong = 'Move up one or more frames.\n'
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
      debugger.console.print('frame must be in range [${e.start}..${e.end-1}]');
    }
    return new Future.value(null);
  }

  String helpShort = 'Set the current frame';

  String helpLong = 'Set the current frame.\n'
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

  String helpLong = 'Pause the isolate.\n'
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

  String helpLong = 'Continue running the isolate.\n'
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

  String helpShort = 'Run until return/unwind to current activation.';

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

  String helpShort = 'Step over await or yield';

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

class RewindCommand extends DebuggerCommand {
  RewindCommand(Debugger debugger) : super(debugger, 'rewind', []);

  Future run(List<String> args) async {
    try {
      int count = 1;
      if (args.length == 1) {
        count = int.parse(args[0]);
      } else if (args.length > 1) {
        debugger.console.print('rewind expects 0 or 1 argument');
        return;
      } else if (count < 1 || count > debugger.stackDepth) {
        debugger.console
            .print('frame must be in range [1..${debugger.stackDepth - 1}]');
        return;
      }
      await debugger.rewind(count);
    } on S.ServerRpcException catch (e) {
      if (e.code == S.ServerRpcException.kCannotResume) {
        debugger.console.printRed(e.data['details']);
      } else {
        rethrow;
      }
    }
  }

  String helpShort = 'Rewind the stack to a previous frame';

  String helpLong = 'Rewind the stack to a previous frame.\n'
      '\n'
      'Syntax: rewind\n'
      '        rewind <count>\n';
}

class ReloadCommand extends DebuggerCommand {
  ReloadCommand(Debugger debugger) : super(debugger, 'reload', []);

  Future run(List<String> args) async {
    try {
      if (args.length > 0) {
        debugger.console.print('reload expects no arguments');
        return;
      }
      await debugger.isolate.reloadSources();
      debugger.console.print('reload complete');
      await debugger.refreshStack();
    } on S.ServerRpcException catch (e) {
      if (e.code == S.ServerRpcException.kIsolateReloadBarred ||
          e.code == S.ServerRpcException.kIsolateIsReloading) {
        debugger.console.printRed(e.data['details']);
      } else {
        rethrow;
      }
    }
  }

  String helpShort = 'Reload the sources for the current isolate';

  String helpLong = 'Reload the sources for the current isolate.\n'
      '\n'
      'Syntax: reload\n';
}

class ClsCommand extends DebuggerCommand {
  ClsCommand(Debugger debugger) : super(debugger, 'cls', []) {}

  Future run(List<String> args) {
    debugger.console.clear();
    debugger.console.newline();
    return new Future.value(null);
  }

  String helpShort = 'Clear the console';

  String helpLong = 'Clear the console.\n'
      '\n'
      'Syntax: cls\n';
}

class LogCommand extends DebuggerCommand {
  LogCommand(Debugger debugger) : super(debugger, 'log', []);

  Future run(List<String> args) async {
    if (args.length == 0) {
      debugger.console.print('Current log level: '
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

  String helpShort = 'Control which log messages are displayed';

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
      if (event is M.PauseStartEvent) {
        debugger.console
            .print("Type 'continue' [F7] or 'step' [F10] to start the isolate");
        return new Future.value(null);
      }
      if (event is M.PauseExitEvent) {
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
  SetCommand(Debugger debugger) : super(debugger, 'set', []);

  static var _boeValues = ['All', 'None', 'Unhandled'];
  static var _boolValues = ['false', 'true'];

  static var _options = {
    'break-on-exception': [
      _boeValues,
      _setBreakOnException,
      (debugger, _) => debugger.breakOnException
    ],
    'up-is-down': [
      _boolValues,
      _setUpIsDown,
      (debugger, _) => debugger.upIsDown
    ],
    'causal-async-stacks': [
      _boolValues,
      _setCausalAsyncStacks,
      (debugger, _) => debugger.saneAsyncStacks
    ],
    'awaiter-stacks': [
      _boolValues,
      _setAwaiterStacks,
      (debugger, _) => debugger.awaiterStacks
    ]
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

  static Future _setCausalAsyncStacks(debugger, name, value) async {
    if (value == 'true') {
      debugger.causalAsyncStacks = true;
    } else {
      debugger.causalAsyncStacks = false;
    }
    debugger.refreshStack();
    debugger.console.print('${name} = ${value}');
  }

  static Future _setAwaiterStacks(debugger, name, value) async {
    debugger.awaiterStacks = (value == 'true');
    debugger.refreshStack();
    debugger.console.print('${name} == ${value}');
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

  String helpShort = 'Set a debugger option';

  String helpLong = 'Set a debugger option.\n'
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
        } on S.ServerRpcException catch (e) {
          if (e.code == S.ServerRpcException.kCannotAddBreakpoint) {
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
              'line number must be in range [1..${script.lines.length}]');
          return;
        }
        try {
          await debugger.isolate.addBreakpoint(script, loc.line, loc.col);
        } on S.ServerRpcException catch (e) {
          if (e.code == S.ServerRpcException.kCannotAddBreakpoint) {
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

  String helpLong = 'Add a breakpoint by source location or function name.\n'
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
      debugger.console.print('Ignoring breakpoint at $loc: '
          'Clearing function breakpoints not yet implemented');
      return;
    }

    var script = loc.script;
    if (loc.line < 1 || loc.line > script.lines.length) {
      debugger.console
          .print('line number must be in range [1..${script.lines.length}]');
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
          if (result is S.DartError) {
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

  String helpLong = 'Remove a breakpoint by source location or function name.\n'
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

  String helpLong = 'Remove a breakpoint by breakpoint id.\n'
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
        debugger.console.print('Future breakpoint ${bpId} at ${locString}');
      } else {
        debugger.console.print('Breakpoint ${bpId} at ${locString}');
      }
    }
  }

  String helpShort = 'List all breakpoints';

  String helpLong = 'List all breakpoints.\n'
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

  String helpLong = 'Show current frame.\n'
      '\n'
      'Syntax: info frame\n';
}

class IsolateCommand extends DebuggerCommand {
  IsolateCommand(Debugger debugger)
      : super(debugger, 'isolate', [
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
    var num = int.parse(arg, onError: (_) => null);

    var candidate;
    for (var isolate in debugger.vm.isolates) {
      if (num != null && num == isolate.number) {
        candidate = isolate;
        break;
      } else if (arg == isolate.name) {
        if (candidate != null) {
          debugger.console.print("Isolate identifier '${arg}' is ambiguous: "
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
        new AnchorElement(href: Uris.debugger(candidate)).click();
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

  String helpShort = 'Switch, list, rename, or reload isolates';

  String helpLong = 'Switch the current isolate.\n'
      '\n'
      'Syntax: isolate <number>\n'
      '        isolate <name>\n';
}

String _isolateRunState(S.Isolate isolate) {
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
      debugger.console.print("Internal error: vm has not been set");
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
      debugger.console
          .print("${isolate.number.toString().padLeft(maxIdLen, ' ')} "
              "${isolate.originNumber.toString().padLeft(maxIdLen, ' ')} "
              "${isolate.name.padRight(maxNameLen, ' ')} "
              "${_isolateRunState(isolate).padRight(maxRunStateLen, ' ')} "
              "${current}");
    }
    debugger.console.newline();
  }

  String helpShort = 'List all isolates';

  String helpLong = 'List all isolates.\n'
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

  String helpShort = 'Rename the current isolate';

  String helpLong = 'Rename the current isolate.\n'
      '\n'
      'Syntax: isolate name <name>\n';
}

class InfoCommand extends DebuggerCommand {
  InfoCommand(Debugger debugger)
      : super(debugger, 'info', [
          new InfoBreakpointsCommand(debugger),
          new InfoFrameCommand(debugger)
        ]);

  Future run(List<String> args) {
    debugger.console.print("'info' expects a subcommand (see 'help info')");
    return new Future.value(null);
  }

  String helpShort = 'Show information on a variety of topics';

  String helpLong = 'Show information on a variety of topics.\n'
      '\n'
      'Syntax: info <subcommand>\n';
}

class RefreshStackCommand extends DebuggerCommand {
  RefreshStackCommand(Debugger debugger) : super(debugger, 'stack', []);

  Future run(List<String> args) {
    return debugger.refreshStack();
  }

  String helpShort = 'Refresh isolate stack';

  String helpLong = 'Refresh isolate stack.\n'
      '\n'
      'Syntax: refresh stack\n';
}

class RefreshCommand extends DebuggerCommand {
  RefreshCommand(Debugger debugger)
      : super(debugger, 'refresh', [
          new RefreshStackCommand(debugger),
        ]);

  Future run(List<String> args) {
    debugger.console
        .print("'refresh' expects a subcommand (see 'help refresh')");
    return new Future.value(null);
  }

  String helpShort = 'Refresh debugging information of various sorts';

  String helpLong = 'Refresh debugging information of various sorts.\n'
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
      debugger.console
          .print("${vm.target.networkAddress.padRight(maxAddrLen, ' ')} "
              "${vm.name.padRight(maxNameLen, ' ')} "
              "${current}");
    }
  }

  String helpShort = 'List all connected Dart virtual machines';

  String helpLong = 'List all connected Dart virtual machines..\n'
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

  String helpLong = 'Rename the current Dart virtual machine.\n'
      '\n'
      'Syntax: vm name <name>\n';
}

class VmCommand extends DebuggerCommand {
  VmCommand(Debugger debugger)
      : super(debugger, 'vm', [
          new VmListCommand(debugger),
          new VmNameCommand(debugger),
        ]);

  Future run(List<String> args) async {
    debugger.console.print("'vm' expects a subcommand (see 'help vm')");
  }

  String helpShort = 'Manage a Dart virtual machine';

  String helpLong = 'Manage a Dart virtual machine.\n'
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

  void onEvent(String streamName, S.ServiceEvent event) {
    if (event.kind == S.ServiceEvent.kLogging) {
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
    if (event.kind == S.ServiceEvent.kLogging) {
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
  S.ServiceMap stack;
  final S.Isolate isolate;
  String breakOnException = "none"; // Last known setting.

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

  bool get causalAsyncStacks => _causalAsyncStacks;
  void set causalAsyncStacks(bool value) {
    settings.set('causal-async-stacks', value);
    _causalAsyncStacks = value;
  }

  bool _causalAsyncStacks;

  bool get awaiterStacks => _awaiterStacks;
  void set awaiterStacks(bool value) {
    settings.set('awaiter-stacks', value);
    _causalAsyncStacks = value;
  }

  bool _awaiterStacks;

  static const String kAwaiterStackFrames = 'awaiterFrames';
  static const String kAsyncCausalStackFrames = 'asyncCausalFrames';
  static const String kStackFrames = 'frames';

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

  int get stackDepth {
    if (awaiterStacks) {
      var awaiterStackFrames = stack[kAwaiterStackFrames];
      if (awaiterStackFrames != null) {
        return awaiterStackFrames.length;
      }
    }
    if (causalAsyncStacks) {
      var asyncCausalStackFrames = stack[kAsyncCausalStackFrames];
      if (asyncCausalStackFrames != null) {
        return asyncCausalStackFrames.length;
      }
    }
    return stack[kStackFrames].length;
  }

  List get stackFrames {
    if (awaiterStacks) {
      var awaiterStackFrames = stack[kAwaiterStackFrames];
      if (awaiterStackFrames != null) {
        return awaiterStackFrames;
      }
    }
    if (causalAsyncStacks) {
      var asyncCausalStackFrames = stack[kAsyncCausalStackFrames];
      if (asyncCausalStackFrames != null) {
        return asyncCausalStackFrames;
      }
    }
    return stack[kStackFrames] ?? [];
  }

  static final _history = [''];

  ObservatoryDebugger(this.isolate) {
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
      new ReloadCommand(this),
      new RefreshCommand(this),
      new RewindCommand(this),
      new SetCommand(this),
      new SmartNextCommand(this),
      new StepCommand(this),
      new SyncNextCommand(this),
      new UpCommand(this),
      new VmCommand(this),
    ], _history);
    _consolePrinter = new _ConsoleStreamPrinter(this);
  }

  void _loadSettings() {
    _upIsDown = settings.get('up-is-down');
    _causalAsyncStacks = settings.get('causal-async-stacks') ?? true;
    _awaiterStacks = settings.get('awaiter-stacks') ?? true;
  }

  S.VM get vm => page.app.vm;

  void init() {
    console.printBold('Debugging isolate isolate ${isolate.number} '
        '\'${isolate.name}\' ');
    console.printBold('Type \'h\' for help');
    // Wait a bit and if polymer still hasn't set up the isolate,
    // report this to the user.
    new Timer(const Duration(seconds: 1), () {
      if (isolate == null) {
        reportStatus();
      }
    });

    if ((breakOnException != isolate.exceptionsPauseInfo) &&
        (isolate.exceptionsPauseInfo != null)) {
      breakOnException = isolate.exceptionsPauseInfo;
    }

    isolate.reload().then((response) {
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
  }

  Future refreshStack() async {
    try {
      if (isolate != null) {
        await _refreshStack(isolate.pauseEvent);
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
    return isolate.status == M.IsolateStatus.paused;
  }

  void warnOutOfDate() {
    // Wait a bit, then tell the user that the stack may be out of date.
    new Timer(const Duration(seconds: 2), () {
      if (!isolatePaused()) {
        stackElement.isSampled = true;
      }
    });
  }

  Future<S.ServiceMap> _refreshStack(M.DebugEvent pauseEvent) {
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
    if (isolate == null) {
      console.print('No current isolate');
    } else if (isolate.idle) {
      console.print('Isolate is idle');
    } else if (isolate.running) {
      console.print("Isolate is running (type 'pause' to interrupt)");
    } else if (isolate.pauseEvent != null) {
      _reportPause(isolate.pauseEvent);
    } else {
      console.print('Isolate is in unknown state');
    }
    warnOutOfDate();
  }

  void _reportIsolateError(S.Isolate isolate, M.DebugEvent event) {
    if (isolate == null) {
      return;
    }
    S.DartError error = isolate.error;
    if (error == null) {
      return;
    }
    console.newline();
    if (event is M.PauseExceptionEvent) {
      console.printBold('Isolate will exit due to an unhandled exception:');
    } else {
      console.printBold('Isolate has exited due to an unhandled exception:');
    }
    console.print(error.message);
    console.newline();
    if (event is M.PauseExceptionEvent &&
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

  void _reportPause(M.DebugEvent event) {
    if (event is M.NoneEvent) {
      console.print("Paused until embedder makes the isolate runnable.");
    } else if (event is M.PauseStartEvent) {
      console.print("Paused at isolate start "
          "(type 'continue' [F7] or 'step' [F10] to start the isolate')");
    } else if (event is M.PauseExitEvent) {
      console.print("Paused at isolate exit "
          "(type 'continue' or [F7] to exit the isolate')");
      _reportIsolateError(isolate, event);
    } else if (event is M.PauseExceptionEvent) {
      console.print("Paused at an unhandled exception "
          "(type 'continue' or [F7] to exit the isolate')");
      _reportIsolateError(isolate, event);
    } else if (stack['frames'].length > 0) {
      S.Frame frame = stack['frames'][0];
      var script = frame.location.script;
      script.load().then((_) {
        var line = script.tokenToLine(frame.location.tokenPos);
        var col = script.tokenToCol(frame.location.tokenPos);
        if ((event is M.PauseBreakpointEvent) && (event.breakpoint != null)) {
          var bpId = event.breakpoint.number;
          console.print('Paused at breakpoint ${bpId} at '
              '${script.name}:${line}:${col}');
        } else if ((event is M.PauseExceptionEvent) &&
            (event.exception != null)) {
          console.print('Paused due to exception at '
              '${script.name}:${line}:${col}');
          // This seems to be missing if we are paused-at-exception after
          // paused-at-isolate-exit. Maybe we shutdown part of the debugger too
          // soon?
          console.printRef(isolate, event.exception, objects);
        } else {
          console.print('Paused at ${script.name}:${line}:${col}');
        }
      });
    } else {
      console.print("Paused in message loop (type 'continue' or [F7] "
          "to resume processing messages)");
    }
  }

  Future _reportBreakpointEvent(S.ServiceEvent event) async {
    var bpt = event.breakpoint;
    var verb = null;
    switch (event.kind) {
      case S.ServiceEvent.kBreakpointAdded:
        verb = 'added';
        break;
      case S.ServiceEvent.kBreakpointResolved:
        verb = 'resolved';
        break;
      case S.ServiceEvent.kBreakpointRemoved:
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
      console.print('Breakpoint ${bpId} ${verb} at ${locString}');
    } else {
      console.print('Future breakpoint ${bpId} ${verb} at ${locString}');
    }
  }

  void onEvent(S.ServiceEvent event) {
    switch (event.kind) {
      case S.ServiceEvent.kVMUpdate:
        var vm = event.owner;
        console.print(
            "VM ${(vm as CommonWebSocketVM).target.networkAddress} renamed to '${vm.name}'");
        break;

      case S.ServiceEvent.kIsolateStart:
        {
          var iso = event.owner;
          console.print("Isolate ${iso.number} '${iso.name}' has been created");
        }
        break;

      case S.ServiceEvent.kIsolateExit:
        {
          var iso = event.owner;
          if (iso == isolate) {
            console.print("The current isolate ${iso.number} '${iso.name}' "
                "has exited");
            var isolates = vm.isolates;
            if (isolates.length > 0) {
              var newIsolate = isolates.first;
              new AnchorElement(href: Uris.debugger(newIsolate)).click();
            } else {
              new AnchorElement(href: Uris.vm()).click();
            }
          } else {
            console.print("Isolate ${iso.number} '${iso.name}' has exited");
          }
        }
        break;

      case S.ServiceEvent.kDebuggerSettingsUpdate:
        if (breakOnException != event.exceptions) {
          breakOnException = event.exceptions;
          console.print("Now pausing for exceptions: $breakOnException");
        }
        break;

      case S.ServiceEvent.kIsolateUpdate:
        var iso = event.owner;
        console.print("Isolate ${iso.number} renamed to '${iso.name}'");
        break;

      case S.ServiceEvent.kIsolateReload:
        var reloadError = event.reloadError;
        if (reloadError != null) {
          console.print('Isolate reload failed: ${event.reloadError}');
        } else {
          console.print('Isolate reloaded.');
        }
        break;

      case S.ServiceEvent.kPauseStart:
      case S.ServiceEvent.kPauseExit:
      case S.ServiceEvent.kPauseBreakpoint:
      case S.ServiceEvent.kPauseInterrupted:
      case S.ServiceEvent.kPauseException:
        if (event.owner == isolate) {
          var e = createEventFromServiceEvent(event);
          _refreshStack(e).then((_) async {
            flushStdio();
            if (isolate != null) {
              await isolate.reload();
            }
            _reportPause(e);
          });
        }
        break;

      case S.ServiceEvent.kResume:
        if (event.owner == isolate) {
          flushStdio();
          console.print('Continuing...');
        }
        break;

      case S.ServiceEvent.kBreakpointAdded:
      case S.ServiceEvent.kBreakpointResolved:
      case S.ServiceEvent.kBreakpointRemoved:
        if (event.owner == isolate) {
          _reportBreakpointEvent(event);
        }
        break;

      case S.ServiceEvent.kIsolateRunnable:
      case S.ServiceEvent.kGraph:
      case S.ServiceEvent.kGC:
      case S.ServiceEvent.kInspect:
        // Ignore.
        break;

      case S.ServiceEvent.kLogging:
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

  void onStdout(S.ServiceEvent event) {
    _consolePrinter.onEvent('stdout', event);
  }

  void onStderr(S.ServiceEvent event) {
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
      console.printRed('Unable to execute command because the connection '
          'to the VM has been closed');
    }, test: (e) => e is S.NetworkRpcException).catchError((e, s) {
      console.printRed(e.toString());
    }, test: (e) => e is CommandException).catchError((e, s) {
      if (s != null) {
        console.printRed('Internal error: $e\n$s');
      } else {
        console.printRed('Internal error: $e\n');
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
      if (event is M.PauseStartEvent) {
        console
            .print("Type 'continue' [F7] or 'step' [F10] to start the isolate");
        return null;
      }
      if (event is M.PauseExitEvent) {
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
      if (event is M.PauseExitEvent) {
        console.print("Type 'continue' [F7] to exit the isolate");
        return new Future.value(null);
      }
      return isolate.stepInto();
    } else {
      console.print('The program is already running');
      return new Future.value(null);
    }
  }

  Future rewind(int count) {
    if (isolatePaused()) {
      var event = isolate.pauseEvent;
      if (event is M.PauseExitEvent) {
        console.print("Type 'continue' [F7] to exit the isolate");
        return new Future.value(null);
      }
      return isolate.rewind(count);
    } else {
      console.print('The program must be paused');
      return new Future.value(null);
    }
  }
}

class DebuggerPageElement extends HtmlElement implements Renderable {
  static const tag =
      const Tag<DebuggerPageElement>('debugger-page', dependencies: const [
    NavTopMenuElement.tag,
    NavVMMenuElement.tag,
    NavIsolateMenuElement.tag,
    NavNotifyElement.tag,
  ]);

  S.Isolate _isolate;
  ObservatoryDebugger _debugger;
  M.ObjectRepository _objects;
  M.ScriptRepository _scripts;
  M.EventRepository _events;

  factory DebuggerPageElement(S.Isolate isolate, M.ObjectRepository objects,
      M.ScriptRepository scripts, M.EventRepository events) {
    assert(isolate != null);
    assert(objects != null);
    assert(scripts != null);
    assert(events != null);
    final e = document.createElement(tag.name);
    final debugger = new ObservatoryDebugger(isolate);
    debugger.page = e;
    debugger.objects = objects;
    e._isolate = isolate;
    e._debugger = debugger;
    e._objects = objects;
    e._scripts = scripts;
    e._events = events;
    return e;
  }

  DebuggerPageElement.created() : super.created();

  Future<StreamSubscription> _vmSubscriptionFuture;
  Future<StreamSubscription> _isolateSubscriptionFuture;
  Future<StreamSubscription> _debugSubscriptionFuture;
  Future<StreamSubscription> _stdoutSubscriptionFuture;
  Future<StreamSubscription> _stderrSubscriptionFuture;
  Future<StreamSubscription> _logSubscriptionFuture;

  ObservatoryApplication get app => ObservatoryApplication.app;

  Timer _timer;

  static final consoleElement = new DebuggerConsoleElement();

  @override
  void attached() {
    super.attached();

    final stackDiv = new DivElement()..classes = ['stack'];
    final stackElement = new DebuggerStackElement(
        _isolate, _debugger, stackDiv, _objects, _scripts, _events);
    stackDiv.children = [stackElement];
    final consoleDiv = new DivElement()
      ..classes = ['console']
      ..children = [consoleElement];
    final commandElement = new DebuggerInputElement(_isolate, _debugger);
    final commandDiv = new DivElement()
      ..classes = ['commandline']
      ..children = [commandElement];

    children = [
      navBar([
        new NavTopMenuElement(queue: app.queue),
        new NavVMMenuElement(app.vm, app.events, queue: app.queue),
        new NavIsolateMenuElement(_isolate, app.events, queue: app.queue),
        navMenu('debugger'),
        new NavNotifyElement(app.notifications,
            notifyOnPause: false, queue: app.queue)
      ]),
      new DivElement()
        ..classes = ['variable']
        ..children = [
          stackDiv,
          new DivElement()
            ..children = [
              new HRElement()..classes = ['splitter']
            ],
          consoleDiv,
        ],
      commandDiv
    ];

    DebuggerConsoleElement._scrollToBottom(consoleDiv);

    // Wire the debugger object to the stack, console, and command line.
    _debugger.stackElement = stackElement;
    _debugger.console = consoleElement;
    _debugger.input = commandElement;
    _debugger.input._debugger = _debugger;
    _debugger.init();

    _vmSubscriptionFuture =
        app.vm.listenEventStream(S.VM.kVMStream, _debugger.onEvent);
    _isolateSubscriptionFuture =
        app.vm.listenEventStream(S.VM.kIsolateStream, _debugger.onEvent);
    _debugSubscriptionFuture =
        app.vm.listenEventStream(S.VM.kDebugStream, _debugger.onEvent);
    _stdoutSubscriptionFuture =
        app.vm.listenEventStream(S.VM.kStdoutStream, _debugger.onStdout);
    if (_stdoutSubscriptionFuture != null) {
      // TODO(turnidge): How do we want to handle this in general?
      _stdoutSubscriptionFuture.catchError((e, st) {
        Logger.root.info('Failed to subscribe to stdout: $e\n$st\n');
        _stdoutSubscriptionFuture = null;
      });
    }
    _stderrSubscriptionFuture =
        app.vm.listenEventStream(S.VM.kStderrStream, _debugger.onStderr);
    if (_stderrSubscriptionFuture != null) {
      // TODO(turnidge): How do we want to handle this in general?
      _stderrSubscriptionFuture.catchError((e, st) {
        Logger.root.info('Failed to subscribe to stderr: $e\n$st\n');
        _stderrSubscriptionFuture = null;
      });
    }
    _logSubscriptionFuture =
        app.vm.listenEventStream(S.Isolate.kLoggingStream, _debugger.onEvent);
    // Turn on the periodic poll timer for this page.
    _timer = new Timer.periodic(const Duration(milliseconds: 100), (_) {
      _debugger.flushStdio();
    });

    onClick.listen((event) {
      // Random clicks should focus on the text box.  If the user selects
      // a range, don't interfere.
      var selection = window.getSelection();
      if (selection == null ||
          (selection.type != 'Range' && selection.type != 'text')) {
        _debugger.input.focus();
      }
    });
  }

  @override
  void render() {
    /* nothing to do */
  }

  @override
  void detached() {
    _timer.cancel();
    children = const [];
    S.cancelFutureSubscription(_vmSubscriptionFuture);
    _vmSubscriptionFuture = null;
    S.cancelFutureSubscription(_isolateSubscriptionFuture);
    _isolateSubscriptionFuture = null;
    S.cancelFutureSubscription(_debugSubscriptionFuture);
    _debugSubscriptionFuture = null;
    S.cancelFutureSubscription(_stdoutSubscriptionFuture);
    _stdoutSubscriptionFuture = null;
    S.cancelFutureSubscription(_stderrSubscriptionFuture);
    _stderrSubscriptionFuture = null;
    S.cancelFutureSubscription(_logSubscriptionFuture);
    _logSubscriptionFuture = null;
    super.detached();
  }
}

class DebuggerStackElement extends HtmlElement implements Renderable {
  static const tag = const Tag<DebuggerStackElement>('debugger-stack');

  S.Isolate _isolate;
  M.ObjectRepository _objects;
  M.ScriptRepository _scripts;
  M.EventRepository _events;
  Element _scroller;
  DivElement _isSampled;
  bool get isSampled => !_isSampled.classes.contains('hidden');
  set isSampled(bool value) {
    if (value != isSampled) {
      _isSampled.classes.toggle('hidden');
    }
  }

  DivElement _hasStack;
  bool get hasStack => _hasStack.classes.contains('hidden');
  set hasStack(bool value) {
    if (value != hasStack) {
      _hasStack.classes.toggle('hidden');
    }
  }

  DivElement _hasMessages;
  bool get hasMessages => _hasMessages.classes.contains('hidden');
  set hasMessages(bool value) {
    if (value != hasMessages) {
      _hasMessages.classes.toggle('hidden');
    }
  }

  UListElement _frameList;
  UListElement _messageList;
  int currentFrame;
  ObservatoryDebugger _debugger;

  factory DebuggerStackElement(
      S.Isolate isolate,
      ObservatoryDebugger debugger,
      Element scroller,
      M.ObjectRepository objects,
      M.ScriptRepository scripts,
      M.EventRepository events) {
    assert(isolate != null);
    assert(debugger != null);
    assert(scroller != null);
    assert(objects != null);
    assert(scripts != null);
    assert(events != null);
    final e = document.createElement(tag.name);
    e._isolate = isolate;
    e._debugger = debugger;
    e._scroller = scroller;
    e._objects = objects;
    e._scripts = scripts;
    e._events = events;

    var btnPause;
    var btnRefresh;
    e.children = [
      e._isSampled = new DivElement()
        ..classes = ['sampledMessage', 'hidden']
        ..children = [
          new SpanElement()
            ..text = 'The program is not paused. '
                'The stack trace below may be out of date.',
          new BRElement(),
          new BRElement(),
          btnPause = new ButtonElement()
            ..text = '[Pause Isolate]'
            ..onClick.listen((_) async {
              btnPause.disabled = true;
              try {
                await debugger.isolate.pause();
              } finally {
                btnPause.disabled = false;
              }
            }),
          btnRefresh = new ButtonElement()
            ..text = '[Refresh Stack]'
            ..onClick.listen((_) async {
              btnRefresh.disabled = true;
              try {
                await debugger.refreshStack();
              } finally {
                btnRefresh.disabled = false;
              }
            }),
          new BRElement(),
          new BRElement(),
          new HRElement()..classes = ['splitter']
        ],
      e._hasStack = new DivElement()
        ..classes = ['noStack', 'hidden']
        ..text = 'No stack',
      e._frameList = new UListElement()..classes = ['list-group'],
      new HRElement(),
      e._hasMessages = new DivElement()
        ..classes = ['noMessages', 'hidden']
        ..text = 'No pending messages',
      e._messageList = new UListElement()..classes = ['messageList']
    ];
    return e;
  }

  void render() {
    /* nothing to do */
  }

  _addFrame(List frameList, S.Frame frameInfo) {
    final frameElement = new DebuggerFrameElement(
        _isolate, frameInfo, _scroller, _objects, _scripts, _events,
        queue: app.queue);

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

  _addMessage(List messageList, S.ServiceMessage messageInfo) {
    final messageElement = new DebuggerMessageElement(
        _isolate, messageInfo, _objects, _scripts, _events,
        queue: app.queue);

    var li = new LIElement();
    li.classes.add('list-group-item');
    li.children.insert(0, messageElement);

    messageList.add(li);
  }

  ObservatoryApplication get app => ObservatoryApplication.app;

  void updateStackFrames(S.ServiceMap newStack) {
    List frameElements = _frameList.children;
    List newFrames;
    if (_debugger.awaiterStacks &&
        (newStack[ObservatoryDebugger.kAwaiterStackFrames] != null)) {
      newFrames = newStack[ObservatoryDebugger.kAwaiterStackFrames];
    } else if (_debugger.causalAsyncStacks &&
        (newStack[ObservatoryDebugger.kAsyncCausalStackFrames] != null)) {
      newFrames = newStack[ObservatoryDebugger.kAsyncCausalStackFrames];
    } else {
      newFrames = newStack[ObservatoryDebugger.kStackFrames];
    }

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
      for (int i = newCount - 1; i >= 0; i--) {
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

  void updateStackMessages(S.ServiceMap newStack) {
    List messageElements = _messageList.children;
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
        DebuggerMessageElement e = messageElements[i].children[0];
        e.updateMessage(newMessages[i]);
      }
    }

    hasMessages = messageElements.isNotEmpty;
  }

  void updateStack(S.ServiceMap newStack, M.DebugEvent pauseEvent) {
    updateStackFrames(newStack);
    updateStackMessages(newStack);
    isSampled = pauseEvent == null;
  }

  void setCurrentFrame(int value) {
    currentFrame = value;
    List frameElements = _frameList.children;
    for (var frameElement in frameElements) {
      DebuggerFrameElement dbgFrameElement = frameElement.children[0];
      if (dbgFrameElement.frame.index == currentFrame) {
        dbgFrameElement.setCurrent(true);
      } else {
        dbgFrameElement.setCurrent(false);
      }
    }
  }

  DebuggerStackElement.created() : super.created();
}

class DebuggerFrameElement extends HtmlElement implements Renderable {
  static const tag = const Tag<DebuggerFrameElement>('debugger-frame');

  RenderingScheduler<DebuggerMessageElement> _r;

  Stream<RenderedEvent<DebuggerMessageElement>> get onRendered => _r.onRendered;

  Element _scroller;
  DivElement _varsDiv;
  M.Isolate _isolate;
  S.Frame _frame;
  S.Frame get frame => _frame;
  M.ObjectRepository _objects;
  M.ScriptRepository _scripts;
  M.EventRepository _events;

  // Is this the current frame?
  bool _current = false;

  // Has this frame been pinned open?
  bool _pinned = false;

  bool _expanded = false;

  void setCurrent(bool value) {
    Future load = (_frame.function != null)
        ? _frame.function.load()
        : new Future.value(null);
    load.then((func) {
      _current = value;
      if (_current) {
        _expand();
        scrollIntoView();
      } else {
        if (_pinned) {
          _expand();
        } else {
          _unexpand();
        }
      }
    });
  }

  factory DebuggerFrameElement(
      M.Isolate isolate,
      S.Frame frame,
      Element scroller,
      M.ObjectRepository objects,
      M.ScriptRepository scripts,
      M.EventRepository events,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(frame != null);
    assert(scroller != null);
    assert(objects != null);
    assert(scripts != null);
    assert(events != null);
    final DebuggerFrameElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._frame = frame;
    e._scroller = scroller;
    e._objects = objects;
    e._scripts = scripts;
    e._events = events;
    return e;
  }

  DebuggerFrameElement.created() : super.created();

  void render() {
    if (_pinned) {
      classes.add('shadow');
    } else {
      classes.remove('shadow');
    }
    if (_current) {
      classes.add('current');
    } else {
      classes.remove('current');
    }
    if ((_frame.kind == M.FrameKind.asyncSuspensionMarker) ||
        (_frame.kind == M.FrameKind.asyncCausal)) {
      classes.add('causalFrame');
    }
    if (_frame.kind == M.FrameKind.asyncSuspensionMarker) {
      final content = <Element>[
        new SpanElement()..children = _createMarkerHeader(_frame.marker)
      ];
      children = content;
      return;
    }
    ButtonElement expandButton;
    final content = <Element>[
      expandButton = new ButtonElement()
        ..children = _createHeader()
        ..onClick.listen((e) async {
          if (e.target is AnchorElement) {
            return;
          }
          expandButton.disabled = true;
          await _toggleExpand();
          expandButton.disabled = false;
        })
    ];
    if (_expanded) {
      final homeMethod = _frame.function.homeMethod;
      String homeMethodName;
      if ((homeMethod.dartOwner is S.Class) && homeMethod.isStatic) {
        homeMethodName = '<class>';
      } else if (homeMethod.dartOwner is S.Library) {
        homeMethodName = '<library>';
      }
      ButtonElement collapseButton;
      content.addAll([
        new DivElement()
          ..classes = ['frameDetails']
          ..children = [
            new DivElement()
              ..classes = ['flex-row-wrap']
              ..children = [
                new DivElement()
                  ..classes = ['flex-item-script']
                  ..children = _frame.function?.location == null
                      ? const []
                      : [
                          new SourceInsetElement(
                              _isolate,
                              _frame.function.location,
                              _scripts,
                              _objects,
                              _events,
                              currentPos: _frame.location.tokenPos,
                              variables: _frame.variables,
                              inDebuggerContext: true,
                              queue: _r.queue)
                        ],
                new DivElement()
                  ..classes = ['flex-item-vars']
                  ..children = [
                    _varsDiv = new DivElement()
                      ..classes = ['memberList', 'frameVars']
                      ..children = ([
                        new DivElement()
                          ..classes = ['memberItem']
                          ..children = homeMethodName == null
                              ? const []
                              : [
                                  new DivElement()
                                    ..classes = ['memberName']
                                    ..text = homeMethodName,
                                  new DivElement()
                                    ..classes = ['memberName']
                                    ..children = [
                                      anyRef(_isolate, homeMethod.dartOwner,
                                          _objects,
                                          queue: _r.queue)
                                    ]
                                ]
                      ]..addAll(_frame.variables
                          .map((v) => new DivElement()
                            ..classes = ['memberItem']
                            ..children = [
                              new DivElement()
                                ..classes = ['memberName']
                                ..text = v.name,
                              new DivElement()
                                ..classes = ['memberName']
                                ..children = [
                                  anyRef(_isolate, v['value'], _objects,
                                      queue: _r.queue)
                                ]
                            ])
                          .toList()))
                  ]
              ],
            new DivElement()
              ..classes = ['frameContractor']
              ..children = [
                collapseButton = new ButtonElement()
                  ..onClick.listen((e) async {
                    collapseButton.disabled = true;
                    await _toggleExpand();
                    collapseButton.disabled = false;
                  })
                  ..children = [iconExpandLess.clone(true)]
              ]
          ]
      ]);
    }
    children = content;
  }

  List<Element> _createMarkerHeader(String marker) {
    final content = [
      new DivElement()
        ..classes = ['frameSummaryText']
        ..children = [
          new DivElement()
            ..classes = ['frameId']
            ..text = 'Frame ${_frame.index}',
          new SpanElement()..text = '$marker',
        ]
    ];
    return [
      new DivElement()
        ..classes = ['frameSummary']
        ..children = content
    ];
  }

  List<Element> _createHeader() {
    final content = [
      new DivElement()
        ..classes = ['frameSummaryText']
        ..children = [
          new DivElement()
            ..classes = ['frameId']
            ..text = 'Frame ${_frame.index}',
          new SpanElement()
            ..children = _frame.function == null
                ? const []
                : [
                    new FunctionRefElement(_isolate, _frame.function,
                        queue: _r.queue)
                  ],
          new SpanElement()..text = ' ( ',
          new SpanElement()
            ..children = _frame.function?.location == null
                ? const []
                : [
                    new SourceLinkElement(
                        _isolate, _frame.function.location, _scripts,
                        queue: _r.queue)
                  ],
          new SpanElement()..text = ' )'
        ]
    ];
    if (!_expanded) {
      content.add(new DivElement()
        ..classes = ['frameExpander']
        ..children = [iconExpandMore.clone(true)]);
    }
    return [
      new DivElement()
        ..classes = ['frameSummary']
        ..children = content
    ];
  }

  String makeExpandKey(String key) {
    return '${_frame.function.qualifiedName}/${key}';
  }

  bool matchFrame(S.Frame newFrame) {
    if (newFrame.kind != _frame.kind) {
      return false;
    }
    if (newFrame.function == null) {
      return frame.function == null;
    }
    return (newFrame.function.id == _frame.function.id &&
        newFrame.location.script.id == frame.location.script.id);
  }

  void updateFrame(S.Frame newFrame) {
    assert(matchFrame(newFrame));
    _frame = newFrame;
  }

  S.Script get script => _frame.location.script;

  int _varsTop(varsDiv) {
    const minTop = 0;
    if (varsDiv == null) {
      return minTop;
    }
    final paddingTop = document.body.contentEdge.top;
    final parent = varsDiv.parent.getBoundingClientRect();
    final varsHeight = varsDiv.clientHeight;
    final maxTop = parent.height - varsHeight;
    final adjustedTop = paddingTop - parent.top;
    return (max(minTop, min(maxTop, adjustedTop)));
  }

  void _onScroll(event) {
    if (!_expanded || _varsDiv == null) {
      return;
    }
    var currentTop = _varsDiv.style.top;
    var newTop = _varsTop(_varsDiv);
    if (currentTop != newTop) {
      _varsDiv.style.top = '${newTop}px';
    }
  }

  void _expand() {
    _expanded = true;
    _subscribeToScroll();
    _r.dirty();
  }

  void _unexpand() {
    _expanded = false;
    _unsubscribeToScroll();
    _r.dirty();
  }

  StreamSubscription _scrollSubscription;
  StreamSubscription _resizeSubscription;

  void _subscribeToScroll() {
    if (_scroller != null) {
      if (_scrollSubscription == null) {
        _scrollSubscription = _scroller.onScroll.listen(_onScroll);
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
    _r.enable();
    if (_expanded) {
      _subscribeToScroll();
    }
  }

  void detached() {
    _r.disable(notify: true);
    super.detached();
    _unsubscribeToScroll();
  }

  Future _toggleExpand() async {
    await _frame.function.load();
    _pinned = !_pinned;
    if (_pinned) {
      _expand();
    } else {
      _unexpand();
    }
  }
}

class DebuggerMessageElement extends HtmlElement implements Renderable {
  static const tag = const Tag<DebuggerMessageElement>('debugger-message');

  RenderingScheduler<DebuggerMessageElement> _r;

  Stream<RenderedEvent<DebuggerMessageElement>> get onRendered => _r.onRendered;

  S.Isolate _isolate;
  S.ServiceMessage _message;
  S.ServiceObject _preview;
  M.ObjectRepository _objects;
  M.ScriptRepository _scripts;
  M.EventRepository _events;

  // Is this the current message?
  bool _current = false;

  // Has this message been pinned open?
  bool _pinned = false;

  bool _expanded = false;

  factory DebuggerMessageElement(
      S.Isolate isolate,
      S.ServiceMessage message,
      M.ObjectRepository objects,
      M.ScriptRepository scripts,
      M.EventRepository events,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(message != null);
    assert(objects != null);
    assert(events != null);
    final DebuggerMessageElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._message = message;
    e._objects = objects;
    e._scripts = scripts;
    e._events = events;
    return e;
  }

  DebuggerMessageElement.created() : super.created();

  void render() {
    if (_pinned) {
      classes.add('shadow');
    } else {
      classes.remove('shadow');
    }
    if (_current) {
      classes.add('current');
    } else {
      classes.remove('current');
    }
    ButtonElement expandButton;
    final content = <Element>[
      expandButton = new ButtonElement()
        ..children = _createHeader()
        ..onClick.listen((e) async {
          if (e.target is AnchorElement) {
            return;
          }
          expandButton.disabled = true;
          await _toggleExpand();
          expandButton.disabled = false;
        })
    ];
    if (_expanded) {
      ButtonElement collapseButton;
      ButtonElement previewButton;
      content.addAll([
        new DivElement()
          ..classes = ['messageDetails']
          ..children = [
            new DivElement()
              ..classes = ['flex-row-wrap']
              ..children = [
                new DivElement()
                  ..classes = ['flex-item-script']
                  ..children = _message.handler == null
                      ? const []
                      : [
                          new SourceInsetElement(
                              _isolate,
                              _message.handler.location,
                              _scripts,
                              _objects,
                              _events,
                              inDebuggerContext: true,
                              queue: _r.queue)
                        ],
                new DivElement()
                  ..classes = ['flex-item-vars']
                  ..children = [
                    new DivElement()
                      ..classes = ['memberItem']
                      ..children = [
                        new DivElement()..classes = ['memberName'],
                        new DivElement()
                          ..classes = ['memberValue']
                          ..children = ([
                            previewButton = new ButtonElement()
                              ..text = 'preview'
                              ..onClick.listen((_) {
                                previewButton.disabled = true;
                              })
                          ]..addAll(_preview == null
                              ? const []
                              : [
                                  anyRef(_isolate, _preview, _objects,
                                      queue: _r.queue)
                                ]))
                      ]
                  ]
              ],
            new DivElement()
              ..classes = ['messageContractor']
              ..children = [
                collapseButton = new ButtonElement()
                  ..onClick.listen((e) async {
                    collapseButton.disabled = true;
                    await _toggleExpand();
                    collapseButton.disabled = false;
                  })
                  ..children = [iconExpandLess.clone(true)]
              ]
          ]
      ]);
    }
    children = content;
  }

  void updateMessage(S.ServiceMessage message) {
    assert(_message != null);
    _message = message;
    _r.dirty();
  }

  List<Element> _createHeader() {
    final content = [
      new DivElement()
        ..classes = ['messageSummaryText']
        ..children = [
          new DivElement()
            ..classes = ['messageId']
            ..text = 'message ${_message.index}',
          new SpanElement()
            ..children = _message.handler == null
                ? const []
                : [
                    new FunctionRefElement(_isolate, _message.handler,
                        queue: _r.queue)
                  ],
          new SpanElement()..text = ' ( ',
          new SpanElement()
            ..children = _message.location == null
                ? const []
                : [
                    new SourceLinkElement(_isolate, _message.location, _scripts,
                        queue: _r.queue)
                  ],
          new SpanElement()..text = ' )'
        ]
    ];
    if (!_expanded) {
      content.add(new DivElement()
        ..classes = ['messageExpander']
        ..children = [iconExpandMore.clone(true)]);
    }
    return [
      new DivElement()
        ..classes = ['messageSummary']
        ..children = content
    ];
  }

  void setCurrent(bool value) {
    _current = value;
    if (_current) {
      _expanded = true;
      scrollIntoView();
      _r.dirty();
    } else {
      _expanded = _pinned;
    }
  }

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    children = [];
  }

  Future _toggleExpand() async {
    var function = _message.handler;
    if (function != null) {
      await function.load();
    }
    _pinned = _pinned;
    _expanded = true;
    _r.dirty();
  }

  Future<S.ServiceObject> previewMessage(_) {
    return _message.isolate.getObject(_message.messageObjectId).then((result) {
      _preview = result;
      return result;
    });
  }
}

class DebuggerConsoleElement extends HtmlElement implements Renderable {
  static const tag = const Tag<DebuggerConsoleElement>('debugger-console');

  factory DebuggerConsoleElement() {
    final DebuggerConsoleElement e = document.createElement(tag.name);
    e.children = [new BRElement()];
    return e;
  }

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
    const threshold = 2; // 2 pixel slop.
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
    bool autoScroll = _isScrolledToBottom(parent);
    children.add(span);
    if (autoScroll) {
      _scrollToBottom(parent);
    }
  }

  void print(String line, {bool newline: true}) {
    var span = new SpanElement();
    span.classes.add('normal');
    span.appendText(line);
    if (newline) {
      span.appendText('\n');
    }
    _append(span);
  }

  void printBold(String line, {bool newline: true}) {
    var span = new SpanElement();
    span.classes.add('bold');
    span.appendText(line);
    if (newline) {
      span.appendText('\n');
    }
    _append(span);
  }

  void printRed(String line, {bool newline: true}) {
    var span = new SpanElement();
    span.classes.add('red');
    span.appendText(line);
    if (newline) {
      span.appendText('\n');
    }
    _append(span);
  }

  void printStdio(List<String> lines) {
    bool autoScroll = _isScrolledToBottom(parent);
    for (var line in lines) {
      var span = new SpanElement();
      span.classes.add('green');
      span.appendText(line);
      span.appendText('\n');
      children.add(span);
    }
    if (autoScroll) {
      _scrollToBottom(parent);
    }
  }

  void printRef(S.Isolate isolate, S.Instance ref, M.ObjectRepository objects,
      {bool newline: true}) {
    _append(new InstanceRefElement(isolate, ref, objects, queue: app.queue));
    if (newline) {
      this.newline();
    }
  }

  void newline() {
    _append(new BRElement());
  }

  void clear() {
    children.clear();
  }

  void render() {
    /* nothing to do */
  }

  ObservatoryApplication get app => ObservatoryApplication.app;
}

class DebuggerInputElement extends HtmlElement implements Renderable {
  static const tag = const Tag<DebuggerInputElement>('debugger-input');

  S.Isolate _isolate;
  ObservatoryDebugger _debugger;
  bool _busy = false;
  final _modalPromptDiv = new DivElement()..classes = ['modalPrompt', 'hidden'];
  final _textBox = new TextInputElement()
    ..classes = ['textBox']
    ..autofocus = true;
  String get modalPrompt => _modalPromptDiv.text;
  set modalPrompt(String value) {
    if (_modalPromptDiv.text == '') {
      _modalPromptDiv.classes.remove('hidden');
    }
    _modalPromptDiv.text = value;
    if (_modalPromptDiv.text == '') {
      _modalPromptDiv.classes.add('hidden');
    }
  }

  String get text => _textBox.value;
  set text(String value) => _textBox.value = value;
  var modalCallback = null;

  factory DebuggerInputElement(
      S.Isolate isolate, ObservatoryDebugger debugger) {
    final DebuggerInputElement e = document.createElement(tag.name);
    e.children = [e._modalPromptDiv, e._textBox];
    e._textBox.select();
    e._textBox.onKeyDown.listen(e._onKeyDown);
    return e;
  }

  DebuggerInputElement.created() : super.created();

  void _onKeyDown(KeyboardEvent e) {
    if (_busy) {
      e.preventDefault();
      return;
    }
    _busy = true;
    if (modalCallback != null) {
      if (e.keyCode == KeyCode.ENTER) {
        var response = text;
        modalCallback(response).whenComplete(() {
          text = '';
          _busy = false;
        });
      } else {
        _busy = false;
      }
      return;
    }
    switch (e.keyCode) {
      case KeyCode.TAB:
        e.preventDefault();
        int cursorPos = _textBox.selectionStart;
        _debugger.complete(text.substring(0, cursorPos)).then((completion) {
          text = completion + text.substring(cursorPos);
          // TODO(turnidge): Move the cursor to the end of the
          // completion, rather than the end of the string.
        }).whenComplete(() {
          _busy = false;
        });
        break;

      case KeyCode.ENTER:
        var command = text;
        _debugger.run(command).whenComplete(() {
          text = '';
          _busy = false;
        });
        break;

      case KeyCode.UP:
        e.preventDefault();
        text = _debugger.historyPrev(text);
        _busy = false;
        break;

      case KeyCode.DOWN:
        e.preventDefault();
        text = _debugger.historyNext(text);
        _busy = false;
        break;

      case KeyCode.PAGE_UP:
        e.preventDefault();
        try {
          _debugger.upFrame(1);
        } on RangeError catch (_) {
          // Ignore.
        }
        _busy = false;
        break;

      case KeyCode.PAGE_DOWN:
        e.preventDefault();
        try {
          _debugger.downFrame(1);
        } on RangeError catch (_) {
          // Ignore.
        }
        _busy = false;
        break;

      case KeyCode.F7:
        e.preventDefault();
        _debugger.resume().whenComplete(() {
          _busy = false;
        });
        break;

      case KeyCode.F8:
        e.preventDefault();
        _debugger.toggleBreakpoint().whenComplete(() {
          _busy = false;
        });
        break;

      case KeyCode.F9:
        e.preventDefault();
        _debugger.smartNext().whenComplete(() {
          _busy = false;
        });
        break;

      case KeyCode.F10:
        e.preventDefault();
        _debugger.step().whenComplete(() {
          _busy = false;
        });
        break;

      case KeyCode.SEMICOLON:
        if (e.ctrlKey) {
          e.preventDefault();
          _debugger.console.printRed('^;');
          _debugger.pause().whenComplete(() {
            _busy = false;
          });
        } else {
          _busy = false;
        }
        break;

      default:
        _busy = false;
        break;
    }
  }

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

  void focus() {
    _textBox.focus();
  }

  void render() {
    // Nothing to do.
  }
}

final SvgSvgElement iconExpandLess = new SvgSvgElement()
  ..setAttribute('width', '24')
  ..setAttribute('height', '24')
  ..children = [
    new PolygonElement()
      ..setAttribute('points', '12,8 6,14 7.4,15.4 12,10.8 16.6,15.4 18,14 ')
  ];

final SvgSvgElement iconExpandMore = new SvgSvgElement()
  ..setAttribute('width', '24')
  ..setAttribute('height', '24')
  ..children = [
    new PolygonElement()
      ..setAttribute('points', '16.6,8.6 12,13.2 7.4,8.6 6,10 12,16 18,10 ')
  ];

final SvgSvgElement iconChevronRight = new SvgSvgElement()
  ..setAttribute('width', '24')
  ..setAttribute('height', '24')
  ..children = [
    new PathElement()
      ..setAttribute('d', 'M10 6L8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6z')
  ];

final SvgSvgElement iconChevronLeft = new SvgSvgElement()
  ..setAttribute('width', '24')
  ..setAttribute('height', '24')
  ..children = [
    new PathElement()
      ..setAttribute('d', 'M15.41 7.41L14 6l-6 6 6 6 1.41-1.41L10.83 12z')
  ];

final SvgSvgElement iconHorizontalThreeDot = new SvgSvgElement()
  ..setAttribute('width', '24')
  ..setAttribute('height', '24')
  ..children = [
    new PathElement()
      ..setAttribute(
          'd',
          'M6 10c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 '
          '2-2-.9-2-2-2zm12 0c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 '
          '2-2-.9-2-2-2zm-6 0c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 '
          '2-2-.9-2-2-2z')
  ];

final SvgSvgElement iconVerticalThreeDot = new SvgSvgElement()
  ..setAttribute('width', '24')
  ..setAttribute('height', '24')
  ..children = [
    new PathElement()
      ..setAttribute(
          'd',
          'M12 8c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 '
          '2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 '
          '2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 '
          '2-.9 2-2-.9-2-2-2z')
  ];

final SvgSvgElement iconInfo = new SvgSvgElement()
  ..setAttribute('width', '24')
  ..setAttribute('height', '24')
  ..children = [
    new PathElement()
      ..setAttribute(
          'd',
          'M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 '
          '10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z')
  ];

final SvgSvgElement iconInfoOutline = new SvgSvgElement()
  ..setAttribute('width', '24')
  ..setAttribute('height', '24')
  ..children = [
    new PathElement()
      ..setAttribute(
          'd',
          'M11 17h2v-6h-2v6zm1-15C6.48 2 2 6.48 2 12s4.48 10 '
          '10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 '
          '0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zM11 '
          '9h2V7h-2v2z')
  ];
