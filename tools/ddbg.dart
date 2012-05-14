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


void printHelp() {
  print("""
  q   Quit debugger shell
  bt  Show backtrace
  r   Resume execution
  s   Single step
  so  Step over
  si  Step into
  sbp <file> <line> Set breakpoint
  ll  List loaded libraries
  ls <libname> List loaded scripts in library
""");
}


void quitShell() {
  vmStream.close();
  vmSock.close();
  stdin.close();
}


Future sendCmd(Map<String, Dynamic> cmd) {
  var completer = new Completer();
  assert(cmd["id"] != null);
  var id = cmd["id"];
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
  var cmd = args[0];
  if (cmd == "r") {
    var cmd = { "id": seqNum, "command": "resume" };
    sendCmd(cmd).then((result) => handleGenericResponse(result));
  } else if (cmd == "s") {
    var cmd = { "id": seqNum, "command": "stepOver" };
    sendCmd(cmd).then((result) => handleGenericResponse(result));
  } else if (cmd == "si") {
    var cmd = { "id": seqNum, "command": "stepInto" };
    sendCmd(cmd).then((result) => handleGenericResponse(result));
  } else if (cmd == "so") {
    var cmd = { "id": seqNum, "command": "stepOut" };
    sendCmd(cmd).then((result) => handleGenericResponse(result));
  } else if (cmd == "bt") {
    var cmd = { "id": seqNum, "command": "getStackTrace" };
    sendCmd(cmd).then((result) => handleStackTraceResponse(result));
  } else if (cmd == "ll") {
    var cmd = { "id": seqNum, "command": "getLibraryURLs" };
    sendCmd(cmd).then((result) => handleGetLibraryResponse(result));
  } else if (cmd == "sbp") {
    if (args.length < 3) {
      return;
    }
    var cmd = { "id": seqNum,
                "command": "setBreakpoint",
                "params": { "url": args[1], "line": Math.parseInt(args[2]) }};
    sendCmd(cmd).then((result) => handleSetBpResponse(result));
  } else if (cmd == "ls") {
    if (args.length < 2) {
      return;
    }
    var cmd = { "id": seqNum,
                 "command": "getScriptURLs",
                "params": { "library": args[1] }};
    sendCmd(cmd).then((result) => handleGetScriptsResponse(result));
  } else if (cmd == "q") {
    quitShell();
  } else if (cmd == "h") {
    printHelp();
  } else {
    print("command '$cmd' not understood, try h for help");
  }
}


void handleGetLibraryResponse(response) {
  var result = response["result"];
  assert(result != null);
  var urls = result["urls"];
  assert(urls != null);
  assert(urls is List);
  print("Loaded libraries:");
  for (int i = 0; i < urls.length; i++) {
    print("  $i ${urls[i]}");
  }
}


void handleGetScriptsResponse(response) {
  var result = response["result"];
  assert(result != null);
  var urls = result["urls"];
  assert(urls != null);
  assert(urls is List);
  print("Loaded scripts:");
  for (int i = 0; i < urls.length; i++) {
    print("  $i ${urls[i]}");
  }
}


void handleSetBpResponse(response) {
  var result = response["result"];
  assert(result != null);
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
  var result = response["result"];
  assert(result != null);
  var callFrames = result["callFrames"];
  assert(callFrames != null);
  printStackTrace(result);
}


void printStackTrace(trace) {
  assert(trace != null);
  var frames = trace["callFrames"];
  if (frames is !List) {
    print("unexpected type for frames parameter $frames");
    return;
  }
  for (int i = 0; i < frames.length; i++) {
    var frame = frames[i];
    var fname = frame["functionName"];
    var url = frame["location"]["url"];
    var line = frame["location"]["lineNumber"];
    print("$i  $fname ($url:$line)");
  }
}


void processVmMessage(String json) {
  var msg = JSON.parse(json);
  if (msg == null) {
    return;
  }
  var event = msg["event"];
  if (event == "paused") {
    print("VM paused, stack trace:");
    printStackTrace(msg["params"]);
    return;
  }
  if (event == "breakpointResolved") {
    var params = msg["params"];
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
