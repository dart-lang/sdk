// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
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
  patch static List _list(String path, bool recursive, bool followLinks) {
    throw new UnsupportedError("Directory._list");
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

patch class FileSystemEntity {
  patch static int _getType(String path, bool followLinks) {
    throw new UnsupportedError("FileSystemEntity._getType");
  }
  patch static bool _identical(String path1, String path2) {
    throw new UnsupportedError("FileSystemEntity._identical");
  }
}

patch class _File {
  patch static _exists(String path) {
    throw new UnsupportedError("File._exists");
  }
  patch static _create(String path) {
    throw new UnsupportedError("File._create");
  }
  patch static _createLink(String path, String target) {
    throw new UnsupportedError("File._createLink");
  }
  patch static _linkTarget(String path) {
    throw new UnsupportedError("File._linkTarget");
  }
  patch static _delete(String path) {
    throw new UnsupportedError("File._delete");
  }
  patch static _deleteLink(String path) {
    throw new UnsupportedError("File._deleteLink");
  }
  patch static _directory(String path) {
    throw new UnsupportedError("File._directory");
  }
  patch static _lengthFromPath(String path) {
    throw new UnsupportedError("File._lengthFromPath");
  }
  patch static _lastModified(String path) {
    throw new UnsupportedError("File._lastModified");
  }
  patch static _open(String path, int mode) {
    throw new UnsupportedError("File._open");
  }
  patch static int _openStdio(int fd) {
    throw new UnsupportedError("File._openStdio");
  }
  patch static _fullPath(String path) {
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
  patch static _read(int id, int bytes) {
    throw new UnsupportedError("RandomAccessFile._read");
  }
  patch static _readInto(int id, List<int> buffer, int start, int end) {
    throw new UnsupportedError("RandomAccessFile._readInto");
  }
  patch static _writeByte(int id, int value) {
    throw new UnsupportedError("RandomAccessFile._writeByte");
  }
  patch static _writeFrom(int id, List<int> buffer, int start, int end) {
    throw new UnsupportedError("RandomAccessFile._writeFrom");
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

patch class _IOCrypto {
  patch static Uint8List getRandomBytes(int count) {
    throw new UnsupportedError("_IOCrypto.getRandomBytes");
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
  patch static _setExitCode(int status) {
    throw new UnsupportedError("ProcessUtils._setExitCode");
  }
  patch static _sleep(int millis) {
    throw new UnsupportedError("ProcessUtils._sleep");
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

patch class RawServerSocket {
  patch static Future<RawServerSocket> bind([String address = "127.0.0.1",
                                             int port = 0,
                                             int backlog = 0]) {
    throw new UnsupportedError("RawServerSocket.bind");
  }
}

patch class ServerSocket {
  patch static Future<ServerSocket> bind([String address = "127.0.0.1",
                                          int port = 0,
                                          int backlog = 0]) {
    throw new UnsupportedError("ServerSocket.bind");
  }
}

patch class RawSocket {
  patch static Future<RawSocket> connect(String host, int port) {
    throw new UnsupportedError("RawSocket constructor");
  }
}

patch class Socket {
  patch static Future<Socket> connect(String host, int port) {
    throw new UnsupportedError("Socket constructor");
  }
}

patch class SecureSocket {
  patch factory SecureSocket._(RawSecureSocket rawSocket) {
    throw new UnsupportedError("SecureSocket constructor");
  }

  patch static void initialize({String database,
                                String password,
                                bool useBuiltinRoots: true}) {
    throw new UnsupportedError("SecureSocket.initialize");
  }
}

patch class _SecureFilter {
  patch factory _SecureFilter() {
    throw new UnsupportedError("_SecureFilter._SecureFilter");
  }
}

patch class _StdIOUtils {
  patch static Stream<List<int>> _getStdioInputStream() {
    throw new UnsupportedError("StdIOUtils._getStdioInputStream");
  }
  patch static IOSink _getStdioOutputStream(int fd) {
    throw new UnsupportedError("StdIOUtils._getStdioOutputStream");
  }
  patch static int _socketType(nativeSocket) {
    throw new UnsupportedError("StdIOUtils._socketType");
  }
}

patch class _WindowsCodePageDecoder {
  patch static String _decodeBytes(List<int> bytes) {
    throw new UnsupportedError("_WindowsCodePageDecoder._decodeBytes");
  }
}

patch class _WindowsCodePageEncoder {
  patch static List<int> _encodeString(String string) {
    throw new UnsupportedError("_WindowsCodePageEncoder._encodeString");
  }
}

patch class _Filter {
  patch static _Filter newZLibDeflateFilter(bool gzip, int level) {
    throw new UnsupportedError("newZLibDeflateFilter");
  }
  patch static _Filter newZLibInflateFilter() {
    throw new UnsupportedError("newZLibInflateFilter");
  }
}
