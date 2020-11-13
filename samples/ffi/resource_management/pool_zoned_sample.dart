// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Sample illustrating resource management with an implicit pool in the zone.

// @dart = 2.9

import 'dart:ffi';

import 'package:expect/expect.dart';

import 'pool.dart';
import '../dylib_utils.dart';

main() {
  final ffiTestDynamicLibrary =
      dlopenPlatformSpecific("ffi_test_dynamic_library");

  final MemMove = ffiTestDynamicLibrary.lookupFunction<
      Void Function(Pointer<Void>, Pointer<Void>, IntPtr),
      void Function(Pointer<Void>, Pointer<Void>, int)>("MemMove");

  // To ensure resources are freed, wrap them in a [using] call.
  usePool(() {
    final p = currentPool.allocate<Int64>(count: 2);
    p[0] = 24;
    MemMove(p.elementAt(1).cast<Void>(), p.cast<Void>(), sizeOf<Int64>());
    print(p[1]);
    Expect.equals(24, p[1]);
  });

  // Resources are freed also when abnormal control flow occurs.
  try {
    usePool(() {
      final p = currentPool.allocate<Int64>(count: 2);
      p[0] = 25;
      MemMove(p.elementAt(1).cast<Void>(), p.cast<Void>(), 8);
      print(p[1]);
      Expect.equals(25, p[1]);
      throw Exception("Some random exception");
    });
  } on RethrownError catch (e) {
    // Note that exceptions are wrapped when using zones.
    print("Caught exception: ${e.original}");
  }

  // In a pool multiple resources can be allocated, which will all be freed
  // at the end of the scope.
  usePool(() {
    final p = currentPool.allocate<Int64>(count: 2);
    final p2 = currentPool.allocate<Int64>(count: 2);
    p[0] = 1;
    p[1] = 2;
    MemMove(p2.cast<Void>(), p.cast<Void>(), 2 * sizeOf<Int64>());
    Expect.equals(1, p2[0]);
    Expect.equals(2, p2[1]);
  });

  // If the resource allocation happens in a different scope, it is in the
  // same zone, so it's lifetime is automatically managed by the pool.
  f1() {
    return currentPool.allocate<Int64>(count: 2);
  }

  usePool(() {
    final p = f1();
    final p2 = f1();
    p[0] = 1;
    p[1] = 2;
    MemMove(p2.cast<Void>(), p.cast<Void>(), 2 * sizeOf<Int64>());
    Expect.equals(1, p2[0]);
    Expect.equals(2, p2[1]);
  });

  // Using Strings.
  usePool(() {
    final p = "Hello world!".toUtf8(currentPool);
    print(p.contents());
  });

  final allocateResource = ffiTestDynamicLibrary.lookupFunction<
      Pointer<SomeResource> Function(),
      Pointer<SomeResource> Function()>("AllocateResource");

  final useResource = ffiTestDynamicLibrary.lookupFunction<
      Void Function(Pointer<SomeResource>),
      void Function(Pointer<SomeResource>)>("UseResource");

  final releaseResource = ffiTestDynamicLibrary.lookupFunction<
      Void Function(Pointer<SomeResource>),
      void Function(Pointer<SomeResource>)>("ReleaseResource");

  // Using an FFI call to release a resource.
  usePool(() {
    final r = currentPool.using(allocateResource(), releaseResource);
    useResource(r);
  });

  // Using an FFI call to release a resource with abnormal control flow.
  try {
    usePool(() {
      final r = currentPool.using(allocateResource(), releaseResource);
      useResource(r);

      throw Exception("Some random exception");
    });
    // Resource has been freed.
  } on RethrownError catch (e) {
    // Note that exceptions are wrapped when using zones.
    print("Caught exception: ${e.original}");
  }
}

/// Represents some opaque resource being managed by a library.
class SomeResource extends Struct {}
