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
    // scheme (http:// or https://), and we prepend one when validating Host
    // headers.
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
  // Host header might not have a scheme, so prepend http:// to parse it as
  // an origin.
  return isAllowedOrigin(
    'http://$hostHeader',
    allowedHosts: allowedHosts,
    allowedPort: allowedPort,
    allowedUris: allowedUris,
  );
}

/// The `Sec-Fetch-Site` forbidden request header sent by browsers on requests
/// to potentially trustworthy origins (loopback or HTTPS).
const secFetchSiteHeader = 'Sec-Fetch-Site';

/// Allowed values for the `Sec-Fetch-Site` request header when `Origin` is
/// omitted.
const _allowedSecFetchSites = <String>{'same-origin', 'none'};

/// Returns `true` if [secFetchSite] is allowed when the `Origin` header is
/// omitted.
///
/// Browsers omit `Origin` on same-origin `GET` requests and on cross-origin
/// no-CORS `GET` requests (`<img>`, `<script>`, `fetch(mode: 'no-cors')`),
/// but attach `Sec-Fetch-Site` on requests to potentially trustworthy origins
/// (`127.0.0.1`, `[::1]`, `localhost`, and HTTPS). Note that plain-HTTP
/// non-loopback binds (e.g., `--host <LAN IP>`) are not potentially
/// trustworthy origins and do not receive `Sec-Fetch-Site` on no-CORS `GET`
/// requests.
///
/// When `Sec-Fetch-Site` is present, only `'same-origin'` (requests from the
/// served DevTools frontend itself) and `'none'` (direct user navigation) are
/// permitted. When `Sec-Fetch-Site` is absent (`null`), the request is from a
/// non-browser HTTP client (or an untrustworthy non-loopback HTTP origin) and
/// is permitted.
bool isAllowedSecFetchSite(String? secFetchSite) {
  if (secFetchSite == null) {
    return true;
  }
  return _allowedSecFetchSites.contains(secFetchSite.trim().toLowerCase());
}
