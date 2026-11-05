// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test() {
  void v = 42;

  <void>[v]; // Ok
  <void>[?v]; // Ok
  <void>{v}; // Ok
  <void>{?v}; // Ok
  <void, void>{v: v}; // Ok
  <void, void>{v: ?v}; // Error
  <void, void>{?v: v}; // Error

  var v1 = [v]; // Ok
  var v2 = [?v]; // Ok
  var v3 = {v}; // Ok
  var v4 = {?v}; // Ok
  var v5 = {v: v}; // Ok
  var v6 = {v: ?v}; // Error
  var v7 = {?v: v}; // Error

  List<void> w1 = [v]; // Ok
  List<void> w2 = [?v]; // Ok
  Set<void> w3 = {v}; // Ok
  Set<void> w4 = {?v}; // Ok
  Map<void, void> w5 = {v: v}; // Ok
  Map<void, void> w6 = {v: ?v}; // Error
  Map<void, void> w7 = {?v: v}; // Error

  <dynamic>[v]; // Error
  <dynamic>[?v]; // Error
  <dynamic>{v}; // Error
  <dynamic>{?v}; // Error
  <dynamic, dynamic>{v: v}; // Error
  <dynamic, dynamic>{v: ?v}; // Error
  <dynamic, dynamic>{?v: v}; // Error
}
