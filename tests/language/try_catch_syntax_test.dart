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
  catch (Exception e) { }                   /// 02: compile-time error
  catch (Exception e, StackTrace trace) { } /// 03: compile-time error
  finally { }                               /// 04: compile-time error
}

testDuplicateCatchVariable() {
  try { } catch (Exception e, StackTrace e) { } /// 05: compile-time error
}

testIllegalFinally() {
  try { } finally (e) { } /// 06: compile-time error
}

testIllegalCatch() {
  try { } catch () { }           /// 07: compile-time error
  try { } catch (MammaMia e) { } /// 09: compile-time error
}

testIllegalRethrow() {
  try { throw; } catch (var e) { }             /// 10: compile-time error
  try { } catch (var e) { } finally { throw; } /// 11: compile-time error
}
