// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class _BufferUtils {
  patch static bool _isBuiltinList(List buffer) {
    throw new UnsupportedError("_isBuiltinList");
  }
}

patch class _Directory {
  patch static String _current() {
    throw new UnsupportedError("Directory._current");
  }
  patch static _createTemp(String template) {
    throw new UnsupportedError("Directory._createTemp");
  }
  patch static int _exists(String path) {
    throw new UnsupportedError("Directory._exists");
  }
  patch static _create(String path) {
    throw new UnsupportedError("Directory._create");
  }
  patch static _delete(String path, bool recursive) {
    throw new UnsupportedError("Directory._delete");
  }
  patch static _rename(String path, String newPath) {
    throw new UnsupportedError("Directory._rename");
  }
  patch static SendPort _newServicePort() {
    throw new UnsupportedError("Directory._newServicePort");
  }
}

patch class _EventHandler {
  patch static void _start() {
    throw new UnsupportedError("EventHandler._start");
  }

  patch static _sendData(Object sender,
                         ReceivePort receivePort,
                         int data) {
    throw new UnsupportedError("EventHandler._sendData");
  }
}

patch class _FileUtils {
  patch static SendPort _newServicePort() {
    throw new UnsupportedError("FileUtils._newServicePort");
  }
}

patch class _File {
  patch static _exists(String name) {
    throw new UnsupportedError("File._exists");
  }
  patch static _create(String name) {
    throw new UnsupportedError("File._create");
  }
  patch static _delete(String name) {
    throw new UnsupportedError("File._delete");
  }
  patch static _directory(String name) {
    throw new UnsupportedError("File._directory");
  }
  patch static _lengthFromName(String name) {
    throw new UnsupportedError("File._lengthFromName");
  }
  patch static _lastModified(String name) {
    throw new UnsupportedError("File._lastModified");
  }
  patch static _open(String name, int mode) {
    throw new UnsupportedError("File._open");
  }
  patch static int _openStdio(int fd) {
    throw new UnsupportedError("File._openStdio");
  }
  patch static _fullPath(String name) {
    throw new UnsupportedError("File._fullPath");
  }
}

patch class _RandomAccessFile {
  patch static int _close(int id) {
    throw new UnsupportedError("RandomAccessFile._close");
  }
  patch static _readByte(int id) {
    throw new UnsupportedError("RandomAccessFile._readByte");
  }
  patch static _readList(int id, List<int> buffer, int offset, int bytes) {
    throw new UnsupportedError("RandomAccessFile._readList");
  }
  patch static _writeByte(int id, int value) {
    throw new UnsupportedError("RandomAccessFile._writeByte");
  }
  patch static _writeList(int id, List<int> buffer, int offset, int bytes) {
    throw new UnsupportedError("RandomAccessFile._writeList");
  }
  patch static _position(int id) {
    throw new UnsupportedError("RandomAccessFile._position");
  }
  patch static _setPosition(int id, int position) {
    throw new UnsupportedError("RandomAccessFile._setPosition");
  }
  patch static _truncate(int id, int length) {
    throw new UnsupportedError("RandomAccessFile._truncate");
  }
  patch static _length(int id) {
    throw new UnsupportedError("RandomAccessFile._length");
  }
  patch static _flush(int id) {
    throw new UnsupportedError("RandomAccessFile._flush");
  }
}

patch class _HttpSessionManager {
  patch static Uint8List _getRandomBytes(int count) {
    throw new UnsupportedError("HttpSessionManager._getRandomBytes");
  }
}

patch class _Platform {
  patch static int _numberOfProcessors() {
    throw new UnsupportedError("Platform._numberOfProcessors");
  }
  patch static String _pathSeparator() {
    throw new UnsupportedError("Platform._pathSeparator");
  }
  patch static String _operatingSystem() {
    throw new UnsupportedError("Platform._operatingSystem");
  }
  patch static _localHostname() {
    throw new UnsupportedError("Platform._localHostname");
  }
  patch static _environment() {
    throw new UnsupportedError("Platform._environment");
  }
}

patch class _ProcessUtils {
  patch static _exit(int status) {
    throw new UnsupportedError("ProcessUtils._exit");
  }
}

patch class Process {
  patch static Future<Process> start(String executable,
                                     List<String> arguments,
                                     [ProcessOptions options]) {
    throw new UnsupportedError("Process.start");
  }

  patch static Future<ProcessResult> run(String executable,
                                         List<String> arguments,
                                         [ProcessOptions options]) {
    throw new UnsupportedError("Process.run");
  }
}

patch class ServerSocket {
  patch factory ServerSocket(String bindAddress, int port, int backlog) {
    return new _ServerSocket(bindAddress, port, backlog);
  }
}

patch class Socket {
  patch factory Socket(String host, int port) => new _Socket(host, port);
}

patch class TlsSocket {
  patch static void setCertificateDatabase(String pkcertDirectory) {
    throw new UnsupportedError("TlsSocket.setCertificateDatabase");
  }
}

patch class _TlsFilter {
  patch factory _TlsFilter() {
    throw new UnsupportedError("_TlsFilter._TlsFilter");
  }
}

patch class _StdIOUtils {
  patch static _getStdioHandle(Socket socket, int num) {
    throw new UnsupportedError("StdIOUtils._getStdioHandle");
  }
  patch static _getStdioHandleType(int num) {
    throw new UnsupportedError("StdIOUtils._getStdioHandleType");
  }
}
