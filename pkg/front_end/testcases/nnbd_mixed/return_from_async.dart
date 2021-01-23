// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'return_from_async_lib.dart';

abstract class Class {
  FutureOr<int> throwFutureOrInt();

  int throwInt();

  Future<int> throwFutureInt();

  dynamic throwDynamic();

  Future<num> throwFutureNum();
}

bool caughtFutureOrInt = false;

Future<int> callFutureOrInt(Class c) async {
  try {
    return c.throwFutureOrInt();
  } catch (e) {
    print('Caught "$e"');
    caughtFutureOrInt = true;
    return 0;
  }
}

bool caughtInt = false;

Future<int> callInt(Class c) async {
  try {
    return c.throwInt();
  } catch (e) {
    print('Caught "$e"');
    caughtInt = true;
    return 0;
  }
}

bool caughtFutureInt = false;

Future<int> callFutureInt(Class c) async {
  try {
    return c.throwFutureInt();
  } catch (e) {
    print('Caught "$e"');
    caughtFutureInt = true;
    return 0;
  }
}

bool caughtDynamic = false;

Future<int> callDynamic(Class c) async {
  try {
    return c.throwDynamic();
  } catch (e) {
    print('Caught "$e"');
    caughtDynamic = true;
    return 0;
  }
}

bool caughtFutureNum = false;

Future<num> callFutureNum(Class c) async {
  try {
    return c.throwFutureNum();
  } catch (e) {
    print('Caught "$e"');
    caughtFutureNum = true;
    return 0;
  }
}

void main() async {
  Class c = new Subclass();
  await callFutureOrInt(c);
  if (!caughtFutureOrInt) throw 'Uncaught async return';
  await callInt(c);
  if (!caughtInt) throw 'Uncaught async return';
  await callFutureInt(c);
  if (!caughtFutureInt) throw 'Uncaught async return';
  await callDynamic(c);
  if (!caughtDynamic) throw 'Uncaught async return';
  await callFutureNum(c);
  if (!caughtFutureNum) throw 'Uncaught async return';
}
