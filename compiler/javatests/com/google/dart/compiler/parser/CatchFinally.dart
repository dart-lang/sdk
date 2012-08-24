// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  static main(arguments) {
    testCatch();
    testFinally();
    testCatchFinally();
    testMultipleCatch();
    testMultipleCatchFinally();
    testRethrow();
  }

  static testRethrow() {
    try {
      throw new Foo();
    } catch(e, st) {
      throw;
    }
  }

  static testCatch() {
    var exception;
    try {
      throw new Foo();
    } catch(e, st) {
      exception = e;
    }
  }

  static testFinally() {
    var exception;
    try {
      throw new Foo();
    } finally {
      exception = null;
    }
  }

  static testCatchFinally() {
    var exception;
    try {
      throw new Foo();
    } catch(e, st) {
      exception = e;
    } finally {
      exception = null;
    }
  }

  static testMultipleCatchFinally() {
    var exception;
    try {
      throw new Foo();
    } on Foo catch(e, st) {
      exception = e;
    } on Bar catch(e) {
      exception = e;
    } finally {
      exception = null;
    }
  }

  static testMultipleCatch() {
    var exception;
    try {
      throw new Foo();
    } catch (e) {
      exception = e;
    } on Map catch (e) {
      exception = e;
    } on int catch (e) {
      exception = e;
    } catch (e, st) {
      exception = e;
    } on Map catch (e, st) {
      exception = e;
    } on int catch (e, st) {
      exception = e;
    } finally {
      exception = e;
    }
  }
}
