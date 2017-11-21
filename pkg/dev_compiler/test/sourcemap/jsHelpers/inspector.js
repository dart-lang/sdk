var args = arguments;
var debugAction = arguments[0];
var filesMap = {};
const magicId = 42;

function receive(message) {
  const parsedMessage = JSON.parse(message);
  const method = parsedMessage.method;
  if (method === "Debugger.paused") {
    if (isStoppedInNonUserScript(parsedMessage.params.callFrames)) {
      send(JSON.stringify({id: 2, method: "Debugger.stepOut" }))
    } else {
      writeStackTrace(parsedMessage.params.callFrames);
      send(JSON.stringify({id: 2, method: debugAction }))
    }
  } else if (method === "Debugger.scriptParsed") {
    filesMap[parsedMessage.params.scriptId] = parsedMessage.params.url;
    if (parsedMessage.params.url.endsWith("js.js")) {
      setBreakpoints(parsedMessage.params.scriptId);
    }
  } else if (parsedMessage.id === magicId) {
    var locations = parsedMessage.result.locations;
    if (locations.length > 0) {
      setBreakpoint(locations[0].scriptId, locations[0].lineNumber,
          locations[0].columnNumber);
    }
  }
}

send(JSON.stringify({id: 0, method: "Debugger.enable" }));

function setBreakpoints(script) {
  for(var i = 1; i < args.length; ++i) {
    var data = args[i];
    data = data.split(":");
    if (data.length === 4) {
      send(JSON.stringify({
        id: magicId,
        method: "Debugger.getPossibleBreakpoints",
        params: {
          start: {
            scriptId: script,
            lineNumber: parseInt(data[0]),
            columnNumber: parseInt(data[1])
          },
          end: {
            scriptId: script,
            lineNumber: parseInt(data[2]),
            columnNumber: parseInt(data[3])
          }
        }
      }));

    } else if (data.length === 2) {
      setBreakpoint(script, parseInt(data[0]), parseInt(data[1]));
    } else {
      throw "Unexpected arguments: " + arguments[i];
    }
  }
}

function setBreakpoint(script, line, column) {
  send(JSON.stringify({
    id: 2,
    method: "Debugger.setBreakpoint",
    params: {
      location: {
        scriptId: script,
        lineNumber: line,
        columnNumber: column
      }
    }
  }));
}

function isStoppedInNonUserScript(callFrames) {
  if (callFrames.length === 0) return true;
  var frame = callFrames[0];
  var location = frame.location;
  var url = filesMap[location.scriptId];
  if (url.endsWith("js.js")) return false;
  if (url.endsWith("wrapper.js")) return false;
  return true;
}

function writeStackTrace(callFrames) {
  print("");
  print("--- Debugger stacktrace start ---");
  for(var i = 0; i < callFrames.length; ++i) {
    writeStackTraceLocation(callFrames[i]);
  }
  print("--- Debugger stacktrace end ---");
  print("");
}

function writeStackTraceLocation(frame) {
  var location = frame.location;
  var url = filesMap[location.scriptId];
  var functionName = frame.functionName;
  if (functionName === null || functionName === "") functionName = "(unknown)";
  print("  at " + functionName + " ("
      + url + ":" + location.lineNumber + ":" + location.columnNumber
      + ")");
}
