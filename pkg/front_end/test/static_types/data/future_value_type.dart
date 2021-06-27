// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: nnbd=false*/

/*cfe:nnbd.library: nnbd=true*/

import 'dart:async';

/*cfe:nnbd.member: declaredFutureInt:futureValueType=int!*/
Future<int> declaredFutureInt() async {
  return
      /*cfe.int*/ /*cfe:nnbd.int!*/ 0;
}

/*cfe:nnbd.member: declaredFutureOrInt:futureValueType=int!*/
FutureOr<int> declaredFutureOrInt() async {
  return
      /*cfe.int*/ /*cfe:nnbd.int!*/ 0;
}

/*cfe:nnbd.member: declaredObject:futureValueType=Object?*/
Object declaredObject() async {
  return
      /*cfe.int*/ /*cfe:nnbd.int!*/ 0;
}

/*cfe:nnbd.member: omitted:futureValueType=dynamic*/
omitted() async {}

/*cfe:nnbd.member: method:futureValueType=dynamic*/
method() async {
  /*cfe:nnbd.futureValueType=int!*/
  Future<int> declaredLocalFutureInt() async {
    return
        /*cfe.int*/ /*cfe:nnbd.int!*/ 0;
  }

  /*cfe:nnbd.futureValueType=int!*/
  FutureOr<int> declaredLocalFutureOrInt() async {
    return
        /*cfe.int*/ /*cfe:nnbd.int!*/ 0;
  }

  /*cfe:nnbd.futureValueType=Object?*/
  Object declaredLocalObject() async {
    return
        /*cfe.int*/ /*cfe:nnbd.int!*/ 0;
  }

  /*cfe:nnbd.futureValueType=Null*/ omittedLocal() async {}

  Future<int> inferredCalledFutureInt =
      /*cfe.Future<int> Function()*/
      /*cfe:nnbd.Future<int!>! Function()!,futureValueType=int!*/
      () async {
    return
        /*cfe.int*/ /*cfe:nnbd.int!*/ 0;
  }
          /*cfe.invoke: Future<int>*/
          /*cfe:nnbd.invoke: Future<int!>!*/
          ();

  FutureOr<int> inferredCalledFutureOrInt =
      /*cfe.Future<int> Function()*/
      /*cfe:nnbd.Future<int!>! Function()!,futureValueType=int!*/
      () async {
    return
        /*cfe.int*/ /*cfe:nnbd.int!*/ 0;
  }
          /*cfe.invoke: Future<int>*/
          /*cfe:nnbd.invoke: Future<int!>!*/
          ();

  Future<int> Function() inferredFutureInt =
      /*cfe.Future<int> Function()*/
      /*cfe:nnbd.Future<int!>! Function()!,futureValueType=int!*/
      () async {
    return
        /*cfe.int*/ /*cfe:nnbd.int!*/ 0;
  };

  FutureOr<int> Function() inferredFutureOrInt =
      /*cfe.Future<int> Function()*/
      /*cfe:nnbd.Future<int!>! Function()!,futureValueType=int!*/
      () async {
    return
        /*cfe.int*/ /*cfe:nnbd.int!*/ 0;
  };

  Object Function() inferredInt =
      /*cfe.Future<int> Function()*/
      /*cfe:nnbd.Future<int!>! Function()!,futureValueType=int!*/
      () async {
    return
        /*cfe.int*/ /*cfe:nnbd.int!*/ 0;
  };

  Object Function() inferredNull =
      /*cfe.Future<Null> Function()*/
      /*cfe:nnbd.Future<Null>! Function()!,futureValueType=Null*/
      () async {
    return
        /*Null*/ null;
  };

  Object Function() inferredEmpty =
      /*cfe.Future<Null> Function()*/
      /*cfe:nnbd.Future<Null>! Function()!,futureValueType=Null*/
      () async {};
}
