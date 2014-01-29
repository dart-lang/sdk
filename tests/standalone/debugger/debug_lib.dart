// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Library used by debugger wire protocol tests (standalone VM debugging).

library DartDebugger;

import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:math";

// Whether or not to print the debugger wire messages on the console.
var verboseWire = false;

// Class to buffer wire protocol data from debug target and
// break it down to individual json messages.
class JsonBuffer {
  String buffer = null;

  append(String s) {
    if (buffer == null || buffer.length == 0) {
      buffer = s;
    } else {
      buffer += s;
    }
  }

  String getNextMessage() {
    if (buffer == null) return null;
    int msgLen = objectLength();
    if (msgLen == 0) return null;
    String msg = null;
    if (msgLen == buffer.length) {
      msg = buffer;
      buffer = null;
    } else {
      assert(msgLen < buffer.length);
      msg = buffer.substring(0, msgLen);
      buffer = buffer.substring(msgLen);
    }
    return msg;
  }

  bool haveGarbage() {
    if (buffer == null || buffer.length == 0) return false;
    var i = 0, char = " ";
    while (i < buffer.length) {
      char = buffer[i];
      if (char != " " && char != "\n" && char != "\r" && char != "\t") break;
      i++;
    }
    if (i >= buffer.length) {
      return false;
    } else {
      return char != "{";
    }
  }

