// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

List stdout, stderr, log;
var replyPort;
int _procId = 1;
Map _procs = {};

/**
 * Create a file path for a temporary file. The file will be in the
 * [tmpDir] directory, with name [basis], but with any extension
 * stripped and replaced by [suffix].
 */
String createTempName(String tmpDir, String basis, String suffix) {
  var p = new Path(basis);
  return '$tmpDir${Platform.pathSeparator}'
      '${p.filenameWithoutExtension}${suffix}';
}

/** Create a file [fileName] and populate it with [contents]. */
void writeFile(String fileName, String contents) {
  var file = new File(fileName);
  var ostream = file.openOutputStream(FileMode.WRITE);
  ostream.writeString(contents);
  ostream.close();
}

/*
 * Run an external process [cmd] with command line arguments [args].
 * [timeout] can be used to forcefully terminate the process after
 * some number of seconds. This is used by runCommand and startProcess.
 * If [procId] is 0 (runCommand) then this will return a [Future] for
 * when the process terminates; if [procId] is instead non-zero
 * (startProcess) then a reference to the [Process] will be put in a
 * map with key [procId]; in this case the process can be terminated
 * later by calling [stopProcess] and passing in the [procId].
 */
Future _processHelper(String command, List<String> args,
    [int timeout = 300, int procId = 0]) {
  var completer = null;
  log.add('Running $command ${Strings.join(args, " ")}');
  var timer = null;
  var stdoutHandler, stderrHandler;
  var process = Process.start(command, args);
  if (procId == 0) {
    completer = new Completer();
  } else {
    _procs[procId] = process;
  }
  process.onStart = () {
    timer = new Timer(1000 * timeout, (t) {
      timer = null;
      process.kill();
    });
  };
  process.onExit = (exitCode) {
    if (timer != null) {
      timer.cancel();
    }
    process.close();
    if (completer != null) {
      completer.complete(exitCode);
    }
  };
  process.onError = (e) {
    stderr.add("Error starting process:");
    stderr.add("  Command: $command");
    stderr.add("  Error: $e");
    completePipeline(-1);
  };

  _pipeStream(process.stdout, stdout);
  _pipeStream(process.stderr, stderr);

  return (completer == null) ? null : completer.future;
}

void _pipeStream(InputStream stream, List<String> destination) {
  var source = new StringInputStream(stream);
  source.onLine = () {
    if (source.available() == 0) return;
    var line = source.readLine();
    while (null != line) {
      if (config["immediate"] && line.startsWith('###')) {
        // TODO - when we dump the list later skip '###' messages if immediate.
        print(line.substring(3));
      }
      destination.add(line);
      line = source.readLine();
    }
  };
}

/**
 * Run an external process [cmd] with command line arguments [args].
 * [timeout] can be used to forcefully terminate the process after
 * some number of seconds.
 * Returns a [Future] for when the process terminates.
 */
Future runCommand(String command, List<String> args, [int timeout = 300]) {
  return _processHelper(command, args, timeout);
}

/**
 * Start an external process [cmd] with command line arguments [args].
 * Returns an ID by which it can later be stopped.
 */
int startProcess(String command, List<String> args) {
  int id = _procId++;
  _processHelper(command, args, 3000, id);
  return id;
}

/**
 * Stop a process previously started with [startProcess] or [runCommand],
 * given the id string.
 */
void stopProcess(int id) {
  Process p = _procs.remove(id);
  p.kill();
}

/** Delete a file named [fname] if it exists. */
bool cleanup(String fname) {
  if (fname != null && !config['keep-files']) {
    var f = new File(fname);
    try {
      if (f.existsSync()) {
        f.deleteSync();
      }
    } catch (e) {
      return false;
    }
  }
  return true;
}

initPipeline(port) {
  replyPort = port;
  stdout = new List();
  stderr = new List();
  log = new List();
}

void completePipeline([exitCode = 0]) {
  replyPort.send([stdout, stderr, log, exitCode]);
}

/** Utility function to log diagnostic messages. */
void logMessage(msg) => log.add(msg);
