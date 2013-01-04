// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Library used by debugger wire protocol tests (standalone VM debugging).

library DartDebugger;

import "dart:io";
import "dart:utf";
import "dart:json";

// TODO(hausner): need to select a different port number for each
// test that runs in parallel.
var debugPort = 5860;

// Whether or not to print debug target process on the console.
var showDebuggeeOutput = true;

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
      buffer = buffer.concat(s);
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

  // Returns the character length of the newxt json message in the
  // buffer, or 0 if there is only a partial message in the buffer.
  // The object value must start with '{' and continues to the
  // matching '}'. No attempt is made to otherwise validate the contents
  // as JSON. If it is invalid, a later JSON.parse() will fail.
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


class BreakpointEvent {
  String functionName;
  var template = { "event": "paused", "params": { "reason": "breakpoint" }};

  BreakpointEvent({String function: null}) {
    functionName = function;
  }

  void match(Debugger debugger) {
    var msg = debugger.currentMessage;
    if (!matchMaps(template, msg)) {
      debugger.error("message does not match $template");
    }
    var name = getJsonValue(msg, "params:callFrames[0]:functionName");
    if (name == "main") {
      // Extract script url of debugged script.
      var scriptUrl = getJsonValue(msg, "params:callFrames[0]:location:url");
      assert(scriptUrl != null);
      debugger.scriptUrl = scriptUrl;
    }
    if (functionName != null) {
      var name = getJsonValue(msg, "params:callFrames[0]:functionName");
      if (functionName != name) {
        debugger.error("expected function name $functionName but got $name");
      }
    }
  }
}

Breakpoint({String function}) {
  return new BreakpointEvent(function: function);
}

class Matcher {
  void match(Debugger debugger);
}

class FrameMatcher extends Matcher {
  int frameIndex;
  List<String> functionNames;

  FrameMatcher(this.frameIndex, this.functionNames);

  void match(Debugger debugger) {
    var msg = debugger.currentMessage;
    List frames = getJsonValue(msg, "params:callFrames");
    assert(frames != null);
    if (frames.length < functionNames.length) {
      debugger.error("stack trace not long enough "
                     "to match ${functionNames.length} frames");
      return;
    }
    for (int i = 0; i < functionNames.length; i++) {
      var idx = i + frameIndex;
      var property = "params:callFrames[$idx]:functionName";
      var name = getJsonValue(msg, property);
      if (name == null) {
        debugger.error("property '$property' not found");
        return;
      }
      if (name != functionNames[i]) {
        debugger.error("call frame $idx: "
          "expected function name '${functionNames[i]}' but found '$name'");
        return;
      }
    }
  }
}


MatchFrame(int frameIndex, String functionName) {
  return new FrameMatcher(frameIndex, [ functionName ]);
}

MatchFrames(List<String> functionNames) {
  return new FrameMatcher(0, functionNames);
}


class Command {
  var template;
  Command();
  Command.resume() {
    template = {"id": 0, "command": "resume", "params": {"isolateId": 0}};
  }
  Command.step() {
    template = {"id": 0, "command": "stepOver", "params": {"isolateId": 0}};
  }
  Map makeMsg(int cmdId, int isolateId) {
    template["id"] = cmdId;
    if ((template["params"] != null)
        && (template["params"]["isolateId"] != null)) {
      template["params"]["isolateId"] = isolateId;
    }
    return template;
  }

  void send(Debugger debugger) {
    template["id"] = debugger.seqNr;
    template["params"]["isolateId"] = debugger.isolateId;
    debugger.sendMessage(template);
  }

  void matchResponse(Debugger debugger) {
    Map response = debugger.currentMessage;
    var id = template["id"];
    assert(id != null && id >= 0);
    if (response["id"] != id) {
      debugger.error("Expected messaged id $id but got ${response["id"]}.");
    }
  }
}

Resume() => new Command.resume();
Step() => new Command.step();

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
    super.send(debugger);
  }
}

SetBreakpoint(int line) => new SetBreakpointCommand(line);


// A debug script is a list of Event, Matcher and Command objects.
class DebugScript {
  List entries;
  int currentIndex;
  DebugScript(List this.entries) : currentIndex = 0;
  get currentEntry {
    if (currentIndex < entries.length) return entries[currentIndex];
    return null;
  }
  advance() {
    currentIndex++;
  }
}


class Debugger {
  // Debug target process properties.
  Process targetProcess;
  int portNumber;
  Socket socket;
  OutputStream to;
  StringInputStream from;
  JsonBuffer responses = new JsonBuffer();

  DebugScript script;
  int seqNr = 0;  // Sequence number of next debugger command message.
  Command lastCommand = null;  // Most recent command sent to target.
  List<String> errors = new List();

  // Data collected from debug target.
  Map currentMessage = null;  // Currently handled message sent by target.
  String scriptUrl = null;
  bool shutdownEventSeen = false;
  int isolateId = 0;
  
