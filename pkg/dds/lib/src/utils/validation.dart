// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Returns `true` if [origin] is a valid origin that is allowed to connect.
///
/// Loopback addresses (localhost, 127.0.0.1, ::1) are always allowed.
///
/// If [allowedUris] is provided, connections matching the host and port of any
/// URI in the list are allowed.
///
/// If [allowedHosts] and [allowedPort] are provided, connections matching any
/// host in [allowedHosts] with the specified [allowedPort] are allowed.
bool isAllowedOrigin(
  String origin, {
  List<String> allowedHosts = const [],
  int? allowedPort,
  List<Uri> allowedUris = const [],
}) {
  Uri uri;
  try {
    // The Origin/Host headers are user-controlled and could contain
    // malformed URIs, so we must guard against parsing failures.
    //
    // Note: If origin doesn't start with a scheme, Uri.parse might not parse it
    // correctly as a URI with a host. However, Origin headers always have a
    // scheme (http:// or https://), and we prepend one when validating Host headers.
    uri = Uri.parse(origin);
  } catch (_) {
    return false;
  }

  final host = uri.host;
  // Loopback is always allowed.
  if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
    return true;
  }

  // Check allowed URIs.
  for (final allowedUri in allowedUris) {
    if (host == allowedUri.host && uri.port == allowedUri.port) {
      return true;
    }
  }

  // Check allowed hosts with specific port.
  if (allowedPort != null) {
    for (final allowedHost in allowedHosts) {
      if (host == allowedHost && uri.port == allowedPort) {
        return true;
      }
    }
  }

  return false;
}

/// Returns `true` if [hostHeader] is a valid host header value that is allowed.
bool isAllowedHost(
  String hostHeader, {
  List<String> allowedHosts = const [],
  int? allowedPort,
  List<Uri> allowedUris = const [],
}) {
  // Host header might not have a scheme, so prepend http:// to parse it as an origin.
  return isAllowedOrigin(
    'http://$hostHeader',
    allowedHosts: allowedHosts,
    allowedPort: allowedPort,
    allowedUris: allowedUris,
  );
}
