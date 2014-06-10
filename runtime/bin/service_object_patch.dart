// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


final Map _servicePathMap = {
  'http' : {
    'servers' : _httpServersServiceObject,
  },
  'sockets' : _socketsServiceObject,
  'websockets' : _webSocketsServiceObject,
  'file' : {
    'randomaccessfiles' : _randomAccessFilesServiceObject
  },
  'processes' : _processesServiceObject,
};

String _getServicePath(obj) => obj._servicePath;

String _serviceObjectHandler(List<String> paths,
                             List<String> keys,
                             List<String> values) {
  assert(keys.length == values.length);
  if (paths.isEmpty) {
    return JSON.encode(_ioServiceObject());
  }
  int i = 0;
  var current = _servicePathMap;
  do {
    current = current[paths[i]];
    i++;
  } while (i < paths.length && current is Map);
  if (current is! Function) {
    return JSON.encode(_makeServiceError('Unrecognized path', paths, keys,
                                         values));
  }
  var query = new Map();
  for (int i = 0; i < keys.length; i++) {
    query[keys[i]] = values[i];
  }
  return JSON.encode(current(paths.sublist(i)));
}

Map _makeServiceError(String message,
                      List<String> paths,
                      List<String> keys,
                      List<String> values,
                      [String kind]) {
  var error = {
    'type': 'Error',
    'id': '',
    'message': message,
    'request': {
      'arguments': paths,
      'option_keys': keys,
      'option_values': values,
    }
  };
  if (kind != null) {
    error['kind'] = kind;
  }
  return error;
}

Map _ioServiceObject() {
  return {
    'id': 'io',
    'type': 'IO',
    'name': 'io',
    'user_name': 'io',
  };
}

Map _httpServersServiceObject(args) {
  if (args.length == 1) {
    var server = _HttpServer._servers[int.parse(args.first)];
    if (server == null) {
      return {};
    }
    return server._toJSON(false);
  }
  return {
    'id': 'io/http/servers',
    'type': 'HttpServerList',
    'members': _HttpServer._servers.values
        .map((server) => server._toJSON(true)).toList(),
  };
}

Map _socketsServiceObject(args) {
  if (args.length == 1) {
    var socket = _NativeSocket._sockets[int.parse(args.first)];
    if (socket == null) {
      return {};
    }
    return socket._toJSON(false);
  }
  return {
    'id': 'io/sockets',
    'type': 'SocketList',
    'members': _NativeSocket._sockets.values
        .map((socket) => socket._toJSON(true)).toList(),
  };
}

Map _webSocketsServiceObject(args) {
  if (args.length == 1) {
    var webSocket = _WebSocketImpl._webSockets[int.parse(args.first)];
    if (webSocket == null) {
      return {};
    }
    return webSocket._toJSON(false);
  }
  return {
    'id': 'io/websockets',
    'type': 'WebSocketList',
    'members': _WebSocketImpl._webSockets.values
        .map((webSocket) => webSocket._toJSON(true)).toList(),
  };
}

Map _randomAccessFilesServiceObject(args) {
  if (args.length == 1) {
    var raf = _RandomAccessFile._files[int.parse(args.first)];
    if (raf == null) {
      return {};
    }
    return raf._toJSON(false);
  }
  return {
    'id': 'io/file/randomaccessfiles',
    'type': 'RandomAccessFileList',
    'members': _RandomAccessFile._files.values
        .map((raf) => raf._toJSON(true)).toList(),
  };
}

Map _processesServiceObject(args) {
  if (args.length == 1) {
    var process = _ProcessImpl._processes[int.parse(args.first)];
    if (process == null) {
      return {};
    }
    return process._toJSON(false);
  }
  return {
    'id': 'io/processes',
    'type': 'ProcessList',
    'members': _ProcessImpl._processes.values
        .map((p) => p._toJSON(true)).toList(),
  };
}
