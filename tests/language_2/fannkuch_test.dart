// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// The Great Computer Language Shootout
// http://shootout.alioth.debian.org/
// Ported from JavaScript contributed by Isaac Gouy.
// Description: Repeatedly access a tiny integer-sequence.

import "package:expect/expect.dart";

class FannkuchTest {
  static fannkuch(n) {
    var p = new List(n), q = new List(n), s = new List(n);
    var sign = 1, maxflips = 0, sum = 0, m = n - 1;
    for (var i = 0; i < n; i++) {
      p[i] = i;
      q[i] = i;
      s[i] = i;
    }
    do {
      // Copy and flip.
      var q0 = p[0]; // Cache 0th element.
      if (q0 != 0) {
        for (var i = 1; i < n; i++) q[i] = p[i]; // Work on a copy.
        var flips = 1;
        do {
          var qq = q[q0];
          if (qq == 0) {
            // ... until 0th element is 0.
            sum += sign * flips;
            if (flips > maxflips) maxflips = flips; // New maximum?
            break;
          }
          q[q0] = q0;
          if (q0 >= 3) {
            var i = 1, j = q0 - 1, t;
            do {
              t = q[i];
              q[i] = q[j];
              q[j] = t;
              i++;
              j--;
            } while (i < j);
          }
          q0 = qq;
          flips++;
        } while (true);
      }
      if (sign == 1) {
        var t = p[1];
        p[1] = p[0];
        p[0] = t;
        sign = -1; // Rotate 0<-1.
      } else {
        // Rotate 0<-1 and 0<-1<-2.
        var t = p[1];
        p[1] = p[2];
        p[2] = t;
        sign = 1;
        for (var i = 2; i < n; i++) {
          var sx = s[i];
          if (sx != 0) {
            s[i] = sx - 1;
            break;
          }
          if (i == m) {
            return [sum, maxflips];
          }
          s[i] = i;
          // Rotate 0<-...<-i+1.
          t = p[0];
          for (var j = 0; j <= i; j++) {
            p[j] = p[j + 1];
          }
          p[i + 1] = t;
        }
      }
    } while (true);
  }

  static testMain() {
    var n = 6;
    var pf = fannkuch(n);
    Expect.equals(49, pf[0]);
    Expect.equals(10, pf[1]);
    print("${pf[0]}\nPfannkuchen($n) = ${pf[1]}");
  }
}

main() {
  FannkuchTest.testMain();
}
