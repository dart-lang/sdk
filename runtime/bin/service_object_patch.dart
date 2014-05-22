// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


final Map _servicePathMap = {
  'http' : {
    'servers' : _httpServersServiceObject
  }
};

String _serviceObjectHandler(List<String> paths,
                             List<String> keys,
                             List<String> values) {
  assert(keys.length == values.length);
  badPath() {
    throw "Invalid path '${paths.join("/")}'";
  }
  if (paths.isEmpty) {
    badPath();
  }
  int i = 0;
  var current = _servicePathMap;
  do {
    current = current[paths[i]];
    i++;
  } while (i < paths.length && current is Map);
  if (current is! Function) {
    badPath();
  }
  var query = new Map();
  for (int i = 0; i < keys.length; i++) {
    query[keys[i]] = values[i];
  }
  return JSON.encode(current(paths.sublist(i)));
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
