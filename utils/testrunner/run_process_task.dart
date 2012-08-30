// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** A pipeline task to run a process and capture the output. */
class RunProcessTask extends PipelineTask {
  String _commandTemplate;
  List _argumentTemplates;
  int _timeout;

  void init(String commandTemplate, List argumentTemplates, int timeout) {
    this._commandTemplate = commandTemplate;
    this._argumentTemplates = argumentTemplates;
    this._timeout = timeout;
  }

  RunProcessTask();

  void execute(Path testfile, List stdout, List stderr, bool logging,
              Function exitHandler) {
    var cmd = expandMacros(_commandTemplate, testfile);
    List args = new List();
    for (var i = 0; i < _argumentTemplates.length; i++) {
      args.add(expandMacros(_argumentTemplates[i], testfile));
    }

    if (logging) {
      stdout.add('Running $cmd ${Strings.join(args, " ")}');
    }
    var timer = null;
    var process = Process.start(cmd, args);
    process.onStart = () {
      timer = new Timer(1000 * _timeout, (t) {
        timer = null;
        process.kill();
      });
    };
    process.onExit = (exitCode) {
      if (timer != null) {
        timer.cancel();
      }
      process.close();
      exitHandler(exitCode);
    };
    process.onError = (e) {
      print("Error starting process:");
      print("  Command: $cmd");
      print("  Error: $e");
      exitHandler(-1);
    };

    StringInputStream stdoutStringStream =
        new StringInputStream(process.stdout);
    StringInputStream stderrStringStream =
        new StringInputStream(process.stderr);
    stdoutStringStream.onLine = makeReadHandler(stdoutStringStream, stdout);
    stderrStringStream.onLine = makeReadHandler(stderrStringStream, stderr);
  }

  Function makeReadHandler(StringInputStream source, List<String> destination) {
    return () {
      if (source.closed) return;
      var line = source.readLine();
      while (null != line) {
        if (config.immediateOutput && line.startsWith('###')) {
          _outStream.writeString(line.substring(3));
          _outStream.writeString('\n');
        } else {
          destination.add(line);
        }
        line = source.readLine();
      }
    };
  }
}
