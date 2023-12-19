// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak

import 'dart:async';
import 'async_mixed_valid_returns_legacy_lib.dart';

/* Test the cases where expression bodied functions are more permissive
 * than block bodied functions (places where they behave the same
 * are tested below).
 *
 * An asynchronous expression bodied function with return type `T`, future
 * value type `Tv`, and return expression `e` has a valid return if:
 * `Tv` is `void`,
 * or `return e;` is a valid return for an equivalent block bodied function
 * with return type `T` as defined below.
 */

void async_int_to_void_e() async => vi;
Future<void> async_int_to_Future_void__e() async => vi;
FutureOr<void> async_int_to_FutureOr_void__e() async => vi;
Future<void>? async_int_to_Future_void_q__e() async => vi;
FutureOr<void>? async_int_to_FutureOr_void_q__e() async => vi;
void async_Object_to_void_e() async => vo;
Future<void> async_Object_to_Future_void__e() async => vo;
FutureOr<void> async_Object_to_FutureOr_void__e() async => vo;
Future<void>? async_Object_to_Future_void_q__e() async => vo;
FutureOr<void>? async_Object_to_FutureOr_void_q__e() async => vo;
void async_Future_int__to_void_e() async => fvi;
Future<void> async_Future_int__to_Future_void__e() async => fvi;
FutureOr<void> async_Future_int__to_FutureOr_void__e() async => fvi;
Future<void>? async_Future_int__to_Future_void_q__e() async => fvi;
FutureOr<void>? async_Future_int__to_FutureOr_void_q__e() async => fvi;
void async_FutureOr_int__to_void_e() async => fovi;
Future<void> async_FutureOr_int__to_Future_void__e() async => fovi;
FutureOr<void> async_FutureOr_int__to_FutureOr_void__e() async => fovi;
Future<void>? async_FutureOr_int__to_Future_void_q__e() async => fovi;
FutureOr<void>? async_FutureOr_int__to_FutureOr_void_q__e() async => fovi;
void async_Future_Object__to_void_e() async => fvo;
Future<void> async_Future_Object__to_Future_void__e() async => fvo;
FutureOr<void> async_Future_Object__to_FutureOr_void__e() async => fvo;
Future<void>? async_Future_Object__to_Future_void_q__e() async => fvo;
FutureOr<void>? async_Future_Object__to_FutureOr_void_q__e() async => fvo;
void async_FutureOr_Object__to_void_e() async => fovo;
Future<void> async_FutureOr_Object__to_Future_void__e() async => fovo;
FutureOr<void> async_FutureOr_Object__to_FutureOr_void__e() async => fovo;
Future<void>? async_FutureOr_Object__to_Future_void_q__e() async => fovo;
FutureOr<void>? async_FutureOr_Object__to_FutureOr_void_q__e() async => fovo;

/* `return exp;` where `exp` has static type `S` and the future value type
 * of the function is `Tv` is a valid return if:
 * `flatten(S)` is `void*`
 * and `Tv` is `void` or `dynamic`.
 */

Future<void> async_void_to_Future_void__e() async => vv;
Future<void> async_void_to_Future_void_() async {
  return vv;
}

Future<void>? async_void_to_Future_void_q__e() async => vv;
Future<void>? async_void_to_Future_void_q_() async {
  return vv;
}

Future<void> async_Future_void__to_Future_void__e() async => fvv;
Future<void> async_Future_void__to_Future_void_() async {
  return fvv;
}

Future<void>? async_Future_void__to_Future_void_q__e() async => fvv;
Future<void>? async_Future_void__to_Future_void_q_() async {
  return fvv;
}

Future<void> async_FutureOr_void__to_Future_void__e() async => fovv;
Future<void> async_FutureOr_void__to_Future_void_() async {
  return fovv;
}

Future<void>? async_FutureOr_void__to_Future_void_q__e() async => fovv;
Future<void>? async_FutureOr_void__to_Future_void_q_() async {
  return fovv;
}

Future<dynamic> async_void_to_Future_dynamic__e() async => vv;
Future<dynamic> async_void_to_Future_dynamic_() async {
  return vv;
}

Future<dynamic>? async_void_to_Future_dynamic_q__e() async => vv;
Future<dynamic>? async_void_to_Future_dynamic_q_() async {
  return vv;
}

Future<dynamic> async_Future_void__to_Future_dynamic__e() async => fvv;
Future<dynamic> async_Future_void__to_Future_dynamic_() async {
  return fvv;
}

