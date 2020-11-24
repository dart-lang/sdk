// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Sample illustrating resources are not cleaned up when isolate is shutdown.

import 'dart:io';
import "dart:isolate";
import 'dart:ffi';

import 'package:expect/expect.dart';

import 'pool.dart';
import '../dylib_utils.dart';

void main() {
  final receiveFromHelper = ReceivePort();

  Isolate.spawn(helperIsolateMain, receiveFromHelper.sendPort)
      .then((helperIsolate) {
    helperIsolate.addOnExitListener(
      receiveFromHelper.sendPort,
    );
    print("Main: Helper started.");
    Pointer<SomeResource> resource = nullptr;
    receiveFromHelper.listen((message) {
      if (message is int) {
        resource = Pointer<SomeResource>.fromAddress(message);
        print("Main: Received resource from helper: $resource.");
        print("Main: Shutting down helper.");
        helperIsolate.kill(priority: Isolate.immediate);
      } else {
        // Isolate kill message.
        Expect.isNull(message);
        print("Main: Helper is shut down.");
        print(
            "Main: Trying to use resource after isolate that was supposed to free it was shut down.");
        useResource(resource);
        print("Main: Releasing resource manually.");
        releaseResource(resource);
        print("Main: Shutting down receive port, end of main.");
        receiveFromHelper.close();
      }
    });
  });
}

/// If set to `false`, this sample can segfault due to use after free and
/// double free.
const keepHelperIsolateAlive = true;

void helperIsolateMain(SendPort sendToMain) {
  using((Pool pool) {
    final resource = pool.using(allocateResource(), releaseResource);
    pool.onReleaseAll(() {
      // Will only run print if [keepHelperIsolateAlive] is false.
      print("Helper: Releasing all resources.");
    });
    print("Helper: Resource allocated.");
    useResource(resource);
    print("Helper: Sending resource to main: $resource.");
    sendToMain.send(resource.address);
    print("Helper: Going to sleep.");
    if (keepHelperIsolateAlive) {
      while (true) {
        sleep(Duration(seconds: 1));
        print("Helper: sleeping.");
      }
    }
  });
}

final ffiTestDynamicLibrary =
    dlopenPlatformSpecific("ffi_test_dynamic_library");

final allocateResource = ffiTestDynamicLibrary.lookupFunction<
    Pointer<SomeResource> Function(),
    Pointer<SomeResource> Function()>("AllocateResource");

final useResource = ffiTestDynamicLibrary.lookupFunction<
    Void Function(Pointer<SomeResource>),
    void Function(Pointer<SomeResource>)>("UseResource");

final releaseResource = ffiTestDynamicLibrary.lookupFunction<
    Void Function(Pointer<SomeResource>),
    void Function(Pointer<SomeResource>)>("ReleaseResource");

/// Represents some opaque resource being managed by a library.
class SomeResource extends Struct {}
