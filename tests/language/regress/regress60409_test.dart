// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/60409.
//
// It appears that dart2js fails to correctly model scopes of for-loops in
// control-flow collections in plain field initializer expressions.
//
// The `field` and `fieldFinal` cases failed at the time of reporting #60409,
// the other variations passed.

import 'package:expect/expect.dart';

final List logField = [];
final List logFinalField = [];
final List logLateField = [];
final List logLateFinalField = [];
final List logConstructorInitializedField = [];
final List logStaticField = [];
final List logStaticFinalField = [];

class A {
  List<int> field = [
    for (int i = 0; i < 9; ++i)
      () {
        logField.add(i);
        i += 2;
        return i;
      }(),
  ];

  final List<int> finalField = [
    for (int i = 0; i < 9; ++i)
      () {
        logFinalField.add(i);
        i += 2;
        return i;
      }(),
  ];

  final List<int> constructorInitializedField;

  late List<int> lateField = [
    for (int i = 0; i < 9; ++i)
      () {
        logLateField.add(i);
        i += 2;
        return i;
      }(),
  ];

  late final List<int> lateFinalField = [
    for (int i = 0; i < 9; ++i)
      () {
        logLateFinalField.add(i);
        i += 2;
        return i;
      }(),
  ];

  static List<int> staticField = [
    for (int i = 0; i < 9; ++i)
      () {
        logStaticField.add(i);
        i += 2;
        return i;
      }(),
  ];

  static final List<int> staticFinalField = [
    for (int i = 0; i < 9; ++i)
      () {
        logStaticFinalField.add(i);
        i += 2;
        return i;
      }(),
  ];

  int version = ++_version;
  static int _version = 0;

  A()
    : constructorInitializedField = [
        for (int i = 0; i < 9; ++i)
          () {
            logConstructorInitializedField.add(i);
            i += 2;
            return i;
          }(),
      ] {
    print('A($version)');
    logField.add('c');
    logFinalField.add('c');
    logLateField.add('c');
    logLateFinalField.add('c');
    logConstructorInitializedField.add('c');
    logStaticField.add('c');
    logStaticFinalField.add('c');
  }

  /// Use all the fields to ensure lazy initialization has happened.
  void use() {
    field;
    finalField;
    constructorInitializedField;
    lateField;
    lateFinalField;
    staticField;
    staticFinalField;
  }

  void check() {
    void expect(String expected, List log) {
      Expect.equals(expected, log.join(','));
    }

    expect('2,5,8', field);
    expect('2,5,8', finalField);
    expect('2,5,8', constructorInitializedField);
    expect('2,5,8', lateField);
    expect('2,5,8', lateFinalField);
    expect('2,5,8', staticField);
    expect('2,5,8', staticFinalField);

    expect('0,3,6,c,x,0,3,6,c', logField);
    expect('0,3,6,c,x,0,3,6,c', logFinalField);
    expect('0,3,6,c,x,0,3,6,c', logConstructorInitializedField);
    expect('c,0,3,6,x,c,0,3,6', logLateField);
    expect('c,0,3,6,x,c,0,3,6', logLateFinalField);
    expect('c,0,3,6,x,c', logStaticField);
    expect('c,0,3,6,x,c', logStaticFinalField);
  }
}

void main() {
  final a1 = A();
  a1.use();

  logField.add('x');
  logFinalField.add('x');
  logLateField.add('x');
  logLateFinalField.add('x');
  logConstructorInitializedField.add('x');
  logStaticField.add('x');
  logStaticFinalField.add('x');

  final a2 = A();
  a2.use();
  a2.check();
}
