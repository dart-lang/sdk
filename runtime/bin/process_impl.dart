// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _ProcessStartStatus {
  int _errorCode;  // Set to OS error code if process start failed.
  String _errorMessage;  // Set to OS error message if process start failed.
}


class _Process implements Process {

  _Process(String path, List<String> arguments) {
    if (path is !String) {
      throw new ProcessException("Path is not a String: $path");
    }
    _path = path;

    if (arguments is !List) {
      throw new ProcessException("Arguments is not a List: $arguments");
    }
    int len = arguments.length;
    _arguments = new ObjectArray<String>(len);
    for (int i = 0; i < len; i++) {
      var arg = arguments[i];
      if (arg is !String) {
        throw new ProcessException("Non-string argument: $arg");
      }
      _arguments[i] = arguments[i];
    }

    _in = new _Socket._internalOutputOnly();
    _out = new _Socket._internalInputOnly();
    _err = new _Socket._internalOutputOnly();
    _exitHandler = new _Socket._internal();
    _closed = false;
    _killed = false;
    _started = false;
    _exitHandlerCallback = null;
  }

  int _intFromBytes(List<int> bytes, int offset) {
    return (bytes[offset] +
            (bytes[offset + 1] << 8) +
            (bytes[offset + 2] << 16) +
            (bytes[offset + 3] << 24));
  }

  void start() {
    var status = new _ProcessStartStatus();
    bool success = _start(
        _path, _arguments, _in, _out, _err, _exitHandler, status);
    if (!success) {
      close();
      throw new ProcessException(status._errorMessage, status._errorCode);
    }
    _started = true;

    // Make sure to activate socket handlers now that the file
    // descriptors have been set.
    _in._activateHandlers();
    _out._activateHandlers();
    _err._activateHandlers();

    // Setup an exit handler to handle internal cleanup and possible
    // callback when a process terminates.
    _exitHandler.dataHandler = () {
        final int EXIT_DATA_SIZE = 12;
        List<int> exitDataBuffer = new List<int>(EXIT_DATA_SIZE);
        InputStream input = _exitHandler.inputStream;
        int exitDataRead = 0;

        int exitCode(List<int> ints) {
          var code = _intFromBytes(ints, 4);
          var negative = _intFromBytes(ints, 8);
          assert(negative == 0 || negative == 1);
          return (negative == 0) ? code : -code;
        }

        int exitPid(List<int> ints) {
          return _intFromBytes(ints, 0);
        }

        void handleExit() {
          _processExit(exitPid(exitDataBuffer));
          if (_exitHandlerCallback !== null) {
            _exitHandlerCallback(exitCode(exitDataBuffer));
          }
        }

        void exitData() {
          exitDataRead += input.readInto(
              exitDataBuffer, exitDataRead, EXIT_DATA_SIZE - exitDataRead);
          if (exitDataRead == EXIT_DATA_SIZE) handleExit();
        }

        input.dataHandler = exitData;
      };
  }

  bool _start(String path,
              List<String> arguments,
              Socket input,
              Socket output,
              Socket error,
              Socket exitHandler,
              _ProcessStartStatus status) native "Process_Start";

  void _processExit(int pid) native "Process_Exit";

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

  bool kill() {
    if (_closed && _pid === null) {
      throw new ProcessException("Process closed");
    }
    if (_killed) {
      return true;
    }
    if (_kill(_pid)) {
      _killed = true;
      return true;
    }
    return false;
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

  void set exitHandler(void callback(int exitCode)) {
    if (_closed) {
      throw new ProcessException("Process closed");
    }
    if (_killed) {
      throw new ProcessException("Process killed");
    }
    _exitHandlerCallback = callback;
  }

  String _path;
  ObjectArray<String> _arguments;
  Socket _in;
  Socket _out;
  Socket _err;
  Socket _exitHandler;
  int _pid;
  bool _closed;
  bool _killed;
  bool _started;
  var _exitHandlerCallback;
}
