// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

add<X extends num, Y extends int, Z extends double>(
    num n, int i, double d, X x, Y y, Z z) {
  var n_n = n + n;
  var n_i = n + i;
  var n_d = n + d;
  var n_x = n + x;
  var n_y = n + y;
  var n_z = n + z;

  var i_n = i + n;
  var i_i = i + i;
  var i_d = i + d;
  var i_x = i + x;
  var i_y = i + y;
  var i_z = i + z;

  var d_n = d + n;
  var d_i = d + i;
  var d_d = d + d;
  var d_x = d + x;
  var d_y = d + y;
  var d_z = d + z;

  var x_n = x + n;
  var x_i = x + i;
  var x_d = x + d;
  var x_x = x + x;
  var x_y = x + y;
  var x_z = x + z;

  var y_n = y + n;
  var y_i = y + i;
  var y_d = y + d;
  var y_x = y + x;
  var y_y = y + y;
  var y_z = y + z;

  var z_n = z + n;
  var z_i = z + i;
  var z_d = z + d;
  var z_x = z + x;
  var z_y = z + y;
  var z_z = z + z;
}

sub<X extends num, Y extends int, Z extends double>(
    num n, int i, double d, X x, Y y, Z z) {
  var n_n = n - n;
  var n_i = n - i;
  var n_d = n - d;
  var n_x = n - x;
  var n_y = n - y;
  var n_z = n - z;

  var i_n = i - n;
  var i_i = i - i;
  var i_d = i - d;
  var i_x = i - x;
  var i_y = i - y;
  var i_z = i - z;

  var d_n = d - n;
  var d_i = d - i;
  var d_d = d - d;
  var d_x = d - x;
  var d_y = d - y;
  var d_z = d - z;

  var x_n = x - n;
  var x_i = x - i;
  var x_d = x - d;
  var x_x = x - x;
  var x_y = x - y;
  var x_z = x - z;

  var y_n = y - n;
  var y_i = y - i;
  var y_d = y - d;
  var y_x = y - x;
  var y_y = y - y;
  var y_z = y - z;

  var z_n = z - n;
  var z_i = z - i;
  var z_d = z - d;
  var z_x = z - x;
  var z_y = z - y;
  var z_z = z - z;
}

mul<X extends num, Y extends int, Z extends double>(
    num n, int i, double d, X x, Y y, Z z) {
  var n_n = n * n;
  var n_i = n * i;
  var n_d = n * d;
  var n_x = n * x;
  var n_y = n * y;
  var n_z = n * z;

  var i_n = i * n;
  var i_i = i * i;
  var i_d = i * d;
  var i_x = i * x;
  var i_y = i * y;
  var i_z = i * z;

  var d_n = d * n;
  var d_i = d * i;
  var d_d = d * d;
  var d_x = d * x;
  var d_y = d * y;
  var d_z = d * z;

  var x_n = x * n;
  var x_i = x * i;
  var x_d = x * d;
  var x_x = x * x;
  var x_y = x * y;
  var x_z = x * z;

  var y_n = y * n;
  var y_i = y * i;
  var y_d = y * d;
  var y_x = y * x;
  var y_y = y * y;
  var y_z = y * z;

  var z_n = z * n;
  var z_i = z * i;
  var z_d = z * d;
  var z_x = z * x;
  var z_y = z * y;
  var z_z = z * z;
}

mod<X extends num, Y extends int, Z extends double>(
    num n, int i, double d, X x, Y y, Z z) {
  var n_n = n % n;
  var n_i = n % i;
  var n_d = n % d;
  var n_x = n % x;
  var n_y = n % y;
  var n_z = n % z;

  var i_n = i % n;
  var i_i = i % i;
  var i_d = i % d;
  var i_x = i % x;
  var i_y = i % y;
  var i_z = i % z;

  var d_n = d % n;
  var d_i = d % i;
  var d_d = d % d;
  var d_x = d % x;
  var d_y = d % y;
  var d_z = d % z;

  var x_n = x % n;
  var x_i = x % i;
  var x_d = x % d;
  var x_x = x % x;
  var x_y = x % y;
  var x_z = x % z;

  var y_n = y % n;
  var y_i = y % i;
  var y_d = y % d;
  var y_x = y % x;
  var y_y = y % y;
  var y_z = y % z;

  var z_n = z % n;
  var z_i = z % i;
  var z_d = z % d;
  var z_x = z % x;
  var z_y = z % y;
  var z_z = z % z;
}

