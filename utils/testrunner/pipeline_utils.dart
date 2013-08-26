// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of pipeline;

List log;
var replyPort;
int _procId = 1;
Map _procs = {};

/**
 * Create a file path for a temporary file. The file will be in the
 * [tmpDir] directory, with name [basis], but with any extension
 * stripped and replaced by [suffix].
 */
String createTempName(String tmpDir, String basis, [String suffix='']) {
  var p = new Path(basis);
  return '$tmpDir${Platform.pathSeparator}'
      '${p.filenameWithoutExtension}${suffix}';
}

/**
 * Given a file path [file], make it absolute if it is relative,
 * and return the result as a [Path].
 */
Path getAbsolutePath(String file) {
  var p = new Path(file).canonicalize();
  if (p.isAbsolute) {
    return p;
  } else {
    var cwd = new Path(Directory.current.path);
    return cwd.join(p);
  }
}

/** Get the directory that contains a [file]. */
String getDirectory(String file) =>
    getAbsolutePath(file).directoryPath.toString();

/** Create a file [fileName] and populate it with [contents]. */
void writeFile(String fileName, String contents) {
  var file = new File(fileName);
  file.writeAsStringSync(contents);
}

/*
 * Run an external process [cmd] with command line arguments [args].
 * [timeout] can be used to forcefully terminate the process after
 * some number of seconds. This is used by runCommand and startProcess.
 * If [procId] is non-zero (i.e. called from startProcess) then a reference
 * to the [Process] will be put in a map with key [procId]; in this case
 * the process can be terminated later by calling [stopProcess] and
 * passing in the [procId].
 * [outputMonitor] is an optional function that will be called back with each
 * line of output from the process.
 * Returns a [Future] for when the process terminates.
 */
Future _processHelper(String command, List<String> args,
    List stdout, List stderr,
    [int timeout = 30, int procId = 0, Function outputMonitor]) {
  var timer = null;
  if (Platform.operatingSystem == 'windows' && command.endsWith('.bat')) {
    var oldArgs = args;
    args = new List();
    args.add('/c');
    // TODO(gram): We may need some escaping here if any of the
    // components contain spaces.
    args.add("$command ${oldArgs.join(' ')}");
    command='cmd.exe';
  }
  log.add('Running $command ${args.join(" ")}');
  
  return Process.start(command, args)
      .then((process) {
        _procs[procId.toString()] = process;

        var stdoutFuture = _pipeStream(process.stdout, stdout, outputMonitor);
        var stderrFuture = _pipeStream(process.stderr, stderr, outputMonitor);

        timer = new Timer(new Duration(seconds: timeout), () {
          timer = null;
          process.kill();
        });
        return Future.wait([process.exitCode, stdoutFuture, stderrFuture])
            .then((values) {
              if (timer != null) {
                timer.cancel();
              }
              return values[0];
            });
      })
      .catchError((e) {
        stderr.add("Error starting process:");
        stderr.add("  Command: $command");
        stderr.add("  Error: ${e.toString()}");
        return new Future.value(-1);
      });
}

Future _pipeStream(Stream stream, List<String> destination,
                 Function outputMonitor) {
  return stream
    .transform(UTF8.decoder)
    .transform(new LineTransformer())
    .listen((String line) {
      if (config["immediate"] && line.startsWith('###')) {
        print(line.substring(3));
      }
      if (outputMonitor != null) {
        outputMonitor(line);
      }
      destination.add(line);
    })
    .asFuture();
}

/**
 * Run an external process [cmd] with command line arguments [args].
 * [timeout] can be used to forcefully terminate the process after
 * some number of seconds.
 * Returns a [Future] for when the process terminates.
 */
Future runCommand(String command, List<String> args,
                  List stdout, List stderr,
                  [int timeout = 30, Function outputMonitor]) {
  return _processHelper(command, args, stdout, stderr, 
      timeout, 0, outputMonitor);
}

/**
 * Start an external process [cmd] with command line arguments [args].
 * Returns an ID by which it can later be stopped.
 */
int startProcess(String command, List<String> args, List stdout, List stderr,
                 [Function outputMonitor]) {
  int id = _procId++;
  var f = _processHelper(command, args, stdout, stderr, 3000, id,
      outputMonitor);
  if (f != null) {
    f.then((e) {
      _procs.remove(id.toString());
    });
  }
  return id;
}

/** Checks if a process is still running. */
bool isProcessRunning(int id) {
  return _procs.containsKey(id.toString());
}

/**
 * Stop a process previously started with [startProcess] or [runCommand],
 * given the id string.
 */
void stopProcess(int id) {
  var sid = id.toString();
  if (_procs.containsKey(sid)) {
    Process p = _procs.remove(sid);
    p.kill();
  }
}

/** Delete a file named [fname] if it exists. */
bool cleanup(String fname) {
  if (fname != null && config['clean-files']) {
    var f = new File(fname);
    try {
      if (f.existsSync()) {
        logMessage('Removing $fname');
        f.deleteSync();
      }
    } catch (e) {
      return false;
    }
  }
  return true;
}

/** Delete a directory named [dname] if it exists. */
bool cleanupDir(String dname) {
  if (dname != null && config['clean-files']) {
    var d = new Directory(dname);
    try {
      if (d.existsSync()) {
        logMessage('Removing $dname');
        d.deleteSync(recursive: true);
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

void completePipeline(List stdout, List stderr, [exitCode = 0]) {
  replyPort.send([stdout, stderr, log, exitCode]);
}

/** Utility function to log diagnostic messages. */
void logMessage(msg) => log.add(msg);

/** Turn file paths into standard form with forward slashes. */
String normalizePath(String p) => (new Path(p)).toString();
