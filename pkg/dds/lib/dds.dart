// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library used to spawn the Dart Developer Service, used to communicate
/// with a Dart VM Service instance.
library dds;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_proxy/shelf_proxy.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:sse/server/sse_handler.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'src/binary_compatible_peer.dart';
part 'src/client.dart';
part 'src/client_manager.dart';
part 'src/constants.dart';
part 'src/dds_impl.dart';
part 'src/expression_evaluator.dart';
part 'src/logging_repository.dart';
part 'src/isolate_manager.dart';
part 'src/named_lookup.dart';
part 'src/rpc_error_codes.dart';
part 'src/stream_manager.dart';

/// An intermediary between a Dart VM service and its clients that offers
/// additional functionality on top of the standard VM service protocol.
///
/// See the [Dart Development Service Protocol](https://github.com/dart-lang/sdk/blob/master/pkg/dds/dds_protocol.md)
/// for details.
abstract class DartDevelopmentService {
  /// Creates a [DartDevelopmentService] instance which will communicate with a
  /// VM service. Requires the target VM service to have no other connected
  /// clients.
  ///
  /// [remoteVmServiceUri] is the address of the VM service that this
  /// development service will communicate with.
  ///
  /// If provided, [serviceUri] will determine the address and port of the
  /// spawned Dart Development Service. The format of [serviceUri] must be
  /// consistent with the protocol determined by [ipv6].
  ///
  /// [enableAuthCodes] controls whether or not an authentication code must
  /// be provided by clients when communicating with this instance of
  /// [DartDevelopmentService]. Authentication codes take the form of a base64
  /// encoded string provided as the first element of the DDS path and is meant
  /// to make it more difficult for unintended clients to connect to this
  /// service. Authentication codes are enabled by default.
  ///
  /// [ipv6] controls whether or not DDS is served via IPv6. IPv4 is enabled by
  /// default.
  static Future<DartDevelopmentService> startDartDevelopmentService(
    Uri remoteVmServiceUri, {
    Uri serviceUri,
    bool enableAuthCodes = true,
    bool ipv6 = false,
  }) async {
    if (remoteVmServiceUri == null) {
      throw ArgumentError.notNull('remoteVmServiceUri');
    }
    if (remoteVmServiceUri.scheme != 'http') {
      throw ArgumentError(
        'remoteVmServiceUri must have an HTTP scheme. Actual: ${remoteVmServiceUri.scheme}',
      );
    }
    if (serviceUri != null) {
      if (serviceUri.scheme != 'http') {
        throw ArgumentError(
          'serviceUri must have an HTTP scheme. Actual: ${serviceUri.scheme}',
        );
      }

      // If provided an address to bind to, ensure it uses a protocol consistent
      // with that used to spawn DDS.
      final addresses = await InternetAddress.lookup(serviceUri.host);
      final address = addresses.firstWhere(
        (a) => (a.type ==
            (ipv6 ? InternetAddressType.IPv6 : InternetAddressType.IPv4)),
        orElse: () => null,
      );
      if (address == null) {
        throw ArgumentError(
          "serviceUri '$serviceUri' is not an IPv${ipv6 ? "6" : "4"} address.",
        );
      }
    }

    final service = _DartDevelopmentService(
      remoteVmServiceUri,
      serviceUri,
      enableAuthCodes,
      ipv6,
    );
    await service.startService();
    return service;
  }

  DartDevelopmentService._();

  /// Stop accepting requests after gracefully handling existing requests.
  Future<void> shutdown();

  /// Set to `true` if this instance of [DartDevelopmentService] requires an
  /// authentication code to connect.
  bool get authCodesEnabled;

  /// Completes when this [DartDevelopmentService] has shut down.
  Future<void> get done;

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
  /// [DartDevelopmentService] via server-sent events (SSE).
  ///
  /// Returns `null` if the service is not running.
  Uri get sseUri;

  /// The [Uri] VM service clients can use to communicate with this
  /// [DartDevelopmentService] via a [WebSocket].
  ///
  /// Returns `null` if the service is not running.
  Uri get wsUri;

  /// Set to `true` if this instance of [DartDevelopmentService] is accepting
  /// requests.
  bool get isRunning;

  /// The version of the DDS protocol supported by this [DartDevelopmentService]
  /// instance.
  static const String protocolVersion = '1.1';
}

class DartDevelopmentServiceException implements Exception {
  /// Set when `DartDeveloperService.startDartDevelopmentService` is called and
  /// the target VM service already has a Dart Developer Service instance
  /// connected.
  static const int existingDdsInstanceError = 1;

  /// Set when the connection to the remote VM service terminates unexpectedly
  /// during Dart Development Service startup.
  static const int failedToStartError = 2;

  /// Set when a connection error has occurred after startup.
  static const int connectionError = 3;

  factory DartDevelopmentServiceException._existingDdsInstanceError(
      String message) {
    return DartDevelopmentServiceException._(existingDdsInstanceError, message);
  }

  factory DartDevelopmentServiceException._failedToStartError() {
    return DartDevelopmentServiceException._(
        failedToStartError, 'Failed to start Dart Development Service');
  }

  factory DartDevelopmentServiceException._connectionError(String message) {
    return DartDevelopmentServiceException._(connectionError, message);
  }

  DartDevelopmentServiceException._(this.errorCode, this.message);

  String toString() => 'DartDevelopmentServiceException: $message';

  final int errorCode;
  final String message;
}