remainder<X extends num, Y extends int, Z extends double>(
    num n, int i, double d, X x, Y y, Z z) {
  var n_n = n.remainder(n);
  var n_i = n.remainder(i);
  var n_d = n.remainder(d);
  var n_x = n.remainder(x);
  var n_y = n.remainder(y);
  var n_z = n.remainder(z);

  var i_n = i.remainder(n);
  var i_i = i.remainder(i);
  var i_d = i.remainder(d);
  var i_x = i.remainder(x);
  var i_y = i.remainder(y);
  var i_z = i.remainder(z);

  var d_n = d.remainder(n);
  var d_i = d.remainder(i);
  var d_d = d.remainder(d);
  var d_x = d.remainder(x);
  var d_y = d.remainder(y);
  var d_z = d.remainder(z);

  var x_n = x.remainder(n);
  var x_i = x.remainder(i);
  var x_d = x.remainder(d);
  var x_x = x.remainder(x);
  var x_y = x.remainder(y);
  var x_z = x.remainder(z);

  var y_n = y.remainder(n);
  var y_i = y.remainder(i);
  var y_d = y.remainder(d);
  var y_x = y.remainder(x);
  var y_y = y.remainder(y);
  var y_z = y.remainder(z);

  var z_n = z.remainder(n);
  var z_i = z.remainder(i);
  var z_d = z.remainder(d);
  var z_x = z.remainder(x);
  var z_y = z.remainder(y);
  var z_z = z.remainder(z);
}

