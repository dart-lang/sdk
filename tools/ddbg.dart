// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Simple interactive debugger shell that connects to the Dart VM's debugger
// connection port.

import "dart:convert";
import "dart:io";
import "dart:async";

import "ddbg/lib/commando.dart";

class TargetIsolate {
  int id;
  // The location of the last paused event.
  Map pausedLocation = null;

  TargetIsolate(this.id);
  bool get isPaused => pausedLocation != null;
}

Map<int, TargetIsolate> targetIsolates= new Map<int, TargetIsolate>();

Map<int, Completer> outstandingCommands;

Socket vmSock;
String vmData;
Commando cmdo;
var vmSubscription;
int seqNum = 0;

Process targetProcess;

final verbose = false;
final printMessages = false;

TargetIsolate currentIsolate;
TargetIsolate mainIsolate;


void printHelp() {
  print("""
  q   Quit debugger shell
  bt  Show backtrace
  r   Resume execution
  s   Single step
  so  Step over
  si  Step into
  sbp [<file>] <line> Set breakpoint
  rbp <id> Remove breakpoint with given id
  po <id> Print object info for given id
  eval obj <id> <expr> Evaluate expr on object id
  eval cls <id> <expr> Evaluate expr on class id
  eval lib <id> <expr> Evaluate expr in toplevel of library id
  pl <id> <idx> [<len>] Print list element/slice
  pc <id> Print class info for given id
  ll  List loaded libraries
  plib <id> Print library info for given library id
  slib <id> <true|false> Set library id debuggable
  pg <id> Print all global variables visible within given library id
  ls <lib_id> List loaded scripts in library
  gs <lib_id> <script_url> Get source text of script in library
  tok <lib_id> <script_url> Get line and token table of script in library
  epi <none|all|unhandled>  Set exception pause info
  li List ids of all isolates in the VM
  sci <id>  Set current target isolate
  i <id> Interrupt execution of given isolate id
  h   Print help
""");
}


String formatLocation(Map location) {
  if (location == null) return "";
  var fileName = location["url"].split("/").last;
  return "file: $fileName lib: ${location['libraryId']} token: ${location['tokenOffset']}";
}


void quitShell() {
  vmSubscription.cancel();
  vmSock.close();
  cmdo.done();
}


Future sendCmd(Map<String, dynamic> cmd) {
  var completer = new Completer();
  int id = cmd["id"];
  outstandingCommands[id] = completer;
  if (verbose) {
    print("sending: '${JSON.encode(cmd)}'");
  }
  vmSock.write(JSON.encode(cmd));
  return completer.future;
}


bool checkCurrentIsolate() {
  if (currentIsolate != null) {
    return true;
  }
  print("Need valid current isolate");
  return false;
}


bool checkPaused() {
  if (!checkCurrentIsolate()) return false;
  if (currentIsolate.isPaused) return true;
  print("Current isolate must be paused");
  return false;
}

typedef void HandlerType(Map response);

HandlerType showPromptAfter(void handler(Map response)) {
  // Hide the command prompt immediately.
  return (response) {
    handler(response);
    cmdo.show();
  };
}


