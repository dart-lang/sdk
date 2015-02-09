// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library debugger_page_element;

import 'dart:async';
import 'dart:html';
import 'observatory_element.dart';
import 'package:observatory/cli.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

// TODO(turnidge): Move Debugger, DebuggerCommand to their own lib.
abstract class DebuggerCommand extends Command {
  Debugger debugger;

  DebuggerCommand(this.debugger, name, children)
      : super(name, children);
}

class HelpCommand extends DebuggerCommand {
  HelpCommand(Debugger debugger) : super(debugger, 'help', []);

  Future run(List<String> args) {
    var con = debugger.console;
    con.printLine('List of commands:');
    con.newline();

    // TODO(turnidge): Build a real help system.
    List completions = debugger.cmd.completeCommand('');
    completions = completions.map((s )=> s.trimRight()).toList();
    completions.sort();
    con.printLine(completions.toString());
    con.newline();
    con.printLine("Command prefixes are accepted (e.g. 'h' for 'help')");
    con.printLine("Hit [TAB] to complete a command (try 'i[TAB][TAB]')");
    con.printLine("Hit [ENTER] to repeat the last command");

    return new Future.value(null);
  }
}

class PauseCommand extends DebuggerCommand {
  PauseCommand(Debugger debugger) : super(debugger, 'pause', []);

  Future run(List<String> args) {
    if (!debugger.isolatePaused()) {
      return debugger.isolate.pause();
    } else {
      debugger.console.printLine('The program is already paused');
      return new Future.value(null);
    }
  }
}

class ContinueCommand extends DebuggerCommand {
  ContinueCommand(Debugger debugger) : super(debugger, 'continue', []);

  Future run(List<String> args) {
    if (debugger.isolatePaused()) {
      return debugger.isolate.resume().then((_) {
          debugger.warnOutOfDate();
        });
    } else {
      debugger.console.printLine('The program must be paused');
      return new Future.value(null);
    }
  }
}

class NextCommand extends DebuggerCommand {
  NextCommand(Debugger debugger) : super(debugger, 'next', []);

  Future run(List<String> args) {
    if (debugger.isolatePaused()) {
      var event = debugger.isolate.pauseEvent;
      if (event.eventType == 'IsolateCreated') {
        debugger.console.printLine("Type 'continue' to start the isolate");
        return new Future.value(null);
      }
      if (event.eventType == 'IsolateShutdown') {
        debugger.console.printLine("Type 'continue' to exit the isolate");
        return new Future.value(null);
      }
      return debugger.isolate.stepOver();
    } else {
      debugger.console.printLine('The program is already running');
      return new Future.value(null);
    }
  }
}

class StepCommand extends DebuggerCommand {
  StepCommand(Debugger debugger) : super(debugger, 'step', []);

  Future run(List<String> args) {
    if (debugger.isolatePaused()) {
      var event = debugger.isolate.pauseEvent;
      if (event.eventType == 'IsolateCreated') {
        debugger.console.printLine("Type 'continue' to start the isolate");
        return new Future.value(null);
      }
      if (event.eventType == 'IsolateShutdown') {
        debugger.console.printLine("Type 'continue' to exit the isolate");
        return new Future.value(null);
      }
      return debugger.isolate.stepInto();
    } else {
      debugger.console.printLine('The program is already running');
      return new Future.value(null);
    }
  }
}

class FinishCommand extends DebuggerCommand {
  FinishCommand(Debugger debugger) : super(debugger, 'finish', []);

  Future run(List<String> args) {
    if (debugger.isolatePaused()) {
      return debugger.isolate.stepOut();
    } else {
      debugger.console.printLine('The program is already running');
      return new Future.value(null);
    }
  }
}

// TODO(turnidge): Add argument completion.
class DeleteCommand extends DebuggerCommand {
  DeleteCommand(Debugger debugger) : super(debugger, 'delete', []);

  Future run(List<String> args) {
    if (args.length < 1) {
      debugger.console.printLine('delete expects one or more arguments');
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
        debugger.console.printLine("Invalid breakpoint id '${id}'");
        return new Future.value(null);
      }
      toDelete.add(bpt);
    }
    List pending = [];
    for (var bpt in toDelete) {
      pending.add(debugger.isolate.removeBreakpoint(bpt).then((_) {
            var id = bpt['breakpointNumber'];
            debugger.console.printLine("Removed breakpoint $id");
          }));
    }
    return Future.wait(pending);
  }
}

class InfoBreakpointsCommand extends DebuggerCommand {
  InfoBreakpointsCommand(Debugger debugger)
      : super(debugger, 'breakpoints', []);

  Future run(List<String> args) {
    return debugger.isolate.reloadBreakpoints().then((_) {
      if (debugger.isolate.breakpoints.isEmpty) {
        debugger.console.printLine('No breakpoints');
      }
      for (var bpt in debugger.isolate.breakpoints) {
        var bpId = bpt['breakpointNumber'];
        var script = bpt['location']['script'];
        var tokenPos = bpt['location']['tokenPos'];
        var line = script.tokenToLine(tokenPos);
        var col = script.tokenToCol(tokenPos);
        debugger.console.printLine(
            'Breakpoint ${bpId} at ${script.name}:${line}:${col}');
      }
    });
  }
}

class InfoIsolatesCommand extends DebuggerCommand {
  InfoIsolatesCommand(Debugger debugger) : super(debugger, 'isolates', []);

  Future run(List<String> args) {
    for (var isolate in debugger.isolate.vm.isolates) {
      debugger.console.printLine(
          "Isolate ${isolate.id} '${isolate.name}'");
    }
    return new Future.value(null);
  }
}

