// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for checking implemention of IsolateMirror when
// inspecting the current isolate.

#library('isolate_mirror_local_test');

#import('dart:isolate');
#import('dart:mirrors');

ReceivePort exit_port;
Set expectedTests;

void testDone(String test) {
  if (!expectedTests.contains(test)) {
    throw "Unexpected test name '$test'";
  }
  expectedTests.remove(test);
  if (expectedTests.isEmpty()) {
    // All tests are done.
    exit_port.close();
  }
}

int global_var = 0;

// This function will be invoked reflectively.
int function(int x) {
  global_var = x;
  return x + 1;
}

void testRootLibraryMirror(LibraryMirror lib_mirror) {
  Expect.equals('isolate_mirror_local_test', lib_mirror.simpleName);
  Expect.isTrue(lib_mirror.url.contains('isolate_mirror_local_test.dart'));
  Expect.equals("LibraryMirror on 'isolate_mirror_local_test'",
                lib_mirror.toString());

  // Test library invocation by calling function(123).
  Expect.equals(0, global_var);
  lib_mirror.invoke('function', [ 123 ]).then(
      (InstanceMirror retval) {
        Expect.equals(123, global_var);
        Expect.equals('Smi', retval.getClass().simpleName);
        Expect.isTrue(retval.hasSimpleValue);
        Expect.equals(124, retval.simpleValue);
        testDone('testRootLibraryMirror');
      });
}

void testLibrariesMap(Map libraries) {
  // Just look for a couple of well-known libs.
  LibraryMirror core_lib = libraries['dart:core'];
  Expect.isTrue(core_lib is LibraryMirror);

  LibraryMirror mirror_lib = libraries['dart:mirrors'];
  Expect.isTrue(mirror_lib is LibraryMirror);

  // Lookup an interface from a library and make sure it is sane.
  InterfaceMirror list_intf = core_lib.members()['List'];
  Expect.isTrue(list_intf is InterfaceMirror);
  Expect.equals('List', list_intf.simpleName);
  Expect.equals('Object', list_intf.superclass().simpleName);
  Expect.equals('ListFactory', list_intf.defaultFactory().simpleName);
  Expect.equals('dart:core', list_intf.library.simpleName);
  Expect.isFalse(list_intf.isClass);
  Expect.equals('Collection', list_intf.superinterfaces()[0].simpleName);
  Expect.equals("InterfaceMirror on 'List'", list_intf.toString());

  // Lookup a class from a library and make sure it is sane.
  InterfaceMirror oom_cls = core_lib.members()['OutOfMemoryException'];
  Expect.isTrue(oom_cls is InterfaceMirror);
  Expect.equals('OutOfMemoryException', oom_cls.simpleName);
  Expect.equals('Object', oom_cls.superclass().simpleName);
  Expect.isTrue(oom_cls.defaultFactory() === null);
  Expect.equals('dart:core', oom_cls.library.simpleName);
  Expect.isTrue(oom_cls.isClass);
  Expect.equals('Exception', oom_cls.superinterfaces()[0].simpleName);
  Expect.equals("InterfaceMirror on 'OutOfMemoryException'",
                oom_cls.toString());
  testDone('testLibrariesMap');
}

void testIsolateMirror(IsolateMirror mirror) {
  Expect.isTrue(mirror.debugName.contains('main'));
  testRootLibraryMirror(mirror.rootLibrary);
  testLibrariesMap(mirror.libraries());
  testDone('testIsolateMirror');
}

void testIntegerInstanceMirror(InstanceMirror mirror) {
  // TODO(turnidge): The mirrors api exposes internal vm
  // implementation class names.  Is this okay?
  Expect.equals('Smi', mirror.getClass().simpleName);
  Expect.isTrue(mirror.hasSimpleValue);
  Expect.equals(1001, mirror.simpleValue);
  Expect.equals("InstanceMirror on <1001>", mirror.toString());

  // Invoke (mirror + mirror).
  mirror.invoke('+', [ mirror ]).then(
      (InstanceMirror retval) {
        Expect.equals('Smi', retval.getClass().simpleName);
        Expect.isTrue(retval.hasSimpleValue);
        Expect.equals(2002, retval.simpleValue);
        testDone('testIntegerInstanceMirror');
      });
}

void testStringInstanceMirror(InstanceMirror mirror) {
  // TODO(turnidge): The mirrors api exposes internal vm
  // implementation class names.  Is this okay?
  Expect.equals('OneByteString', mirror.getClass().simpleName);
  Expect.isTrue(mirror.hasSimpleValue);
  Expect.equals('This\nis\na\nString', mirror.simpleValue);
  Expect.equals("InstanceMirror on <'This\\nis\\na\\nString'>",
                mirror.toString());

  // Invoke mirror[0].
  mirror.invoke('[]', [ 0 ]).then(
      (InstanceMirror retval) {
        Expect.equals('OneByteString', retval.getClass().simpleName);
        Expect.isTrue(retval.hasSimpleValue);
        Expect.equals('T', retval.simpleValue);
        testDone('testStringInstanceMirror');
      });
}

void testBoolInstanceMirror(InstanceMirror mirror) {
  Expect.equals('Bool', mirror.getClass().simpleName);
  Expect.isTrue(mirror.hasSimpleValue);
  Expect.equals(true, mirror.simpleValue);
  Expect.equals("InstanceMirror on <true>", mirror.toString());
  testDone('testBoolInstanceMirror');
}

