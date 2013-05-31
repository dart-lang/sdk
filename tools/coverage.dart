// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test forks a second vm process that runs a dart script as
// a debug target, single stepping through the entire program, and
// recording each breakpoint. At the end, a coverage map of the source
// is printed.
//
// Usage: dart coverage.dart [--wire] [--verbose] target_script.dart
//
//   --wire      see json messages sent between the processes.
//   --verbose   see the stdout and stderr output of the debug
//               target process.

import "dart:io";
import "dart:utf";
import "dart:json" as JSON;


// Whether or not to print debug target process on the console.
var showDebuggeeOutput = false;

// Whether or not to print the debugger wire messages on the console.
var verboseWire = false;


class Program {
  static int numBps = 0;

  // Maps source code url to source.
  static var sources = new Map<String, Source>();

  // Takes a JSON Debugger response and increments the count for
  // the source position.
  static void recordBp(Debugger debugger, Map<String,dynamic> msg) {
    // Progress indicator.
    if (++numBps % 100 == 0) print(numBps);
    var location = msg["params"]["location"];
    if (location == null) return;
    String url = location["url"];
    assert(url != null);
    int tokenPos = location["tokenOffset"];;
    Source s = sources[url];
    if (s == null) {
      debugger.GetLineNumberTable(url);
      s = new Source(url);
      sources[url] = s;
    }
    s.recordBp(tokenPos);
  }

  // Prints the annotated source code.
  static void printCoverage() {
    print("Coverage info collected from $numBps breakpoints:");
    for(Source s in sources.values) s.printCoverage();
  }
}


class Source {
  final String url;

  // Maps token position to breakpoint count.
  final tokenCounts = new Map<int,int>();

  // Maps token position to line number.
  final tokenPosToLine = new Map<int,int>();

  Source(this.url);

  void recordBp(int tokenPos) {
    var count = tokenCounts[tokenPos];
    tokenCounts[tokenPos] = count == null ? 1 : count + 1;
  }

  void SetLineInfo(List lineInfoTable) {
    // Each line is encoded as an array with first element being the line
    // number, followed by pairs of (tokenPosition, textOffset).
    lineInfoTable.forEach((List<int> line) {
      int lineNumber = line[0];
      for (int t = 1; t < line.length; t += 2) {
        assert(tokenPosToLine[line[t]] == null);
        tokenPosToLine[line[t]] = lineNumber;
      }
    });
  }

  // Print out the annotated source code. For each line that has seen
  // a breakpoint, print out the maximum breakpoint count for all
  // tokens in the line.
  void printCoverage() {
    var lineCounts = new Map<int,int>();  // BP counts for each line.
    print(url);
    tokenCounts.forEach((tp, bpCount) {
      int lineNumber = tokenPosToLine[tp];
      var lineCount = lineCounts[lineNumber];
      // Remember maximum breakpoint count of all tokens in this line.
      if (lineCount == null || lineCount < bpCount) {
        lineCounts[lineNumber] = bpCount;
      }
    });

    List lines = new File(Uri.parse(url).path).readAsLinesSync();
    for (int line = 1; line <= lines.length; line++) {
      String prefix = "      ";
      if (lineCounts.containsKey(line)) {
        prefix = lineCounts[line].toString();
        StringBuffer b = new StringBuffer();
        for (int i = prefix.length; i < 6; i++) b.write(" ");
        b.write(prefix);
        prefix = b.toString();
      }
      print("${prefix}|${lines[line-1]}");
    }
  }
}


class StepCmd {
  Map msg;
  StepCmd(int isolateId) {
    msg = {"id": 0, "command": "stepInto", "params": {"isolateId": isolateId}};
  }
  void handleResponse(Map response) {}
}


class GetLineTableCmd {
  Map msg;
  GetLineTableCmd(int isolateId, int libraryId, String url) {
    msg = { "id": 0,
            "command":  "getLineNumberTable",
            "params": { "isolateId" : isolateId,
                        "libraryId": libraryId,
                        "url": url } };
  }

  void handleResponse(Map response) {
    var url = msg["params"]["url"];
    Source s = Program.sources[url];
    assert(s != null);
    s.SetLineInfo(response["result"]["lines"]);
  }
}


class Debugger {
  // Debug target process properties.
  Process targetProcess;
  Socket socket;
  bool cleanupDone = false;
  JsonBuffer responses = new JsonBuffer();
  List<String> errors = new List();

  // Data collected from debug target.
  Map currentMessage = null;  // Currently handled message sent by target.
  var outstandingCommand = null;
  var queuedCommand = null;
  String scriptUrl = null;
  bool shutdownEventSeen = false;
  int isolateId = 0;
  int libraryId = null;

  int nextMessageId = 0;
  bool isPaused = false;
  bool pendingAck = false;

