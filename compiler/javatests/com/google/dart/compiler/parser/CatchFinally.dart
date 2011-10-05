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
    } catch(var e, var st) {
      throw;
    }
  }

  static testCatch() {
    var exception;
    try {
      throw new Foo();
    } catch(var e, var st) {
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
    } catch(var e, var st) {
      exception = e;
    } finally {
      exception = null;
    }
  }

  static testMultipleCatchFinally() {
    var exception;
    try {
      throw new Foo();
    } catch(Foo e, var st) {
      exception = e;
    } catch(Bar e) {
      exception = e;
    } finally {
      exception = null;
    }
  }

  static testMultipleCatch() {
    var exception;
    try {
      throw new Foo();
    } catch (final e) {
      exception = e;
    } catch (var e) {
      exception = e;
    } catch (Map<int, double> e) {
      exception = e;
    } catch (final Map<int, double> e) {
      exception = e;
    } catch (int e) {
      exception = e;
    } catch (final int e) {
      exception = e;
    } catch (final e, final st) {
      exception = e;
    } catch (var e, final st) {
      exception = e;
    } catch (Map<int, double> e, final st) {
      exception = e;
    } catch (int e, final st) {
      exception = e;
    } catch (int e, final int st) {
      exception = e;
    } catch (final e, var st) {
      exception = e;
    } catch (var e, var st) {
      exception = e;
    } catch (Map<int, double> e, var st) {
      exception = e;
    } catch (int e, var st) {
      exception = e;
    } catch (final e, Map<int, double> st) {
      exception = e;
    } catch (var e, Map<int, double> st) {
      exception = e;
    } catch (Map<int, double> e, Map<int, double> st) {
      exception = e;
    } catch (int e, Map<int, double> st) {
      exception = e;
    } catch (final e, int st) {
      exception = e;
    } catch (var e, int st) {
      exception = e;
    } catch (Map<int, double> e, int st) {
      exception = e;
    } catch (int e, int st) {
      exception = e;
    } finally {
      exception = e;
    }
  }
}
