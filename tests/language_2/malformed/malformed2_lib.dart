// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of malformed_test;

void testValue(var o) {
  o is Unresolved1;
  o is List<Unresolved2>;
  o is! Unresolved3;
  o is! List<Unresolved4>;

  try {
    o as Unresolved5;
  } catch (e) {
  }

  try {
    o as List<Unresolved6>;
  } catch (e) {
  }

  try {
  } on Unresolved7 catch (e) {
  } catch (e) {
  }

  try {
    throw o;
  } on Unresolved8 catch (e) {
  } catch (e) {
  }

  try {
    throw o;
  } on List<String> catch (e) {
  } on NullThrownError catch (e) {
  } on Unresolved9 catch (e) {
  } catch (e) {
  }

  try {
    throw o;
  } on List<Unresolved10> catch (e) {
  } on NullThrownError catch (e) {
  } on Unresolved11 catch (e) {
  } catch (e) {
  }

  Unresolved12 u = o;

  List<Unresolved13> u2 = o;
}
