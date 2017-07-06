// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "dart:developer";

/// Service protocol is the protocol that a client like the observatory
/// could use to access the services provided by the Dart VM for
/// debugging and inspecting Dart programs. This class encapsulates the
/// version number and Uri for accessing this service.
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

/// Access information about the service protocol and control the web server
/// that provides access to the services provided by the Dart VM for
/// debugging and inspecting Dart programs.
class Service {
  /// Get information about the service protocol (version number and
  /// Uri to access the service).
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
  /// The [enable] argument must be a boolean and is used as a toggle to
  /// enable(true) or disable(false) the web server servicing requests.
  static Future<ServiceProtocolInfo> controlWebServer(
      {bool enable: false}) async {
    if (enable is! bool) {
      throw new ArgumentError.value(enable, 'enable', 'Must be a bool');
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

  /// Returns a [String] token representing the ID of [isolate].
  ///
  /// Returns null if the running Dart environment does not support the service
  /// protocol.
  static String getIsolateID(Isolate isolate) {
    if (isolate is! Isolate) {
      throw new ArgumentError.value(isolate, 'isolate', 'Must be an Isolate');
    }
    return _getIsolateIDFromSendPort(isolate.controlPort);
  }
}

/// [sendPort] will receive a Uri or null.
external void _getServerInfo(SendPort sendPort);

/// [sendPort] will receive a Uri or null.
external void _webServerControl(SendPort sendPort, bool enable);

/// Returns the major version of the service protocol.
external int _getServiceMajorVersion();

/// Returns the minor version of the service protocol.
external int _getServiceMinorVersion();

/// Returns the service id for the isolate that owns [sendPort].
external String _getIsolateIDFromSendPort(SendPort sendPort);
