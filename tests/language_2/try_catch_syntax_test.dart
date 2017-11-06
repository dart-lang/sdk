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
  try { } // //# 01: syntax error
}

testMissingTry() {
  on Exception catch (e) { } //                  //# 02: syntax error
  on Exception catch (e, trace) { } //           //# 03: syntax error
  finally { } //                                 //# 04: syntax error
}

testDuplicateCatchVariable() {
  try { } on Exception catch (e, e) { } //# 05: compile-time error
}

testIllegalFinally() {
  try { } finally (e) { } //# 06: syntax error
}

testIllegalCatch() {
  try { } catch () { } //             //# 07: syntax error
  try { } on MammaMia catch (e) { } //# 08: compile-time error
  try { } catch (var e) { } //        //# 09: syntax error
  try { } catch (final e) { } //      //# 10: syntax error
  try { } catch (int e) { } //        //# 11: syntax error
  try { } catch (final int e) { } //  //# 12: syntax error
  try { } catch ([e, s]) { } //       //# 13: syntax error
  try { } catch (e, [s]) { } //       //# 14: syntax error
  try { } catch (e, [s0, s1]) { } //  //# 15: syntax error
}

testIllegalRethrow() {
  try { rethrow; } catch (e) { } //            //# 16: compile-time error
  try { } catch (e) { } finally { rethrow; } //# 17: compile-time error
}
