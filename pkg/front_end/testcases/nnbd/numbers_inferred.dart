// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

T f<T>() => throw 'Unsupported';

add<X extends num, Y extends int, Z extends double>(
    num n, int i, double d, X x, Y y, Z z) {
  num n_n = n + f();
  int n_i = n + f();
  double n_d = n + f();
  X n_x = n + f();
  Y n_y = n + f();
  Z n_z = n + f();

  num i_n = i + f();
  int i_i = i + f();
  double i_d = i + f();
  X i_x = i + f();
  Y i_y = i + f();
  Z i_z = i + f();

  num d_n = d + f();
  int d_i = d + f();
  double d_d = d + f();
  X d_x = d + f();
  Y d_y = d + f();
  Z d_z = d + f();

  num x_n = x + f();
  int x_i = x + f();
  double x_d = x + f();
  X x_x = x + f();
  Y x_y = x + f();
  Z x_z = x + f();

  num y_n = y + f();
  int y_i = y + f();
  double y_d = y + f();
  X y_x = y + f();
  Y y_y = y + f();
  Z y_z = y + f();

  num z_n = z + f();
  int z_i = z + f();
  double z_d = z + f();
  X z_x = z + f();
  Y z_y = z + f();
  Z z_z = z + f();
}

sub<X extends num, Y extends int, Z extends double>(
    num n, int i, double d, X x, Y y, Z z) {
  num n_n = n - f();
  int n_i = n - f();
  double n_d = n - f();
  X n_x = n - f();
  Y n_y = n - f();
  Z n_z = n - f();

  num i_n = i - f();
  int i_i = i - f();
  double i_d = i - f();
  X i_x = i - f();
  Y i_y = i - f();
  Z i_z = i - f();

  num d_n = d - f();
  int d_i = d - f();
  double d_d = d - f();
  X d_x = d - f();
  Y d_y = d - f();
  Z d_z = d - f();

  num x_n = x - f();
  int x_i = x - f();
  double x_d = x - f();
  X x_x = x - f();
  Y x_y = x - f();
  Z x_z = x - f();

  num y_n = y - f();
  int y_i = y - f();
  double y_d = y - f();
  X y_x = y - f();
  Y y_y = y - f();
  Z y_z = y - f();

  num z_n = z - f();
  int z_i = z - f();
  double z_d = z - f();
  X z_x = z - f();
  Y z_y = z - f();
  Z z_z = z - f();
}

mul<X extends num, Y extends int, Z extends double>(
    num n, int i, double d, X x, Y y, Z z) {
  num n_n = n * f();
  int n_i = n * f();
  double n_d = n * f();
  X n_x = n * f();
  Y n_y = n * f();
  Z n_z = n * f();

  num i_n = i * f();
  int i_i = i * f();
  double i_d = i * f();
  X i_x = i * f();
  Y i_y = i * f();
  Z i_z = i * f();

  num d_n = d * f();
  int d_i = d * f();
  double d_d = d * f();
  X d_x = d * f();
  Y d_y = d * f();
  Z d_z = d * f();

  num x_n = x * f();
  int x_i = x * f();
  double x_d = x * f();
  X x_x = x * f();
  Y x_y = x * f();
  Z x_z = x * f();

  num y_n = y * f();
  int y_i = y * f();
  double y_d = y * f();
  X y_x = y * f();
  Y y_y = y * f();
  Z y_z = y * f();

  num z_n = z * f();
  int z_i = z * f();
  double z_d = z * f();
  X z_x = z * f();
  Y z_y = z * f();
  Z z_z = z * f();
}

