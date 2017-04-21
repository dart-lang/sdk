// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the ParalleMoveResolver in the VM uses valid registers
// when requiring scratch registers.

main() {
  // Iterate enough to ensure optimizing `spillingMethod`.
  for (int i = 0; i < 100000; i++) {
    spillingMethod(i, () => 0);
  }
}

spillingMethod(what, obfuscate) {
  // Define lots of variables to get a few in stack.
  var a = obfuscate();
  var b = obfuscate();
  var c = obfuscate();
  var d = obfuscate();
  var e = obfuscate();
  var f = obfuscate();
  var g = obfuscate();
  var h = obfuscate();
  var i = obfuscate();
  var j = obfuscate();
  var k = obfuscate();
  var l = obfuscate();
  var m = obfuscate();
  var n = obfuscate();
  var o = obfuscate();
  var p = obfuscate();
  var q = obfuscate();
  var r = obfuscate();
  var s = obfuscate();
  var t = obfuscate();
  var u = obfuscate();
  var v = obfuscate();

  // Swap all variables, in the hope of a memory <-> memory swap operation.
  while (what == 42) {
    a = b;
    b = a;
    c = d;
    d = c;
    e = f;
    f = e;
    g = h;
    h = g;
    i = j;
    j = i;
    k = l;
    l = k;
    m = n;
    n = m;
    o = p;
    p = o;
    q = r;
    r = q;
    s = t;
    t = s;
    u = v;
    v = u;
    what++;
  }

  // Keep all variables alive.
  return a +
      b +
      c +
      d +
      e +
      f +
      g +
      h +
      i +
      j +
      k +
      l +
      m +
      n +
      o +
      p +
      q +
      r +
      s +
      t +
      u +
      v;
}
