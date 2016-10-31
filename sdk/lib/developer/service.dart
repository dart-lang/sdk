// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.developer;

/// Information about the service protocol.
class ServiceProtocolInfo {
  /// The major version of the protocol. If the running Dart environment does
  /// not support the service protocol, this is 0.
  final int majorVersion = _getServiceMajorVersion();
  /// The minor version of the protocol. If the running Dart environment does
  /// not support the service protocol, this is 0.
  final int minorVersion = _getServiceMinorVersion();
  /// The Uri to access the service. If the web server is not running, this
  /// will be null.
  final Uri serverUri;

  ServiceProtocolInfo(this.serverUri);

  String toString() {
    if (serverUri != null) {
      return 'Dart VM Service Protocol v$majorVersion.$minorVersion '
             'listening on $serverUri';
    } else {
      return 'Dart VM Service Protocol v$majorVersion.$minorVersion';
    }
  }
}

/// Access information about the service protocol and control the web server.
class Service {
  /// Get information about the service protocol.
  static Future<ServiceProtocolInfo> getInfo() async {
    // Port to receive response from service isolate.
    final RawReceivePort receivePort = new RawReceivePort();
    final Completer<Uri> uriCompleter = new Completer<Uri>();
    receivePort.handler = (Uri uri) => uriCompleter.complete(uri);
    // Request the information from the service isolate.
    _getServerInfo(receivePort.sendPort);
    // Await the response from the service isolate.
    Uri uri = await uriCompleter.future;
    // Close the port.
    receivePort.close();
    return new ServiceProtocolInfo(uri);
  }

  /// Control the web server that the service protocol is accessed through.
  static Future<ServiceProtocolInfo> controlWebServer(
      {bool enable: false}) async {
    if (enable is! bool) {
      throw new ArgumentError.value(enable,
                                    'enable',
                                    'Must be a bool');
    }
    // Port to receive response from service isolate.
    final RawReceivePort receivePort = new RawReceivePort();
    final Completer<Uri> uriCompleter = new Completer<Uri>();
    receivePort.handler = (Uri uri) => uriCompleter.complete(uri);
    // Request the information from the service isolate.
    _webServerControl(receivePort.sendPort, enable);
    // Await the response from the service isolate.
    Uri uri = await uriCompleter.future;
    // Close the port.
    receivePort.close();
    return new ServiceProtocolInfo(uri);
  }
}

/// [sp] will receive a Uri or null.
external void _getServerInfo(SendPort sp);

/// [sp] will receive a Uri or null.
external void _webServerControl(SendPort sp, bool enable);

/// Returns the major version of the service protocol.
external int _getServiceMajorVersion();

/// Returns the minor version of the service protocol.
external int _getServiceMinorVersion();

