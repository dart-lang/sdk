// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

void vv = null;
dynamic vd = null;
Object vo = null;
Null vn = null;
int vi = null;
Future<void> fvv = null;
Future<dynamic> fvd = null;
Future<Object> fvo = null;
Future<Null> fvn = null;
Future<int> fvi = null;
FutureOr<void> fovv = null;
FutureOr<dynamic> fovd = null;
FutureOr<Object> fovo = null;
FutureOr<Null> fovn = null;
FutureOr<int> fovi = null;

/* Test the cases where expression bodied functions are more permissive
 * than block bodied functions (places where they behave the same
 * are tested below).

A synchronous expression bodied function with return type `T` and return expression
`e` has a valid return if:
  * `T` is `void`
  * or `return exp;` is a valid return for an equivalent block bodied function
  with return type `T` as defined below.
*/
void sync_int_to_void_e() => vi;
void sync_Object_to_void_e() => vo;
void sync_Future_int__to_void_e() => fvi;
void sync_FutureOr_int__to_void_e() => fovi;
void sync_Future_Object__to_void_e() => fvo;
void sync_FutureOr_Object__to_void_e() => fovo;

/* Test the cases that apply only to block bodied  functions
 */

/*
* `return;` is a valid return if any of the following are true:
  * `T` is `void`
  * `T` is `dynamic`
  * `T` is `Null`.
*/
void sync_empty_to_void() {
  return;
}

dynamic sync_empty_to_dynamic() {
  return;
}

Null sync_empty_to_Null() {
  return;
}

/* Test the cases that apply to both expression bodied and block bodied
 * functions
 */

/*
* `return exp;` where `exp` has static type `S` is a valid return if:
  * `S` is `void`
  * and `T` is `void` or `dynamic` or `Null`
*/
void sync_void_to_void_e() => vv;
void sync_void_to_void() {
  return vv;
}

dynamic sync_void_to_dynamic_e() => vv;
dynamic sync_void_to_dynamic() {
  return vv;
}

Null sync_void_to_Null_e() => vv;
Null sync_void_to_Null() {
  return vv;
}

/*
* `return exp;` where `exp` has static type `S` is a valid return if:
  * `T` is `void`
  * and `S` is `void` or `dynamic` or `Null`

*/
void sync_dynamic_to_void_e() => vd;
void sync_dynamic_to_void() {
  return vd;
}

void sync_Null_to_void_e() => vn;
void sync_Null_to_void() {
  return vn;
}

/*
* `return exp;` where `exp` has static type `S` is a valid return if:
  * `T` is not `void`
  * and `S` is not `void`
  * and `S` is assignable to `T`
*/
int sync_int_to_int_e() => vi;
int sync_int_to_int() {
  return vi;
}

int sync_Object_to_int_e() => vo;
int sync_Object_to_int() {
  return vo;
}

int sync_FutureOr_int__to_int_e() => fovi;
int sync_FutureOr_int__to_int() {
  return fovi;
}

void main() {
  sync_int_to_void_e();
  sync_Object_to_void_e();
  sync_Future_int__to_void_e();
  sync_FutureOr_int__to_void_e();
  sync_Future_Object__to_void_e();
  sync_FutureOr_Object__to_void_e();
  sync_empty_to_void();
  sync_empty_to_dynamic();
  sync_empty_to_Null();
  sync_void_to_void_e();
  sync_void_to_void();
  sync_void_to_dynamic_e();
  sync_void_to_dynamic();
  sync_void_to_Null_e();
  sync_void_to_Null();
  sync_dynamic_to_void_e();
  sync_dynamic_to_void();
  sync_Null_to_void_e();
  sync_Null_to_void();
  sync_int_to_int_e();
  sync_int_to_int();
  sync_Object_to_int_e();
  sync_Object_to_int();
  sync_FutureOr_int__to_int_e();
  sync_FutureOr_int__to_int();
}