  Debugger(this.targetProcess, this.portNumber) {
    var targetStdout = new StringInputStream(targetProcess.stdout);
    targetStdout.onLine = () {
      var s = targetStdout.readLine();
      if (showDebuggeeOutput) {
        print("TARG: $s");
      }
    };
    var targetStderr = new StringInputStream(targetProcess.stderr);
    targetStderr.onLine = () {
      var s = targetStderr.readLine();
      if (showDebuggeeOutput) {
        print("TARG: $s");
      }
    };
  }

  // Handle debugger events for which there is no explicit
  // entry in the debug script, for example isolate create and
  // shutdown events, breakpoint resolution events, etc.
  bool handleImplicitEvents(Map<String,dynamic> msg) {
    if (msg["event"] == "isolate") {
      if (msg["params"]["reason"] == "created") {
        isolateId = msg["params"]["id"];
        assert(isolateId != null);
        print("Debuggee isolate id $isolateId created.");
      } else if (msg["params"]["reason"] == "shutdown") {
        print("Debuggee isolate id ${msg["params"]["id"]} shut down.");
        shutdownEventSeen = true;
        if (script.currentEntry != null) {
          error("Premature isolate shutdown event seen.");
        }
      }
      return true;
    } else if (msg["event"] == "breakpointResolved") {
      // Ignore the event. We may want to maintain a table of
      // breakpoints in the future.
      return true;
    }
    return false;
  }

  // Handle one JSON message object and match it to the
  // expected events and responses in the debugging script.
  void handleMessage(Map<String,dynamic> receivedMsg) {
    currentMessage = receivedMsg;
    var isHandled = handleImplicitEvents(receivedMsg);
    if (isHandled) return;

    if (receivedMsg["id"] != null) {
      // This is a response to the last command we sent.
      assert(lastCommand != null);
      lastCommand.matchResponse(this);
      lastCommand = null;
      if (errorsDetected) {
        error("Error while matching response to debugger command");
        error("Response received from debug target: $receivedMsg");
      }
      return;
    }

    // This message must be an event that is expected by the script.
    assert(receivedMsg["event"] != null);
    if ((script.currentEntry == null) || (script.currentEntry is Command)) {
      // Error: unexpected event received.
      error("unexpected event received: $receivedMsg");
      return;
    } else {
      // Match received message with expected event.
      script.currentEntry.match(this);
      if (errorsDetected) return;
      script.advance();
      while (script.currentEntry is Matcher) {
        script.currentEntry.match(this);
        if (errorsDetected) return;
        script.advance();
      }
    }
  }

  // Send next debugger command in the script, if a response
  // form the last command has been received and processed.
  void sendNextCommand() {
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
      var msgObj = JSON.parse(msg);
      handleMessage(msgObj);
      if (errorsDetected) {
        error("Error while handling script entry ${script.currentIndex}");
        error("Message received from debug target: $msg");
        close();
        return;
      }
      if (shutdownEventSeen) {
        close();
        return;
      }
      sendNextCommand();
      msg = responses.getNextMessage();
    }
  }

  runScript(List entries) {
    script = new DebugScript(entries);
    openConnection();
  }

  // Send a debugger command to the target VM.
  void sendMessage(Map<String,dynamic> msg) {
    String jsonMsg = JSON.stringify(msg);
    if (verboseWire) print("SEND: $jsonMsg");
    to.writeString(jsonMsg, Encoding.UTF_8);
  }

  bool get errorsDetected => errors.length > 0;

  // Record error message.
  void error(String s) {
    errors.add(s);
  }

  void openConnection() {
    socket = new Socket("127.0.0.1", portNumber);
    to = socket.outputStream;
    from = new StringInputStream(socket.inputStream, Encoding.UTF_8);
    from.onData = () {
      try {
        responses.append(from.read());
        handleMessages();
      } catch(e, trace) {
        print("Unexpected exception:\n$e\n$trace");
        close();
      }
    };
    from.onClosed = () {
      print("Connection closed by debug target");
      close();
    };
    from.onError = (e) {
      print("Error '$e' detected in input stream from debug target");
      close();
    };
  }

  void close() {
    if (errorsDetected) {
      for (int i = 0; i < errors.length; i++) print(errors[i]);
    }
    to.close();
    socket.close();
    targetProcess.kill();
    print("Target process killed");
    Expect.isTrue(!errorsDetected);
    stdin.close();
    stdout.close();
    stderr.close();
  }
}


bool RunScript(List script) {
  var options = new Options();
  if (options.arguments.contains("--debuggee")) {
    return false;
  }
  showDebuggeeOutput = options.arguments.contains("--verbose");
  verboseWire = options.arguments.contains("--wire");

  var targetOpts = [ "--debug:$debugPort" ];
  if (showDebuggeeOutput) targetOpts.add("--verbose_debug");
  targetOpts.add(options.script);
  targetOpts.add("--debuggee");

  Process.start(options.executable, targetOpts).then((Process process) {
    print("Debug target process started");
    process.stdin.close();
    process.stdout.onData = process.stdout.read;
    process.stderr.onData = process.stderr.read;
    process.onExit = (int exitCode) {
      print("Debug target process exited with exit code $exitCode");
    };
    var debugger = new Debugger(process, debugPort);
    stdin.onClosed = () => debugger.close();
    stdin.onError = (error) => debugger.close();
    debugger.runScript(script);
  });
  return true;
}
