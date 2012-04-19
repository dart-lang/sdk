// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _ProcessStartStatus {
  int _errorCode;  // Set to OS error code if process start failed.
  String _errorMessage;  // Set to OS error message if process start failed.
}


// Abstract factory class capable of producing interactive and
// non-interactive processes.
class _Process {

  factory Process.start(String path,
                        List<String> arguments,
                        [ProcessOptions options]) {
    return new _InteractiveProcess.start(path, arguments, options);
  }

  factory Process.run(String path,
                      List<String> arguments,
                      ProcessOptions options,
                      void callback(int exitCode,
                                    String stdout,
                                    String stderr)) {
    return new _NonInteractiveProcess.start(path,
                                            arguments,
                                            options,
                                            callback);
  }
}


// _InteractiveProcess is the actual implementation of all processes
// started from Dart code.
class _InteractiveProcess implements Process {

  _InteractiveProcess.start(String path,
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
      if (Platform.operatingSystem() == 'windows') {
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

    _in = new _Socket._internalReadOnly();  // stdout coming from process.
    _out = new _Socket._internalWriteOnly();  // stdin going to process.
    _err = new _Socket._internalReadOnly();  // stderr coming from process.
    _exitHandler = new _Socket._internalReadOnly();
    _closed = false;
    _killed = false;
    _started = false;
    _onExit = null;
    // TODO(ager): Make the actual process starting really async instead of
    // simulating it with a timer.
    new Timer(0, (Timer ignore) => start());
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

  void start() {
    var status = new _ProcessStartStatus();
    bool success = _start(_path,
                          _arguments,
                          _workingDirectory,
                          _in,
                          _out,
                          _err,
                          _exitHandler,
                          status);
    if (!success) {
      close();
      if (_onError !== null) {
        _onError(new ProcessException(status._errorMessage, status._errorCode));
        return;
      }
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

  bool _start(String path,
              List<String> arguments,
              String workingDirectory,
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

  void kill() {
    if (_closed && _pid === null) {
      if (_onError !== null) {
        _onError(new ProcessException("Process closed"));
      }
      return;
    }
    if (_killed) {
      return;
    }
    // TODO(ager): Make the actual kill operation asynchronous.
    if (_kill(_pid)) {
      _killed = true;
      return;
    }
    if (_onError !== null) {
      _onError(new ProcessException("Could not kill process"));
      return;
    }
  }

  void _kill(int pid) native "Process_Kill";

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
    if (_killed) {
      throw new ProcessException("Process killed");
    }
    _onExit = callback;
  }

  void set onError(void callback(ProcessException exception)) {
    _onError = callback;
  }

  void set onStart(void callback()) {
    _onStart = callback;
  }

  String _path;
  ObjectArray<String> _arguments;
  String _workingDirectory;
  // Private methods of _Socket are used by _in, _out, and _err.
  _Socket _in;
  _Socket _out;
  _Socket _err;
  Socket _exitHandler;
  int _pid;
  bool _closed;
  bool _killed;
  bool _started;
  Function _onExit;
  Function _onError;
  Function _onStart;
}


// _NonInteractiveProcess is a wrapper around an interactive process
// that restricts the interface to disallow access to the streams and
// buffers output so it can be delivered to the callback when the
// process exits.
class _NonInteractiveProcess implements Process {

  _NonInteractiveProcess.start(String path,
                               List<String> arguments,
                               ProcessOptions options,
                               Function this._callback) {
    _process = new _InteractiveProcess.start(path, arguments, options);

    // Setup process exit handling.
    _process.onExit = (exitCode) {
      _exitCode = exitCode;
      _checkDone();
    };

    // Extract output encoding options.
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
      _callback(_exitCode, _stdoutBuffer.toString(), _stderrBuffer.toString());
    }
  }

  InputStream get stdout() {
    throw new UnsupportedOperationException(
        'Cannot get stdout stream for process started with '
        'the run constructor. The entire stdout '
        'will be supplied in the callback on completion.');
  }

  InputStream get stderr() {
    throw new UnsupportedOperationException(
        'Cannot get stderr stream for process started with '
        'the run constructor. The entire stderr '
        'will be supplied in the callback on completion.');
  }

  OutputStream get stdin() {
    throw new UnsupportedOperationException(
        'Cannot communicate via stdin with process started with '
        'the run constructor');
  }

  void set onStart(void callback()) => _process.onStart = callback;

  void set onExit(void callback(int exitCode)) {
    throw new UnsupportedOperationException(
        'Cannot set exit handler on process started with '
        'the run constructor. The exit code will '
        'be supplied in the callback on completion.');
  }

  void set onError(void callback(ProcessException error)) {
    _process.onError = callback;
  }

  void kill() => _process.kill();

  void close() => _process.close();

  Process _process;
  Function _callback;
  StringBuffer _stdoutBuffer;
  StringBuffer _stderrBuffer;
  int _exitCode;
  bool _stdoutClosed = false;
  bool _stderrClosed = false;
}