  Debugger(this.targetProcess) {
    var stdoutStringStream = targetProcess.stdout
        .transform(new StringDecoder())
        .transform(new LineTransformer());
    stdoutStringStream.listen((line) {
      if (showDebuggeeOutput) {
        print("TARG: $line");
      }
      if (line.startsWith("Debugger listening")) {
        RegExp portExpr = new RegExp(r"\d+");
        var port = portExpr.stringMatch(line);
        var pid = targetProcess.pid;
        print("Coverage target process (pid $pid) found "
              "listening on port $port.");
        openConnection(int.parse(port));
      }
    });

    var stderrStringStream = targetProcess.stderr
        .transform(new StringDecoder())
        .transform(new LineTransformer());
    stderrStringStream.listen((line) {
      if (showDebuggeeOutput) {
        print("TARG: $line");
      }
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
      if (libraryId == null) {
        libraryId = msg["params"]["location"]["libraryId"];
        assert(libraryId != null);
      }
      if (msg["params"]["reason"] == "breakpoint") {
        Program.recordBp(this, msg);
      }
    } else {
      error("Error: unknown debugger event received");
    }
  }

  // Handle one JSON message object.
  void handleMessage(Map<String,dynamic> receivedMsg) {
    currentMessage = receivedMsg;
    if (receivedMsg["event"] != null) {
      handleEvent(receivedMsg);
      if (errorsDetected) {
        error("Error while handling event message");
        error("Event received from coverage target: $receivedMsg");
      }
    } else if (receivedMsg["id"] != null) {
      // This is a response to the last command we sent.
      int id = receivedMsg["id"];
      assert(outstandingCommand != null);
      assert(outstandingCommand.msg["id"] == id);
      outstandingCommand.handleResponse(receivedMsg);
      outstandingCommand = null;
    } else {
      error("Unexpected message from target");
    }
  }

  // Handle data received over the wire from the coverage target
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
      var msgObj = JSON.parse(msg);
      handleMessage(msgObj);
      if (errorsDetected) {
        error("Error while handling message from coverage target");
        error("Message received from coverage target: $msg");
        cleanup();
        return;
      }
      if (shutdownEventSeen) {
        if (outstandingCommand != null) {
          error("Error: outstanding command when shutdown received");
        }
        cleanup();
        return;
      }
      if (isPaused && (outstandingCommand == null)) {
        var cmd = queuedCommand;
        queuedCommand = null;
        if (cmd == null) {
          cmd = new StepCmd(isolateId);
          isPaused = false;
        }
        sendMessage(cmd.msg);
        outstandingCommand = cmd;
      }
      msg = responses.getNextMessage();
    }
  }

  // Send a debugger command to the target VM.
  void sendMessage(Map<String,dynamic> msg) {
    assert(msg["id"] != null);
    msg["id"] = nextMessageId++;
    String jsonMsg = JSON.stringify(msg);
    if (verboseWire) print("SEND: $jsonMsg");
    socket.write(jsonMsg);
  }

  void GetLineNumberTable(String url) {
    assert(queuedCommand == null);
    queuedCommand = new GetLineTableCmd(isolateId, libraryId, url);
  }
  
  bool get errorsDetected => errors.length > 0;

  // Record error message.
  void error(String s) {
    errors.add(s);
  }

  void openConnection(int portNumber) {
    Socket.connect("127.0.0.1", portNumber).then((s) {
      socket = s;
      var stringStream = socket.transform(new StringDecoder());
      stringStream.listen(
          (str) {
            try {
              responses.append(str);
              handleMessages();
            } catch(e, trace) {
              print("Unexpected exception:\n$e\n$trace");
              cleanup();
            }
          },
          onDone: () {
            print("Connection closed by coverage target");
            cleanup();
          },
          onError: (e) {
            print("Error '$e' detected in input stream from coverage target");
            cleanup();
          });
      },
      onError: (e) {
        String msg = "Error while connecting to coverage target: $e";
        var trace = getAttachedStackTrace(e);
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
    print("Sending kill signal to process $targetPid.");
    targetProcess.kill();
    // If the process was already dead exitCode is already
    // available and we call exit() in the next event loop cycle.
    // Otherwise this will wait for the process to exit.

    targetProcess.exitCode.then((exitCode) {
      print("Process $targetPid terminated with exit code $exitCode.");
      if (errorsDetected) {
        print("\n===== Errors detected: =====");
        for (int i = 0; i < errors.length; i++) print(errors[i]);
        print("============================\n");
      }
      Program.printCoverage();
      exit(errors.length);
    });
    cleanupDone = true;
  }
}


// Class to buffer wire protocol data from coverage target and
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


void main() {
  var options = new Options();
  var targetOpts = [ "--debug:0" ];
  for (String str in options.arguments) {
    switch (str) {
      case "--verbose":
        showDebuggeeOutput = true;
        break;
      case "--wire":
        verboseWire = true;
        break;
      default:
        targetOpts.add(str);
        break;
    }
  }

  Process.start(options.executable, targetOpts).then((Process process) {
    process.stdin.close();
    var debugger = new Debugger(process);
  });
}
