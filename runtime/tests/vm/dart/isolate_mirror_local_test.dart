// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for checking implemention of MirrorSystem when
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
final int final_global_var = 0;

// Top-level getter and setter.
int get myVar() { return 5; }
int set myVar(x) {}

// This function will be invoked reflectively.
int function(int x) {
  global_var = x;
  return x + 1;
}

_stringCompare(String a, String b) => a.compareTo(b);
sort(list) => list.sort(_stringCompare);

String buildMethodString(MethodMirror func) {
  var result = '${func.simpleName}';
  if (func.isTopLevel) {
    result = '$result toplevel';
  }
  if (func.isStatic) {
    result = '$result static';
  }
  if (func.isMethod) {
    result = '$result method';
  }
  if (func.isGetter) {
    result = '$result getter';
  }
  if (func.isSetter) {
    result = '$result setter';
  }
  if (func.isConstructor) {
    result = '$result constructor';
  }
  if (func.isConstConstructor) {
    result = '$result const';
  }
  if (func.isGenerativeConstructor) {
    result = '$result generative';
  }
  if (func.isRedirectingConstructor) {
    result = '$result redirecting';
  }
  if (func.isFactoryConstructor) {
    result = '$result factory';
  }
  return result;
}

String buildVariableString(VariableMirror variable) {
  var result = '${variable.simpleName}';
  if (variable.isTopLevel) {
    result = '$result toplevel';
  }
  if (variable.isStatic) {
    result = '$result static';
  }
  if (variable.isFinal) {
    result = '$result final';
  }
  return result;
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
        Expect.equals('int', retval.type.simpleName);
        Expect.isTrue(retval.hasReflectee);
        Expect.equals(124, retval.reflectee);
        testDone('testRootLibraryMirror');
      });

  // Check that the members map is complete.
  List keys = lib_mirror.members.getKeys();
  sort(keys);
  Expect.equals('['
                'MyClass, '
                'MyException, '
                'MyInterface, '
                'MySuperClass, '
                '_stringCompare, '
                'buildMethodString, '
                'buildVariableString, '
                'exit_port, '
                'expectedTests, '
                'final_global_var, '
                'function, '
                'global_var, '
                'main, '
                'methodWithError, '
                'methodWithException, '
                'myVar, '
                'myVar=, '
                'sort, '
                'testBoolInstanceMirror, '
                'testCustomInstanceMirror, '
                'testDone, '
                'testIntegerInstanceMirror, '
                'testLibrariesMap, '
                'testMirrorErrors, '
                'testMirrorSystem, '
                'testNullInstanceMirror, '
                'testRootLibraryMirror, '
                'testStringInstanceMirror]',
                '$keys');

  // Check that the classes map is complete.
  keys = lib_mirror.classes.getKeys();
  sort(keys);
  Expect.equals('['
                'MyClass, '
                'MyException, '
                'MyInterface, '
                'MySuperClass]',
                '$keys');

  // Check that the functions map is complete.
  keys = lib_mirror.functions.getKeys();
  sort(keys);
  Expect.equals('['
                '_stringCompare, '
                'buildMethodString, '
                'buildVariableString, '
                'function, '
                'main, '
                'methodWithError, '
                'methodWithException, '
                'myVar, '
                'myVar=, '
                'sort, '
                'testBoolInstanceMirror, '
                'testCustomInstanceMirror, '
                'testDone, '
                'testIntegerInstanceMirror, '
                'testLibrariesMap, '
                'testMirrorErrors, '
                'testMirrorSystem, '
                'testNullInstanceMirror, '
                'testRootLibraryMirror, '
                'testStringInstanceMirror]',
                '$keys');

  // Check that the variables map is complete.
  keys = lib_mirror.variables.getKeys();
  sort(keys);
  Expect.equals('['
                'exit_port, '
                'expectedTests, '
                'final_global_var, '
                'global_var]',
                '$keys');

  ClassMirror cls_mirror = lib_mirror.members['MyClass'];

  // Test function mirrors.
  MethodMirror func = lib_mirror.members['function'];
  Expect.isTrue(func is MethodMirror);
  Expect.equals('function toplevel static method', buildMethodString(func));

  func = lib_mirror.members['myVar'];
  Expect.isTrue(func is MethodMirror);
  Expect.equals('myVar toplevel static getter', buildMethodString(func));

  func = lib_mirror.members['myVar='];
  Expect.isTrue(func is MethodMirror);
  Expect.equals('myVar= toplevel static setter', buildMethodString(func));

  func = cls_mirror.members['method'];
  Expect.isTrue(func is MethodMirror);
  Expect.equals('method method', buildMethodString(func));

  func = cls_mirror.members['MyClass'];
  Expect.isTrue(func is MethodMirror);
  Expect.equals('MyClass constructor', buildMethodString(func));

  // Test variable mirrors.
  VariableMirror variable = lib_mirror.members['global_var'];
  Expect.isTrue(variable is VariableMirror);
  Expect.equals('global_var toplevel static', buildVariableString(variable));

  variable = lib_mirror.members['final_global_var'];
  Expect.isTrue(variable is VariableMirror);
  Expect.equals('final_global_var toplevel static final',
                buildVariableString(variable));

  variable = cls_mirror.members['value'];
  Expect.isTrue(variable is VariableMirror);
  Expect.equals('value final', buildVariableString(variable));
}

