// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'dtd_connection.dart';

abstract class DartToolingDaemon {
  // TODO(@danchevalier)
  static Future<DTDConnection> connect(Uri uri) async {
    final channel = WebSocketChannel.connect(uri);
    return DTDConnection(channel);
  }
}
