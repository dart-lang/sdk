// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Simple interactive debugger shell that connects to the Dart VM's debugger
// connection port.

import "dart:convert";
import "dart:io";
import "dart:async";
import "dart:math";

import "ddbg/lib/commando.dart";

class TargetScript {
  // The text of a script.
  String source = null;

  // A mapping from line number to source text.
  List<String> lineToSource = null;

  // A mapping from token offset to line number.
  Map<int,int> tokenToLine = null;
}

const UnknownLocation = const {};

class TargetIsolate {
  int id;
  // The location of the last paused event.
  Map pausedLocation = null;

  TargetIsolate(this.id);
  bool get isPaused => pausedLocation != null;
  String get pausedUrl => pausedLocation != null ? pausedLocation["url"] : null;

  Map<String, TargetScript> scripts = {};
}

Map<int, TargetIsolate> targetIsolates= new Map<int, TargetIsolate>();

Map<int, Completer> outstandingCommands;

Socket vmSock;
String vmData;
var cmdSubscription;
Commando cmdo;
var vmSubscription;
int seqNum = 0;

bool isDebugging = false;
Process targetProcess = null;
bool suppressNextExitCode = false;

final verbose = false;
final printMessages = false;

TargetIsolate currentIsolate;
TargetIsolate mainIsolate;

int debugPort = 5858;

String formatLocation(Map location) {
  if (location == null) return "";
  var fileName = location["url"].split("/").last;
  return "file: $fileName lib: ${location['libraryId']} token: ${location['tokenOffset']}";
}


Future sendCmd(Map<String, dynamic> cmd) {
  var completer = new Completer.sync();
  int id = cmd["id"];
  outstandingCommands[id] = completer;
  if (verbose) {
    print("sending: '${JSON.encode(cmd)}'");
  }
  vmSock.write(JSON.encode(cmd));
  return completer.future;
}


bool checkCurrentIsolate() {
  if (vmSock == null) {
    print("There is no active script.  Try 'help run'.");
    return false;
  }
  if (currentIsolate == null) {
    print('There is no current isolate.');
    return false;
  }
  return true;
}


void setCurrentIsolate(TargetIsolate isolate) {
  if (isolate != currentIsolate) {
    currentIsolate = isolate;
    if (mainIsolate == null) {
      print("Main isolate is ${isolate.id}");
      mainIsolate = isolate;
    }
    print("Current isolate is now ${isolate.id}");
  }
}


bool checkPaused() {
  if (!checkCurrentIsolate()) return false;
  if (currentIsolate.isPaused) return true;
  print("Current isolate must be paused");
  return false;
}

// These settings are allowed in the 'set' and 'show' debugger commands.
var validSettings = ['vm', 'vmargs', 'script', 'args'];

// The current values for all settings.
var settings = new Map();

String _leftJustify(text, int width) {
  StringBuffer buffer = new StringBuffer();
  buffer.write(text);
  while (buffer.length < width) {
    buffer.write(' ');
  }
  return buffer.toString();
}

// TODO(turnidge): Move all commands here.
List<Command> commandList =
    [ new HelpCommand(),
      new QuitCommand(),
      new RunCommand(),
      new KillCommand(),
      new ConnectCommand(),
      new DisconnectCommand(),
      new SetCommand(),
      new ShowCommand() ];