void testLibrariesMap(Map libraries) {
  // Just look for a couple of well-known libs.
  LibraryMirror core_lib = libraries['dart:core'];
  Expect.isTrue(core_lib is LibraryMirror);

  LibraryMirror mirror_lib = libraries['dart:mirrors'];
  Expect.isTrue(mirror_lib is LibraryMirror);

  // Lookup an interface from a library and make sure it is sane.
  ClassMirror list_intf = core_lib.members['List'];
  Expect.isTrue(list_intf is ClassMirror);
  Expect.equals('List', list_intf.simpleName);
  Expect.equals('Object', list_intf.superclass.simpleName);
  Expect.equals('ListFactory', list_intf.defaultFactory.simpleName);
  Expect.equals('dart:core', list_intf.library.simpleName);
  Expect.isFalse(list_intf.isClass);
  Expect.equals('Collection', list_intf.superinterfaces[0].simpleName);
  Expect.equals("ClassMirror on 'List'", list_intf.toString());

  // Lookup a class from a library and make sure it is sane.
  ClassMirror oom_cls = core_lib.members['OutOfMemoryException'];
  Expect.isTrue(oom_cls is ClassMirror);
  Expect.equals('OutOfMemoryException', oom_cls.simpleName);
  Expect.equals('Object', oom_cls.superclass.simpleName);
  Expect.isTrue(oom_cls.defaultFactory === null);
  Expect.equals('dart:core', oom_cls.library.simpleName);
  Expect.isTrue(oom_cls.isClass);
  Expect.equals('Exception', oom_cls.superinterfaces[0].simpleName);
  Expect.equals("ClassMirror on 'OutOfMemoryException'",
                oom_cls.toString());
  testDone('testLibrariesMap');
}

void testMirrorSystem(MirrorSystem mirrors) {
  Expect.isTrue(mirrors.isolate.debugName.contains('main'));
  testRootLibraryMirror(mirrors.isolate.rootLibrary);
  testLibrariesMap(mirrors.libraries);
  Expect.equals('void', mirrors.voidType.simpleName);
  Expect.equals('Dynamic', mirrors.dynamicType.simpleName);
  testDone('testMirrorSystem');
}

void testIntegerInstanceMirror(InstanceMirror mirror) {
  Expect.equals('int', mirror.type.simpleName);
  Expect.isTrue(mirror.hasReflectee);
  Expect.equals(1001, mirror.reflectee);
  Expect.equals("InstanceMirror on <1001>", mirror.toString());

  // Invoke (mirror + mirror).
  mirror.invoke('+', [ mirror ]).then(
      (InstanceMirror retval) {
        Expect.equals('int', retval.type.simpleName);
        Expect.isTrue(retval.hasReflectee);
        Expect.equals(2002, retval.reflectee);
        testDone('testIntegerInstanceMirror');
      });
}

