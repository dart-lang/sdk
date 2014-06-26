// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library reflective.tests;

import 'dart:async';

@MirrorsUsed(metaTargets: 'ReflectiveTestCase')
import 'dart:mirrors';

import 'package:unittest/unittest.dart';


/**
 * A marker annotation used to instruct dart2js to keep reflection information
 * for the annotated classes.
 */
class ReflectiveTestCase {
  const ReflectiveTestCase();
}


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
 * method invocation. If method returns [Future] to test some asyncronous
 * behavior, then `tearDown` will be invoked in `Future.complete`.
 */
void runReflectiveTests(Type type) {
  ClassMirror classMirror = reflectClass(type);
  classMirror.instanceMembers.forEach((symbol, memberMirror) {
    // we need only methods
    if (memberMirror is! MethodMirror || !memberMirror.isRegularMethod) {
      return;
    }
    String memberName = MirrorSystem.getName(symbol);
    // test_
    if (memberName.startsWith('test_')) {
      String testName = memberName.substring('test_'.length);
      test(testName, () {
        return _runTest(classMirror, symbol);
      });
      return;
    }
    // solo_test_
    if (memberName.startsWith('solo_test_')) {
      String testName = memberName.substring('solo_test_'.length);
      solo_test(testName, () {
        return _runTest(classMirror, symbol);
      });
    }
  });
}

_runTest(ClassMirror classMirror, Symbol symbol) {
  InstanceMirror instanceMirror = classMirror.newInstance(new Symbol(''), []);
  _invokeSymbolIfExists(instanceMirror, #setUp);
  var testReturn = instanceMirror.invoke(symbol, []).reflectee;
  if (testReturn is Future) {
    return testReturn.whenComplete(() {
      _invokeSymbolIfExists(instanceMirror, #tearDown);
    });
  } else {
    _invokeSymbolIfExists(instanceMirror, #tearDown);
    return testReturn;
  }
}


void _invokeSymbolIfExists(InstanceMirror instanceMirror, Symbol symbol) {
  try {
    instanceMirror.invoke(symbol, []);
  } on NoSuchMethodError catch (e) {
  }
}
