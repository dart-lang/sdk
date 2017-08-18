// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void testUriCombi() {
  var schemes = ["", "file", "ws", "ftp"];
  var fragments = ["", "#", "#f", "#fragment", "#l:?/"];
  var queries = ["", "?", "?q", "?query", "?q:/"];
  var paths = ["/", "/x", "/x/y", "/x/y/", "/x:y", "x", "x/y", "x/y/"];
  var userInfos = ["", "x", "xxx", "x:4", "xxx:444", "x:4:x"];
  var hosts = ["", "h", "hhh", "h:4", "hhh:444", "[::1.2.3.4]"];

  void check(uriString, scheme, fragment, query, path, user, host) {
    for (var uri in [
      Uri.parse(uriString),
      Uri.parse(">\u{10000}>$uriString<\u{10000}<", 4, uriString.length + 4),
      Uri.parse(
          "http://example.com/$uriString#?:/[]\"", 19, uriString.length + 19),
      Uri.parse(uriString * 3, uriString.length, uriString.length * 2)
    ]) {
      String name = "$uriString -> $uri";
      Expect.equals(scheme, uri.scheme, name);
      var uriFragment = uri.fragment;
      if (fragment.startsWith('#')) uriFragment = "#$uriFragment";
      Expect.equals(fragment, uriFragment, name);
      var uriQuery = uri.query;
      if (query.startsWith('?')) uriQuery = "?$uriQuery";
      Expect.equals(query, uriQuery, name);
      Expect.equals(path, uri.path, name);
      Expect.equals(user, uri.userInfo, name);
      var uriHost = uri.host;
      if (host.startsWith("[")) uriHost = "[$uriHost]";
      if (uri.port != 0) uriHost += ":${uri.port}";
      Expect.equals(host, uriHost, name);
    }
  }

  for (var scheme in schemes) {
    for (var fragment in fragments) {
      for (var query in queries) {
        for (var path in paths) {
          // File scheme URIs always get a leading slash.
          if (scheme == "file" && !path.startsWith('/')) continue;
          for (var user in userInfos) {
            for (var host in hosts) {
              var auth = host;
              var s = scheme;
              if (user.isNotEmpty) auth = "$user@$auth";
              if (auth.isNotEmpty) auth = "//$auth";
              if (auth.isNotEmpty && !path.startsWith('/')) continue;
              check(
                  "$scheme${scheme.isEmpty ? "" : ":"}"
                  "$auth$path$query$fragment",
                  scheme,
                  fragment,
                  query,
                  path,
                  user,
                  host);
            }
          }
        }
      }
    }
  }
}

void main() {
  testUriCombi();
}