void testNullInstanceMirror(InstanceMirror mirror) {
  // TODO(turnidge): This is returning the wrong class.  Fix it.
  Expect.equals('Object', mirror.getClass().simpleName);
  Expect.isTrue(mirror.hasSimpleValue);
  Expect.equals(null, mirror.simpleValue);
  Expect.equals("InstanceMirror on <null>", mirror.toString());
  testDone('testNullInstanceMirror');
}

class MySuperClass {
}

class MyInterface {
}

class MyClass extends MySuperClass implements MyInterface {
  MyClass(this.value) {}

  final value;

  int method(int arg) {
    return arg + value;
  }
}

void testCustomInstanceMirror(InstanceMirror mirror) {
  Expect.isFalse(mirror.hasSimpleValue);
  bool saw_exception = false;
  try {
    // mirror.simpleValue;
  } catch (MirrorException me) {
    saw_exception = true;
  }
  //Expect.isTrue(saw_exception);
  Expect.equals("InstanceMirror on instance of 'MyClass'", mirror.toString());

  InterfaceMirror cls = mirror.getClass();
  Expect.isTrue(cls is InterfaceMirror);
  Expect.equals('MyClass', cls.simpleName);
  Expect.equals('MySuperClass', cls.superclass().simpleName);
  Expect.isTrue(cls.defaultFactory() === null);
  Expect.equals('isolate_mirror_local_test', cls.library.simpleName);
  Expect.isTrue(cls.isClass);
  Expect.equals('MyInterface', cls.superinterfaces()[0].simpleName);
  Expect.equals("InterfaceMirror on 'MyClass'",
                cls.toString());

  // Invoke mirror.method(1000).
  mirror.invoke('method', [ 1000 ]).then(
      (InstanceMirror retval) {
        Expect.equals('Smi', retval.getClass().simpleName);
        Expect.isTrue(retval.hasSimpleValue);
        Expect.equals(1017, retval.simpleValue);
        testDone('testCustomInstanceMirror');
      });

}

class MyException implements Exception {
  MyException(this._message);
  final String _message;
  String toString() { return 'MyException: $_message'; }
}

void methodWithException() {
  throw new MyException("from methodWithException");
}

void methodWithError() {
  // We get a parse error when we try to run this function.
  +++;
}

void testMirrorErrors(IsolateMirror mirror) {
  LibraryMirror lib_mirror = mirror.rootLibrary;

  Future<InstanceMirror> future =
      lib_mirror.invoke('methodWithException', []);
  future.handleException(
      (MirroredError exc) {
        Expect.isTrue(exc is MirroredUncaughtExceptionError);
        Expect.equals('MyException',
                      exc.exception_mirror.getClass().simpleName);
        Expect.equals('MyException: from methodWithException',
                      exc.exception_string);
        Expect.isTrue(exc.stacktrace.toString().contains(
            'isolate_mirror_local_test.dart'));
        testDone('testMirrorErrors1');
        return true;
      });
  future.then(
      (InstanceMirror retval) {
        // Should not reach here.
        Expect.isTrue(false);
      });

  Future<InstanceMirror> future2 =
      lib_mirror.invoke('methodWithError', []);
  future2.handleException(
      (MirroredError exc) {
        Expect.isTrue(exc is MirroredCompilationError);
        Expect.isTrue(exc.message.contains('unexpected token'));
        testDone('testMirrorErrors2');
        return true;
      });
  future2.then(
      (InstanceMirror retval) {
        // Should not reach here.
        Expect.isTrue(false);
      });

  // TODO(turnidge): When we call a method that doesn't exist, we
  // should probably call noSuchMethod().  I'm adding this test to
  // document the current behavior in the meantime.
  Future<InstanceMirror> future3 =
      lib_mirror.invoke('methodNotFound', []);
  future3.handleException(
      (MirroredError exc) {
        Expect.isTrue(exc is MirroredCompilationError);
        Expect.isTrue(exc.message.contains(
            "did not find top-level function 'methodNotFound'"));
        testDone('testMirrorErrors3');
        return true;
      });
  future3.then(
      (InstanceMirror retval) {
        // Should not reach here.
        Expect.isTrue(false);
      });
}

void main() {
  // When all of the expected tests complete, the exit_port is closed,
  // allowing the program to terminate.
  exit_port = new ReceivePort();
  expectedTests = new Set<String>.from(['testRootLibraryMirror',
                                        'testLibrariesMap',
                                        'testIsolateMirror',
                                        'testIntegerInstanceMirror',
                                        'testStringInstanceMirror',
                                        'testBoolInstanceMirror',
                                        'testNullInstanceMirror',
                                        'testCustomInstanceMirror',
                                        'testMirrorErrors1',
                                        'testMirrorErrors2',
                                        'testMirrorErrors3']);

  // Test that an isolate can reflect on itself.
  isolateMirrorOf(exit_port.toSendPort()).then(testIsolateMirror);

  testIntegerInstanceMirror(mirrorOf(1001));
  testStringInstanceMirror(mirrorOf('This\nis\na\nString'));
  testBoolInstanceMirror(mirrorOf(true));
  testNullInstanceMirror(mirrorOf(null));
  testCustomInstanceMirror(mirrorOf(new MyClass(17)));
  testMirrorErrors(currentIsolateMirror());
}