  // Returns the character length of the next json message in the
  // buffer, or 0 if there is only a partial message in the buffer.
  // The object value must start with '{' and continues to the
  // matching '}'. No attempt is made to otherwise validate the contents
  // as JSON. If it is invalid, a later JSON.decode() will fail.
  int objectLength() {
    int skipWhitespace(int index) {
      while (index < buffer.length) {
        String char = buffer[index];
        if (char != " " && char != "\n" && char != "\r" && char != "\t") break;
        index++;
      }
      return index;
    }
    int skipString(int index) {
      assert(buffer[index - 1] == '"');
      while (index < buffer.length) {
        String char = buffer[index];
        if (char == '"') return index + 1;
        if (char == r'\') index++;
        if (index == buffer.length) return index;
        index++;
      }
      return index;
    }
    int index = 0;
    index = skipWhitespace(index);
    // Bail out if the first non-whitespace character isn't '{'.
    if (index == buffer.length || buffer[index] != '{') return 0;
    int nesting = 0;
    while (index < buffer.length) {
      String char = buffer[index++];
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
}


getJsonValue(Map jsonMsg, String path) {
  List properties = path.split(new RegExp(":"));
  assert(properties.length >= 1);
  var node = jsonMsg;
  for (int i = 0; i < properties.length; i++) {
    if (node == null) return null;
    String property = properties[i];
    var index = null;
    if (property.endsWith("]")) {
      var bracketPos = property.lastIndexOf("[");
      if (bracketPos <= 0) return null;
      var indexStr = property.substring(bracketPos + 1, property.length - 1);
      try {
        index = int.parse(indexStr);
      } on FormatException {
        print("$indexStr is not a valid array index");
        return null;
      }
      property = property.substring(0, bracketPos);
    }
    if (node is Map) {
      node = node[property];
    } else {
      return null;
    }
    if (index != null) {
      if (node is List && node.length > index) {
        node = node[index];
      } else {
        return null;
      }
    }
  }
  return node;
}


// Returns true if [template] is a subset of [map].
bool matchMaps(Map template, Map msg) {
  bool isMatch = true;
  template.forEach((k, v) {
    if (msg.containsKey(k)) {
      var receivedValue = msg[k];
      if ((v is Map) && (receivedValue is Map)) {
        if (!matchMaps(v, receivedValue)) isMatch = false;
      } else if (v == null) {
        // null in the template matches everything.
      } else if (v != receivedValue) {
        isMatch = false;
      }
    } else {
      isMatch = false;
    }
  });
  return isMatch;
}


class Command {
  var template;

  void send(Debugger debugger) {
    debugger.sendMessage(template);
  }

  void matchResponse(Debugger debugger) {
    Map response = debugger.currentMessage;
    var id = template["id"];
    assert(id != null && id >= 0);
    if (response["id"] != id) {
      debugger.error("Error: expected messaged id $id but got ${response["id"]}.");
    }
  }
}

class GetLineTableCmd extends Command {
  GetLineTableCmd() {
    template = {"id": 0,
                "command": "getLineNumberTable",
                "params": {"isolateId": 0, "libraryId": 0, "url": ""}};
  }

  void send(Debugger debugger) {
    assert(debugger.scriptUrl != null);
    template["params"]["url"] = debugger.scriptUrl;
    template["params"]["libraryId"] = debugger.libraryId;
    debugger.sendMessage(template);
  }

  void matchResponse(Debugger debugger) {
    super.matchResponse(debugger);
    List<List<int>> table = getJsonValue(debugger.currentMessage, "result:lines");
    debugger.tokenToLine = {};
    for (var line in table) {
      // Each entry begins with a line number...
      var lineNumber = line[0];
      for (var pos = 1; pos < line.length; pos += 2) {
        // ...and is followed by (token offset, col number) pairs.
        var tokenOffset = line[pos];
        debugger.tokenToLine[tokenOffset] = lineNumber;
      }
    }
  }
}


class LineMatcher extends Command {
  int expectedLineNumber;

  LineMatcher(this.expectedLineNumber) {
    template = {"id": 0, "command": "getStackTrace", "params": {"isolateId": 0}};
  }

  void matchResponse(Debugger debugger) {
    assert(debugger.tokenToLine != null);
    super.matchResponse(debugger);
    var msg = debugger.currentMessage;
    List frames = getJsonValue(msg, "result:callFrames");
    assert(frames != null);
    var tokenOffset = frames[0]["location"]["tokenOffset"];
    assert(tokenOffset != null);
    var lineNumber = debugger.tokenToLine[tokenOffset];
    assert(lineNumber != null);
    if (expectedLineNumber != lineNumber) {
      debugger.error("Error: expected pause at line $expectedLineNumber "
                     "but reported line is $lineNumber.");
      return;
    }
    print("Matched line number $lineNumber");
  }
}

MatchLine(lineNumber) {
  return new LineMatcher(lineNumber);
}


class FrameMatcher extends Command {
  int frameIndex;
  List<String> functionNames;
  bool exactMatch;

  FrameMatcher(this.frameIndex, this.functionNames, this.exactMatch) {
    template = {"id": 0, "command": "getStackTrace", "params": {"isolateId": 0}};
  }

  void matchResponse(Debugger debugger) {
    super.matchResponse(debugger);
    var msg = debugger.currentMessage;
    List frames = getJsonValue(msg, "result:callFrames");
    assert(frames != null);
    if (debugger.scriptUrl == null) {
      var name = frames[0]["functionName"];
      if (name == "main") {
        // Extract script url of debugged script.
        debugger.scriptUrl = frames[0]["location"]["url"];
        assert(debugger.scriptUrl != null);
        debugger.libraryId = frames[0]["location"]["libraryId"];
        assert(debugger.libraryId != null);
      }
    }
    if (frames.length < functionNames.length) {
      debugger.error("Error: stack trace not long enough "
                     "to match ${functionNames.length} frames");
      return;
    }
    for (int i = 0; i < functionNames.length; i++) {
      var idx = i + frameIndex;
      var name = frames[idx]["functionName"];
      assert(name != null);
      bool isMatch = exactMatch ? name == functionNames[i]
                                : name.contains(functionNames[i]);
      if (!isMatch) {
        debugger.error("Error: call frame $idx: "
          "expected function name '${functionNames[i]}' but found '$name'");
        return;
      }
    }
    print("Matched frames: $functionNames");
  }
}


MatchFrame(int frameIndex, String functionName, {exactMatch: false}) {
  return new FrameMatcher(frameIndex, [functionName], exactMatch);
}

MatchFrames(List<String> functionNames, {exactMatch: false}) {
  return new FrameMatcher(0, functionNames, exactMatch);
}


class LocalsMatcher extends Command {
  Map locals = {};

  LocalsMatcher(this.locals) {
    template = {"id": 0, "command": "getStackTrace", "params": {"isolateId": 0}};
  }

  void matchResponse(Debugger debugger) {
    super.matchResponse(debugger);

    List frames = getJsonValue(debugger.currentMessage, "result:callFrames");
    assert(frames != null);

    String functionName = frames[0]['functionName'];
    List localsList = frames[0]['locals'];
    Map reportedLocals = {};
    localsList.forEach((local) => reportedLocals[local['name']] = local['value']);
    for (String key in locals.keys) {
      if (reportedLocals[key] == null) {
        debugger.error("Error in $functionName(): no value reported for local "
            "variable $key");
        return;
      }
      String expected = locals[key];
      String actual = reportedLocals[key]['text'];
      if (expected != actual) {
        debugger.error("Error in $functionName(): got '$actual' for local "
            "variable $key, but expected '$expected'");
        return;
      }
    }
    print("Matched locals ${locals.keys}");
  }
}


MatchLocals(Map localValues) {
  return new LocalsMatcher(localValues);
}


class EventMatcher {
  String eventName;
  Map params;

  EventMatcher(this.eventName, this.params);

  void matchEvent(Debugger debugger) {
    for (Event event in debugger.events) {
      if (event.name == eventName) {
        if (params == null || matchMaps(params, event.params)) {
          // Remove the matched event, so we don't match against it in the future.
          debugger.events.remove(event);
          return;
        }
      }
    }

    String msg = params == null ? '' : params.toString();
    debugger.error("Error: could not match event $eventName $msg");
  }
}


ExpectEvent(String eventName, [Map params]) {
  return new EventMatcher(eventName, params);
}


class RunCommand extends Command {
  RunCommand.resume() {
    template = {"id": 0, "command": "resume", "params": {"isolateId": 0}};
  }
  RunCommand.step() {
    template = {"id": 0, "command": "stepOver", "params": {"isolateId": 0}};
  }
  RunCommand.stepInto() {
    template = {"id": 0, "command": "stepInto", "params": {"isolateId": 0}};
  }
  RunCommand.stepOut() {
    template = {"id": 0, "command": "stepOut", "params": {"isolateId": 0}};
  }
  void send(Debugger debugger) {
    debugger.sendMessage(template);
    debugger.isPaused = false;
  }
  void matchResponse(Debugger debugger) {
    super.matchResponse(debugger);
    print("Command: ${template['command']}");
  }
}


Resume() => new RunCommand.resume();
Step() => new RunCommand.step();
StepInto() => new RunCommand.stepInto();
StepOut() => new RunCommand.stepOut();

class SetBreakpointCommand extends Command {
  int line;
  SetBreakpointCommand(int this.line) {
    template = {"id": 0,
                "command": "setBreakpoint",
                "params": { "isolateId": 0,
                            "url": null,
                            "line": null }};
  }

  void send(Debugger debugger) {
    assert(debugger.scriptUrl != null);
    template["params"]["url"] = debugger.scriptUrl;
    template["params"]["line"] = line;
    debugger.sendMessage(template);
  }

  void matchResponse(Debugger debugger) {
    super.matchResponse(debugger);
    print("Set breakpoint at line $line");
  }
}

SetBreakpoint(int line) => new SetBreakpointCommand(line);

class Event {
  String name;
  Map params;

  Event(Map json) {
    name = json['event'];
    params = json['params'];
  }
}


// A debug script is a list of Command objects.
class DebugScript {
  List entries;
  DebugScript(List scriptEntries) {
    entries = new List.from(scriptEntries.reversed);
    entries.add(new GetLineTableCmd());
    entries.add(MatchFrame(0, "main"));
  }
  bool get isEmpty => entries.isEmpty;
  bool get isNextEventMatcher => !isEmpty && currentEntry is EventMatcher;
  get currentEntry => entries.last;
  advance() => entries.removeLast();
  add(entry) => entries.add(entry);
}


class Debugger {
  // Debug target process properties.
  Process targetProcess;
  Socket socket;
  JsonBuffer responses = new JsonBuffer();

  DebugScript script;
  int seqNr = 0;  // Sequence number of next debugger command message.
  Command lastCommand = null;  // Most recent command sent to target.
  List<String> errors = new List();
  List<Event> events = new List();
  bool cleanupDone = false;

  // Data collected from debug target.
  Map currentMessage = null;  // Currently handled message sent by target.
  String scriptUrl = null;
  int libraryId = null;
  Map<int,int> tokenToLine = null;
  bool shutdownEventSeen = false;
  int isolateId = 0;
  bool isPaused = false;

  Debugger(this.targetProcess, this.script) {
    var stdoutStringStream = targetProcess.stdout
        .transform(UTF8.decoder)
        .transform(new LineSplitter());
    stdoutStringStream.listen((line) {
      print("TARG: $line");
      if (line.startsWith("Debugger listening")) {
        RegExp portExpr = new RegExp(r"\d+");
        var port = portExpr.stringMatch(line);
        print("Debug target found listening at port '$port'");
        openConnection(int.parse(port));
      }
    });

    var stderrStringStream = targetProcess.stderr
        .transform(UTF8.decoder)
        .transform(new LineSplitter());
    stderrStringStream.listen((line) {
      print("TARG: $line");
    });
  }

  // Handle debugger events, updating the debugger state.
  void handleEvent(Map<String,dynamic> msg) {
    events.add(new Event(msg));

    if (msg["event"] == "isolate") {
      if (msg["params"]["reason"] == "created") {
        isolateId = msg["params"]["id"];
        assert(isolateId != null);
        print("Debuggee isolate id $isolateId created.");
      } else if (msg["params"]["reason"] == "shutdown") {
        print("Debuggee isolate id ${msg["params"]["id"]} shut down.");
        shutdownEventSeen = true;
        if (!script.isEmpty) {
          error("Error: premature isolate shutdown event seen.");
          error("Next expected event: ${script.currentEntry}");
        }
      }
    } else if (msg["event"] == "breakpointResolved") {
      var bpId = msg["params"]["breakpointId"];
      assert(bpId != null);
      var isolateId = msg["params"]["isolateId"];
      assert(isolateId != null);
      var location = msg["params"]["location"];
      assert(location != null);
      print("Isolate $isolateId: breakpoint $bpId resolved"
            " at location $location");
      // We may want to maintain a table of breakpoints in the future.
    } else if (msg["event"] == "paused") {
      isPaused = true;
    } else {
      error("Error: unknown debugger event received");
    }
  }

  // Handle one JSON message object and match it to the
  // expected events and responses in the debugging script.
  void handleMessage(Map<String,dynamic> receivedMsg) {
    currentMessage = receivedMsg;
    if (receivedMsg["event"] != null) {
      handleEvent(receivedMsg);
      if (errorsDetected) {
        error("Error while handling debugger event");
        error("Event received from debug target: $receivedMsg");
      }
    } else if (receivedMsg["id"] != null) {
      // This is a response to the last command we sent.
      assert(lastCommand != null);
      lastCommand.matchResponse(this);
      lastCommand = null;
      if (errorsDetected) {
        error("Error while matching response to debugger command");
        error("Response received from debug target: $receivedMsg");
      }
    }
  }

  // Send next debugger command in the script, if a response
  // from the last command has been received and processed.
  void sendNextCommand() {
    while (script.isNextEventMatcher) {
      EventMatcher matcher = script.currentEntry;
      script.advance();
      matcher.matchEvent(this);
    }

    if (lastCommand == null) {
      if (script.currentEntry is Command) {
        script.currentEntry.send(this);
        lastCommand = script.currentEntry;
        seqNr++;
        script.advance();
      }
    }
  }

  // Handle data received over the wire from the debug target
  // process. Split input from JSON wire format into individual
  // message objects (maps).
  void handleMessages() {
    var msg = responses.getNextMessage();
    while (msg != null) {
      if (verboseWire) print("RECV: $msg");
      if (responses.haveGarbage()) {
        error("Error: leftover text after message: '${responses.buffer}'");
        error("Previous message may be malformed, was: '$msg'");
        cleanup();
        return;
      }
      var msgObj = JSON.decode(msg);
      handleMessage(msgObj);
      if (errorsDetected) {
        error("Error while handling script entry");
        error("Message received from debug target: $msg");
        cleanup();
        return;
      }
      if (shutdownEventSeen) {
        cleanup();
        return;
      }
      if (isPaused) sendNextCommand();
      msg = responses.getNextMessage();
    }
  }

  // Send a debugger command to the target VM.
  void sendMessage(Map<String,dynamic> msg) {
    if (msg["id"] != null) {
      msg["id"] = seqNr;
    }
    if (msg["params"] != null && msg["params"]["isolateId"] != null) {
      msg["params"]["isolateId"] = isolateId;
    }
    String jsonMsg = JSON.encode(msg);
    if (verboseWire) print("SEND: $jsonMsg");
    socket.write(jsonMsg);
  }

  bool get errorsDetected => errors.length > 0;

  // Record error message.
  void error(String s) {
    errors.add(s);
  }

  void openConnection(int portNumber) {
    Socket.connect("127.0.0.1", portNumber).then((s) {
        s.setOption(SocketOption.TCP_NODELAY, true);
        this.socket = s;
        var stringStream = socket.transform(UTF8.decoder);
        stringStream.listen((str) {
            try {
              responses.append(str);
              handleMessages();
            } catch(e, trace) {
              print("Unexpected exception:\n$e\n$trace");
              cleanup();
            }
          },
          onDone: () {
            print("Connection closed by debug target");
            cleanup();
          },
          onError: (e, trace) {
            print("Error '$e' detected in input stream from debug target");
            if (trace != null) print("StackTrace: $trace");
            cleanup();
          });
      },
      onError: (e, trace) {
        String msg = "Error while connecting to debugee: $e";
        if (trace != null) msg += "\nStackTrace: $trace";
        error(msg);
        cleanup();
      });
  }

  void cleanup() {
    if (cleanupDone) return;
    if (socket != null) {
      socket.close().catchError((error) {
        // Print this directly in addition to adding it to the
        // error message queue, in case the error message queue
        // gets printed before this error handler is called.
        print("Error occurred while closing socket: $error");
        error("Error while closing socket: $error");
      });
    }
    var targetPid = targetProcess.pid;
    if (errorsDetected || !shutdownEventSeen) {
      print("Sending kill signal to process $targetPid...");
      targetProcess.kill();
    }
    // If the process was already dead, exitCode is
    // available and we call exit() in the next event loop cycle.
    // Otherwise this will wait for the process to exit.
    targetProcess.exitCode.then((exitCode) {
      print("process $targetPid terminated with exit code $exitCode.");
      if (exitCode != 0) {
        error("Error: target process died with exit code $exitCode");
      }
      if (errorsDetected) {
        print("\n===== Errors detected: =====");
        for (int i = 0; i < errors.length; i++) print(errors[i]);
        print("============================\n");
      }
      exit(errors.length);
    });
    cleanupDone = true;
  }
}


bool RunScript(List script, List<String> arguments) {
  if (arguments.contains("--debuggee")) {
    return false;
  }
  verboseWire = arguments.contains("--wire");

  // Port number 0 means debug target picks a free port dynamically.
  var targetOpts = [ "--debug:0" ];
  if (arguments.contains("--verbose")) {
    targetOpts.add("--verbose_debug");
  }
  targetOpts.add(Platform.script.toFilePath());
  targetOpts.add("--debuggee");
  print('args: ${targetOpts.join(" ")}');

  Process.start(Platform.executable, targetOpts).then((Process process) {
    print("Debug target process started, pid ${process.pid}.");
    process.stdin.close();
    var debugger = new Debugger(process, new DebugScript(script));
  });
  return true;
}