Future<dynamic>? async_Future_void__to_Future_dynamic_q__e() async => fvv;
Future<dynamic>? async_Future_void__to_Future_dynamic_q_() async {
  return fvv;
}

Future<dynamic> async_FutureOr_void__to_Future_dynamic__e() async => fovv;
Future<dynamic> async_FutureOr_void__to_Future_dynamic_() async {
  return fovv;
}

Future<dynamic>? async_FutureOr_void__to_Future_dynamic_q__e() async => fovv;
Future<dynamic>? async_FutureOr_void__to_Future_dynamic_q_() async {
  return fovv;
}

FutureOr<void> async_void_to_FutureOr_void__e() async => vv;
FutureOr<void> async_void_to_FutureOr_void_() async {
  return vv;
}

FutureOr<void>? async_void_to_FutureOr_void_q__e() async => vv;
FutureOr<void>? async_void_to_FutureOr_void_q_() async {
  return vv;
}

FutureOr<void> async_Future_void__to_FutureOr_void__e() async => fvv;
FutureOr<void> async_Future_void__to_FutureOr_void_() async {
  return fvv;
}

FutureOr<void>? async_Future_void__to_FutureOr_void_q__e() async => fvv;
FutureOr<void>? async_Future_void__to_FutureOr_void_q_() async {
  return fvv;
}

FutureOr<void> async_FutureOr_void__to_FutureOr_void__e() async => fovv;
FutureOr<void> async_FutureOr_void__to_FutureOr_void_() async {
  return fovv;
}

FutureOr<void>? async_FutureOr_void__to_FutureOr_void_q__e() async => fovv;
FutureOr<void>? async_FutureOr_void__to_FutureOr_void_q_() async {
  return fovv;
}

FutureOr<dynamic> async_void_to_FutureOr_dynamic__e() async => vv;
FutureOr<dynamic> async_void_to_FutureOr_dynamic_() async {
  return vv;
}

FutureOr<dynamic>? async_void_to_FutureOr_dynamic_q__e() async => vv;
FutureOr<dynamic>? async_void_to_FutureOr_dynamic_q_() async {
  return vv;
}

FutureOr<dynamic> async_Future_void__to_FutureOr_dynamic__e() async => fvv;
FutureOr<dynamic> async_Future_void__to_FutureOr_dynamic_() async {
  return fvv;
}

FutureOr<dynamic>? async_Future_void__to_FutureOr_dynamic_q__e() async => fvv;
FutureOr<dynamic>? async_Future_void__to_FutureOr_dynamic_q_() async {
  return fvv;
}

FutureOr<dynamic> async_FutureOr_void__to_FutureOr_dynamic__e() async => fovv;
FutureOr<dynamic> async_FutureOr_void__to_FutureOr_dynamic_() async {
  return fovv;
}

FutureOr<dynamic>? async_FutureOr_void__to_FutureOr_dynamic_q__e() async =>
    fovv;
FutureOr<dynamic>? async_FutureOr_void__to_FutureOr_dynamic_q_() async {
  return fovv;
}

void async_void_to_void_e() async => vv;
void async_void_to_void() async {
  return vv;
}

void async_Future_void__to_void_e() async => fvv;
void async_Future_void__to_void() async {
  return fvv;
}

void async_FutureOr_void__to_void_e() async => fovv;
void async_FutureOr_void__to_void() async {
  return fovv;
}

dynamic async_void_to_dynamic_e() async => vv;
dynamic async_void_to_dynamic() async {
  return vv;
}

dynamic? async_void_to_dynamic_q_e() async => vv;
dynamic? async_void_to_dynamic_q() async {
  return vv;
}

dynamic async_Future_void__to_dynamic_e() async => fvv;
dynamic async_Future_void__to_dynamic() async {
  return fvv;
}

dynamic? async_Future_void__to_dynamic_q_e() async => fvv;
dynamic? async_Future_void__to_dynamic_q() async {
  return fvv;
}

dynamic async_FutureOr_void__to_dynamic_e() async => fovv;
dynamic async_FutureOr_void__to_dynamic() async {
  return fovv;
}

dynamic? async_FutureOr_void__to_dynamic_q_e() async => fovv;
dynamic? async_FutureOr_void__to_dynamic_q() async {
  return fovv;
}

