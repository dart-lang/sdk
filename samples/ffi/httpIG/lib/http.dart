// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'dylib_utils.dart';

Function (Pointer<Utf8>) createGetSender(SendPort sendPort) {
  return (Pointer<Utf8> responsePointer) {
    final typedList = responsePointer.cast<Uint8>().asTypedList(
          responsePointer.length,
        );
    sendPort.send(utf8.decode(typedList));
  };
}

// Runs a simple HTTP GET request using a native HTTP library that runs
// the request on a background thread.
Future<String> httpGet(String uri) async {
  // Create the NativeCallable.listener.
  final completer = Completer<String>();
  final ReceivePort rp = ReceivePort()
    ..listen(
      (string) {
        completer.complete(string);
      },
      onError: (e, st) {
        print('httpGet receiver get error $e $st');
      },
    );
  final callback = NativeCallable<HttpCallback>.isolateGroupBound(
      createGetSender(rp.sendPort));

  // Invoke the native HTTP API. Our example HTTP library runs our GET
  // request on a background thread, and calls the callback on that same
  // thread when it receives the response.
  final uriPointer = uri.toNativeUtf8();
  nativeHttpGet(uriPointer, callback.nativeFunction);
  calloc.free(uriPointer);

  // Wait for the response.
  final response = await completer.future;

  rp.close();
  callback.close();

  return response;
}

@pragma('vm:shared')
late int counter;

Function (Pointer<Utf8>) createServeSender(SendPort sendPort) {
  return (Pointer<Utf8> requestPointer) {
    counter++;
    final typedList = requestPointer.cast<Uint8>().asTypedList(
          requestPointer.length,
        );
    sendPort.send(utf8.decode(typedList));
  };
}

// Start a HTTP server on a background thread.
ReceivePort httpServe(void Function(String) onRequest) {
  counter = 0;
  final rp = ReceivePort();
  final callback = NativeCallable<HttpCallback>.isolateGroupBound(
      createServeSender(rp.sendPort));
  rp.listen(
    (s) {
      print('httpServe counter: $counter');
      onRequest(s);
    },
    onError: (e, st) {
      print('httpServe receiver get error $e $st');
    },
    onDone: () {
      nativeHttpStopServing();
      callback.close();
    },
  );

  // Invoke the native function to start the HTTP server. Our example
  // HTTP library will start a server on a background thread, and pass
  // any requests it receives to out callback.
  nativeHttpStartServing(callback.nativeFunction);

  return rp;
}

// Load the native functions from a DynamicLibrary.
late final DynamicLibrary dylib = dlopenPlatformSpecific(
  'fake_httpIG',
  paths: [
    Platform.script.resolve('../lib/'),
    Uri.file(Platform.resolvedExecutable),
  ],
);
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
  final rpServer = httpServe((String request) {
    print('Received a request: $request');
  });

  await Future.delayed(Duration(seconds: 10));
  print('All done');

  rpServer.close();
}
