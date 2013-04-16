// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Library used by debugger wire protocol tests (standalone VM debugging).

library DartDebugger;

import "dart:async";
import "dart:io";
import "dart:math";
import "dart:utf";
import "dart:json" as JSON;

// Whether or not to print the debugger wire messages on the console.
var verboseWire = false;

// The number of attempts made to find an unused debugger port.
var retries = 0;

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
      debugger.error("Expected messaged id $id but got ${response["id"]}.");
    }
  }
}


class FrameMatcher extends Command {
  int frameIndex;
  List<String> functionNames;

  FrameMatcher(this.frameIndex, this.functionNames) {
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
      }
    }
    if (frames.length < functionNames.length) {
      debugger.error("stack trace not long enough "
                     "to match ${functionNames.length} frames");
      return;
    }
    for (int i = 0; i < functionNames.length; i++) {
      var idx = i + frameIndex;
      var name = frames[idx]["functionName"];
      assert(name != null);
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


class RunCommand extends Command {
  RunCommand.resume() {
    template = {"id": 0, "command": "resume", "params": {"isolateId": 0}};
  }
  RunCommand.step() {
    template = {"id": 0, "command": "stepOver", "params": {"isolateId": 0}};
  }
  void send(Debugger debugger) {
    debugger.sendMessage(template);
    debugger.isPaused = false;
  }
}


Resume() => new RunCommand.resume();
Step() => new RunCommand.step();


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
}

SetBreakpoint(int line) => new SetBreakpointCommand(line);


// A debug script is a list of Command objects.
class DebugScript {
  List entries;
  DebugScript(List scriptEntries) {
    entries = new List.from(scriptEntries.reversed);
    entries.add(MatchFrame(0, "main"));
  }
  bool get isEmpty => entries.isEmpty;
  get currentEntry => entries.last;
  advance() => entries.removeLast();
  add(entry) => entries.add(entry);
}


class Debugger {
  // Debug target process properties.
  Process targetProcess;
  int portNumber;
  Socket socket;
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
  bool isPaused = false;

  Debugger(this.targetProcess, this.portNumber, this.script) {
    stdin.listen((_) {});
    var stdoutStringStream = targetProcess.stdout
        .transform(new StringDecoder())
        .transform(new LineTransformer());
    stdoutStringStream.listen((line) {
      if (line == "Debugger initialized") {
        openConnection();
      }
      print("TARG: $line");
    });

    var stderrStringStream = targetProcess.stderr
        .transform(new StringDecoder())
        .transform(new LineTransformer());
    stderrStringStream.listen((line) {
      print("TARG: $line");
    });
  }

  // Handle debugger events, updating the debugger state.
  void handleEvent(Map<String,dynamic> msg) {
    if (msg["event"] == "isolate") {
      if (msg["params"]["reason"] == "created") {
        isolateId = msg["params"]["id"];
        assert(isolateId != null);
        print("Debuggee isolate id $isolateId created.");
      } else if (msg["params"]["reason"] == "shutdown") {
        print("Debuggee isolate id ${msg["params"]["id"]} shut down.");
        shutdownEventSeen = true;
        if (!script.isEmpty) {
          error("Premature isolate shutdown event seen.");
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
      error("unknown debugger event received");
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
      if (responses.haveGarbage()) {
        error("Error: leftover text after message: '${responses.buffer}'");
        error("Previous message may be malformed, was: '$msg'");
        close(killDebugee: true);
        return;
      }
      var msgObj = JSON.parse(msg);
      handleMessage(msgObj);
      if (errorsDetected) {
        error("Error while handling script entry");
        error("Message received from debug target: $msg");
        close(killDebugee: true);
        return;
      }
      if (shutdownEventSeen) {
        close();
        return;
      }
      if (isPaused) sendNextCommand();
      msg = responses.getNextMessage();
    }
  }

  runScript(List entries) {
    script = new DebugScript(entries);
    openConnection();
  }

  // Send a debugger command to the target VM.
  void sendMessage(Map<String,dynamic> msg) {
    if (msg["id"] != null) {
      msg["id"] = seqNr;
    }
    if (msg["params"] != null && msg["params"]["isolateId"] != null) {
      msg["params"]["isolateId"] = isolateId;
    }
    String jsonMsg = JSON.stringify(msg);
    if (verboseWire) print("SEND: $jsonMsg");
    socket.write(jsonMsg);
  }

  bool get errorsDetected => errors.length > 0;

  // Record error message.
  void error(String s) {
    errors.add(s);
  }

  void openConnection() {
    Socket.connect("127.0.0.1", portNumber).then((s) {
        this.socket = s;
        var stringStream = socket.transform(new StringDecoder());
        stringStream.listen((str) {
            try {
              responses.append(str);
              handleMessages();
            } catch(e, trace) {
              print("Unexpected exception:\n$e\n$trace");
              close(killDebugee: true);
            }
          },
          onDone: () {
            print("Connection closed by debug target");
            close(killDebugee: true);
          },
          onError: (e) {
            print("Error '$e' detected in input stream from debug target");
            var trace = getAttachedStackTrace(e);
            if (trace != null) print("StackTrace: $trace");
            close(killDebugee: true);
          });
      },
      onError: (e) {
        String msg = "Error while connecting to debugee: $e";
        var trace = getAttachedStackTrace(e);
        if (trace != null) msg += "\nStackTrace: $trace";
        error(msg);
        close(killDebugee: true);
      });
  }

  void close({killDebugee: false}) {
    if (errorsDetected) {
      for (int i = 0; i < errors.length; i++) print(errors[i]);
    }
    if (socket != null) socket.close();
    if (killDebugee) {
      targetProcess.kill();
      print("Target process killed");
    }
    if (errorsDetected) throw "Errors detected";
    exit(errors.length);
  }
}


bool RunScript(List script) {
  var options = new Options();
  if (options.arguments.contains("--debuggee")) {
    return false;
  }
  verboseWire = options.arguments.contains("--wire");
  
  // Pick a port in the upper half of the port number range.
  var seed = new DateTime.now().millisecondsSinceEpoch;
  Random random = new Random(seed);
  var debugPort = random.nextInt(32000) + 32000;
  print('using debug port $debugPort ...');
  ServerSocket.bind('127.0.0.1', debugPort).then((ServerSocket s) {
      s.close();
      var targetOpts = [ "--debug:$debugPort" ];
      // --verbose_debug is necessary so the test knows when the debuggee
      // is initialized.
      targetOpts.add("--verbose_debug");
      targetOpts.add(options.script);
      targetOpts.add("--debuggee");
      print('args: ${targetOpts.join(" ")}');

      Process.start(options.executable, targetOpts).then((Process process) {
        print("Debug target process started");
        process.stdin.close();
        process.exitCode.then((int exitCode) {
          if (exitCode != 0) throw "bad exit code: $exitCode";
          print("Debug target process exited with exit code $exitCode");
        });
        var debugger =
            new Debugger(process, debugPort, new DebugScript(script));
      });
    },
    onError: (e) {
      if (++retries >= 3) { 
        print('unable to find unused port: $e');
        var trace = getAttachedStackTrace(e);
        if (trace != null) print("StackTrace: $trace");
        return -1; 
      } else {
        // Retry with another random port.
        RunScript(script);
      }
    });
  return true;
}