/* `return exp;` where `exp` has static type `S` and the future value type
 * of the function is `Tv` is a valid return if:
 * `Tv` is `void`
 * and `flatten(S)` is `void*`, `dynamic*`, or `Null*`.
 */

void async_Future_dynamic__to_void_e() async => fvd;
void async_Future_dynamic__to_void() async {
  return fvd;
}

Future<void> async_Future_dynamic__to_Future_void__e() async => fvd;
Future<void> async_Future_dynamic__to_Future_void_() async {
  return fvd;
}

Future<void>? async_Future_dynamic__to_Future_void_q__e() async => fvd;
Future<void>? async_Future_dynamic__to_Future_void_q_() async {
  return fvd;
}

FutureOr<void> async_Future_dynamic__to_FutureOr_void__e() async => fvd;
FutureOr<void> async_Future_dynamic__to_FutureOr_void_() async {
  return fvd;
}

FutureOr<void>? async_Future_dynamic__to_FutureOr_void_q__e() async => fvd;
FutureOr<void>? async_Future_dynamic__to_FutureOr_void_q_() async {
  return fvd;
}

void async_Future_Null__to_void_e() async => fvn;
void async_Future_Null__to_void() async {
  return fvn;
}

Future<void> async_Future_Null__to_Future_void__e() async => fvn;
Future<void> async_Future_Null__to_Future_void_() async {
  return fvn;
}

Future<void>? async_Future_Null__to_Future_void_q__e() async => fvn;
Future<void>? async_Future_Null__to_Future_void_q_() async {
  return fvn;
}

FutureOr<void> async_Future_Null__to_FutureOr_void__e() async => fvn;
FutureOr<void> async_Future_Null__to_FutureOr_void_() async {
  return fvn;
}

FutureOr<void>? async_Future_Null__to_FutureOr_void_q__e() async => fvn;
FutureOr<void>? async_Future_Null__to_FutureOr_void_q_() async {
  return fvn;
}

void async_FutureOr_dynamic__to_void_e() async => fovd;
void async_FutureOr_dynamic__to_void() async {
  return fovd;
}

Future<void> async_FutureOr_dynamic__to_Future_void__e() async => fovd;
Future<void> async_FutureOr_dynamic__to_Future_void_() async {
  return fovd;
}

Future<void>? async_FutureOr_dynamic__to_Future_void_q__e() async => fovd;
Future<void>? async_FutureOr_dynamic__to_Future_void_q_() async {
  return fovd;
}

FutureOr<void> async_FutureOr_dynamic__to_FutureOr_void__e() async => fovd;
FutureOr<void> async_FutureOr_dynamic__to_FutureOr_void_() async {
  return fovd;
}

FutureOr<void>? async_FutureOr_dynamic__to_FutureOr_void_q__e() async => fovd;
FutureOr<void>? async_FutureOr_dynamic__to_FutureOr_void_q_() async {
  return fovd;
}

void async_FutureOr_Null__to_void_e() async => fovn;
void async_FutureOr_Null__to_void() async {
  return fovn;
}

Future<void> async_FutureOr_Null__to_Future_void__e() async => fovn;
Future<void> async_FutureOr_Null__to_Future_void_() async {
  return fovn;
}

Future<void>? async_FutureOr_Null__to_Future_void_q__e() async => fovn;
Future<void>? async_FutureOr_Null__to_Future_void_q_() async {
  return fovn;
}

FutureOr<void> async_FutureOr_Null__to_FutureOr_void__e() async => fovn;
FutureOr<void> async_FutureOr_Null__to_FutureOr_void_() async {
  return fovn;
}

FutureOr<void>? async_FutureOr_Null__to_FutureOr_void_q__e() async => fovn;
FutureOr<void>? async_FutureOr_Null__to_FutureOr_void_q_() async {
  return fovn;
}

void async_dynamic_to_void_e() async => vd;
void async_dynamic_to_void() async {
  return vd;
}

Future<void> async_dynamic_to_Future_void__e() async => vd;
Future<void> async_dynamic_to_Future_void_() async {
  return vd;
}

Future<void>? async_dynamic_to_Future_void_q__e() async => vd;
Future<void>? async_dynamic_to_Future_void_q_() async {
  return vd;
}

FutureOr<void> async_dynamic_to_FutureOr_void__e() async => vd;
FutureOr<void> async_dynamic_to_FutureOr_void_() async {
  return vd;
}

FutureOr<void>? async_dynamic_to_FutureOr_void_q__e() async => vd;
FutureOr<void>? async_dynamic_to_FutureOr_void_q_() async {
  return vd;
}

