// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

bool caughtFutureOrInt = false;

FutureOr<int> throwFutureOrInt() async {
  throw 'FutureOr<int>';
}

Future<int> callFutureOrInt() async {
  try {
    return throwFutureOrInt();
  } catch (e) {
    print('Caught "$e"');
    caughtFutureOrInt = true;
    return 0;
  }
}

bool caughtInt = false;

int throwInt() {
  throw 'int';
}

Future<int> callInt() async {
  try {
    return throwInt();
  } catch (e) {
    print('Caught "$e"');
    caughtInt = true;
    return 0;
  }
}

bool caughtFutureInt = false;

Future<int> throwFutureInt() async {
  throw 'Future<int>';
}

Future<int> callFutureInt() async {
  try {
    return throwFutureInt();
  } catch (e) {
    print('Caught "$e"');
    caughtFutureInt = true;
    return 0;
  }
}

bool caughtDynamic = false;

dynamic throwDynamic() {
  throw 'dynamic';
}

Future<int> callDynamic() async {
  try {
    return throwDynamic();
  } catch (e) {
    print('Caught "$e"');
    caughtDynamic = true;
    return 0;
  }
}

bool caughtFutureNum = false;

Future<int> throwFutureNum() async {
  throw 'Future<num>';
}

Future<num> callFutureNum() async {
  try {
    return throwFutureNum();
  } catch (e) {
    print('Caught "$e"');
    caughtFutureNum = true;
    return 0;
  }
}

void main() async {
  await callFutureOrInt();
  if (!caughtFutureOrInt) throw 'Uncaught async return';
  await callInt();
  if (!caughtInt) throw 'Uncaught async return';
  await callFutureInt();
  if (!caughtFutureInt) throw 'Uncaught async return';
  await callDynamic();
  if (!caughtDynamic) throw 'Uncaught async return';
  await callFutureNum();
  if (!caughtFutureNum) throw 'Uncaught async return';
}
