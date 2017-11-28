// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

abstract class _IOResourceInfo {
  final String type;
  final int id;
  String get name;
  static int _count = 0;

  static final Stopwatch _sw = new Stopwatch()..start();
  static final _startTime = new DateTime.now().millisecondsSinceEpoch;

  static double get timestamp => _startTime + _sw.elapsedMicroseconds / 1000;

  _IOResourceInfo(this.type) : id = _IOResourceInfo.getNextID();

  /// Get the full set of values for a specific implementation. This is normally
  /// looked up based on an id from a referenceValueMap.
  Map<String, dynamic> get fullValueMap;

  /// The reference map, used to return a list of values, e.g., getting
  /// all open sockets. The structure of this is shared among all subclasses.
  Map<String, dynamic> get referenceValueMap => {
        // The type for a reference object is prefixed with @ in observatory.
        'type': '@$type',
        'id': id,
        'name': name,
      };

  static int getNextID() => _count++;
}

abstract class _ReadWriteResourceInfo extends _IOResourceInfo {
  int totalRead;
  int totalWritten;
  int readCount;
  int writeCount;
  double lastRead;
  double lastWrite;

  // Not all call sites use this. In some cases, e.g., a socket, a read does
  // not always mean that we actually read some bytes (we may do a read to see
  // if there are some bytes available).
  void addRead(int bytes) {
    totalRead += bytes;
    readCount++;
    lastRead = _IOResourceInfo.timestamp;
  }

  // In cases where we read but did not necessarily get any bytes, use this to
  // update the readCount and timestamp. Manually update totalRead if any bytes
  // where actually read.
  void didRead() {
    addRead(0);
  }

  void addWrite(int bytes) {
    totalWritten += bytes;
    writeCount++;
    lastWrite = _IOResourceInfo.timestamp;
  }

  _ReadWriteResourceInfo(String type)
      : totalRead = 0,
        totalWritten = 0,
        readCount = 0,
        writeCount = 0,
        lastRead = 0.0,
        lastWrite = 0.0,
        super(type);

  Map<String, dynamic> get fullValueMap => {
        'type': type,
        'id': id,
        'name': name,
        'totalRead': totalRead,
        'totalWritten': totalWritten,
        'readCount': readCount,
        'writeCount': writeCount,
        'lastRead': lastRead,
        'lastWrite': lastWrite
      };
}

class _FileResourceInfo extends _ReadWriteResourceInfo {
  static const String TYPE = '_file';

  final file;

  static Map<int, _FileResourceInfo> openFiles =
      new Map<int, _FileResourceInfo>();

  _FileResourceInfo(this.file) : super(TYPE) {
    FileOpened(this);
  }

  static FileOpened(_FileResourceInfo info) {
    assert(!openFiles.containsKey(info.id));
    openFiles[info.id] = info;
  }

  static FileClosed(_FileResourceInfo info) {
    assert(openFiles.containsKey(info.id));
    openFiles.remove(info.id);
  }

  static Iterable<Map<String, String>> getOpenFilesList() {
    return new List.from(openFiles.values.map((e) => e.referenceValueMap));
  }

  static Future<ServiceExtensionResponse> getOpenFiles(function, params) {
    assert(function == 'ext.dart.io.getOpenFiles');
    var data = {'type': '_openfiles', 'data': getOpenFilesList()};
    var jsonValue = json.encode(data);
    return new Future.value(new ServiceExtensionResponse.result(jsonValue));
  }

  Map<String, dynamic> getFileInfoMap() {
    return fullValueMap;
  }

  static Future<ServiceExtensionResponse> getFileInfoMapByID(function, params) {
    assert(params.containsKey('id'));
    var id = int.parse(params['id']);
    var result =
        openFiles.containsKey(id) ? openFiles[id].getFileInfoMap() : {};
    var jsonValue = json.encode(result);
    return new Future.value(new ServiceExtensionResponse.result(jsonValue));
  }

  String get name {
    return '${file.path}';
  }
}

class _ProcessResourceInfo extends _IOResourceInfo {
  static const String TYPE = '_process';
  final process;
  final double startedAt;

  static Map<int, _ProcessResourceInfo> startedProcesses =
      new Map<int, _ProcessResourceInfo>();

  _ProcessResourceInfo(this.process)
      : startedAt = _IOResourceInfo.timestamp,
        super(TYPE) {
    ProcessStarted(this);
  }

  String get name => process._path;

