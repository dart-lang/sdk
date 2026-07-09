// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:ffi";

@Native<Pointer Function(IntPtr)>(symbol: 'malloc')
external Pointer malloc(int size);
@Native<Void Function(Pointer)>(symbol: 'free')
external void free(Pointer ptr);

@pragma("vm:never-inline")
@pragma("vm:entry-point")
escape(x) {}

main() {
  var p1 = malloc(1).cast<Uint8>();
  p1[0] = 0;
  escape(p1); // No load-store forwarding.
  print(p1[0]);
  free(p1);

  var p2 = malloc(2).cast<Uint16>();
  p2[0] = 0;
  escape(p2); // No load-store forwarding.
  print(p2[0]);
  free(p2);

  var p4 = malloc(4).cast<Uint32>();
  p4[0] = 0;
  escape(p4); // No load-store forwarding.
  print(p4[0]);
  free(p4);

  var p8 = malloc(8).cast<Uint64>();
  p8[0] = 0;
  escape(p8); // No load-store forwarding.
  print(p8[0]);
  free(p8);

  var pf4 = malloc(4).cast<Float>();
  pf4[0] = 0.0;
  escape(pf4); // No load-store forwarding.
  print(pf4[0]);
  free(pf4);

  var pf8 = malloc(8).cast<Double>();
  pf8[0] = 0.0;
  escape(pf8); // No load-store forwarding.
  print(pf8[0]);
  free(pf8);
}
