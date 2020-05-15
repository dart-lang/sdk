// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: nnbd=false*/
/*cfe:nnbd.library: nnbd=true*/

forInDynamicList(dynamic list) {
  /*current: dynamic*/
  for (var e in
      /*cfe.as: Iterable<dynamic>*/
      /*cfe:nnbd.as: Iterable<dynamic>!*/
      /*dynamic*/ list) {
    /*dynamic*/ e;
  }
}

forInDynamic(List<dynamic> list) {
  /*current: dynamic*/
  for (var e in
      /*cfe.List<dynamic>*/
      /*cfe:nnbd.List<dynamic>!*/ list) {
    /*dynamic*/ e;
  }
}

forInInt(List<int> list) {
  /*cfe.current: int*/
  /*cfe:nnbd.current: int!*/
  for (var e in
      /*cfe.List<int>*/
      /*cfe:nnbd.List<int!>!*/ list) {
    /*cfe.int*/
    /*cfe:nnbd.int!*/
    e;
  }
}

forInIntToNum(List<int> list) {
  /*cfe.current: int*/
  /*cfe:nnbd.current: int!*/
  for (num e in
      /*cfe.List<int>*/
      /*cfe:nnbd.List<int!>!*/ list) {
    /*cfe.num*/
    /*cfe:nnbd.num!*/
    e;
  }
}

asyncForInDynamicStream(dynamic stream) async {
  /*current: dynamic*/
  await for (var e in
      /*cfe.as: Stream<dynamic>*/
      /*cfe:nnbd.as: Stream<dynamic>!*/
      /*dynamic*/ stream) {
    /*dynamic*/ e;
  }
}

asyncForInDynamic(Stream<dynamic> stream) async {
  /*current: dynamic*/
  await for (var e in
      /*cfe.Stream<dynamic>*/
      /*cfe:nnbd.Stream<dynamic>!*/
      stream) {
    /*dynamic*/ e;
  }
}

asyncForInInt(Stream<int> stream) async {
  /*cfe.current: int*/
  /*cfe:nnbd.current: int!*/
  await for (var e in
      /*cfe.Stream<int>*/
      /*cfe:nnbd.Stream<int!>!*/
      stream) {
    /*cfe.int*/
    /*cfe:nnbd.int!*/
    e;
  }
}

asyncForInIntToNum(Stream<int> stream) async {
  /*cfe.current: int*/
  /*cfe:nnbd.current: int!*/
  await for (num e in
      /*cfe.Stream<int>*/
      /*cfe:nnbd.Stream<int!>!*/
      stream) {
    /*cfe.num*/
    /*cfe:nnbd.num!*/
    e;
  }
}

abstract class CustomIterable implements Iterable<num> {
  Iterator<int> get iterator;
}

customIterable(CustomIterable iterable) {
  /*cfe.current: num*/
  /*cfe:nnbd.current: num!*/
  for (var e in
      /*cfe.CustomIterable*/
      /*cfe:nnbd.CustomIterable!*/
      iterable) {
    /*cfe.num*/
    /*cfe:nnbd.num!*/
    e;
  }
}

abstract class CustomStream implements Stream<num> {
  Iterator<int> get iterator;
}

customStream(CustomStream stream) async {
  /*cfe.current: num*/
  /*cfe:nnbd.current: num!*/
  await for (var e in
      /*cfe.CustomStream*/
      /*cfe:nnbd.CustomStream!*/
      stream) {
    /*cfe.num*/
    /*cfe:nnbd.num!*/
    e;
  }
}

abstract class IterableWithCustomIterator implements Iterable<num> {
  CustomIterator get iterator;
}

abstract class CustomIterator implements Iterator<num> {
  int get current;
}

customIterableIterator(IterableWithCustomIterator iterable) {
  /*cfe.current: num*/
  /*cfe:nnbd.current: num!*/
  for (var e in
      /*cfe.IterableWithCustomIterator*/
      /*cfe:nnbd.IterableWithCustomIterator!*/
      iterable) {
    /*cfe.num*/
    /*cfe:nnbd.num!*/
    e;
  }
}

abstract class StreamWithCustomIterator implements Stream<num> {
  CustomIterator get iterator;
}

customStreamIterator(StreamWithCustomIterator stream) async {
  /*cfe.current: num*/
  /*cfe:nnbd.current: num!*/
  await for (var e in
      /*cfe.StreamWithCustomIterator*/
      /*cfe:nnbd.StreamWithCustomIterator!*/
      stream) {
    /*cfe.num*/
    /*cfe:nnbd.num!*/
    e;
  }
}

void genericIterable<T extends Iterable<T>>(T x) {
  /*cfe.current: T*/
  /*cfe:nnbd.current: T!*/
  for (var y in
      /*cfe.T*/
      /*cfe:nnbd.T!*/
      x) {
    /*cfe.T*/ /*cfe:nnbd.T!*/ y;
  }
}

void genericStream<T extends Stream<T>>(T x) async {
  /*cfe.current: T*/
  /*cfe:nnbd.current: T!*/
  await for (var y in
      /*cfe.T*/
      /*cfe:nnbd.T!*/
      x) {
    /*cfe.T*/ /*cfe:nnbd.T!*/ y;
  }
}
