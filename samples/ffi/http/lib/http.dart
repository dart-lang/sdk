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
// Returns a function that should be called to stop the server.
Function httpServe(void Function(String) onRequest) {
  // Create the NativeCallable.listener.
  void onNativeRequest(Pointer<Utf8> requestPointer) {
    onRequest(requestPointer.toDartString());
  }

  final callback = NativeCallable<HttpCallback>.listener(onNativeRequest);

  // Invoke the native function to start the HTTP server. Our example
  // HTTP library will start a server on a background thread, and pass
  // any requests it receives to out callback.
  nativeHttpStartServing(callback.nativeFunction);

  return () {
      nativeHttpStopServing();
      callback.close();
  };
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

typedef HttpStartServingFunction = bool Function(
    Pointer<NativeFunction<HttpCallback>>);
typedef HttpStartServingNativeFunction = Bool Function(
    Pointer<NativeFunction<HttpCallback>>);
final nativeHttpStartServing = dylib
    .lookupFunction<HttpStartServingNativeFunction, HttpStartServingFunction>(
  'http_start_serving',
);

typedef HttpStopServingFunction = void Function();
typedef HttpStopServingNativeFunction = Void Function();
final nativeHttpStopServing = dylib
    .lookupFunction<HttpStopServingNativeFunction, HttpStopServingFunction>(
  'http_stop_serving',
);

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
