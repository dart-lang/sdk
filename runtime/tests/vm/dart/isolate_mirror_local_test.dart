// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for checking implemention of IsolateMirror when
// inspecting the current isolate.

#library('isolate_mirror_local_test');

#import('dart:isolate');
#import('dart:mirrors');

ReceivePort rp;
int global_var = 0;

// This function will be invoked reflectively.
int function(int x) {
  global_var = x;
  return x + 1;
}

void testRootLibraryMirror(LibraryMirror lib_mirror) {
  Expect.equals('isolate_mirror_local_test', lib_mirror.simpleName);
  Expect.isTrue(lib_mirror.url.contains('isolate_mirror_local_test.dart'));

  // Test library invocation.
  Expect.equals(0, global_var);
  lib_mirror.invoke('function', [ 123 ]).then(
      (InstanceMirror retval) {
        Expect.equals(123, global_var);
        Expect.equals(124, retval.simpleValue);
        rp.close();
      });
}

void testLibrariesMap(Map libraries) {
  // Just look for a couple of well-known libs.
  LibraryMirror core_lib = libraries['dart:core'];
  Expect.isTrue(core_lib is LibraryMirror);

  LibraryMirror mirror_lib = libraries['dart:mirrors'];
  Expect.isTrue(mirror_lib is LibraryMirror);
}

void testIsolateMirror(IsolateMirror mirror) {
  Expect.isTrue(mirror.debugName.contains('main'));
  testRootLibraryMirror(mirror.rootLibrary);
  testLibrariesMap(mirror.libraries);
}

void main() {
  // Test that an isolate can reflect on itself.
  rp = new ReceivePort();
  isolateMirrorOf(rp.toSendPort()).then(testIsolateMirror);
}
