// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class _WindowsCodePageDecoder {
  /* patch */ static String _decodeBytes(List<int> bytes)
      native "SystemEncodingToString";
}


patch class _WindowsCodePageEncoder {
  /* patch */ static List<int> _encodeString(String string)
      native "StringToSystemEncoding";
}


patch class Process {
  /* patch */ static Future<Process> start(String executable,
                                           List<String> arguments,
                                           [ProcessOptions options]) {
    _ProcessImpl process = new _ProcessImpl(executable, arguments, options);
    return process._start();
  }

  /* patch */ static Future<ProcessResult> run(String executable,
                                               List<String> arguments,
                                               [ProcessOptions options]) {
    return _runNonInteractiveProcess(executable, arguments, options);
  }
}


patch class _ProcessUtils {
  /* patch */ static _exit(int status) native "Process_Exit";
  /* patch */ static _setExitCode(int status) native "Process_SetExitCode";
  /* patch */ static _sleep(int millis) native "Process_Sleep";
}


class _ProcessStartStatus {
  int _errorCode;  // Set to OS error code if process start failed.
  String _errorMessage;  // Set to OS error message if process start failed.
}


class _ProcessImpl extends NativeFieldWrapperClass1 implements Process {
  _ProcessImpl(String path, List<String> arguments, ProcessOptions options) {
    if (path is !String) {
      throw new ArgumentError("Path is not a String: $path");
    }
    _path = path;

    if (arguments is !List) {
      throw new ArgumentError("Arguments is not a List: $arguments");
    }
    int len = arguments.length;
    _arguments = new List<String>(len);
    for (int i = 0; i < len; i++) {
      var arg = arguments[i];
      if (arg is !String) {
        throw new ArgumentError("Non-string argument: $arg");
      }
      _arguments[i] = arguments[i];
      if (Platform.operatingSystem == 'windows') {
        _arguments[i] = _windowsArgumentEscape(_arguments[i]);
      }
    }

    if (options != null && options.workingDirectory != null) {
      _workingDirectory = options.workingDirectory;
      if (_workingDirectory is !String) {
        throw new ArgumentError(
            "WorkingDirectory is not a String: $_workingDirectory");
      }
    }

    if (options != null && options.environment != null) {
      var env = options.environment;
      if (env is !Map) {
        throw new ArgumentError("Environment is not a map: $env");
      }
      _environment = [];
      env.forEach((key, value) {
        if (key is !String || value is !String) {
          throw new ArgumentError(
              "Environment key or value is not a string: ($key, $value)");
        }
        _environment.add('$key=$value');
      });
    }

    // stdin going to process.
    _stdin = new _StdSink(new _Socket._writePipe());
    // stdout coming from process.
    _stdout = new _StdStream(new _Socket._readPipe());
    // stderr coming from process.
    _stderr = new _StdStream(new _Socket._readPipe());
    _exitHandler = new _Socket._readPipe();
    _ended = false;
    _started = false;
  }

  String _windowsArgumentEscape(String argument) {
    var result = argument;
    if (argument.contains('\t') || argument.contains(' ')) {
      // Produce something that the C runtime on Windows will parse
      // back as this string.

      // Replace any number of '\' followed by '"' with
      // twice as many '\' followed by '\"'.
      var backslash = '\\'.codeUnitAt(0);
      var sb = new StringBuffer();
      var nextPos = 0;
      var quotePos = argument.indexOf('"', nextPos);
      while (quotePos != -1) {
        var numBackslash = 0;
        var pos = quotePos - 1;
        while (pos >= 0 && argument.codeUnitAt(pos) == backslash) {
          numBackslash++;
          pos--;
        }
        sb.write(argument.substring(nextPos, quotePos - numBackslash));
        for (var i = 0; i < numBackslash; i++) {
          sb.write(r'\\');
        }
        sb.write(r'\"');
        nextPos = quotePos + 1;
        quotePos = argument.indexOf('"', nextPos);
      }
      sb.write(argument.substring(nextPos, argument.length));
      result = sb.toString();

      // Add '"' at the beginning and end and replace all '\' at
      // the end with two '\'.
      sb = new StringBuffer('"');
      sb.write(result);
      nextPos = argument.length - 1;
      while (argument.codeUnitAt(nextPos) == backslash) {
        sb.write('\\');
        nextPos--;
      }
      sb.write('"');
      result = sb.toString();
    }

    return result;
  }

  int _intFromBytes(List<int> bytes, int offset) {
    return (bytes[offset] +
            (bytes[offset + 1] << 8) +
            (bytes[offset + 2] << 16) +
            (bytes[offset + 3] << 24));
  }

