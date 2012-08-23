// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

_exit(int status) native "Exit";

class _ProcessStartStatus {
  int _errorCode;  // Set to OS error code if process start failed.
  String _errorMessage;  // Set to OS error message if process start failed.
}


class _Process extends Process {
  static Process start(String path,
                                  List<String> arguments,
                                  [ProcessOptions options]) {
    return new _Process.start(path, arguments, options);
  }

  static Future<ProcessResult> run(String path,
                                   List<String> arguments,
                                   [ProcessOptions options]) {
    return new _NonInteractiveProcess._start(path, arguments, options)._result;
  }

  _Process.start(String path,
                 List<String> arguments,
                 ProcessOptions options) {
    if (path is !String) {
      throw new IllegalArgumentException("Path is not a String: $path");
    }
    _path = path;

    if (arguments is !List) {
      throw new IllegalArgumentException("Arguments is not a List: $arguments");
    }
    int len = arguments.length;
    _arguments = new ObjectArray<String>(len);
    for (int i = 0; i < len; i++) {
      var arg = arguments[i];
      if (arg is !String) {
        throw new IllegalArgumentException("Non-string argument: $arg");
      }
      _arguments[i] = arguments[i];
      if (Platform.operatingSystem == 'windows') {
        _arguments[i] = _windowsArgumentEscape(_arguments[i]);
      }
    }

    if (options !== null && options.workingDirectory !== null) {
      _workingDirectory = options.workingDirectory;
      if (_workingDirectory is !String) {
        throw new IllegalArgumentException(
            "WorkingDirectory is not a String: $_workingDirectory");
      }
    }

    if (options !== null && options.environment !== null) {
      var env = options.environment;
      if (env is !Map) {
        throw new IllegalArgumentException("Environment is not a map: $env");
      }
      _environment = [];
      env.forEach((key, value) {
        if (key is !String || value is !String) {
          throw new IllegalArgumentException(
              "Environment key or value is not a string: ($key, $value)");
        }
        _environment.add('$key=$value');
      });
    }

    _in = new _Socket._internalReadOnly();  // stdout coming from process.
    _out = new _Socket._internalWriteOnly();  // stdin going to process.
    _err = new _Socket._internalReadOnly();  // stderr coming from process.
    _exitHandler = new _Socket._internalReadOnly();
    _closed = false;
    _ended = false;
    _started = false;
    _onExit = null;
    // TODO(ager): Make the actual process starting really async instead of
    // simulating it with a timer.
    new Timer(0, (Timer ignore) => _start());
  }

