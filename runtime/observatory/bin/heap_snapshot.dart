// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A way to test heap snapshot loading and analysis outside of Observatory.
// Output is too noisy to be useful.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:observatory/object_graph.dart';

Future<SnapshotGraph> load(String uri) async {
  final ws = await WebSocket.connect(uri,
      compression: CompressionOptions.compressionOff);

  final getVM = new Completer<String>();
  final reader = new SnapshotReader();

  reader.onProgress.listen(print);

  ws.listen((dynamic response) {
    if (response is String) {
      response = json.decode(response);
      if (response['id'] == 1) {
        getVM.complete(response['result']['isolates'][0]['id']);
      }
    } else if (response is List<int>) {
      response = new Uint8List.fromList(response);
      final dataOffset =
          new ByteData.view(response.buffer).getUint32(0, Endian.little);
      dynamic metadata = new Uint8List.view(response.buffer, 4, dataOffset - 4);
      final data = new Uint8List.view(
          response.buffer, dataOffset, response.length - dataOffset);
      metadata = utf8.decode(metadata);
      metadata = json.decode(metadata);
      var event = metadata['params']['event'];
      if (event['kind'] == 'HeapSnapshot') {
        bool last = event['last'] == true;
        reader.add(data);
        if (last) {
          reader.close();
          ws.close();
        }
      }
    }
  });

  ws.add(json.encode({
    'jsonrpc': '2.0',
    'method': 'getVM',
    'params': {},
    'id': 1,
  }));

  final String isolateId = await getVM.future;

  ws.add(json.encode({
    'jsonrpc': '2.0',
    'method': 'streamListen',
    'params': {'streamId': 'HeapSnapshot'},
    'id': 2,
  }));
  ws.add(json.encode({
    'jsonrpc': '2.0',
    'method': 'requestHeapSnapshot',
    'params': {'isolateId': isolateId},
    'id': 3,
  }));

  return reader.done;
}

String size(SnapshotMergedDominator object) {
  int s = object.retainedSize;
  if (s < 1024) return '${s}B';
  s = s ~/ 1024;
  if (s < 1024) return '${s}kB';
  s = s ~/ 1024;
  if (s < 1024) return '${s}MB';
  s = s ~/ 1024;
  if (s < 1024) return '${s}GB';
  s = s ~/ 1024;
  return '${s}TB';
}

void display(SnapshotMergedDominator object, int depth) {
  if (object.retainedSize < 4096) return;

  var line = (' ' * (4 * depth)) + '[${size(object)}] ${object.description}';
  print(line);

  if (depth > 4) return;

  var children = new List.from(object.children);
  children.sort((a, b) => b.retainedSize - a.retainedSize);
  for (var c in children) {
    display(c, depth + 1);
  }
}

main(List<String> args) async {
  final snapshot = await load(args[0]);
  display(snapshot.mergedRoot, 0);
}
