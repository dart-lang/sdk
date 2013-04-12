// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:io";
import "dart:uri";

expect(expected, String uri, environment) {
  Expect.equals(expected,
                HttpClient.findProxyFromEnvironment(Uri.parse(uri),
                                                    environment: environment));
}

expectDirect(String uri, environment) {
  Expect.equals("DIRECT",
                HttpClient.findProxyFromEnvironment(Uri.parse(uri),
                                                    environment: environment));
}

main() {
  expectDirect("http://www.google.com", {});
  expect("PROXY www.proxy.com:1080",
         "http://www.google.com",
         {"http_proxy": "www.proxy.com"});
  expect("PROXY www.proxys.com:1080",
         "https://www.google.com",
         {"https_proxy": "www.proxys.com"});
  expect("PROXY www.proxy.com:8080",
         "http://www.google.com",
         {"http_proxy": "www.proxy.com:8080"});
  expect("PROXY www.proxys.com:8080",
         "https://www.google.com",
         {"https_proxy": "www.proxys.com:8080"});
  expect("PROXY www.proxy.com:8080",
         "http://www.google.com",
         {"http_proxy": "www.proxy.com:8080",
          "https_proxy": "www.proxy.com:8080"});
  expect("PROXY www.proxys.com:8080",
         "https://www.google.com",
         {"http_proxy": "www.proxy.com:8080",
          "https_proxy": "www.proxys.com:8080"});
  expectDirect("http://www.google.com",
               {"http_proxy": "www.proxy.com:8080",
                "no_proxy": "www.google.com"});
  expectDirect("http://www.google.com",
               {"http_proxy": "www.proxy.com:8080",
                "no_proxy": "google.com"});
  expectDirect("http://www.google.com",
               {"http_proxy": "www.proxy.com:8080",
                "no_proxy": ".com"});
  expectDirect("http://www.google.com",
               {"http_proxy": "www.proxy.com:8080",
                "no_proxy": ",,  , www.google.edu,,.com    "});
  expectDirect("http://www.google.edu",
               {"http_proxy": "www.proxy.com:8080",
                "no_proxy": ",,  , www.google.edu,,.com    "});
  expectDirect("http://www.google.com",
               {"https_proxy": "www.proxy.com:8080"});
}
