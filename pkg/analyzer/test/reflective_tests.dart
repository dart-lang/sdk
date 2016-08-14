// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.reflective_tests;

import 'dart:async';
@MirrorsUsed(metaTargets: 'ReflectiveTest')
import 'dart:mirrors';

import 'package:unittest/unittest.dart';

/**
 * A marker annotation used to annotate overridden test methods (so we cannot
 * rename them to `fail_`) which are expected to fail at `assert` in the
 * checked mode.
 */
const _AssertFailingTest assertFailingTest = const _AssertFailingTest();

/**
 * A marker annotation used to annotate overridden test methods (so we cannot
 * rename them to `fail_`) which are expected to fail.
 */
const _FailingTest failingTest = const _FailingTest();

/**
 * A marker annotation used to instruct dart2js to keep reflection information
 * for the annotated classes.
 */
const ReflectiveTest reflectiveTest = const ReflectiveTest();

/**
 * Test classes annotated with this annotation are run using [solo_group].
 */
const _SoloTest soloTest = const _SoloTest();

/**
 * Is `true` the application is running in the checked mode.
 */
final bool _isCheckedMode = () {
  try {
    assert(false);
    return false;
  } catch (_) {
    return true;
  }
}();

/**
 * Runs test methods existing in the given [type].
 *
 * Methods with names starting with `test` are run using [test] function.
 * Methods with names starting with `solo_test` are run using [solo_test] function.
 *
 * Each method is run with a new instance of [type].
 * So, [type] should have a default constructor.
 *
 * If [type] declares method `setUp`, it methods will be invoked before any test
 * method invocation.
 *
 * If [type] declares method `tearDown`, it will be invoked after any test
 * method invocation. If method returns [Future] to test some asynchronous
 * behavior, then `tearDown` will be invoked in `Future.complete`.
 */
void runReflectiveTests(Type type) {
  ClassMirror classMirror = reflectClass(type);
  if (!classMirror.metadata.any((InstanceMirror annotation) =>
      annotation.type.reflectedType == ReflectiveTest)) {
    String name = MirrorSystem.getName(classMirror.qualifiedName);
    throw new Exception('Class $name must have annotation "@reflectiveTest" '
        'in order to be run by runReflectiveTests.');
  }
  void runMembers() {
    classMirror.instanceMembers
        .forEach((Symbol symbol, MethodMirror memberMirror) {
      // we need only methods
      if (memberMirror is! MethodMirror || !memberMirror.isRegularMethod) {
        return;
      }
      String memberName = MirrorSystem.getName(symbol);
      // test_
      if (memberName.startsWith('test_')) {
        test(memberName, () {
          if (_hasFailingTestAnnotation(memberMirror) ||
              _isCheckedMode && _hasAssertFailingTestAnnotation(memberMirror)) {
            return _runFailingTest(classMirror, symbol);
          } else {
            return _runTest(classMirror, symbol);
          }
        });
        return;
      }
      // solo_test_
      if (memberName.startsWith('solo_test_')) {
        solo_test(memberName, () {
          return _runTest(classMirror, symbol);
        });
      }
      // fail_test_
      if (memberName.startsWith('fail_')) {
        test(memberName, () {
          return _runFailingTest(classMirror, symbol);
        });
      }
      // solo_fail_test_
      if (memberName.startsWith('solo_fail_')) {
        solo_test(memberName, () {
          return _runFailingTest(classMirror, symbol);
        });
      }
    });
  }
  String className = MirrorSystem.getName(classMirror.simpleName);
  if (_hasAnnotationInstance(classMirror, soloTest)) {
    solo_group(className, runMembers);
  } else {
    group(className, runMembers);
  }
}

bool _hasAnnotationInstance(DeclarationMirror declaration, instance) =>
    declaration.metadata.any((InstanceMirror annotation) =>
        identical(annotation.reflectee, instance));

bool _hasAssertFailingTestAnnotation(MethodMirror method) =>
    _hasAnnotationInstance(method, assertFailingTest);

bool _hasFailingTestAnnotation(MethodMirror method) =>
    _hasAnnotationInstance(method, failingTest);

Future _invokeSymbolIfExists(InstanceMirror instanceMirror, Symbol symbol) {
  var invocationResult = null;
  InstanceMirror closure;
  try {
    closure = instanceMirror.getField(symbol);
  } on NoSuchMethodError {}

  if (closure is ClosureMirror) {
    invocationResult = closure.apply([]).reflectee;
  }
  return new Future.value(invocationResult);
}

/**
 * Run a test that is expected to fail, and confirm that it fails.
 *
 * This properly handles the following cases:
 * - The test fails by throwing an exception
 * - The test returns a future which completes with an error.
 *
 * However, it does not handle the case where the test creates an asynchronous
 * callback using expectAsync(), and that callback generates a failure.
 */
Future _runFailingTest(ClassMirror classMirror, Symbol symbol) {
  return new Future(() => _runTest(classMirror, symbol)).then((_) {
    fail('Test passed - expected to fail.');
  }, onError: (_) {});
}

_runTest(ClassMirror classMirror, Symbol symbol) {
  InstanceMirror instanceMirror = classMirror.newInstance(new Symbol(''), []);
  return _invokeSymbolIfExists(instanceMirror, #setUp)
      .then((_) => instanceMirror.invoke(symbol, []).reflectee)
      .whenComplete(() => _invokeSymbolIfExists(instanceMirror, #tearDown));
}

/**
 * A marker annotation used to instruct dart2js to keep reflection information
 * for the annotated classes.
 */
class ReflectiveTest {
  const ReflectiveTest();
}

/**
 * A marker annotation used to annotate overridden test methods (so we cannot
 * rename them to `fail_`) which are expected to fail at `assert` in the
 * checked mode.
 */
class _AssertFailingTest {
  const _AssertFailingTest();
}

/**
 * A marker annotation used to annotate overridden test methods (so we cannot
 * rename them to `fail_`) which are expected to fail.
 */
class _FailingTest {
  const _FailingTest();
}

/**
 * A marker annotation used to annotate a test class to run it using
 * [solo_group].
 */
class _SoloTest {
  const _SoloTest();
}
