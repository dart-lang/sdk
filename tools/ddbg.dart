// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Simple interactive debugger shell that connects to the Dart VM's debugger
// connection port.

#import("dart:io");
#import("dart:json");

Map<int, Completer> outstandingCommands;

Socket vmSock;
OutputStream vmStream;
int seqNum = 0;

bool verbose = false;

// The current stack trace, while the VM is paused. It's a list
// of activation frames.
List stackTrace;

// The current activation frame, while the VM is paused.
Map curFrame;


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
  pc <id> Print class info for given id
  ll  List loaded libraries
  pl <id> Print dlibrary info for given id
  ls <libname> List loaded scripts in library
  h   Print help
""");
}


void quitShell() {
  vmStream.close();
  vmSock.close();
  stdin.close();
}


Future sendCmd(Map<String, Dynamic> cmd) {
  var completer = new Completer();
  int id = cmd["id"];
  outstandingCommands[id] = completer;
  if (verbose) {
    print("sending: '${JSON.stringify(cmd)}'");
  }
  vmStream.writeString(JSON.stringify(cmd));
  return completer.future;
}


void processCommand(String cmdLine) {
  seqNum++;
  var args = cmdLine.split(' ');
  if (args.length == 0) {
    return;
  }
  var command = args[0];
  var simple_commands =
      { 'r':'resume', 's':'stepOver', 'si':'stepInto', 'so':'stepOut'};
  if (simple_commands[command] != null) {
    var cmd = { "id": seqNum, "command": simple_commands[command]};
    sendCmd(cmd).then((result) => handleGenericResponse(result));
    stackTrace = curFrame = null;
  } else if (command == "bt") {
    var cmd = { "id": seqNum, "command": "getStackTrace" };
    sendCmd(cmd).then((result) => handleStackTraceResponse(result));
  } else if (command == "ll") {
    var cmd = { "id": seqNum, "command": "getLibraries" };
    sendCmd(cmd).then((result) => handleGetLibraryResponse(result));
  } else if (command == "sbp" && args.length >= 2) {
    var url, line;
    if (args.length == 2) {
      url = stackTrace[0]["location"]["url"];
      line = Math.parseInt(args[1]);
    } else {
      url = args[1];
      line = Math.parseInt(args[2]);
    }
    var cmd = { "id": seqNum,
                "command": "setBreakpoint",
                "params": { "url": url, "line": line }};
    sendCmd(cmd).then((result) => handleSetBpResponse(result));
  } else if (command == "rbp" && args.length == 2) {
    var cmd = { "id": seqNum,
                "command": "removeBreakpoint",
                "params": { "breakpointId": Math.parseInt(args[1]) }};
    sendCmd(cmd).then((result) => handleGenericResponse(result));
  } else if (command == "ls" && args.length == 2) {
    var cmd = { "id": seqNum,
                "command": "getScriptURLs",
                "params": { "libraryId": Math.parseInt(args[1]) }};
    sendCmd(cmd).then((result) => handleGetScriptsResponse(result));
  } else if (command == "po" && args.length == 2) {
    var cmd = { "id": seqNum, "command": "getObjectProperties",
                "params": {"objectId": Math.parseInt(args[1]) }};
    sendCmd(cmd).then((result) => handleGetObjPropsResponse(result));
  } else if (command == "pc" && args.length == 2) {
    var cmd = { "id": seqNum, "command": "getClassProperties",
                "params": {"classId": Math.parseInt(args[1]) }};
    sendCmd(cmd).then((result) => handleGetClassPropsResponse(result));
  } else if (command == "pl" && args.length == 2) {
    var cmd = { "id": seqNum, "command": "getLibraryProperties",
                "params": {"libraryId": Math.parseInt(args[1]) }};
    sendCmd(cmd).then((result) => handleGetLibraryPropsResponse(result));
  } else if (command == "q") {
    quitShell();
  } else if (command == "h") {
    printHelp();
  } else {
    print("command '$command' not understood, try h for help");
  }
}


printNamedObject(obj) {
  var name = obj["name"];
  var value = obj["value"];
  var kind = value["kind"];
  var text = value["text"];
  var id = value["objectId"];
  if (kind == "string") {
    print("  $name = '$text'");
  } else if (kind == "object") {
    print("  $name (id:$id) = $text");
  } else {
    print("  $name = $text");
  }
}


handleGetObjPropsResponse(response) {
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


handleGetClassPropsResponse(response) {
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


handleGetLibraryPropsResponse(response) {
  Map props = response["result"];
  assert(props["url"] != null);
  print("  library url=${props["url"]}");
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


void handleGetLibraryResponse(response) {
  Map result = response["result"];
  List libs = result["libraries"];
  print("Loaded libraries:");
  print(libs);
  for (int i = 0; i < libs.length; i++) {
    print("  ${libs[i]["id"]} ${libs[i]["url"]}");
  }
}


void handleGetScriptsResponse(response) {
  Map result = response["result"];
  List urls = result["urls"];
  print("Loaded scripts:");
  for (int i = 0; i < urls.length; i++) {
    print("  $i ${urls[i]}");
  }
}


void handleSetBpResponse(response) {
  Map result = response["result"];
  var id = result["breakpointId"];
  assert(id != null);
  print("Set BP $id");
}


void handleGenericResponse(response) {
  if (response["error"] != null) {
    print("Error: ${response["error"]}");
  }
}


void handleStackTraceResponse(response) {
  Map result = response["result"];
  List callFrames = result["callFrames"];
  assert(callFrames != null);
  printStackTrace(callFrames);
}


void printStackFrame(frame_num, Map frame) {
  var fname = frame["functionName"];
  var url = frame["location"]["url"];
  var line = frame["location"]["lineNumber"];
  print("$frame_num  $fname ($url:$line)");
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
  stackTrace = msg["params"]["callFrames"];
  assert(stackTrace != null);
  assert(stackTrace.length >= 1);
  curFrame = stackTrace[0];
  print("VM paused, stack trace:");
  printStackTrace(stackTrace);
}


void processVmMessage(String json) {
  var msg = JSON.parse(json);
  if (msg == null) {
    return;
  }
  var event = msg["event"];
  if (event == "paused") {
    handlePausedEvent(msg);
    return;
  }
  if (event == "breakpointResolved") {
    Map params = msg["params"];
    assert(params != null);
    print("BP ${params["breakpointId"]} resolved and "
          "set at line ${params["line"]}.");
    return;
  }
  if (msg["id"] != null) {
    var id = msg["id"];
    if (outstandingCommands.containsKey(id)) {
      if (msg["error"] != null) {
        print("VM says: ${msg["error"]}");
      } else {
        var completer = outstandingCommands[id];
        completer.complete(msg);
      }
      outstandingCommands.remove(id);
    }
  }
}


// TODO(hausner): Need to handle the case where we receive only a partial
// message from the debugger, e.g. when the message is too big to fit in
// one network packet.
void processVmData(String s) {
  final printMessages = false;
  int msg_len = JSON.length(s);
  if (printMessages && msg_len == 0) {
    print("vm sent illegal or partial json message '$s'");
    quitShell();
    return;
  }
  while (msg_len > 0 && msg_len <= s.length) {
    if (msg_len == s.length) {
      if (printMessages) { print("message: $s"); }
      processVmMessage(s);
      return;
    }
    if (printMessages) { print("at least one message: '$s'"); }
    var msg = s.substring(0, msg_len);
    if (printMessages) { print("first message: $msg"); }
    processVmMessage(msg);
    s = s.substring(msg_len);
    msg_len = JSON.length(s);
  }
  if (printMessages) { print("leftover vm data '$s'"); }
}


void main() {
  outstandingCommands = new Map<int, Completer>();
  vmSock = new Socket("127.0.0.1", 5858);
  vmStream = new SocketOutputStream(vmSock);
  var stdinStream = new StringInputStream(stdin);
  stdinStream.onLine = () {
    processCommand(stdinStream.readLine());
  };
  var vmInStream = new SocketInputStream(vmSock);
  vmInStream.onData = () {
    var s = new String.fromCharCodes(vmInStream.read());
    processVmData(s);
  };
  vmInStream.onError = (err) {
    print("Error in debug connection: $err");
    quitShell();
  };
  vmInStream.onClosed = () {
    print("VM debugger connection closed");
    quitShell();
  };
}
