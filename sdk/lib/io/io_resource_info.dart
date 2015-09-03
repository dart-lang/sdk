// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

const String TCP_STRING = 'TCP';
const String UDP_STRING = 'UDP';


abstract class _IOResourceInfo {
  final String type;
  final int id;
  String get name;
  static int _count = 0;

  _IOResourceInfo(this.type) : id = _IOResourceInfo.getNextID();

  String toJSON();

  /// Get the full set of values for a specific implementation. This is normally
  /// looked up based on an id from a referenceValueMap.
  Map<String, String> get fullValueMap;

  /// The reference map, used to return a list of values, e.g., getting
  /// all open sockets. The structure of this is shared among all subclasses.
  Map<String, String> get referenceValueMap =>
      {
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

  _ReadWriteResourceInfo(String type) :
    totalRead = 0,
    totalWritten = 0,
    readCount = 0,
    writeCount = 0,
    lastRead = 0.0,
    lastWrite = 0.0,
    super(type);

  Map<String, String> get fullValueMap =>
    {
      'type': type,
      'id': id,
      'name': name,
      'total_read': totalRead,
      'total_written': totalWritten,
      'read_count': readCount,
      'write_count': writeCount,
      'last_read': lastRead,
      'last_write': lastWrite
    };

  String toJSON() {
    return JSON.encode(fullValueMap);
  }
}

class _SocketResourceInfo extends _ReadWriteResourceInfo {
  final socket;

  static Map<int, _SocketResourceInfo> openSockets =
      new Map<int, _SocketResourceInfo>();

  _SocketResourceInfo(this.socket) : super('_socket') {
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
    } catch (e) { } // ignored if we can't get the information
    return '${socket.address.host}:${socket.port}$remote';
  }

  static Iterable<Map<String, String>> getOpenSocketsList() {
    return new List.from(openSockets.values.map((e) => e.referenceValueMap));
  }

  Map<String, String> getSocketInfoMap() {
    var result = fullValueMap;
    result['socket_type'] = socket.isTcp ? TCP_STRING : UDP_STRING;
    result['listening'] = socket.isListening;
    result['host'] = socket.address.host;
    result['port'] = socket.port;
    if (!socket.isListening) {
      try {
        result['remote_host'] = socket.remoteAddress.host;
        result['remote_port'] = socket.remotePort;
      } catch (e) {
        // UDP.
        result['remote_port'] = 'NA';
        result['remote_host'] = 'NA';
      }
    } else {
      result['remote_port'] = 'NA';
      result['remote_host'] = 'NA';
    }
    result['address_type'] = socket.address.type.name;
    return result;
  }

  static Future<ServiceExtensionResponse> getSocketInfoMapByID(
      String function, Map<String, String> params) {
    assert(params.containsKey('id'));
    var id = int.parse(params['id']);
    var result =
      openSockets.containsKey(id) ? openSockets[id].getSocketInfoMap() : {};
    var json = JSON.encode(result);
    return new Future.value(new ServiceExtensionResponse.result(json));
  }

  static Future<ServiceExtensionResponse> getOpenSockets(function, params) {
    assert(function == '__getOpenSockets');
    var data = {'type': '_opensockets', 'data': getOpenSocketsList()};
    var json = JSON.encode(data);
    return new Future.value(new ServiceExtensionResponse.result(json));
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