List<Command> matchCommand(String commandName, bool exactMatchWins) {
  List matches = [];
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

abstract class Command {
  String get name;
  Future run(List<String> args);
}

class HelpCommand extends Command {
  final name = 'help';
  final helpShort = 'Show a list of debugger commands';
  final helpLong ="""
Show a list of debugger commands or get more information about a
particular command.

Usage:
  help
  help <command>
""";

  Future run(List<String> args) {
    if (args.length == 1) {
      print("Debugger commands:\n");
      for (var command in commandList) {
        print('  ${_leftJustify(command.name, 11)} ${command.helpShort}');
      }

      // TODO(turnidge): Convert all commands to use the Command class.
      print("""
  bt          Show backtrace
  r           Resume execution
  s           Single step
  so          Step over
  si          Step into
  sbp [<file>] <line> Set breakpoint
  rbp <id>    Remove breakpoint with given id
  po <id>     Print object info for given id
  eval fr  <n> <expr> Evaluate expr on stack frame index n
  eval obj <id> <expr> Evaluate expr on object id
  eval cls <id> <expr> Evaluate expr on class id
  eval lib <id> <expr> Evaluate expr in toplevel of library id
  pl <id> <idx> [<len>] Print list element/slice
  pc <id>     Print class info for given id
  ll          List loaded libraries
  plib <id>   Print library info for given library id
  slib <id> <true|false> Set library id debuggable
  pg <id>     Print all global variables visible within given library id
  ls <lib_id> List loaded scripts in library
  gs <lib_id> <script_url> Get source text of script in library
  tok <lib_id> <script_url> Get line and token table of script in library
  epi <none|all|unhandled>  Set exception pause info
  li          List ids of all isolates in the VM
  sci <id>    Set current target isolate
  i <id>      Interrupt execution of given isolate id
""");

      print("For more information about a particular command, type:\n\n"
            "  help <command>\n");

      print("Commands may be abbreviated: e.g. type 'h' for 'help.\n");
    } else if (args.length == 2) {
      var commandName = args[1];
      var matches = matchCommand(commandName, true);
      if (matches.length == 0) {
        print("Command '$commandName' not recognized.  "
              "Try 'help' for a list of commands.");
      } else {
        for (var command in matches) {
          print("---- ${command.name} ----\n${command.helpLong}");
        }
      }
    } else {
      print("Command '$command' not recognized.  "
            "Try 'help' for a list of commands.");
    }

    return new Future.value();
  }
}


class QuitCommand extends Command {
  final name = 'quit';
  final helpShort = 'Quit the debugger.';
  final helpLong ="""
Quit the debugger.

Usage:
  quit
""";

  Future run(List<String> args) {
    if (args.length > 1) {
      print("Unexpected arguments to $name command.");
      return new Future.value();
    }
    return debuggerQuit();
  }
}

class SetCommand extends Command {
  final name = 'set';
  final helpShort = 'Change the value of a debugger setting.';
  final helpLong ="""
Change the value of a debugger setting.

Usage:
  set <setting> <value>

Valid settings are:
  ${validSettings.join('\n  ')}.

See also 'help show'.
""";

  Future run(List<String> args) {
    if (args.length < 3 || !validSettings.contains(args[1])) {
      print("Undefined $name command.  Try 'help $name'.");
      return new Future.value();
    }
    var option = args[1];
    var value = args.getRange(2, args.length).join(' ');
    settings[option] = value;
    return new Future.value();
  }
}

class ShowCommand extends Command {
  final name = 'show';
  final helpShort = 'Show the current value of a debugger setting.';
  final helpLong ="""
Show the current value of a debugger setting.

Usage:
  show
  show <setting>

If no <setting> is specified, all current settings are shown.

Valid settings are:
  ${validSettings.join('\n  ')}.

See also 'help set'.
""";

  Future run(List<String> args) {
    if (args.length == 1) {
      for (var option in validSettings) {
        var value = settings[option];
        print("$option = '$value'");
      }
    } else if (args.length == 2 && validSettings.contains(args[1])) {
      var option = args[1];
      var value = settings[option];
      if (value == null) {
        print('$option has not been set.');
      } else {
        print("$option = '$value'");
      }
      return new Future.value();
    } else {
      print("Undefined $name command.  Try 'help $name'.");
    }
    return new Future.value();
  }
}

class RunCommand extends Command {
  final name = 'run';
  final helpShort = "Run the currrent script.";
  final helpLong ="""
Runs the current script.

Usage:
  run
  run <args>

The current script will be run on the current vm.  The 'vm' and
'vmargs' settings are used to specify the current vm and vm arguments.
The 'script' and 'args' settings are used to specify the current
script and script arguments.

For more information on settings type 'help show' or 'help set'.

If <args> are provided to the run command, it is the same as typing
'set args <args>' followed by 'run'.
""";

  Future run(List<String> cmdArgs) {
    if (isDebugging) {
      // TODO(turnidge): Implement modal y/n dialog to stop running script.
      print("There is already a running dart process.  "
            "Try 'kill'.");
      return new Future.value();
    }
    assert(targetProcess == null);
    if (settings['script'] == null) {
      print("There is no script specified.  "
            "Use 'set script' to set the current script.");
      return new Future.value();
    }
    if (cmdArgs.length > 1) {
      settings['args'] = cmdArgs.getRange(1, cmdArgs.length);
    }

    // Build the process arguments.
    var processArgs = ['--debug:$debugPort'];
    if (verbose) {
      processArgs.add('--verbose_debug');
    }
    if (settings['vmargs'] != null) {
      processArgs.addAll(settings['vmargs'].split(' '));
    }
    processArgs.add(settings['script']);
    if (settings['args'] != null) {
      processArgs.addAll(settings['args'].split(' '));
    }
    String vm = settings['vm'];

    isDebugging = true;
    cmdo.hide();
    return Process.start(vm, processArgs).then((process) {
        print("Started process ${process.pid} '$vm ${processArgs.join(' ')}'");
        targetProcess = process;
        process.stdin.close();

        // TODO(turnidge): For now we only show full lines of output
        // from the debugged process.  Should show each character.
        process.stdout
            .transform(UTF8.decoder)
            .transform(new LineSplitter())
            .listen((String line) {
                cmdo.hide();
                // TODO(turnidge): Escape output in any way?
                print(line);
                cmdo.show();
              });

        process.stderr
            .transform(UTF8.decoder)
            .transform(new LineSplitter())
            .listen((String line) {
                cmdo.hide();
                print(line);
                cmdo.show();
              });

        process.exitCode.then((int exitCode) {
            cmdo.hide();
            if (suppressNextExitCode) {
              suppressNextExitCode = false;
            } else {
              if (exitCode == 0) {
                print('Process exited normally.');
              } else {
                print('Process exited with code $exitCode.');
              }
            }
            targetProcess = null;
            cmdo.show();
          });

        // Wait for the vm to open the debugging port.
        return openVmSocket(0);
      });
  }
}

class KillCommand extends Command {
  final name = 'kill';
  final helpShort = 'Kill the currently executing script.';
  final helpLong ="""
Kill the currently executing script.

Usage:
  kill
""";

  Future run(List<String> cmdArgs) {
    if (!isDebugging) {
      print('There is no running script.');
      return new Future.value();
    }
    if (targetProcess == null) {
      print("The active dart process was not started with 'run'. "
            "Try 'disconnect' instead.");
      return new Future.value();
    }
    assert(targetProcess != null);
    bool result = targetProcess.kill();
    if (result) {
      print('Process killed.');
      suppressNextExitCode = true;
    } else {
      print('Unable to kill process ${targetProcess.pid}');
    }
    return new Future.value();
  }
}

class ConnectCommand extends Command {
  final name = 'connect';
  final helpShort = "Connect to a running dart script.";
  final helpLong ="""
Connect to a running dart script.

Usage:
  connect
  connect <port>

The debugger will connect to a dart script which has already been
started with the --debug option.  If no port is provided, the debugger
will attempt to connect on the default debugger port.
""";

  Future run(List<String> cmdArgs) {
    if (cmdArgs.length > 2) {
      print("Too many arguments to 'connect'.");
    }
    if (isDebugging) {
      // TODO(turnidge): Implement modal y/n dialog to stop running script.
      print("There is already a running dart process.  "
            "Try 'kill'.");
      return new Future.value();
    }
    assert(targetProcess == null);
    if (cmdArgs.length == 2) {
      debugPort = int.parse(cmdArgs[1]);
    }

    isDebugging = true;
    cmdo.hide();
    return openVmSocket(0);
  }
}

class DisconnectCommand extends Command {
  final name = 'disconnect';
  final helpShort = "Disconnect from a running dart script.";
  final helpLong ="""
Disconnect from a running dart script.

Usage:
  disconnect

The debugger will disconnect from a dart script's debugging port.  The
script must have been connected to earlier with the 'connect' command.
""";

  Future run(List<String> cmdArgs) {
    if (cmdArgs.length > 1) {
      print("Too many arguments to 'disconnect'.");
    }
    if (!isDebugging) {
      // TODO(turnidge): Implement modal y/n dialog to stop running script.
      print("There is no active dart process.  "
            "Try 'connect'.");
      return new Future.value();
    }
    if (targetProcess != null) {
      print("The active dart process was started with 'run'.  "
            "Try 'kill'.");
    }

    cmdo.hide();
    return closeVmSocket();
  }
}

typedef void HandlerType(Map response);

HandlerType showPromptAfter(void handler(Map response)) {
  return (response) {
    handler(response);
    cmdo.show();
  };
}

void processCommand(String cmdLine) {
  void huh() {
    print("'$cmdLine' not understood, try 'help' for help.");
  }

  cmdo.hide();
  seqNum++;
  cmdLine = cmdLine.trim();
  var args = cmdLine.split(' ');
  if (args.length == 0) {
    return;
  }
  var command = args[0];

  var resume_commands =
      { 'r':'resume', 's':'stepOver', 'si':'stepInto', 'so':'stepOut'};
  if (resume_commands[command] != null) {
    if (!checkPaused()) {
      cmdo.show();
      return;
    }
    var cmd = { "id": seqNum,
                "command": resume_commands[command],
                "params": { "isolateId" : currentIsolate.id } };
    sendCmd(cmd).then(showPromptAfter(handleResumedResponse));
  } else if (command == "bt") {
    if (!checkCurrentIsolate()) {
      cmdo.show();
      return;
    }
    var cmd = { "id": seqNum,
                "command": "getStackTrace",
                "params": { "isolateId" : currentIsolate.id } };
    sendCmd(cmd).then(showPromptAfter(handleStackTraceResponse));
  } else if (command == "ll") {
    if (!checkCurrentIsolate()) {
      cmdo.show();
      return;
    }
    var cmd = { "id": seqNum,
                "command": "getLibraries",
                "params": { "isolateId" : currentIsolate.id } };
    sendCmd(cmd).then(showPromptAfter(handleGetLibraryResponse));
  } else if (command == "sbp" && args.length >= 2) {
    if (!checkCurrentIsolate()) {
      cmdo.show();
      return;
    }
    var url, line;
    if (args.length == 2 && currentIsolate.pausedUrl != null) {
      url = currentIsolate.pausedUrl;
      line = int.parse(args[1]);
    } else {
      url = args[1];
      line = int.parse(args[2]);
    }
    var cmd = { "id": seqNum,
                "command": "setBreakpoint",
                "params": { "isolateId" : currentIsolate.id,
                            "url": url,
                            "line": line }};
    sendCmd(cmd).then(showPromptAfter(handleSetBpResponse));
  } else if (command == "rbp" && args.length == 2) {
    if (!checkCurrentIsolate()) {
      cmdo.show();
      return;
    }
    var cmd = { "id": seqNum,
                "command": "removeBreakpoint",
                "params": { "isolateId" : currentIsolate.id,
                            "breakpointId": int.parse(args[1]) } };
    sendCmd(cmd).then(showPromptAfter(handleGenericResponse));
  } else if (command == "ls" && args.length == 2) {
    if (!checkCurrentIsolate()) {
      cmdo.show();
      return;
    }
    var cmd = { "id": seqNum,
                "command": "getScriptURLs",
                "params": { "isolateId" : currentIsolate.id,
                            "libraryId": int.parse(args[1]) } };
    sendCmd(cmd).then(showPromptAfter(handleGetScriptsResponse));
  } else if (command == "eval" && args.length > 3) {
    if (!checkCurrentIsolate()) {
      cmdo.show();
      return;
    }
    var expr = args.getRange(3, args.length).join(" ");
    var target = args[1];
    if (target == "obj") {
      target = "objectId";
    } else if (target == "cls") {
      target = "classId";
    } else if (target == "lib") {
      target = "libraryId";
    } else if (target == "fr") {
      target = "frameId";
    } else {
      huh();
      return;
    }
    var cmd = { "id": seqNum,
                "command": "evaluateExpr",
                "params": { "isolateId": currentIsolate.id,
                            target: int.parse(args[2]),
                            "expression": expr } };
    sendCmd(cmd).then(showPromptAfter(handleEvalResponse));
  } else if (command == "po" && args.length == 2) {
    if (!checkCurrentIsolate()) {
      cmdo.show();
      return;
    }
    var cmd = { "id": seqNum,
                "command": "getObjectProperties",
                "params": { "isolateId" : currentIsolate.id,
                            "objectId": int.parse(args[1]) } };
    sendCmd(cmd).then(showPromptAfter(handleGetObjPropsResponse));
  } else if (command == "pl" && args.length >= 3) {
    if (!checkCurrentIsolate()) {
      cmdo.show();
      return;
    }
    var cmd;
    if (args.length == 3) {
      cmd = { "id": seqNum,
              "command": "getListElements",
              "params": { "isolateId" : currentIsolate.id,
                          "objectId": int.parse(args[1]),
                          "index": int.parse(args[2]) } };
    } else {
      cmd = { "id": seqNum,
              "command": "getListElements",
              "params": { "isolateId" : currentIsolate.id,
                          "objectId": int.parse(args[1]),
                          "index": int.parse(args[2]),
                          "length": int.parse(args[3]) } };
    }
    sendCmd(cmd).then(showPromptAfter(handleGetListResponse));
  } else if (command == "pc" && args.length == 2) {
    if (!checkCurrentIsolate()) {
      cmdo.show();
      return;
    }
    var cmd = { "id": seqNum,
                "command": "getClassProperties",
                "params": { "isolateId" : currentIsolate.id,
                            "classId": int.parse(args[1]) } };
    sendCmd(cmd).then(showPromptAfter(handleGetClassPropsResponse));
  } else if (command == "plib" && args.length == 2) {
    if (!checkCurrentIsolate()) {
      cmdo.show();
      return;
    }
    var cmd = { "id": seqNum,
                "command": "getLibraryProperties",
                "params": {"isolateId" : currentIsolate.id,
                           "libraryId": int.parse(args[1]) } };
    sendCmd(cmd).then(showPromptAfter(handleGetLibraryPropsResponse));
  } else if (command == "slib" && args.length == 3) {
    if (!checkCurrentIsolate()) {
      cmdo.show();
      return;
    }
    var cmd = { "id": seqNum,
                "command": "setLibraryProperties",
                "params": {"isolateId" : currentIsolate.id,
                           "libraryId": int.parse(args[1]),
                           "debuggingEnabled": args[2] } };
    sendCmd(cmd).then(showPromptAfter(handleSetLibraryPropsResponse));
  } else if (command == "pg" && args.length == 2) {
    if (!checkCurrentIsolate()) {
      cmdo.show();
      return;
    }
    var cmd = { "id": seqNum,
                "command": "getGlobalVariables",
                "params": { "isolateId" : currentIsolate.id,
                            "libraryId": int.parse(args[1]) } };
    sendCmd(cmd).then(showPromptAfter(handleGetGlobalVarsResponse));
  } else if (command == "gs" && args.length == 3) {
    if (!checkCurrentIsolate()) {
      cmdo.show();
      return;
    }
    var cmd = { "id": seqNum,
                "command":  "getScriptSource",
                "params": { "isolateId" : currentIsolate.id,
                            "libraryId": int.parse(args[1]),
                            "url": args[2] } };
    sendCmd(cmd).then(showPromptAfter(handleGetSourceResponse));
  } else if (command == "tok" && args.length == 3) {
    if (!checkCurrentIsolate()) {
      cmdo.show();
      return;
    }
    var cmd = { "id": seqNum,
                "command":  "getLineNumberTable",
                "params": { "isolateId" : currentIsolate.id,
                            "libraryId": int.parse(args[1]),
                            "url": args[2] } };
    sendCmd(cmd).then(showPromptAfter(handleGetLineTableResponse));
  } else if (command == "epi" && args.length == 2) {
    if (!checkCurrentIsolate()) {
      cmdo.show();
      return;
    }
    var cmd = { "id": seqNum,
                "command":  "setPauseOnException",
                "params": { "isolateId" : currentIsolate.id,
                            "exceptions": args[1] } };
    sendCmd(cmd).then(showPromptAfter(handleGenericResponse));
  } else if (command == "li") {
    if (!checkCurrentIsolate()) {
      cmdo.show();
      return;
    }
    var cmd = { "id": seqNum, "command": "getIsolateIds" };
    sendCmd(cmd).then(showPromptAfter(handleGetIsolatesResponse));
  } else if (command == "sci" && args.length == 2) {
    var id = int.parse(args[1]);
    if (targetIsolates[id] != null) {
      setCurrentIsolate(targetIsolates[id]);
    } else {
      print("$id is not a valid isolate id");
    }
    cmdo.show();
  } else if (command == "i" && args.length == 2) {
    var cmd = { "id": seqNum,
                "command": "interrupt",
                "params": { "isolateId": int.parse(args[1]) } };
    sendCmd(cmd).then(showPromptAfter(handleGenericResponse));
  } else if (command.length == 0) {
    huh();
    cmdo.show();
  } else {
    // TODO(turnidge): Use this for all commands.
    var matches = matchCommand(command, true);
    if (matches.length == 0) {
      huh();
      cmdo.show();
    } else if (matches.length == 1) {
      matches[0].run(args).then((_) {
          cmdo.show();
        });
    } else {
      var matchNames = matches.map((handler) => handler.name);
      print("Ambigous command '$command' : ${matchNames.toList()}");
      cmdo.show();
    }
  }
}


void processError(error, trace) {
  cmdo.hide();
  print("\nInternal error:\n$error\n$trace");
  cmdo.show();
}


void processDone() {
  debuggerQuit();
}


String remoteObject(value) {
  var kind = value["kind"];
  var text = value["text"];
  var id = value["objectId"];
  if (kind == "string") {
    return "(string, id $id) '$text'";
  } else if (kind == "list") {
    var len = value["length"];
    return "(list, id $id, len $len) $text";
  } else if (kind == "object") {
    return "(obj, id $id) $text";
  } else if (kind == "function") {
    var location = formatLocation(value['location']);
    var name = value['name'];
    var signature = value['signature'];
    return "(closure ${name}${signature} $location)";
  } else {
    return "$text";
  }
}


printNamedObject(obj) {
  var name = obj["name"];
  var value = obj["value"];
  print("  $name = ${remoteObject(value)}");
}


handleGetObjPropsResponse(Map response) {
  Map props = response["result"];
  int class_id = props["classId"];
  if (class_id == -1) {
    print("  null");
    return;
  }
  List fields = props["fields"];
  print("  class id: $class_id");
  for (int i = 0; i < fields.length; i++) {
    printNamedObject(fields[i]);
  }
}

handleGetListResponse(Map response) {
  Map result = response["result"];
  if (result["elements"] != null) {
    // List slice.
    var index = result["index"];
    var length = result["length"];
    List elements = result["elements"];
    assert(length == elements.length);
    for (int i = 0; i < length; i++) {
      var kind = elements[i]["kind"];
      var text = elements[i]["text"];
      print("  ${index + i}: ($kind) $text");
    }
  } else {
    // One element, a remote object.
    print(result);
    print("  ${remoteObject(result)}");
  }
}


handleGetClassPropsResponse(Map response) {
  Map props = response["result"];
  assert(props["name"] != null);
  int libId = props["libraryId"];
  assert(libId != null);
  print("  class ${props["name"]} (library id: $libId)");
  List fields = props["fields"];
  if (fields.length > 0) {
    print("  static fields:");
    for (int i = 0; i < fields.length; i++) {
      printNamedObject(fields[i]);
    }
  }
}


handleGetLibraryPropsResponse(Map response) {
  Map props = response["result"];
  assert(props["url"] != null);
  print("  library url: ${props["url"]}");
  assert(props["debuggingEnabled"] != null);
  print("  debugging enabled: ${props["debuggingEnabled"]}");
  List imports = props["imports"];
  assert(imports != null);
  if (imports.length > 0) {
    print("  imports:");
    for (int i = 0; i < imports.length; i++) {
      print("    id ${imports[i]["libraryId"]} prefix ${imports[i]["prefix"]}");
    }
  }
  List globals = props["globals"];
  assert(globals != null);
  if (globals.length > 0) {
    print("  global variables:");
    for (int i = 0; i < globals.length; i++) {
      printNamedObject(globals[i]);
    }
  }
}


handleSetLibraryPropsResponse(Map response) {
  Map props = response["result"];
  assert(props["debuggingEnabled"] != null);
  print("  debugging enabled: ${props["debuggingEnabled"]}");
}


handleGetGlobalVarsResponse(Map response) {
  List globals = response["result"]["globals"];
  for (int i = 0; i < globals.length; i++) {
    printNamedObject(globals[i]);
  }
}


handleGetSourceResponse(Map response) {
  Map result = response["result"];
  String source = result["text"];
  print("Source text:\n$source\n--------");
}


handleGetLineTableResponse(Map response) {
  Map result = response["result"];
  var info = result["lines"];
  print("Line info table:\n$info");
}


void handleGetIsolatesResponse(Map response) {
  Map result = response["result"];
  List ids = result["isolateIds"];
  assert(ids != null);
  print("List of isolates:");
  for (int id in ids) {
    TargetIsolate isolate = targetIsolates[id];
    var state = (isolate != null) ? "running" : "<unknown isolate>";
    if (isolate != null && isolate.isPaused) {
      var loc = formatLocation(isolate.pausedLocation);
      state = "paused at $loc";
    }
    var marker = " ";
    if (currentIsolate != null && id == currentIsolate.id) {
      marker = "*";
    }
    print("$marker $id $state");
  }
}


void handleGetLibraryResponse(Map response) {
  Map result = response["result"];
  List libs = result["libraries"];
  print("Loaded libraries:");
  print(libs);
  for (int i = 0; i < libs.length; i++) {
    print("  ${libs[i]["id"]} ${libs[i]["url"]}");
  }
}


void handleGetScriptsResponse(Map response) {
  Map result = response["result"];
  List urls = result["urls"];
  print("Loaded scripts:");
  for (int i = 0; i < urls.length; i++) {
    print("  $i ${urls[i]}");
  }
}


void handleEvalResponse(Map response) {
  Map result = response["result"];
  print(remoteObject(result));
}


void handleSetBpResponse(Map response) {
  Map result = response["result"];
  var id = result["breakpointId"];
  assert(id != null);
  print("Set BP $id");
}


void handleGenericResponse(Map response) {
  if (response["error"] != null) {
    print("Error: ${response["error"]}");
  }
}

void handleResumedResponse(Map response) {
  if (response["error"] != null) {
    print("Error: ${response["error"]}");
    return;
  }
  assert(currentIsolate != null);
  currentIsolate.pausedLocation = null;
}


void handleStackTraceResponse(Map response) {
  Map result = response["result"];
  List callFrames = result["callFrames"];
  assert(callFrames != null);
  printStackTrace(callFrames);
}


void printStackFrame(frame_num, Map frame) {
  var fname = frame["functionName"];
  var loc = formatLocation(frame["location"]);
  print("#${_leftJustify(frame_num,2)} $fname at $loc");
  List locals = frame["locals"];
  for (int i = 0; i < locals.length; i++) {
    printNamedObject(locals[i]);
  }
}


void printStackTrace(List frames) {
  for (int i = 0; i < frames.length; i++) {
    printStackFrame(i, frames[i]);
  }
}


Map<int, int> parseLineNumberTable(List<List<int>> table) {
  Map tokenToLine = {};
  for (var line in table) {
    // Each entry begins with a line number...
    var lineNumber = line[0];
    for (var pos = 1; pos < line.length; pos += 2) {
      // ...and is followed by (token offset, col number) pairs.
      // We ignore the column numbers.
      var tokenOffset = line[pos];
      tokenToLine[tokenOffset] = lineNumber;
    }
  }
  return tokenToLine;
}


Future<TargetScript> getTargetScript(Map location) {
  var isolate = targetIsolates[currentIsolate.id];
  var url = location['url'];
  var script = isolate.scripts[url];
  if (script != null) {
    return new Future.value(script);
  }
  script = new TargetScript();

  // Ask the vm for the source and line number table.
  var sourceCmd = {
    "id": seqNum++,
    "command":  "getScriptSource",
    "params": { "isolateId": currentIsolate.id,
                "libraryId": location['libraryId'],
                "url": url } };

  var lineNumberCmd = {
    "id": seqNum++,
    "command":  "getLineNumberTable",
    "params": { "isolateId": currentIsolate.id,
                "libraryId": location['libraryId'],
                "url": url } };

  // Send the source command
  var sourceResponse = sendCmd(sourceCmd).then((response) {
      Map result = response["result"];
      script.source = result['text'];
      // Line numbers are 1-based so add a dummy for line 0.
      script.lineToSource = [''];
      script.lineToSource.addAll(script.source.split('\n'));
    });

  // Send the line numbers command
  var lineNumberResponse = sendCmd(lineNumberCmd).then((response) {
      Map result = response["result"];
      script.tokenToLine = parseLineNumberTable(result['lines']);
    });

  return Future.wait([sourceResponse, lineNumberResponse]).then((_) {
      // When both commands complete, cache the result.
      isolate.scripts[url] = script;
      return script;
    });
}


Future printLocation(String label, Map location) {
  // Figure out the line number.
  return getTargetScript(location).then((script) {
      var lineNumber = script.tokenToLine[location['tokenOffset']];
      var text = script.lineToSource[lineNumber];
      if (label != null) {
        var fileName = location['url'].split("/").last;
        print("$label \n"
              "    at $fileName:$lineNumber");
      }
      print("${_leftJustify(lineNumber, 8)}$text");
    });
}


Future handlePausedEvent(msg) {
  assert(msg["params"] != null);
  var reason = msg["params"]["reason"];
  int isolateId = msg["params"]["isolateId"];
  assert(isolateId != null);
  var isolate = targetIsolates[isolateId];
  assert(isolate != null);
  assert(!isolate.isPaused);
  var location = msg["params"]["location"];;
  setCurrentIsolate(isolate);
  isolate.pausedLocation = (location == null) ? UnknownLocation : location;
  if (reason == "breakpoint") {
    assert(location != null);
    var bpId = (msg["params"]["breakpointId"]);
    var label = (bpId != null) ? "Breakpoint $bpId" : null;
    return printLocation(label, location);
  } else if (reason == "interrupted") {
    assert(location != null);
    return printLocation("Interrupted", location);
  } else {
    assert(reason == "exception");
    var excObj = msg["params"]["exception"];
    print("Isolate $isolateId paused on exception");
    print(remoteObject(excObj));
    return new Future.value();
  }
}

void handleIsolateEvent(msg) {
  Map params = msg["params"];
  assert(params != null);
  var isolateId = params["id"];
  var reason = params["reason"];
  if (reason == "created") {
    print("Isolate $isolateId has been created.");
    assert(targetIsolates[isolateId] == null);
    targetIsolates[isolateId] = new TargetIsolate(isolateId);
  } else {
    assert(reason == "shutdown");
    var isolate = targetIsolates.remove(isolateId);
    assert(isolate != null);
    if (isolate == mainIsolate) {
      mainIsolate = null;
      print("Main isolate ${isolate.id} has terminated.");
    } else {
      print("Isolate ${isolate.id} has terminated.");
    }
    if (isolate == currentIsolate) {
      currentIsolate = mainIsolate;
      if (currentIsolate == null && !targetIsolates.isEmpty) {
        currentIsolate = targetIsolates.values.first;
      }
      if (currentIsolate != null) {
        print("Setting current isolate to ${currentIsolate.id}.");
      } else {
        print("All isolates have terminated.");
      }
    }
  }
}

void processVmMessage(String jsonString) {
  var msg = JSON.decode(jsonString);
  if (msg == null) {
    return;
  }
  var event = msg["event"];
  if (event == "isolate") {
    cmdo.hide();
    handleIsolateEvent(msg);
    cmdo.show();
    return;
  }
  if (event == "paused") {
    cmdo.hide();
    handlePausedEvent(msg).then((_) {
        cmdo.show();
      });
    return;
  }
  if (event == "breakpointResolved") {
    Map params = msg["params"];
    assert(params != null);
    var isolateId = params["isolateId"];
    var location = formatLocation(params["location"]);
    cmdo.hide();
    print("Breakpoint ${params["breakpointId"]} resolved in isolate $isolateId"
          " at $location.");
    cmdo.show();
    return;
  }
  if (msg["id"] != null) {
    var id = msg["id"];
    if (outstandingCommands.containsKey(id)) {
      var completer = outstandingCommands.remove(id);
      if (msg["error"] != null) {
        print("VM says: ${msg["error"]}");
        // TODO(turnidge): Rework how hide/show happens.  For now we
        // show here explicitly.
        cmdo.show();
      } else {
        completer.complete(msg);
      }
    }
  }
}

bool haveGarbageVmData() {
  if (vmData == null || vmData.length == 0) return false;
  var i = 0, char = " ";
  while (i < vmData.length) {
    char = vmData[i];
    if (char != " " && char != "\n" && char != "\r" && char != "\t") break;
    i++;
  }
  if (i >= vmData.length) {
    return false;
  } else {
    return char != "{";
  }
}


void processVmData(String data) {
  if (vmData == null || vmData.length == 0) {
    vmData = data;
  } else {
    vmData = vmData + data;
  }
  if (haveGarbageVmData()) {
    print("Error: have garbage data from VM: '$vmData'");
    return;
  }
  int msg_len = jsonObjectLength(vmData);
  if (printMessages && msg_len == 0) {
    print("have partial or illegal json message"
          " of ${vmData.length} chars:\n'$vmData'");
    return;
  }
  while (msg_len > 0 && msg_len <= vmData.length) {
    if (msg_len == vmData.length) {
      if (printMessages) { print("have one full message:\n$vmData"); }
      processVmMessage(vmData);
      vmData = null;
      return;
    }
    if (printMessages) { print("at least one message: '$vmData'"); }
    var msg = vmData.substring(0, msg_len);
    if (printMessages) { print("first message: $msg"); }
    vmData = vmData.substring(msg_len);
    if (haveGarbageVmData()) {
      print("Error: garbage data after previous message: '$vmData'");
      print("Previous message was: '$msg'");
      return;
    }
    processVmMessage(msg);
    msg_len = jsonObjectLength(vmData);
  }
  if (printMessages) { print("leftover vm data '$vmData'"); }
}

/**
 * Skip past a JSON object value.
 * The object value must start with '{' and continues to the
 * matching '}'. No attempt is made to otherwise validate the contents
 * as JSON. If it is invalid, a later [parseJson] will fail.
 */
int jsonObjectLength(String string) {
  int skipWhitespace(int index) {
    while (index < string.length) {
      String char = string[index];
      if (char != " " && char != "\n" && char != "\r" && char != "\t") break;
      index++;
    }
    return index;
  }
  int skipString(int index) {
    assert(string[index - 1] == '"');
    while (index < string.length) {
      String char = string[index];
      if (char == '"') return index + 1;
      if (char == r'\') index++;
      if (index == string.length) return index;
      index++;
    }
    return index;
  }
  int index = 0;
  index = skipWhitespace(index);
  // Bail out if the first non-whitespace character isn't '{'.
  if (index == string.length || string[index] != '{') return 0;
  int nesting = 0;
  while (index < string.length) {
    String char = string[index++];
    if (char == '{') {
      nesting++;
    } else if (char == '}') {
      nesting--;
      if (nesting == 0) return index;
    } else if (char == '"') {
      // Strings can contain braces. Skip their content.
      index = skipString(index);
    }
  }
  return 0;
}

List<String> debuggerCommandCompleter(List<String> commandParts) {
  List<String> completions = new List<String>();

  // TODO(turnidge): Have a global command table and use it to for
  // help messages, command completion, and command dispatching.  For now
  // we hardcode the list here.
  //
  // TODO(turnidge): Implement completion for arguments as well.
  List<String> oldCommands = ['bt', 'r', 's', 'so', 'si', 'sbp', 'rbp',
                              'po', 'eval', 'pl', 'pc', 'll', 'plib', 'slib',
                              'pg', 'ls', 'gs', 'tok', 'epi', 'li', 'i' ];

  // Completion of first word in the command.
  if (commandParts.length == 1) {
    String prefix = commandParts.last;
    for (var command in oldCommands) {
      if (command.startsWith(prefix)) {
        completions.add(command);
      }
    }
    for (var command in commandList) {
      if (command.name.startsWith(prefix)) {
        completions.add(command.name);
      }
    }
  }

  return completions;
}

Future closeCommando() {
  var subscription = cmdSubscription;
  cmdSubscription = null;
  cmdo = null;

  var future = subscription.cancel();
  if (future != null) {
    return future;
  } else {
    return new Future.value();
  }
}


Future openVmSocket(int attempt) {
  return Socket.connect("127.0.0.1", debugPort).then(
      setupVmSocket,
      onError: (e) {
        // We were unable to connect to the debugger's port.  Try again.
        retryOpenVmSocket(e, attempt);
      });
}


void setupVmSocket(Socket s) {
  vmSock = s;
  vmSock.setOption(SocketOption.TCP_NODELAY, true);
  var stringStream = vmSock.transform(UTF8.decoder);
  outstandingCommands = new Map<int, Completer>();
  vmSubscription = stringStream.listen(
      (String data) {
        processVmData(data);
      },
      onDone: () {
        cmdo.hide();
        if (verbose) {
          print("VM debugger connection closed");
        }
        closeVmSocket().then((_) {
            cmdo.show();
          });
      },
      onError: (err) {
        cmdo.hide();
        // TODO(floitsch): do we want to print the stack trace?
        print("Error in debug connection: $err");

        // TODO(turnidge): Kill the debugged process here?
        closeVmSocket().then((_) {
            cmdo.show();
          });
      });
}


Future retryOpenVmSocket(error, int attempt) {
  var delay;
  if (attempt < 10) {
    delay = new Duration(milliseconds:10);
  } else if (attempt < 20) {
    delay = new Duration(seconds:1);
  } else {
    // Too many retries.  Give up.
    //
    // TODO(turnidge): Kill the debugged process here?
    print('Timed out waiting for debugger to start.\nError: $e');
    return closeVmSocket();
  }
  // Wait and retry.
  return new Future.delayed(delay, () {
      openVmSocket(attempt + 1);
    });
}


Future closeVmSocket() {
  if (vmSubscription == null) {
    // Already closed, nothing to do.
    assert(vmSock == null);
    return new Future.value();
  }

  isDebugging = false;
  var subscription = vmSubscription;
  var sock = vmSock;

  // Wait for the socket to close and the subscription to be
  // cancelled.  Perhaps overkill, but it means we know these will be
  // done.
  //
  // This is uglier than it needs to be since cancel can return null.
  var cleanupFutures = [sock.close()];
  var future = subscription.cancel();
  if (future != null) {
    cleanupFutures.add(future);
  }

  vmSubscription = null;
  vmSock = null;
  outstandingCommands = null;
  return Future.wait(cleanupFutures);
}

void debuggerError(self, parent, zone, error, StackTrace trace) {
  print('\n--------\nExiting due to unexpected error:\n'
        '  $error\n$trace\n');
  debuggerQuit();
}

Future debuggerQuit() {
  // Kill target process, if any.
  if (targetProcess != null) {
    if (!targetProcess.kill()) {
      print('Unable to kill process ${targetProcess.pid}');
    }
  }

  // Restore terminal settings, close connections.
  return Future.wait([closeCommando(), closeVmSocket()]).then((_) {
      exit(0);

      // Unreachable.
      return new Future.value();
    });
}


void parseArgs(List<String> args) {
  int pos = 0;
  settings['vm'] = Platform.executable;
  while (pos < args.length && args[pos].startsWith('-')) {
    pos++;
  }
  if (pos < args.length) {
    settings['vmargs'] = args.getRange(0, pos).join(' ');
    settings['script'] = args[pos];
    settings['args'] = args.getRange(pos + 1, args.length).join(' ');
  }
}

void main(List<String> args) {
  // Setup a zone which will exit the debugger cleanly on any uncaught
  // exception.
  var zone = Zone.ROOT.fork(specification:new ZoneSpecification(
      handleUncaughtError: debuggerError));

  zone.run(() {
      parseArgs(args);
      cmdo = new Commando(completer: debuggerCommandCompleter);
      cmdSubscription = cmdo.commands.listen(processCommand,
                                             onError: processError,
                                             onDone: processDone);
    });
}
