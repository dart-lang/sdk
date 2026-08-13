// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var K = 1024;
var SIZE = 256 * K;

var runInt8ToInt8 = (function() {
  var a1, a2;

  function setup() {
    var storage = new Int8Array(SIZE);
    var buffer = storage.buffer;
    a1 = new Int8Array(buffer, 0, buffer.byteLength);
    a2 = new Int8Array(buffer, 8, buffer.byteLength - 8);

    for (var i = 0; i < a1.length; i++) a1[i] = i;
  }

  function run() {
    a1.set(a2, 0);
    var check = a1[a1.length - 8 - 1];
    if (check != -1) throw 'Bad ' + check;
  }

  setup();
  return run;
})();

var runInt8ToUint8Clamped = (function() {
  var a1, a2;

  function setup() {
    a1 = new Uint8ClampedArray(SIZE);
    a2 = new Int8Array(SIZE);

    for (var i = 0; i < a2.length; i++) a2[i] = i;
  }

  function run() {
    a1.set(a2, 0);
    var check = a1[100];
    if (check != 100) throw 'Bad ' + check;
    check = a1[200];
    if (check != 0) throw 'Bad ' + check;  // 200 = -56 clipped to 0.
  }

  setup();
  return run;
})();

var runByteSwap = (function() {
  var a8 = new Int8Array((SIZE / 16) | 0);

  function setup() {
    for (var i = 0; i < a8.length; i++) a8[i] = i;
  }

  function check(e0, e1, e2, e3) {
    var a0 = a8[0];
    var a1 = a8[1];
    var a2 = a8[2];
    var a3 = a8[3];
    if (a0 != e0 || a1 != e1 || a2 != e2 || a3 != e3) {
      throw 'Bad: ' + [a0, a1, a2, a3] + ', expected ' + [e0, e1, e2, e3];
    }
  }

  function run() {
    var b = new DataView(a8.buffer);
    var i, e;

    // Do several passes over the data, reading and writing in different widths
    // with different endiannesses.

    for (i = 0; i < b.byteLength; i += 4) {
      e = b.getInt32(i);          // Implicit BIG_ENDIAN.
      b.setInt32(i, e, true);     // LITTLE_ENDIAN
    }
    check(3, 2, 1, 0);

    for (i = 0; i < b.byteLength; i += 2) {
      e = b.getInt16(i, false);   // BIG_ENDIAN
      b.setInt16(i, e, true);     // LITTLE_ENDIAN
    }
    check(2, 3, 0, 1);

    for (i = 0; i < b.byteLength; i += 4) {
      e = b.getUint32(i, true);   // LITTLE_ENDIAN
      b.setUint32(i, e);          // Implicit BIG_ENDIAN.
    }
    check(1, 0, 3, 2);

    for (i = 0; i < b.byteLength; i += 2) {
      e = b.getUint16(i, true);   // LITTLE_ENDIAN
      b.setUint16(i, e, false);   // BIG_ENDIAN
    }
    check(0, 1, 2, 3);  // Back to normal for the next run().
  }

  setup();
  return run;
})();

Benchmark.report("TypedDataCopy.Int8ViewToInt8View", runInt8ToInt8);
// Yes, these are the same:
Benchmark.report("TypedDataCopy.Int8ToInt8", runInt8ToInt8);
Benchmark.report("TypedDataCopy.Int8ViewToInt8", runInt8ToInt8);

Benchmark.report("TypedDataCopy.Int8ToUint8Clamped", runInt8ToUint8Clamped);

Benchmark.report("TypedDataCopy.ByteSwap", runByteSwap);
