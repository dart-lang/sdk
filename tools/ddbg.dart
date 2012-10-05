// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Simple interactive debugger shell that connects to the Dart VM's debugger
// connection port.

#import("dart:io");
#import("dart:json");
#import("dart:math", prefix: "Math");
#import("dart:utf");


Map<int, Completer> outstandingCommands;

Socket vmSock;
String vmData;
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
  pl <id> <idx> [<len>] Print list element/slice
  pc <id> Print class info for given id
  ll  List loaded libraries
  plib <id> Print library info for given library id
  slib <id> <true|false> Set library id debuggable
  pg <id> Print all global variables visible within given library id
  ls <lib_id> List loaded scripts in library
  gs <lib_id> <script_url> Get source text of script in library
  epi <none|all|unhandled>  Set exception pause info
  i <id> Interrupt execution of given isolate id
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
  } else if (command == "pl" && args.length >= 3) {
     var cmd;
     if (args.length == 3) {
       cmd = { "id": seqNum, "command": "getListElements",
                "params": {"objectId": Math.parseInt(args[1]),
                            "index": Math.parseInt(args[2]) }};
    } else {
       cmd = { "id": seqNum, "command": "getListElements",
                "params": {"objectId": Math.parseInt(args[1]),
                            "index": Math.parseInt(args[2]),
                            "length": Math.parseInt(args[3]) }};
    }
    sendCmd(cmd).then((result) => handleGetListResponse(result));
  } else if (command == "pc" && args.length == 2) {
    var cmd = { "id": seqNum, "command": "getClassProperties",
                "params": {"classId": Math.parseInt(args[1]) }};
    sendCmd(cmd).then((result) => handleGetClassPropsResponse(result));
  } else if (command == "plib" && args.length == 2) {
    var cmd = { "id": seqNum, "command": "getLibraryProperties",
                "params": {"libraryId": Math.parseInt(args[1]) }};
    sendCmd(cmd).then((result) => handleGetLibraryPropsResponse(result));
  } else if (command == "slib" && args.length == 3) {
    var cmd = { "id": seqNum, "command": "setLibraryProperties",
                "params": {"libraryId": Math.parseInt(args[1]),
                           "debuggingEnabled": args[2] }};
    sendCmd(cmd).then((result) => handleSetLibraryPropsResponse(result));
  } else if (command == "pg" && args.length == 2) {
    var cmd = { "id": seqNum, "command": "getGlobalVariables",
                "params": {"libraryId": Math.parseInt(args[1]) }};
    sendCmd(cmd).then((result) => handleGetGlobalVarsResponse(result));
  } else if (command == "gs" && args.length == 3) {
    var cmd = { "id": seqNum, "command":  "getScriptSource",
                "params": { "libraryId": Math.parseInt(args[1]),
                            "url": args[2] }};
    sendCmd(cmd).then((result) => handleGetSourceResponse(result));
  } else if (command == "epi" && args.length == 2) {
    var cmd = { "id": seqNum, "command":  "setPauseOnException",
                "params": { "exceptions": args[1] }};
    sendCmd(cmd).then((result) => handleGenericResponse(result));
  } else if (command == "i" && args.length == 2) {
    var cmd = { "id": seqNum, "command": "interrupt",
                "params": {"isolateId": Math.parseInt(args[1]) }};
    sendCmd(cmd).then((result) => handleGenericResponse(result));
  } else if (command == "q") {
    quitShell();
  } else if (command == "h") {
    printHelp();
  } else {
    print("command '$command' not understood, try h for help");
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
  } else {
    return "$text";
  }
}


printNamedObject(obj) {
  var name = obj["name"];
  var value = obj["value"];
  print("  $name = ${remoteObject(value)}");
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

handleGetListResponse(response) {
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


handleSetLibraryPropsResponse(response) {
  Map props = response["result"];
  assert(props["debuggingEnabled"] != null);
  print("  debugging enabled: ${props["debuggingEnabled"]}");
}


handleGetGlobalVarsResponse(response) {
  List globals = response["result"]["globals"];
  for (int i = 0; i < globals.length; i++) {
    printNamedObject(globals[i]);
  }
}


handleGetSourceResponse(response) {
  Map result = response["result"];
  String source = result["text"];
  print("Source text:\n$source\n--------");
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
  var libId = frame["libraryId"];
  var url = frame["location"]["url"];
  var line = frame["location"]["lineNumber"];
  print("$frame_num  $fname ($url:$line) (lib $libId)");
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
  var id = msg["params"]["id"];
  stackTrace = msg["params"]["callFrames"];
  assert(stackTrace != null);
  assert(stackTrace.length >= 1);
  curFrame = stackTrace[0];
  if (reason == "breakpoint") {
    print("Isolate $id paused on breakpoint");
  } else if (reason == "interrupted") {
    print("Isolate $id paused due to an interrupt");
  } else {
    assert(reason == "exception");
    var excObj = msg["params"]["exception"];
    print("Isolate $id paused on exception");
    print(remoteObject(excObj));
  }
  print("Stack trace:");
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
  if (event == "isolate") {
    Map params = msg["params"];
    assert(params != null);
    print("Isolate ${params["id"]} has been ${params["reason"]}.");
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


void processVmData(String data) {
  final printMessages = false;
  if (vmData == null || vmData.length == 0) {
    vmData = data;
  } else {
    vmData = vmData.concat(data);
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
    processVmMessage(msg);
    vmData = vmData.substring(msg_len);
    msg_len = jsonObjectLength(vmData);
  }
  if (printMessages) { print("leftover vm data '$vmData'"); }
}

/**
 * Skip past a JSON object value.
 * The object value must start with '{' and continues to the
 * matching '}'. No attempt is made to otherwise validate the contents
 * as JSON. If it is invalid, a later [JSON.parse] will fail.
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
  int nexting = 0;
  while (index < string.length) {
    String char = string[index++];
    if (char == '{') {
      nexting++;
    } else if (char == '}') {
      nexting--;
      if (nexting == 0) return index;
    } else if (char == '"') {
      // Strings can contain braces. Skip their content.
      index = skipString(index);
    }
  }
  return 0;
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
    String s = decodeUtf8(vmInStream.read());
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