  Future<Process> _start() {
    var completer = new Completer();
    // TODO(ager): Make the actual process starting really async instead of
    // simulating it with a timer.
    Timer.run(() {
      var status = new _ProcessStartStatus();
      bool success = _startNative(_path,
                                  _arguments,
                                  _workingDirectory,
                                  _environment,
                                  _stdin._sink._nativeSocket,
                                  _stdout._stream._nativeSocket,
                                  _stderr._stream._nativeSocket,
                                  _exitHandler._nativeSocket,
                                  status);
      if (!success) {
        completer.completeError(
            new ProcessException(_path,
                                 _arguments,
                                 status._errorMessage,
                                 status._errorCode));
        return;
      }
      _started = true;

      // Setup an exit handler to handle internal cleanup and possible
      // callback when a process terminates.
      int exitDataRead = 0;
      final int EXIT_DATA_SIZE = 8;
      List<int> exitDataBuffer = new List<int>(EXIT_DATA_SIZE);
      _exitHandler.listen((data) {

        int exitCode(List<int> ints) {
          var code = _intFromBytes(ints, 0);
          var negative = _intFromBytes(ints, 4);
          assert(negative == 0 || negative == 1);
          return (negative == 0) ? code : -code;
        }

        void handleExit() {
          _ended = true;
          _exitCode.complete(exitCode(exitDataBuffer));
          // Kill stdin, helping hand if the user forgot to do it.
          _stdin._sink.destroy();
        }

        exitDataBuffer.setRange(exitDataRead, exitDataRead + data.length, data);
        exitDataRead += data.length;
        if (exitDataRead == EXIT_DATA_SIZE) {
          handleExit();
        }
      });

      completer.complete(this);
    });
    return completer.future;
  }

  bool _startNative(String path,
                    List<String> arguments,
                    String workingDirectory,
                    List<String> environment,
                    _NativeSocket stdin,
                    _NativeSocket stdout,
                    _NativeSocket stderr,
                    _NativeSocket exitHandler,
                    _ProcessStartStatus status) native "Process_Start";

  Stream<List<int>> get stdout {
    return _stdout;
  }

  Stream<List<int>> get stderr {
    return _stderr;
  }

  IOSink get stdin {
    return _stdin;
  }

  Future<int> get exitCode => _exitCode.future;

  bool kill([ProcessSignal signal = ProcessSignal.SIGTERM]) {
    if (signal is! ProcessSignal) {
      throw new ArgumentError(
          "Argument 'signal' must be a ProcessSignal");
    }
    assert(_started);
    if (_ended) return false;
    return _kill(this, signal._signalNumber);
  }

  bool _kill(Process p, int signal) native "Process_Kill";

  String _path;
  List<String> _arguments;
  String _workingDirectory;
  List<String> _environment;
  // Private methods of Socket are used by _in, _out, and _err.
  _StdSink _stdin;
  _StdStream _stdout;
  _StdStream _stderr;
  Socket _exitHandler;
  bool _ended;
  bool _started;
  final Completer<int> _exitCode = new Completer<int>();
}


// _NonInteractiveProcess is a wrapper around an interactive process
// that buffers output so it can be delivered when the process exits.
// _NonInteractiveProcess is used to implement the Process.run
// method.
Future<ProcessResult> _runNonInteractiveProcess(String path,
                                                List<String> arguments,
                                                ProcessOptions options) {
  // Extract output encoding options and verify arguments.
  var stdoutEncoding = Encoding.SYSTEM;
  var stderrEncoding = Encoding.SYSTEM;
  if (options != null) {
    if (options.stdoutEncoding != null) {
      stdoutEncoding = options.stdoutEncoding;
      if (stdoutEncoding is !Encoding) {
        throw new ArgumentError(
            'stdoutEncoding option is not an encoding: $stdoutEncoding');
      }
    }
    if (options.stderrEncoding != null) {
      stderrEncoding = options.stderrEncoding;
      if (stderrEncoding is !Encoding) {
        throw new ArgumentError(
            'stderrEncoding option is not an encoding: $stderrEncoding');
      }
    }
  }

  // Start the underlying process.
  return Process.start(path, arguments, options).then((Process p) {
    // Make sure the process stdin is closed.
    p.stdin.close();

    // Setup stdout handling.
    Future<StringBuffer> stdout = p.stdout
        .transform(new StringDecoder(stdoutEncoding))
        .fold(
            new StringBuffer(),
            (buf, data) {
              buf.write(data);
              return buf;
            });

    Future<StringBuffer> stderr = p.stderr
        .transform(new StringDecoder(stderrEncoding))
        .fold(
            new StringBuffer(),
            (buf, data) {
              buf.write(data);
              return buf;
            });

    return Future.wait([p.exitCode, stdout, stderr]).then((result) {
      return new _ProcessResult(result[0],
                                result[1].toString(),
                                result[2].toString());
    });
  });
}


class _ProcessResult implements ProcessResult {
  const _ProcessResult(int this.exitCode,
                       String this.stdout,
                       String this.stderr);

  final int exitCode;
  final String stdout;
  final String stderr;
}
