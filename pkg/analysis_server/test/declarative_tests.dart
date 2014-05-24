library declarative_tests;

import 'dart:mirrors';

import 'package:unittest/unittest.dart' show group, test;

/**
 * Use [runTest] annotation to indicate that method is a test method.
 * Alternatively method name can have the `test` prefix.
 */
const runTest = const _RunTest();

class _RunTest {
  const _RunTest();
}

/**
 * Creates a new named group of tests with the name of the given [Type], then
 * adds new tests using [addTestMethods].
 */
addTestSuite(Type type) {
  group(type.toString(), () {
    addTestMethods(type);
  });
}

/**
 * Creates a new test case for the each static method with the name starting
 * with `test` or having the [runTest] annotation.
 */
addTestMethods(Type type) {
  var typeMirror = reflectClass(type);
  typeMirror.staticMembers.forEach((methodSymbol, method) {
    if (_isTestMethod(method)) {
      var methodName = MirrorSystem.getName(methodSymbol);
      test(methodName, () {
        typeMirror.invoke(methodSymbol, []);
      });
    }
  });
}

bool _isTestMethod(MethodMirror method) {
  if (method.parameters.isNotEmpty) {
    return false;
  }
  var methodSymbol = method.simpleName;
  // name starts with "test"
  var methodName = MirrorSystem.getName(methodSymbol);
  if (methodName.startsWith('test')) {
    return true;
  }
  // has @testMethod
  return method.metadata.any((annotation) {
    return identical(annotation.reflectee, runTest);
  });
}