mod<X extends num, Y extends int, Z extends double>(
    num n, int i, double d, X x, Y y, Z z) {
  num n_n = n % f();
  int n_i = n % f();
  double n_d = n % f();
  X n_x = n % f();
  Y n_y = n % f();
  Z n_z = n % f();

  num i_n = i % f();
  int i_i = i % f();
  double i_d = i % f();
  X i_x = i % f();
  Y i_y = i % f();
  Z i_z = i % f();

  num d_n = d % f();
  int d_i = d % f();
  double d_d = d % f();
  X d_x = d % f();
  Y d_y = d % f();
  Z d_z = d % f();

  num x_n = x % f();
  int x_i = x % f();
  double x_d = x % f();
  X x_x = x % f();
  Y x_y = x % f();
  Z x_z = x % f();

  num y_n = y % f();
  int y_i = y % f();
  double y_d = y % f();
  X y_x = y % f();
  Y y_y = y % f();
  Z y_z = y % f();

  num z_n = z % f();
  int z_i = z % f();
  double z_d = z % f();
  X z_x = z % f();
  Y z_y = z % f();
  Z z_z = z % f();
}

remainder<X extends num, Y extends int, Z extends double>(
    num n, int i, double d, X x, Y y, Z z) {
  var n_n = n.remainder(f());
  int n_i = n.remainder(f());
  double n_d = n.remainder(f());
  X n_x = n.remainder(f());
  Y n_y = n.remainder(f());
  Z n_z = n.remainder(f());

  num i_n = i.remainder(f());
  int i_i = i.remainder(f());
  double i_d = i.remainder(f());
  X i_x = i.remainder(f());
  Y i_y = i.remainder(f());
  Z i_z = i.remainder(f());

  var d_n = d.remainder(f());
  int d_i = d.remainder(f());
  double d_d = d.remainder(f());
  X d_x = d.remainder(f());
  Y d_y = d.remainder(f());
  Z d_z = d.remainder(f());

  var x_n = x.remainder(f());
  int x_i = x.remainder(f());
  double x_d = x.remainder(f());
  X x_x = x.remainder(f());
  Y x_y = x.remainder(f());
  Z x_z = x.remainder(f());

  var y_n = y.remainder(f());
  int y_i = y.remainder(f());
  double y_d = y.remainder(f());
  X y_x = y.remainder(f());
  Y y_y = y.remainder(f());
  Z y_z = y.remainder(f());

  var z_n = z.remainder(f());
  int z_i = z.remainder(f());
  double z_d = z.remainder(f());
  X z_x = z.remainder(f());
  Y z_y = z.remainder(f());
  Z z_z = z.remainder(f());
}

clamp<X extends num, Y extends int, Z extends double>(
    num n, int i, double d, X x, Y y, Z z) {
  var n_n = n.clamp(f(), f());
  int n_i = n.clamp(f(), f());
  double n_d = n.clamp(f(), f());
  X n_x = n.clamp(f(), f());
  Y n_y = n.clamp(f(), f());
  Z n_z = n.clamp(f(), f());

  num i_n = i.clamp(f(), f());
  int i_i = i.clamp(f(), f());
  double i_d = i.clamp(f(), f());
  X i_x = i.clamp(f(), f());
  Y i_y = i.clamp(f(), f());
  Z i_z = i.clamp(f(), f());

  var d_n = d.clamp(f(), f());
  int d_i = d.clamp(f(), f());
  double d_d = d.clamp(f(), f());
  X d_x = d.clamp(f(), f());
  Y d_y = d.clamp(f(), f());
  Z d_z = d.clamp(f(), f());

  var x_n = x.clamp(f(), f());
  int x_i = x.clamp(f(), f());
  double x_d = x.clamp(f(), f());
  X x_x = x.clamp(f(), f());
  Y x_y = x.clamp(f(), f());
  Z x_z = x.clamp(f(), f());

  var y_n = y.clamp(f(), f());
  int y_i = y.clamp(f(), f());
  double y_d = y.clamp(f(), f());
  X y_x = y.clamp(f(), f());
  Y y_y = y.clamp(f(), f());
  Z y_z = y.clamp(f(), f());

  var z_n = z.clamp(f(), f());
  int z_i = z.clamp(f(), f());
  double z_d = z.clamp(f(), f());
  X z_x = z.clamp(f(), f());
  Y z_y = z.clamp(f(), f());
  Z z_z = z.clamp(f(), f());
}

main() {}
