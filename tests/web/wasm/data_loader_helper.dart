// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';
import 'dart:typed_data';

@JS()
external JSPromise<JSArrayBuffer> loadData(JSString uri);

Future<Uint8List> loadFileWrapper(String uri) async {
  final resultRef = loadData(uri.toJS);
  final arrayBuffer = await resultRef.toDart;
  return arrayBuffer.toDart.asUint8List();
}
