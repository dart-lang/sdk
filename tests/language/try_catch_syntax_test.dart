// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  testMissingCatch();
  testMissingTry();
  testDuplicateCatchVariable();
  testIllegalFinally();
  testIllegalCatch();
  testIllegalRethrow();
}

testMissingCatch() {
  try { }  /// 01: compile-time error
}

testMissingTry() {
  on Exception catch (e) { }                   /// 02: compile-time error
  on Exception catch (e, trace) { }            /// 03: compile-time error
  finally { }                                  /// 04: compile-time error
}

testDuplicateCatchVariable() {
  try { } on Exception catch (e, e) { } /// 05: compile-time error
}

testIllegalFinally() {
  try { } finally (e) { } /// 06: compile-time error
}

testIllegalCatch() {
  try { } catch () { }              /// 07: compile-time error
  try { } on MammaMia catch (e) { } /// 09: compile-time error
}

testIllegalRethrow() {
  try { throw; } catch (e) { }             /// 10: compile-time error
  try { } catch (e) { } finally { throw; } /// 11: compile-time error
}