  void stopped() {
    ProcessStopped(this);
  }

  Map<String, dynamic> get fullValueMap => {
        'type': type,
        'id': id,
        'name': name,
        'pid': process.pid,
        'startedAt': startedAt,
        'arguments': process._arguments,
        'workingDirectory':
            process._workingDirectory == null ? '.' : process._workingDirectory,
      };

  static ProcessStarted(_ProcessResourceInfo info) {
    assert(!startedProcesses.containsKey(info.id));
    startedProcesses[info.id] = info;
  }

  static ProcessStopped(_ProcessResourceInfo info) {
    assert(startedProcesses.containsKey(info.id));
    startedProcesses.remove(info.id);
  }

  static Iterable<Map<String, String>> getStartedProcessesList() =>
      new List.from(startedProcesses.values.map((e) => e.referenceValueMap));

  static Future<ServiceExtensionResponse> getStartedProcesses(
      String function, Map<String, String> params) {
    assert(function == 'ext.dart.io.getProcesses');
    var data = {'type': '_startedprocesses', 'data': getStartedProcessesList()};
    var jsonValue = json.encode(data);
    return new Future.value(new ServiceExtensionResponse.result(jsonValue));
  }

  static Future<ServiceExtensionResponse> getProcessInfoMapById(
      String function, Map<String, String> params) {
    var id = int.parse(params['id']);
    var result = startedProcesses.containsKey(id)
        ? startedProcesses[id].fullValueMap
        : {};
    var jsonValue = json.encode(result);
    return new Future.value(new ServiceExtensionResponse.result(jsonValue));
  }
}

class _SocketResourceInfo extends _ReadWriteResourceInfo {
  static const String TCP_STRING = 'TCP';
  static const String UDP_STRING = 'UDP';
  static const String TYPE = '_socket';

  final /*_NativeSocket|*/ socket;

  static Map<int, _SocketResourceInfo> openSockets =
      new Map<int, _SocketResourceInfo>();

  _SocketResourceInfo(this.socket) : super(TYPE) {
    SocketOpened(this);
  }

  String get name {
    if (socket.isListening) {
      return 'listening:${socket.address.host}:${socket.port}';
    }
    var remote = '';
    try {
      var remoteHost = socket.remoteAddress.host;
      var remotePort = socket.remotePort;
      remote = ' -> $remoteHost:$remotePort';
    } catch (e) {} // ignored if we can't get the information
    return '${socket.address.host}:${socket.port}$remote';
  }

  static Iterable<Map<String, String>> getOpenSocketsList() {
    return new List.from(openSockets.values.map((e) => e.referenceValueMap));
  }

  Map<String, dynamic> getSocketInfoMap() {
    var result = fullValueMap;
    result['socketType'] = socket.isTcp ? TCP_STRING : UDP_STRING;
    result['listening'] = socket.isListening;
    result['host'] = socket.address.host;
    result['port'] = socket.port;
    if (!socket.isListening) {
      try {
        result['remoteHost'] = socket.remoteAddress.host;
        result['remotePort'] = socket.remotePort;
      } catch (e) {
        // UDP.
        result['remotePort'] = 'NA';
        result['remoteHost'] = 'NA';
      }
    } else {
      result['remotePort'] = 'NA';
      result['remoteHost'] = 'NA';
    }
    result['addressType'] = socket.address.type.name;
    return result;
  }

  static Future<ServiceExtensionResponse> getSocketInfoMapByID(
      String function, Map<String, String> params) {
    assert(params.containsKey('id'));
    var id = int.parse(params['id']);
    var result =
        openSockets.containsKey(id) ? openSockets[id].getSocketInfoMap() : {};
    var jsonValue = json.encode(result);
    return new Future.value(new ServiceExtensionResponse.result(jsonValue));
  }

  static Future<ServiceExtensionResponse> getOpenSockets(function, params) {
    assert(function == 'ext.dart.io.getOpenSockets');
    var data = {'type': '_opensockets', 'data': getOpenSocketsList()};
    var jsonValue = json.encode(data);
    return new Future.value(new ServiceExtensionResponse.result(jsonValue));
  }

  static SocketOpened(_SocketResourceInfo info) {
    assert(!openSockets.containsKey(info.id));
    openSockets[info.id] = info;
  }

  static SocketClosed(_SocketResourceInfo info) {
    assert(openSockets.containsKey(info.id));
    openSockets.remove(info.id);
  }
}