void async_Null_to_void_e() async => vn;
void async_Null_to_void() async {
  return vn;
}

Future<void> async_Null_to_Future_void__e() async => vn;
Future<void> async_Null_to_Future_void_() async {
  return vn;
}

Future<void>? async_Null_to_Future_void_q__e() async => vn;
Future<void>? async_Null_to_Future_void_q_() async {
  return vn;
}

FutureOr<void> async_Null_to_FutureOr_void__e() async => vn;
FutureOr<void> async_Null_to_FutureOr_void_() async {
  return vn;
}

FutureOr<void>? async_Null_to_FutureOr_void_q__e() async => vn;
FutureOr<void>? async_Null_to_FutureOr_void_q_() async {
  return vn;
}

void main() {
  async_int_to_void_e();
  async_int_to_Future_void__e();
  async_int_to_FutureOr_void__e();
  async_int_to_Future_void_q__e();
  async_int_to_FutureOr_void_q__e();
  async_Object_to_void_e();
  async_Object_to_Future_void__e();
  async_Object_to_FutureOr_void__e();
  async_Object_to_Future_void_q__e();
  async_Object_to_FutureOr_void_q__e();
  async_Future_int__to_void_e();
  async_Future_int__to_Future_void__e();
  async_Future_int__to_FutureOr_void__e();
  async_Future_int__to_Future_void_q__e();
  async_Future_int__to_FutureOr_void_q__e();
  async_FutureOr_int__to_void_e();
  async_FutureOr_int__to_Future_void__e();
  async_FutureOr_int__to_FutureOr_void__e();
  async_FutureOr_int__to_Future_void_q__e();
  async_FutureOr_int__to_FutureOr_void_q__e();
  async_Future_Object__to_void_e();
  async_Future_Object__to_Future_void__e();
  async_Future_Object__to_FutureOr_void__e();
  async_Future_Object__to_Future_void_q__e();
  async_Future_Object__to_FutureOr_void_q__e();
  async_FutureOr_Object__to_void_e();
  async_FutureOr_Object__to_Future_void__e();
  async_FutureOr_Object__to_FutureOr_void__e();
  async_FutureOr_Object__to_Future_void_q__e();
  async_FutureOr_Object__to_FutureOr_void_q__e();
  async_void_to_Future_void__e();
  async_void_to_Future_void_();
  async_void_to_Future_void_q__e();
  async_void_to_Future_void_q_();
  async_Future_void__to_Future_void__e();
  async_Future_void__to_Future_void_();
  async_Future_void__to_Future_void_q__e();
  async_Future_void__to_Future_void_q_();
  async_FutureOr_void__to_Future_void__e();
  async_FutureOr_void__to_Future_void_();
  async_FutureOr_void__to_Future_void_q__e();
  async_FutureOr_void__to_Future_void_q_();
  async_void_to_Future_dynamic__e();
  async_void_to_Future_dynamic_();
  async_void_to_Future_dynamic_q__e();
  async_void_to_Future_dynamic_q_();
  async_Future_void__to_Future_dynamic__e();
  async_Future_void__to_Future_dynamic_();
  async_Future_void__to_Future_dynamic_q__e();
  async_Future_void__to_Future_dynamic_q_();
  async_FutureOr_void__to_Future_dynamic__e();
  async_FutureOr_void__to_Future_dynamic_();
  async_FutureOr_void__to_Future_dynamic_q__e();
  async_FutureOr_void__to_Future_dynamic_q_();
  async_void_to_FutureOr_void__e();
  async_void_to_FutureOr_void_();
  async_void_to_FutureOr_void_q__e();
  async_void_to_FutureOr_void_q_();
  async_Future_void__to_FutureOr_void__e();
  async_Future_void__to_FutureOr_void_();
  async_Future_void__to_FutureOr_void_q__e();
  async_Future_void__to_FutureOr_void_q_();
  async_FutureOr_void__to_FutureOr_void__e();
  async_FutureOr_void__to_FutureOr_void_();
  async_FutureOr_void__to_FutureOr_void_q__e();
  async_FutureOr_void__to_FutureOr_void_q_();
  async_void_to_FutureOr_dynamic__e();
  async_void_to_FutureOr_dynamic_();
  async_void_to_FutureOr_dynamic_q__e();
  async_void_to_FutureOr_dynamic_q_();
  async_Future_void__to_FutureOr_dynamic__e();
  async_Future_void__to_FutureOr_dynamic_();
  async_Future_void__to_FutureOr_dynamic_q__e();
  async_Future_void__to_FutureOr_dynamic_q_();
  async_FutureOr_void__to_FutureOr_dynamic__e();
  async_FutureOr_void__to_FutureOr_dynamic_();
  async_FutureOr_void__to_FutureOr_dynamic_q__e();
  async_FutureOr_void__to_FutureOr_dynamic_q_();
  async_void_to_void_e();
  async_void_to_void();
  async_Future_void__to_void_e();
  async_Future_void__to_void();
  async_FutureOr_void__to_void_e();
  async_FutureOr_void__to_void();
  async_void_to_dynamic_e();
  async_void_to_dynamic();
  async_void_to_dynamic_q_e();
  async_void_to_dynamic_q();
  async_Future_void__to_dynamic_e();
  async_Future_void__to_dynamic();
  async_Future_void__to_dynamic_q_e();
  async_Future_void__to_dynamic_q();
  async_FutureOr_void__to_dynamic_e();
  async_FutureOr_void__to_dynamic();
  async_FutureOr_void__to_dynamic_q_e();
  async_FutureOr_void__to_dynamic_q();
  async_Future_dynamic__to_void_e();
  async_Future_dynamic__to_void();
  async_Future_dynamic__to_Future_void__e();
  async_Future_dynamic__to_Future_void_();
  async_Future_dynamic__to_Future_void_q__e();
  async_Future_dynamic__to_Future_void_q_();
  async_Future_dynamic__to_FutureOr_void__e();
  async_Future_dynamic__to_FutureOr_void_();
  async_Future_dynamic__to_FutureOr_void_q__e();
  async_Future_dynamic__to_FutureOr_void_q_();
  async_Future_Null__to_void_e();
  async_Future_Null__to_void();
  async_Future_Null__to_Future_void__e();
  async_Future_Null__to_Future_void_();
  async_Future_Null__to_Future_void_q__e();
  async_Future_Null__to_Future_void_q_();
  async_Future_Null__to_FutureOr_void__e();
  async_Future_Null__to_FutureOr_void_();
  async_Future_Null__to_FutureOr_void_q__e();
  async_Future_Null__to_FutureOr_void_q_();
  async_FutureOr_dynamic__to_void_e();
  async_FutureOr_dynamic__to_void();
  async_FutureOr_dynamic__to_Future_void__e();
  async_FutureOr_dynamic__to_Future_void_();
  async_FutureOr_dynamic__to_Future_void_q__e();
  async_FutureOr_dynamic__to_Future_void_q_();
  async_FutureOr_dynamic__to_FutureOr_void__e();
  async_FutureOr_dynamic__to_FutureOr_void_();
  async_FutureOr_dynamic__to_FutureOr_void_q__e();
  async_FutureOr_dynamic__to_FutureOr_void_q_();
  async_FutureOr_Null__to_void_e();
  async_FutureOr_Null__to_void();
  async_FutureOr_Null__to_Future_void__e();
  async_FutureOr_Null__to_Future_void_();
  async_FutureOr_Null__to_Future_void_q__e();
  async_FutureOr_Null__to_Future_void_q_();
  async_FutureOr_Null__to_FutureOr_void__e();
  async_FutureOr_Null__to_FutureOr_void_();
  async_FutureOr_Null__to_FutureOr_void_q__e();
  async_FutureOr_Null__to_FutureOr_void_q_();
  async_dynamic_to_void_e();
  async_dynamic_to_void();
  async_dynamic_to_Future_void__e();
  async_dynamic_to_Future_void_();
  async_dynamic_to_Future_void_q__e();
  async_dynamic_to_Future_void_q_();
  async_dynamic_to_FutureOr_void__e();
  async_dynamic_to_FutureOr_void_();
  async_dynamic_to_FutureOr_void_q__e();
  async_dynamic_to_FutureOr_void_q_();
  async_Null_to_void_e();
  async_Null_to_void();
  async_Null_to_Future_void__e();
  async_Null_to_Future_void_();
  async_Null_to_Future_void_q__e();
  async_Null_to_Future_void_q_();
  async_Null_to_FutureOr_void__e();
  async_Null_to_FutureOr_void_();
  async_Null_to_FutureOr_void_q__e();
  async_Null_to_FutureOr_void_q_();
}