void testStringInstanceMirror(InstanceMirror mirror) {
  Expect.equals('String', mirror.type.simpleName);
  Expect.isTrue(mirror.hasReflectee);
  Expect.equals('This\nis\na\nString', mirror.reflectee);
  Expect.equals("InstanceMirror on <'This\\nis\\na\\nString'>",
                mirror.toString());

  // Invoke mirror[0].
  mirror.invoke('[]', [ 0 ]).then(
      (InstanceMirror retval) {
        Expect.equals('String', retval.type.simpleName);
        Expect.isTrue(retval.hasReflectee);
        Expect.equals('T', retval.reflectee);
        testDone('testStringInstanceMirror');
      });
}

void testBoolInstanceMirror(InstanceMirror mirror) {
  Expect.equals('bool', mirror.type.simpleName);
  Expect.isTrue(mirror.hasReflectee);
  Expect.equals(true, mirror.reflectee);
  Expect.equals("InstanceMirror on <true>", mirror.toString());
  testDone('testBoolInstanceMirror');
}

void testNullInstanceMirror(InstanceMirror mirror) {
  // TODO(turnidge): This is returning the wrong class.  Fix it.
  Expect.equals('Object', mirror.type.simpleName);
  Expect.isTrue(mirror.hasReflectee);
  Expect.equals(null, mirror.reflectee);
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
  Expect.isTrue(mirror.hasReflectee);
  bool saw_exception = false;
  try {
    mirror.reflectee;
  } catch (MirrorException me) {
    saw_exception = true;
  }
  Expect.isFalse(saw_exception);
  Expect.equals("InstanceMirror on instance of 'MyClass'", mirror.toString());

  ClassMirror cls = mirror.type;
  Expect.isTrue(cls is ClassMirror);
  Expect.equals('MyClass', cls.simpleName);
  Expect.equals('MySuperClass', cls.superclass.simpleName);
  Expect.isTrue(cls.defaultFactory === null);
  Expect.equals('isolate_mirror_local_test', cls.library.simpleName);
  Expect.isTrue(cls.isClass);
  Expect.equals('MyInterface', cls.superinterfaces[0].simpleName);
  Expect.equals("ClassMirror on 'MyClass'",
                cls.toString());

  // Invoke mirror.method(1000).
  mirror.invoke('method', [ 1000 ]).then(
      (InstanceMirror retval) {
        Expect.equals('int', retval.type.simpleName);
        Expect.isTrue(retval.hasReflectee);
        Expect.equals(1017, retval.reflectee);
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

void testMirrorErrors(MirrorSystem mirrors) {
  LibraryMirror lib_mirror = mirrors.isolate.rootLibrary;

  Future<InstanceMirror> future =
      lib_mirror.invoke('methodWithException', []);
  future.handleException(
      (MirroredError exc) {
        Expect.isTrue(exc is MirroredUncaughtExceptionError);
        Expect.equals('MyException',
                      exc.exception_mirror.type.simpleName);
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
                                        'testMirrorSystem',
                                        'testIntegerInstanceMirror',
                                        'testStringInstanceMirror',
                                        'testBoolInstanceMirror',
                                        'testNullInstanceMirror',
                                        'testCustomInstanceMirror',
                                        'testMirrorErrors1',
                                        'testMirrorErrors2',
                                        'testMirrorErrors3']);

  // Test that an isolate can reflect on itself.
  mirrorSystemOf(exit_port.toSendPort()).then(testMirrorSystem);

  testIntegerInstanceMirror(reflect(1001));
  testStringInstanceMirror(reflect('This\nis\na\nString'));
  testBoolInstanceMirror(reflect(true));
  testNullInstanceMirror(reflect(null));
  testCustomInstanceMirror(reflect(new MyClass(17)));
  testMirrorErrors(currentMirrorSystem());
}