clamp<X extends num, Y extends int, Z extends double>(
    num n, int i, double d, X x, Y y, Z z) {
  var n_n_n = n.clamp(n, n);
  var n_i_n = n.clamp(i, n);
  var n_d_n = n.clamp(d, n);
  var n_x_n = n.clamp(x, n);
  var n_y_n = n.clamp(y, n);
  var n_z_n = n.clamp(z, n);

  var n_n_i = n.clamp(n, i);
  var n_i_i = n.clamp(i, i);
  var n_d_i = n.clamp(d, i);
  var n_x_i = n.clamp(x, i);
  var n_y_i = n.clamp(y, i);
  var n_z_i = n.clamp(z, i);

  var n_n_d = n.clamp(n, d);
  var n_i_d = n.clamp(i, d);
  var n_d_d = n.clamp(d, d);
  var n_x_d = n.clamp(x, d);
  var n_y_d = n.clamp(y, d);
  var n_z_d = n.clamp(z, d);

  var n_n_x = n.clamp(n, x);
  var n_i_x = n.clamp(i, x);
  var n_d_x = n.clamp(d, x);
  var n_x_x = n.clamp(x, x);
  var n_y_x = n.clamp(y, x);
  var n_z_x = n.clamp(z, x);

  var n_n_y = n.clamp(n, y);
  var n_i_y = n.clamp(i, y);
  var n_d_y = n.clamp(d, y);
  var n_x_y = n.clamp(x, y);
  var n_y_y = n.clamp(y, y);
  var n_z_y = n.clamp(z, y);

  var n_n_z = n.clamp(n, z);
  var n_i_z = n.clamp(i, z);
  var n_d_z = n.clamp(d, z);
  var n_x_z = n.clamp(x, z);
  var n_y_z = n.clamp(y, z);
  var n_z_z = n.clamp(z, z);

  var i_n_n = i.clamp(n, n);
  var i_i_n = i.clamp(i, n);
  var i_d_n = i.clamp(d, n);
  var i_x_n = i.clamp(x, n);
  var i_y_n = i.clamp(y, n);
  var i_z_n = i.clamp(z, n);

  var i_n_i = i.clamp(n, i);
  var i_i_i = i.clamp(i, i);
  var i_d_i = i.clamp(d, i);
  var i_x_i = i.clamp(x, i);
  var i_y_i = i.clamp(y, i);
  var i_z_i = i.clamp(z, i);

  var i_n_d = i.clamp(n, d);
  var i_i_d = i.clamp(i, d);
  var i_d_d = i.clamp(d, d);
  var i_x_d = i.clamp(x, d);
  var i_y_d = i.clamp(y, d);
  var i_z_d = i.clamp(z, d);

  var i_n_x = i.clamp(n, x);
  var i_i_x = i.clamp(i, x);
  var i_d_x = i.clamp(d, x);
  var i_x_x = i.clamp(x, x);
  var i_y_x = i.clamp(y, x);
  var i_z_x = i.clamp(z, x);

  var i_n_y = i.clamp(n, y);
  var i_i_y = i.clamp(i, y);
  var i_d_y = i.clamp(d, y);
  var i_x_y = i.clamp(x, y);
  var i_y_y = i.clamp(y, y);
  var i_z_y = i.clamp(z, y);

  var i_n_z = i.clamp(n, z);
  var i_i_z = i.clamp(i, z);
  var i_d_z = i.clamp(d, z);
  var i_x_z = i.clamp(x, z);
  var i_y_z = i.clamp(y, z);
  var i_z_z = i.clamp(z, z);

  var d_n_n = d.clamp(n, n);
  var d_i_n = d.clamp(i, n);
  var d_d_n = d.clamp(d, n);
  var d_x_n = d.clamp(x, n);
  var d_y_n = d.clamp(y, n);
  var d_z_n = d.clamp(z, n);

  var d_n_i = d.clamp(n, i);
  var d_i_i = d.clamp(i, i);
  var d_d_i = d.clamp(d, i);
  var d_x_i = d.clamp(x, i);
  var d_y_i = d.clamp(y, i);
  var d_z_i = d.clamp(z, i);

  var d_n_d = d.clamp(n, d);
  var d_i_d = d.clamp(i, d);
  var d_d_d = d.clamp(d, d);
  var d_x_d = d.clamp(x, d);
  var d_y_d = d.clamp(y, d);
  var d_z_d = d.clamp(z, d);

  var d_n_x = d.clamp(n, x);
  var d_i_x = d.clamp(i, x);
  var d_d_x = d.clamp(d, x);
  var d_x_x = d.clamp(x, x);
  var d_y_x = d.clamp(y, x);
  var d_z_x = d.clamp(z, x);

  var d_n_y = d.clamp(n, y);
  var d_i_y = d.clamp(i, y);
  var d_d_y = d.clamp(d, y);
  var d_x_y = d.clamp(x, y);
  var d_y_y = d.clamp(y, y);
  var d_z_y = d.clamp(z, y);

  var d_n_z = d.clamp(n, z);
  var d_i_z = d.clamp(i, z);
  var d_d_z = d.clamp(d, z);
  var d_x_z = d.clamp(x, z);
  var d_y_z = d.clamp(y, z);
  var d_z_z = d.clamp(z, z);

  var x_n_n = x.clamp(n, n);
  var x_i_n = x.clamp(i, n);
  var x_d_n = x.clamp(d, n);
  var x_x_n = x.clamp(x, n);
  var x_y_n = x.clamp(y, n);
  var x_z_n = x.clamp(z, n);

  var x_n_i = x.clamp(n, i);
  var x_i_i = x.clamp(i, i);
  var x_d_i = x.clamp(d, i);
  var x_x_i = x.clamp(x, i);
  var x_y_i = x.clamp(y, i);
  var x_z_i = x.clamp(z, i);

  var x_n_d = x.clamp(n, d);
  var x_i_d = x.clamp(i, d);
  var x_d_d = x.clamp(d, d);
  var x_x_d = x.clamp(x, d);
  var x_y_d = x.clamp(y, d);
  var x_z_d = x.clamp(z, d);

  var x_n_x = x.clamp(n, x);
  var x_i_x = x.clamp(i, x);
  var x_d_x = x.clamp(d, x);
  var x_x_x = x.clamp(x, x);
  var x_y_x = x.clamp(y, x);
  var x_z_x = x.clamp(z, x);

  var x_n_y = x.clamp(n, y);
  var x_i_y = x.clamp(i, y);
  var x_d_y = x.clamp(d, y);
  var x_x_y = x.clamp(x, y);
  var x_y_y = x.clamp(y, y);
  var x_z_y = x.clamp(z, y);

  var x_n_z = x.clamp(n, z);
  var x_i_z = x.clamp(i, z);
  var x_d_z = x.clamp(d, z);
  var x_x_z = x.clamp(x, z);
  var x_y_z = x.clamp(y, z);
  var x_z_z = x.clamp(z, z);

  var y_n_n = y.clamp(n, n);
  var y_i_n = y.clamp(i, n);
  var y_d_n = y.clamp(d, n);
  var y_x_n = y.clamp(x, n);
  var y_y_n = y.clamp(y, n);
  var y_z_n = y.clamp(z, n);

  var y_n_i = y.clamp(n, i);
  var y_i_i = y.clamp(i, i);
  var y_d_i = y.clamp(d, i);
  var y_x_i = y.clamp(x, i);
  var y_y_i = y.clamp(y, i);
  var y_z_i = y.clamp(z, i);

  var y_n_d = y.clamp(n, d);
  var y_i_d = y.clamp(i, d);
  var y_d_d = y.clamp(d, d);
  var y_x_d = y.clamp(x, d);
  var y_y_d = y.clamp(y, d);
  var y_z_d = y.clamp(z, d);

  var y_n_x = y.clamp(n, x);
  var y_i_x = y.clamp(i, x);
  var y_d_x = y.clamp(d, x);
  var y_x_x = y.clamp(x, x);
  var y_y_x = y.clamp(y, x);
  var y_z_x = y.clamp(z, x);

  var y_n_y = y.clamp(n, y);
  var y_i_y = y.clamp(i, y);
  var y_d_y = y.clamp(d, y);
  var y_x_y = y.clamp(x, y);
  var y_y_y = y.clamp(y, y);
  var y_z_y = y.clamp(z, y);

  var y_n_z = y.clamp(n, z);
  var y_i_z = y.clamp(i, z);
  var y_d_z = y.clamp(d, z);
  var y_x_z = y.clamp(x, z);
  var y_y_z = y.clamp(y, z);
  var y_z_z = y.clamp(z, z);

  var z_n_n = z.clamp(n, n);
  var z_i_n = z.clamp(i, n);
  var z_d_n = z.clamp(d, n);
  var z_x_n = z.clamp(x, n);
  var z_y_n = z.clamp(y, n);
  var z_z_n = z.clamp(z, n);

  var z_n_i = z.clamp(n, i);
  var z_i_i = z.clamp(i, i);
  var z_d_i = z.clamp(d, i);
  var z_x_i = z.clamp(x, i);
  var z_y_i = z.clamp(y, i);
  var z_z_i = z.clamp(z, i);

  var z_n_d = z.clamp(n, d);
  var z_i_d = z.clamp(i, d);
  var z_d_d = z.clamp(d, d);
  var z_x_d = z.clamp(x, d);
  var z_y_d = z.clamp(y, d);
  var z_z_d = z.clamp(z, d);

  var z_n_x = z.clamp(n, x);
  var z_i_x = z.clamp(i, x);
  var z_d_x = z.clamp(d, x);
  var z_x_x = z.clamp(x, x);
  var z_y_x = z.clamp(y, x);
  var z_z_x = z.clamp(z, x);

  var z_n_y = z.clamp(n, y);
  var z_i_y = z.clamp(i, y);
  var z_d_y = z.clamp(d, y);
  var z_x_y = z.clamp(x, y);
  var z_y_y = z.clamp(y, y);
  var z_z_y = z.clamp(z, y);

  var z_n_z = z.clamp(n, z);
  var z_i_z = z.clamp(i, z);
  var z_d_z = z.clamp(d, z);
  var z_x_z = z.clamp(x, z);
  var z_y_z = z.clamp(y, z);
  var z_z_z = z.clamp(z, z);
}

main() {}