  String _windowsArgumentEscape(String argument) {
    var result = argument;
    if (argument.contains('\t') || argument.contains(' ')) {
      // Produce something that the C runtime on Windows will parse
      // back as this string.

      // Replace any number of '\' followed by '"' with
      // twice as many '\' followed by '\"'.
      var backslash = '\\'.charCodeAt(0);
      var sb = new StringBuffer();
      var nextPos = 0;
      var quotePos = argument.indexOf('"', nextPos);
      while (quotePos != -1) {
        var numBackslash = 0;
        var pos = quotePos - 1;
        while (pos >= 0 && argument.charCodeAt(pos) == backslash) {
          numBackslash++;
          pos--;
        }
        sb.add(argument.substring(nextPos, quotePos - numBackslash));
        for (var i = 0; i < numBackslash; i++) {
          sb.add(@'\\');
        }
        sb.add(@'\"');
        nextPos = quotePos + 1;
        quotePos = argument.indexOf('"', nextPos);
      }
      sb.add(argument.substring(nextPos, argument.length));
      result = sb.toString();

      // Add '"' at the beginning and end and replace all '\' at
      // the end with two '\'.
      sb = new StringBuffer('"');
      sb.add(result);
      nextPos = argument.length - 1;
      while (argument.charCodeAt(nextPos) == backslash) {
        sb.add('\\');
        nextPos--;
      }
      sb.add('"');
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

  void _start() {
    var status = new _ProcessStartStatus();
    bool success = _startNative(_path,
                                _arguments,
                                _workingDirectory,
                                _environment,
                                _in,
                                _out,
                                _err,
                                _exitHandler,
                                status);
    if (!success) {
      close();
      _reportError(new ProcessException(status._errorMessage,
                                        status._errorCode));
      return;
    }
    _started = true;

    // Make sure to activate socket handlers now that the file
    // descriptors have been set.
    _in._activateHandlers();
    _out._activateHandlers();
    _err._activateHandlers();

    // Setup an exit handler to handle internal cleanup and possible
    // callback when a process terminates.
    int exitDataRead = 0;
    final int EXIT_DATA_SIZE = 8;
    List<int> exitDataBuffer = new List<int>(EXIT_DATA_SIZE);
    _exitHandler.inputStream.onData = () {

      int exitCode(List<int> ints) {
        var code = _intFromBytes(ints, 0);
        var negative = _intFromBytes(ints, 4);
        assert(negative == 0 || negative == 1);
        return (negative == 0) ? code : -code;
      }

      void handleExit() {
        _ended = true;
        if (_onExit !== null) {
          _onExit(exitCode(exitDataBuffer));
        }
      }

      exitDataRead += _exitHandler.inputStream.readInto(
          exitDataBuffer, exitDataRead, EXIT_DATA_SIZE - exitDataRead);
      if (exitDataRead == EXIT_DATA_SIZE) handleExit();
    };

    if (_onStart !== null) {
      _onStart();
    }
  }

  bool _startNative(String path,
                    List<String> arguments,
                    String workingDirectory,
                    List<String> environment,
                    Socket input,
                    Socket output,
                    Socket error,
                    Socket exitHandler,
                    _ProcessStartStatus status) native "Process_Start";

  InputStream get stdout() {
    if (_closed) {
      throw new ProcessException("Process closed");
    }
    return _in.inputStream;
  }

  InputStream get stderr() {
    if (_closed) {
      throw new ProcessException("Process closed");
    }
    return _err.inputStream;
  }

  OutputStream get stdin() {
    if (_closed) {
      throw new ProcessException("Process closed");
    }
    return _out.outputStream;
  }

  void kill([ProcessSignal signal = ProcessSignal.SIGTERM]) {
    if (signal is! ProcessSignal) {
      throw new IllegalArgumentException(
          "Argument 'signal' must be a ProcessSignal");
    }
    if (_closed && _pid === null) {
      _reportError(new ProcessException("Process closed"));
      return;
    }
    if (_ended) {
      return;
    }
    // TODO(ager): Make the actual kill operation asynchronous.
    if (_kill(_pid, signal._signalNumber)) {
      return;
    }
    _reportError(new ProcessException("Could not kill process"));
    return;
  }

  bool _kill(int pid, int signal) native "Process_Kill";

  void close() {
    if (_closed) {
      throw new ProcessException("Process closed");
    }
    _in.close();
    _out.close();
    _err.close();
    _exitHandler.close();
    _closed = true;
  }

  void set onExit(void callback(int exitCode)) {
    if (_closed) {
      throw new ProcessException("Process closed");
    }
    if (_ended) {
      throw new ProcessException("Process killed");
    }
    _onExit = callback;
  }

  void set onError(void callback(e)) {
    _onError = callback;
  }

  void set onStart(void callback()) {
    _onStart = callback;
  }

  void _reportError(e) {
    if (_onError != null) {
      _onError(e);
    } else {
      throw e;
    }
  }

  String _path;
  ObjectArray<String> _arguments;
  String _workingDirectory;
  List<String> _environment;
  // Private methods of _Socket are used by _in, _out, and _err.
  _Socket _in;
  _Socket _out;
  _Socket _err;
  Socket _exitHandler;
  int _pid;
  bool _closed;
  bool _ended;
  bool _started;
  Function _onExit;
  Function _onError;
  Function _onStart;
}


// _NonInteractiveProcess is a wrapper around an interactive process
// that buffers output so it can be delivered when the process exits.
// _NonInteractiveProcess is used to implement the Process.run
// method.
class _NonInteractiveProcess {
  _NonInteractiveProcess._start(String path,
                                List<String> arguments,
                                ProcessOptions options) {
    _completer = new Completer<ProcessResult>();
    // Extract output encoding options and verify arguments.
    var stdoutEncoding = Encoding.UTF_8;
    var stderrEncoding = Encoding.UTF_8;
    if (options !== null) {
      if (options.stdoutEncoding !== null) {
        stdoutEncoding = options.stdoutEncoding;
        if (stdoutEncoding is !Encoding) {
          throw new IllegalArgumentException(
              'stdoutEncoding option is not an encoding: $stdoutEncoding');
        }
      }
      if (options.stderrEncoding !== null) {
        stderrEncoding = options.stderrEncoding;
        if (stderrEncoding is !Encoding) {
          throw new IllegalArgumentException(
              'stderrEncoding option is not an encoding: $stderrEncoding');
        }
      }
    }

    // Start the underlying process.
    _process = new _Process.start(path, arguments, options);

    // Make sure stdin is closed.
    _process.onStart = _process.stdin.close;

    // Setup process error handling.
    _process.onError = (e) => _completer.completeException(e);

    // Setup process exit handling.
    _process.onExit = (exitCode) {
      _exitCode = exitCode;
      _checkDone();
    };

    // Setup stdout handling.
    _stdoutBuffer = new StringBuffer();
    var stdoutStream = new StringInputStream(_process.stdout, stdoutEncoding);
    stdoutStream.onData = () {
      var data = stdoutStream.read();
      if (data != null) _stdoutBuffer.add(data);
    };
    stdoutStream.onClosed = () {
      _stdoutClosed = true;
      _checkDone();
    };

    // Setup stderr handling.
    _stderrBuffer = new StringBuffer();
    var stderrStream = new StringInputStream(_process.stderr, stderrEncoding);
    stderrStream.onData = () {
      var data = stderrStream.read();
      if (data != null) _stderrBuffer.add(data);
    };
    stderrStream.onClosed = () {
      _stderrClosed = true;
      _checkDone();
    };
  }

  void _checkDone() {
    if (_exitCode != null && _stderrClosed && _stdoutClosed) {
      _completer.complete(new _ProcessResult(_exitCode,
                                             _stdoutBuffer.toString(),
                                             _stderrBuffer.toString()));
    }
  }

  Future<ProcessResult> get _result() => _completer.future;

  Completer<ProcessResult> _completer;
  Process _process;
  StringBuffer _stdoutBuffer;
  StringBuffer _stderrBuffer;
  int _exitCode;
  bool _stdoutClosed = false;
  bool _stderrClosed = false;
}


class _ProcessResult implements ProcessResult {
  const _ProcessResult(int this.exitCode,
                       String this.stdout,
                       String this.stderr);

  final int exitCode;
  final String stdout;
  final String stderr;
}
