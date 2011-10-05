// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _ProcessStartStatus {
  int _errorCode;  // Set to OS error code if process start failed.
  String _errorMessage;  // Set to OS error message if process start failed.
}


class _Process implements Process {

  _Process(String path, List<String> arguments) {
    _path = path;
    {
      int len = arguments.length;
      _arguments = new ObjectArray<String>(len);
      for (int i = 0; i < len; i++) {
        _arguments[i] = arguments[i];
      }
    }
    _in = new _Socket._internal();
    _out = new _Socket._internal();
    _err = new _Socket._internal();
    _exitHandler = new _Socket._internal();
    _closed = false;
    _killed = false;
    _started = false;
    _exitHandlerCallback = null;
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
    if (_exitHandlerCallback !== null) {
      setExitHandler(_exitHandlerCallback);
    }
  }

  bool _start(String path,
              List<String> arguments,
              Socket input,
              Socket output,
              Socket error,
              Socket exitHandler,
              _ProcessStartStatus status) native "Process_Start";

  InputStream get stdoutStream() {
    if (_closed) {
      throw new ProcessException("Process closed");
    }
    return _in.inputStream;
  }

  InputStream get stderrStream() {
    if (_closed) {
      throw new ProcessException("Process closed");
    }
    return _err.inputStream;
  }

  OutputStream get stdinStream() {
    if (_closed) {
      throw new ProcessException("Process closed");
    }
    return _out.outputStream;
  }

  bool kill() {
    if (_closed && _pid == null) {
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

  void setExitHandler(void callback(int exitCode)) {
    if (_closed) {
      throw new ProcessException("Process closed");
    }
    if (_killed) {
      throw new ProcessException("Process killed");
    }
    if (_started) {
      _exitHandler.setDataHandler(() {
        List<int> buffer = new List<int>(4);
        SocketInputStream input = _exitHandler.inputStream;

        int getExitValue(List<int> ints) {
          return ints[0] + (ints[1] << 8) + (ints[2] << 16) + (ints[3] << 24);
        }

        void readData() {
          callback(getExitValue(buffer));
        }

        bool result = input.read(buffer, 0, 4, readData);
        if (result) {
          callback(getExitValue(buffer));
        }
      });
    } else {
      _exitHandlerCallback = callback;
    }
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
