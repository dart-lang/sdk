// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library used to spawn the Dart Developer Service, used to communicate
/// with a Dart VM Service instance.
library dds;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:pedantic/pedantic.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_proxy/shelf_proxy.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'src/binary_compatible_peer.dart';
part 'src/client.dart';
part 'src/dds_impl.dart';
part 'src/stream_manager.dart';

/// An intermediary between a Dart VM service and its clients that offers
/// additional functionality on top of the standard VM service protocol.
///
/// See the [Dart Development Service Protocol](https://github.com/dart-lang/sdk/blob/master/pkg/dds/dds_protocol.md)
/// for details.
abstract class DartDevelopmentService {
  /// Creates a [DartDevelopmentService] instance which will communicate with a
  /// VM service.
  ///
  /// [remoteVmServiceUri] is the address of the VM service that this
  /// development service will communicate with.
  ///
  /// If provided, [serviceUri] will determine the address and port of the
  /// spawned Dart Development Service.
  static Future<DartDevelopmentService> startDartDevelopmentService(
    Uri remoteVmServiceUri, {
    Uri serviceUri,
  }) async {
    if (remoteVmServiceUri == null) {
      throw ArgumentError.notNull('remoteVmServiceUri');
    }
    if (remoteVmServiceUri.scheme != 'http') {
      throw ArgumentError(
        'remoteVmServiceUri must have an HTTP scheme. Actual: ${remoteVmServiceUri.scheme}',
      );
    }
    if (serviceUri != null && serviceUri.scheme != 'http') {
      throw ArgumentError(
        'serviceUri must have an HTTP scheme. Actual: ${serviceUri.scheme}',
      );
    }

    final service = _DartDevelopmentService(remoteVmServiceUri, serviceUri);
    await service.startService();
    return service;
  }

  DartDevelopmentService._();

  /// Stop accepting requests after gracefully handling existing requests.
  Future<void> shutdown();

  /// The HTTP [Uri] of the remote VM service instance that this service will
  /// forward requests to.
  Uri get remoteVmServiceUri;

  /// The web socket [Uri] of the remote VM service instance that this service
  /// will forward requests to.
  ///
  /// Can be used with [WebSocket] to communicate directly with the VM service.
  Uri get remoteVmServiceWsUri;

  /// The [Uri] VM service clients can use to communicate with this
  /// [DartDevelopmentService] via HTTP.
  ///
  /// Returns `null` if the service is not running.
  Uri get uri;

  /// The [Uri] VM service clients can use to communicate with this
  /// [DartDevelopmentService] via a [WebSocket].
  ///
  /// Returns `null` if the service is not running.
  Uri get wsUri;

  /// Set to `true` if this instance of [DartDevelopmentService] is accepting
  /// requests.
  bool get isRunning;
}
