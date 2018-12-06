// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_catching_errors`

void bad() {
  try {} on A catch (e) { // LINT
    // ignore
  } on B catch (e) { // LINT
    // ignore
  } on C { // LINT
    // ignore
  } on D { // LINT
    // ignore
  } on Error catch (e) { // LINT
    // ignore
  } on Exception catch (e) { // OK
    // ignore
  } on String catch (e) { // OK
    // ignore
  } catch (e) {// OK
    // ignore
  }
}

class A extends B {}

class B implements Error {
  @override
  StackTrace get stackTrace => null;
}

class C extends D {}

class D extends Error {}
