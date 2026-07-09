// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <atomic>
#include <chrono>
#include <cstring>
#include <thread>

#if defined(_WIN32)
#define DART_EXPORT extern "C" __declspec(dllexport)
#else
#define DART_EXPORT                                                            \
  extern "C" __attribute__((visibility("default"))) __attribute((used))
#endif

constexpr char kExampleRequest[] = R"(
GET / HTTP/1.1
Host: www.example.com
)";

constexpr char kExampleResponse[] = R"(
HTTP/1.1 200 OK
Content-Length: 54
Content-Type: text/html; charset=UTF-8

<html>
  <body>
    Hello world!
  </body>
</html>
)";

DART_EXPORT void http_get(const char* uri, void (*onResponse)(const char*)) {
  std::thread([onResponse]() {
    std::this_thread::sleep_for(std::chrono::seconds(3));
    onResponse(kExampleResponse);
  }).detach();
}

std::atomic<bool> stop_requested = false;
std::thread* server = nullptr;

DART_EXPORT void http_start_serving(void (*onRequest)(const char*)) {
  server = new std::thread([onRequest]() {
    while (!stop_requested) {
      std::this_thread::sleep_for(std::chrono::seconds(1));
      onRequest(kExampleRequest);
    }
  });
}

DART_EXPORT void http_stop_serving() {
  if (server != nullptr) {
    stop_requested = true;
    server->join();
    delete server;
    server = nullptr;
  }
}