class InfoCommand extends DebuggerCommand {
  InfoCommand(Debugger debugger) : super(debugger, 'info', [
      new InfoBreakpointsCommand(debugger),
      new InfoIsolatesCommand(debugger),
  ]);

  Future run(List<String> args) {
    debugger.console.printLine("Invalid info command");
    return new Future.value(null);
  }
}

class RefreshCoverageCommand extends DebuggerCommand {
  RefreshCoverageCommand(Debugger debugger) : super(debugger, 'coverage', []);

  Future run(List<String> args) {
    Set<Script> scripts = debugger.stackElement.activeScripts();
    List pending = [];
    for (var script in scripts) {
      pending.add(script.refreshCoverage().then((_) {
          debugger.console.printLine('Refreshed coverage for ${script.name}');
        }));
    }
    return Future.wait(pending);
  }
}

class RefreshCommand extends DebuggerCommand {
  RefreshCommand(Debugger debugger) : super(debugger, 'refresh', [
      new RefreshCoverageCommand(debugger),
  ]);

  Future run(List<String> args) {
    return debugger.refreshStack();
  }
}

// Tracks the state for an isolate debugging session.
class Debugger {
  RootCommand cmd;
  DebuggerConsoleElement console;
  DebuggerStackElement stackElement;
  ServiceMap stack;

  Debugger() {
    cmd = new RootCommand([
        new HelpCommand(this),
        new PauseCommand(this),
        new ContinueCommand(this),
        new NextCommand(this),
        new StepCommand(this),
        new FinishCommand(this),
        new DeleteCommand(this),
        new InfoCommand(this),
        new RefreshCommand(this),
    ]);
  }

  void set isolate(Isolate iso) {
    _isolate = iso;
    if (_isolate != null) {
      _isolate.reload().then((_) {
        _isolate.vm.events.stream.listen(_onEvent);
        _refreshStack(isolate.pauseEvent).then((_) {
          reportStatus();
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
      // stackElement.stack = stack;
      stackElement.updateStack(stack, pauseEvent);
    });
  }

  void reportStatus() {
    if (_isolate.idle) {
      console.printLine('Isolate is idle');
    } else if (_isolate.running) {
      console.printLine("Isolate is running (type 'pause' to interrupt)");
    } else if (_isolate.pauseEvent != null) {
      _reportPause(_isolate.pauseEvent);
    } else {
      console.printLine('Isolate is in unknown state');
    }
  }

  void _reportPause(ServiceEvent event) {
    if (event.eventType == 'IsolateCreated') {
      console.printLine(
          "Paused at isolate start (type 'continue' to start the isolate')");
    } else if (event.eventType == 'IsolateShutdown') {
      console.printLine(
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
          console.printLine('Breakpoint ${bpId} at ${script.name}:${line}:${col}');
        } else if (event.exception != null) {
          // TODO(turnidge): Test this.
          console.printLine(
              'Exception ${event.exception} at ${script.name}:${line}:${col}');
        } else {
          console.printLine('Paused at ${script.name}:${line}:${col}');
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
        console.printLine('Isolate shutdown');
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
        console.printLine('Continuing...');
        break;

      case '_Graph':
      case 'BreakpointResolved':
      case 'IsolateCreated':
      case 'GC':
        // Ignore these events for now.
        break;

      default:
        console.printLine('Unrecognized event: $event');
        break;
    }
  }

  String complete(String line) {
    List<String> completions = cmd.completeCommand(line);
    if (completions.length == 0) {
      // No completions.  Leave the line alone.
      return line;
    } else if (completions.length == 1) {
      // Unambiguous completion.
      return completions[0];
    } else {
      // Ambigous completion.
      completions = completions.map((s )=> s.trimRight()).toList();
      completions.sort();
      console.printBold(completions.toString());

      // TODO(turnidge): Complete to common prefix of all completions.
      return line;
    }
  }

  // TODO(turnidge): Implement real command line history.
  String lastCommand;
  bool busy = false;

  Future run(String command) {
    assert(!busy);
    busy = true;
    if (command == '') {
      command = lastCommand;
    }
    lastCommand = command;
    console.printBold('\$ $command');
    return cmd.runCommand(command).then((_) {
      busy = false;
    }).catchError((e) {
      console.printLine('ERROR $e');
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
  Debugger debugger = new Debugger();

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
  Debugger debugger = null;

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

  void printLine(String line) {
    var div = new DivElement();
    div.classes.add('normal');
    div.appendText(line);
    $['consoleText'].children.add(div);
    div.scrollIntoView();
  }

  void printBold(String line) {
    var div = new DivElement();
    div.classes.add('bold');
    div.appendText(line);
    $['consoleText'].children.add(div);
    div.scrollIntoView();
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
  @observable Debugger debugger;

  @override
  void ready() {
    super.ready();
    var textBox = $['textBox'];
    textBox.select();
    textBox.onKeyDown.listen((KeyboardEvent e) {
	switch (e.keyCode) {
          case KeyCode.TAB:
            e.preventDefault();
            int cursorPos = textBox.selectionStart;
            var completion = debugger.complete(text.substring(0, cursorPos));
            text = completion + text.substring(cursorPos);
            // TODO(turnidge): Move the cursor to the end of the
            // completion, rather than the end of the string.
            break;
          case KeyCode.ENTER:
            if (!debugger.busy) {
              debugger.run(text);
              text = '';
            }
            break;
	}
      });
  }

  DebuggerInputElement.created() : super.created();
}

