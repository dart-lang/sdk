// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

import 'dart:async';

/*member: declaredFutureInt:futureValueType=int!*/
Future<int> declaredFutureInt() async {
  return
      /*int!*/ 0;
}

/*member: declaredFutureOrInt:futureValueType=int!*/
FutureOr<int> declaredFutureOrInt() async {
  return
      /*int!*/ 0;
}

/*member: declaredObject:futureValueType=Object?*/
Object declaredObject() async {
  return
      /*int!*/ 0;
}

/*member: omitted:futureValueType=dynamic*/
omitted() async {}

/*member: method:futureValueType=dynamic*/
method() async {
  /*futureValueType=int!*/Future<int> declaredLocalFutureInt() async {
    return
        /*int!*/ 0;
  }

  /*futureValueType=int!*/FutureOr<int> declaredLocalFutureOrInt() async {
    return
        /*int!*/ 0;
  }

  /*futureValueType=Object?*/Object declaredLocalObject() async {
    return
        /*int!*/ 0;
  }

  /*futureValueType=Null*/omittedLocal() async {}

  Future<int> inferredCalledFutureInt =
      /*Future<int!>! Function()!,futureValueType=int!*/
      () async {
    return
        /*int!*/ 0;
  }
          /*invoke: Future<int!>!*/
          ();

  FutureOr<int> inferredCalledFutureOrInt =
      /*Future<int!>! Function()!,futureValueType=int!*/
      () async {
    return
        /*int!*/ 0;
  }
          /*invoke: Future<int!>!*/
          ();

  Future<int> Function() inferredFutureInt =
      /*Future<int!>! Function()!,futureValueType=int!*/
      () async {
    return
        /*int!*/ 0;
  };

  FutureOr<int> Function() inferredFutureOrInt =
      /*Future<int!>! Function()!,futureValueType=int!*/
      () async {
    return
        /*int!*/ 0;
  };

  Object Function() inferredInt =
      /*Future<int!>! Function()!,futureValueType=int!*/
      () async {
    return
        /*int!*/ 0;
  };

  Object Function() inferredNull =
      /*Future<Null>! Function()!,futureValueType=Null*/
      () async {
    return
        /*Null*/ null;
  };

  Object Function() inferredEmpty =
      /*Future<Null>! Function()!,futureValueType=Null*/
      () async {};
}