void processCommand(String cmdLine) {
  
  void huh() {
    print("'$cmdLine' not understood, try h for help");
  }

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
    if (!checkPaused()) return;
    var cmd = { "id": seqNum,
                "command": resume_commands[command],
                "params": { "isolateId" : currentIsolate.id } };
    cmdo.hide();
    sendCmd(cmd).then(showPromptAfter(handleResumedResponse));
  } else if (command == "bt") {
    var cmd = { "id": seqNum,
                "command": "getStackTrace",
                "params": { "isolateId" : currentIsolate.id } };
    cmdo.hide();
    sendCmd(cmd).then(showPromptAfter(handleStackTraceResponse));
  } else if (command == "ll") {
    var cmd = { "id": seqNum,
                "command": "getLibraries",
                "params": { "isolateId" : currentIsolate.id } };
    cmdo.hide();
    sendCmd(cmd).then(showPromptAfter(handleGetLibraryResponse));
  } else if (command == "sbp" && args.length >= 2) {
    var url, line;
    if (args.length == 2 && currentIsolate.pausedLocation != null) {
      url = currentIsolate.pausedLocation["url"];
      assert(url != null);
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
    cmdo.hide();
    sendCmd(cmd).then(showPromptAfter(handleSetBpResponse));
  } else if (command == "rbp" && args.length == 2) {
    var cmd = { "id": seqNum,
                "command": "removeBreakpoint",
                "params": { "isolateId" : currentIsolate.id,
                            "breakpointId": int.parse(args[1]) } };
    cmdo.hide();
    sendCmd(cmd).then(showPromptAfter(handleGenericResponse));
  } else if (command == "ls" && args.length == 2) {
    var cmd = { "id": seqNum,
                "command": "getScriptURLs",
                "params": { "isolateId" : currentIsolate.id,
                            "libraryId": int.parse(args[1]) } };
    cmdo.hide();
    sendCmd(cmd).then(showPromptAfter(handleGetScriptsResponse));
  } else if (command == "eval" && args.length > 3) {
    var expr = args.getRange(3, args.length).join(" ");
    var target = args[1];
    if (target == "obj") {
      target = "objectId";
    } else if (target == "cls") {
      target = "classId";
    } else if (target == "lib") {
      target = "libraryId";
    } else {
      huh();
      return;
    }
    var cmd = { "id": seqNum,
                "command": "evaluateExpr",
                "params": { "isolateId": currentIsolate.id,
                            target: int.parse(args[2]),
                            "expression": expr } };
    cmdo.hide();
    sendCmd(cmd).then(showPromptAfter(handleEvalResponse));
  } else if (command == "po" && args.length == 2) {
    var cmd = { "id": seqNum,
                "command": "getObjectProperties",
                "params": { "isolateId" : currentIsolate.id,
                            "objectId": int.parse(args[1]) } };
    cmdo.hide();
    sendCmd(cmd).then(showPromptAfter(handleGetObjPropsResponse));
  } else if (command == "pl" && args.length >= 3) {
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
    cmdo.hide();
    sendCmd(cmd).then(showPromptAfter(handleGetListResponse));
  } else if (command == "pc" && args.length == 2) {
    var cmd = { "id": seqNum,
                "command": "getClassProperties",
                "params": { "isolateId" : currentIsolate.id,
                            "classId": int.parse(args[1]) } };
    cmdo.hide();
    sendCmd(cmd).then(showPromptAfter(handleGetClassPropsResponse));
  } else if (command == "plib" && args.length == 2) {
    var cmd = { "id": seqNum,
                "command": "getLibraryProperties",
                "params": {"isolateId" : currentIsolate.id,
                           "libraryId": int.parse(args[1]) } };
    cmdo.hide();
    sendCmd(cmd).then(showPromptAfter(handleGetLibraryPropsResponse));
  } else if (command == "slib" && args.length == 3) {
    var cmd = { "id": seqNum,
                "command": "setLibraryProperties",
                "params": {"isolateId" : currentIsolate.id,
                           "libraryId": int.parse(args[1]),
                           "debuggingEnabled": args[2] } };
    cmdo.hide();
    sendCmd(cmd).then(showPromptAfter(handleSetLibraryPropsResponse));
  } else if (command == "pg" && args.length == 2) {
    var cmd = { "id": seqNum,
                "command": "getGlobalVariables",
                "params": { "isolateId" : currentIsolate.id,
                            "libraryId": int.parse(args[1]) } };
    cmdo.hide();
    sendCmd(cmd).then(showPromptAfter(handleGetGlobalVarsResponse));
  } else if (command == "gs" && args.length == 3) {
    var cmd = { "id": seqNum,
                "command":  "getScriptSource",
                "params": { "isolateId" : currentIsolate.id,
                            "libraryId": int.parse(args[1]),
                            "url": args[2] } };
    cmdo.hide();
    sendCmd(cmd).then(showPromptAfter(handleGetSourceResponse));
  } else if (command == "tok" && args.length == 3) {
    var cmd = { "id": seqNum,
                "command":  "getLineNumberTable",
                "params": { "isolateId" : currentIsolate.id,
                            "libraryId": int.parse(args[1]),
                            "url": args[2] } };
    cmdo.hide();
    sendCmd(cmd).then(showPromptAfter(handleGetLineTableResponse));
  } else if (command == "epi" && args.length == 2) {
    var cmd = { "id": seqNum,
                "command":  "setPauseOnException",
                "params": { "isolateId" : currentIsolate.id,
                            "exceptions": args[1] } };
    cmdo.hide();
    sendCmd(cmd).then(showPromptAfter(handleGenericResponse));
  } else if (command == "li") {
    var cmd = { "id": seqNum, "command": "getIsolateIds" };
    cmdo.hide();
    sendCmd(cmd).then(showPromptAfter(handleGetIsolatesResponse));
  } else if (command == "sci" && args.length == 2) {
    var id = int.parse(args[1]);
    if (targetIsolates[id] != null) {
      currentIsolate = targetIsolates[id];
      print("Setting current target isolate to $id");
    } else {
      print("$id is not a valid isolate id");
    }
  } else if (command == "i" && args.length == 2) {
    var cmd = { "id": seqNum,
                "command": "interrupt",
                "params": { "isolateId": int.parse(args[1]) } };
    cmdo.hide();
    sendCmd(cmd).then(showPromptAfter(handleGenericResponse));
  } else if (command == "q") {
    quitShell();
  } else if (command == "h") {
    printHelp();
  } else {
    huh();
  }
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
  print("$frame_num  $fname ($loc)");
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


void handlePausedEvent(msg) {
  assert(msg["params"] != null);
  var reason = msg["params"]["reason"];
  int isolateId = msg["params"]["isolateId"];
  assert(isolateId != null);
  var isolate = targetIsolates[isolateId];
  assert(isolate != null);
  assert(!isolate.isPaused);
  var location = msg["params"]["location"];;
  assert(location != null);
  isolate.pausedLocation = location;
  if (reason == "breakpoint") {
    print("Isolate $isolateId paused on breakpoint");
    print("location: ${formatLocation(location)}");
  } else if (reason == "interrupted") {
    print("Isolate $isolateId paused due to an interrupt");
    print("location: ${formatLocation(location)}");
  } else {
    assert(reason == "exception");
    var excObj = msg["params"]["exception"];
    print("Isolate $isolateId paused on exception");
    print(remoteObject(excObj));
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
    if (mainIsolate == null) {
      mainIsolate = targetIsolates[isolateId];
      currentIsolate = mainIsolate;
      print("Current isolate set to ${currentIsolate.id}.");
    }
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
        currentIsolate = targetIsolates.first;
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
    handlePausedEvent(msg);
    cmdo.show();
    return;
  }
  if (event == "breakpointResolved") {
    Map params = msg["params"];
    assert(params != null);
    var isolateId = params["isolateId"];
    var location = formatLocation(params["location"]);
    cmdo.hide();
    print("BP ${params["breakpointId"]} resolved in isolate $isolateId"
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
  List<String> allCommands = ['q', 'bt', 'r', 's', 'so', 'si', 'sbp', 'rbp',
                              'po', 'eval', 'pl', 'pc', 'll', 'plib', 'slib',
                              'pg', 'ls', 'gs', 'tok', 'epi', 'li', 'i', 'h'];

  // Completion of first word in the command.
  if (commandParts.length == 1) {
    String prefix = commandParts.last;
    for (String command in allCommands) {
      if (command.startsWith(prefix)) {
        completions.add(command);
      }
    } 
  }

  return completions;
}

void debuggerMain() {
  outstandingCommands = new Map<int, Completer>();
  Socket.connect("127.0.0.1", 5858).then((s) {
    vmSock = s;
    vmSock.setOption(SocketOption.TCP_NODELAY, true);
    var stringStream = vmSock.transform(UTF8.decoder);
    vmSubscription = stringStream.listen(
        (String data) {
          processVmData(data);
        },
        onDone: () {
          print("VM debugger connection closed");
          quitShell();
        },
        onError: (err) {
          print("Error in debug connection: $err");
          // TODO(floitsch): do we want to print the stack trace?
          quitShell();
        });
    cmdo = new Commando(stdin, stdout, processCommand,
                        completer : debuggerCommandCompleter);
  });
}

void main(List<String> args) {
  if (args.length > 0) {
    if (verbose) {
      args = <String>['--debug', '--verbose_debug']..addAll(args);
    } else {
      args = <String>['--debug']..addAll(args);
    }
    Process.start(Platform.executable, args).then((Process process) {
        targetProcess = process;
        process.stdin.close();

        // TODO(turnidge): For now we only show full lines of output
        // from the debugged process.  Should show each character.
        process.stdout
            .transform(UTF8.decoder)
            .transform(new LineSplitter())
            .listen((String line) {
                // Hide/show command prompt across asynchronous output.
                if (cmdo != null) {
                  cmdo.hide();
                }
                print("$line");
                if (cmdo != null) {
                  cmdo.show();
                }
              });

        process.exitCode.then((int exitCode) {
            if (exitCode == 0) {
              print('Program exited normally.');
            } else {
              print('Program exited with code $exitCode.');
            }
          });

      debuggerMain();
    });
  } else {
    debuggerMain();
  }
}
