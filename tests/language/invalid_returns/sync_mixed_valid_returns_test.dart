// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak

import 'dart:async';
import 'sync_mixed_valid_returns_legacy_lib.dart';

/* Test the cases where expression bodied functions are more permissive
 * than block bodied functions (places where they behave the same
 * are tested below).
 *
 * A synchronous expression bodied function with return type `T` and return
 * expression `e` has a valid return if:
 * `T` is `void`,
 * or `return exp;` is a valid return for an equivalent block bodied function
 * with return type `T` as defined below.
 */

void sync_Object_to_void_e() => vo;
void sync_int_to_void_e() => vi;
void sync_Future_void_to_void_e() => fvv;
void sync_Future_dynamic_to_void_e() => fvd;
void sync_Future_Object_to_void_e() => fvo;
void sync_Future_Null_to_void_e() => fvn;
void sync_Future_int_to_void_e() => fvi;
void sync_FutureOr_void_to_void_e() => fovv;
void sync_FutureOr_dynamic_to_void_e() => fovd;
void sync_FutureOr_Object_to_void_e() => fovo;
void sync_FutureOr_Null_to_void_e() => fovn;
void sync_FutureOr_int_to_void_e() => fovi;

/* `return exp;` where `exp` has static type `S` is a valid return if:
 * `S` is `void*`
 * and `T` is `void` or `dynamic`.
 */

void sync_void_to_void_e() => vv;
void sync_void_to_void() {
  return vv;
}

dynamic sync_void_to_dynamic_e() => vv;
dynamic sync_void_to_dynamic() {
  return vv;
}

/* `return exp;` where `exp` has static type `S` is a valid return if:
 * `T` is `void`
 * and `S` is `void*` or `dynamic*` or `Null*`
 */

void sync_dynamic_to_void_e() => vd;
void sync_dynamic_to_void() {
  return vd;
}

void sync_Null_to_void_e() => vn;
void sync_Null_to_void() {
  return vn;
}

/* `return exp;` where `exp` has static type `S` is a valid return if:
 * `T` is not `void`
 * and `S` is not `void` nor `void*`,
 * and `S` is assignable to `T`
 */

int sync_int_to_int_e() => vi;
int sync_int_to_int() {
  return vi;
}

int sync_dynamic_to_int_e() => vi as dynamic;
int sync_dynamic_to_int() {
  return vi as dynamic;
}

FutureOr<int> sync_int_to_FutureOr_int_e() => vi;
FutureOr<int> sync_int_to_FutureOr_int() {
  return vi;
}

FutureOr<int> sync_dynamic_to_FutureOr_int_e() => vi as dynamic;
FutureOr<int> sync_dynamic_to_FutureOr_int() {
  return vi as dynamic;
}

void main() {
  sync_void_to_void_e();
  sync_dynamic_to_void_e();
  sync_Object_to_void_e();
  sync_Null_to_void_e();
  sync_int_to_void_e();
  sync_Future_void_to_void_e();
  sync_Future_dynamic_to_void_e();
  sync_Future_Object_to_void_e();
  sync_Future_Null_to_void_e();
  sync_Future_int_to_void_e();
  sync_FutureOr_void_to_void_e();
  sync_FutureOr_dynamic_to_void_e();
  sync_FutureOr_Object_to_void_e();
  sync_FutureOr_Null_to_void_e();
  sync_FutureOr_int_to_void_e();
  sync_void_to_void_e();
  sync_void_to_void();
  sync_void_to_dynamic_e();
  sync_void_to_dynamic();
  sync_dynamic_to_void_e();
  sync_dynamic_to_void();
  sync_Null_to_void_e();
  sync_Null_to_void();
  sync_int_to_int_e();
  sync_int_to_int();
  sync_dynamic_to_int_e();
  sync_dynamic_to_int();
  sync_int_to_FutureOr_int_e();
  sync_int_to_FutureOr_int();
  sync_dynamic_to_FutureOr_int_e();
  sync_dynamic_to_FutureOr_int();
}
