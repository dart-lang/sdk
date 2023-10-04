// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'dylib_utils.dart';

// Runs a simple HTTP GET request using a native HTTP library that runs
// the request on a background thread.
Future<String> httpGet(String uri) async {
  // Create the NativeCallable.listener.
  final completer = Completer<String>();
  void onResponse(Pointer<Utf8> responsePointer) {
    completer.complete(responsePointer.toDartString());
    calloc.free(responsePointer);
  }

  final callback = NativeCallable<HttpCallback>.listener(onResponse);

  // Invoke the native HTTP API. Our example HTTP library runs our GET
  // request on a background thread, and calls the callback on that same
  // thread when it receives the response.
  final uriPointer = uri.toNativeUtf8();
  nativeHttpGet(uriPointer, callback.nativeFunction);
  calloc.free(uriPointer);

  // Wait for the response.
  final response = await completer.future;

  // Remember to close the NativeCallable once the native API is finished
  // with it, otherwise this isolate will stay alive indefinitely.
  callback.close();

  return response;
}

// Start a HTTP server on a background thread.
void httpServe(void Function(String) onRequest) {
  // Create the NativeCallable.listener.
  void onNativeRequest(Pointer<Utf8> requestPointer) {
    onRequest(requestPointer.toDartString());
    calloc.free(requestPointer);
  }

  final callback = NativeCallable<HttpCallback>.listener(onNativeRequest);

  // Invoke the native function to start the HTTP server. Our example
  // HTTP library will start a server on a background thread, and pass
  // any requests it receives to out callback.
  nativeHttpServe(callback.nativeFunction);

  // The server will run indefinitely, and the callback needs to stay
  // alive for that whole time, so we can't close the callback here.
  // But we also don't want the callback to keep the isolate alive
  // forever, so we set keepIsolateAlive to false.
  callback.keepIsolateAlive = false;
}

// Load the native functions from a DynamicLibrary.
late final DynamicLibrary dylib = dlopenPlatformSpecific('fake_http', paths: [
  Platform.script.resolve('../lib/'),
  Uri.file(Platform.resolvedExecutable),
]);
typedef HttpCallback = Void Function(Pointer<Utf8>);

typedef HttpGetFunction = void Function(
    Pointer<Utf8>, Pointer<NativeFunction<HttpCallback>>);
typedef HttpGetNativeFunction = Void Function(
    Pointer<Utf8>, Pointer<NativeFunction<HttpCallback>>);
final nativeHttpGet =
    dylib.lookupFunction<HttpGetNativeFunction, HttpGetFunction>('http_get');

typedef HttpServeFunction = void Function(
    Pointer<NativeFunction<HttpCallback>>);
typedef HttpServeNativeFunction = Void Function(
    Pointer<NativeFunction<HttpCallback>>);
final nativeHttpServe = dylib
    .lookupFunction<HttpServeNativeFunction, HttpServeFunction>('http_serve');

Future<void> main() async {
  print('Sending GET request...');
  final response = await httpGet('http://example.com');
  print('Received a response: $response');

  print('Starting HTTP server...');
  httpServe((String request) {
    print('Received a request: $request');
  });

  await Future.delayed(Duration(seconds: 10));
  print('All done');
}
