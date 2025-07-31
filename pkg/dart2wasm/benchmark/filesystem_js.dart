// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';
import 'dart:typed_data';

import 'filesystem_base.dart';

class WasmCompilerFileSystem extends WasmCompilerFileSystemBase {
  @override
  Uint8List? tryReadBytesSync(String path) {
    try {
      if (isD8) {
        return d8Read(path).toDart.asUint8List();
      }
      if (isJSC) {
        path = path.startsWith('/') ? path : '../../$path';
        return jscRead(path, 'binary').toDart;
      }
      if (isJSShell) {
        return jsshellRead(path, 'binary').toDart;
      }
      throw 'Unknown JS Shell';
    } catch (_) {
      print('-> failed to load $path');
      return null;
    }
  }

  @override
  void writeBytesSync(String path, Uint8List bytes) {
    try {
      if (isJSShell) {
        return jsshellWrite(path, bytes.toJS);
      }
      final buffer =
          (Uint8List(bytes.length)..setRange(0, bytes.length, bytes)).buffer;
      if (isD8) {
        return d8Write(path, buffer.toJS);
      }
      if (isJSC) {
        path = path.startsWith('/') ? path : '../../$path';
        return jscWrite(path, buffer.toJS);
      }
      throw 'Unknown JS Shell';
    } catch (_) {
      print('-> failed to write to $path');
    }
  }
}

final bool isD8 = d8Only != null;
final bool isJSC = !isD8 && notD8JSCOnly != null;
final bool isJSShell = !isD8 && !isJSC;

@JS('readbuffer')
external JSArrayBuffer d8Read(String filename);

@JS('writeFile')
external void d8Write(String filename, JSArrayBuffer bytes);

@JS('readFile') // Have to prepend ../../ for relative paths
external JSUint8Array jscRead(String filename, String binary);

@JS('writeFile') // Have to prepend ../../ for relative paths
external void jscWrite(String filename, JSArrayBuffer bytes);

@JS('os.file.readFile')
external JSUint8Array jsshellRead(String filename, String binary);

@JS('os.file.writeTypedArrayToFile')
external void jsshellWrite(String filename, JSUint8Array bytes);

@JS('readbuffer')
external JSAny? d8Only;

@JS('readFile')
external JSAny? notD8JSCOnly;
