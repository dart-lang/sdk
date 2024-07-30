// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

forInDynamicList(dynamic list) {
  /*current: dynamic*/
  for (var e in
      /*as: Iterable<dynamic>!*/
      /*dynamic*/ list) {
    /*dynamic*/ e;
  }
}

forInDynamic(List<dynamic> list) {
  /*current: dynamic*/
  for (var e in
      /*List<dynamic>!*/
      list) {
    /*dynamic*/ e;
  }
}

forInInt(List<int> list) {
  /*current: int!*/
  for (var e in
      /*List<int!>!*/
      list) {
    /*int!*/
    e;
  }
}

forInIntToNum(List<int> list) {
  /*current: int!*/
  for (num e in
      /*List<int!>!*/
      list) {
    /*num!*/
    e;
  }
}

/*member: asyncForInDynamicStream:futureValueType=dynamic*/
asyncForInDynamicStream(dynamic stream) async {
  /*current: dynamic*/
  await for (var e in
      /*as: Stream<dynamic>!*/
      /*dynamic*/ stream) {
    /*dynamic*/ e;
  }
}

/*member: asyncForInDynamic:futureValueType=dynamic*/
asyncForInDynamic(Stream<dynamic> stream) async {
  /*current: dynamic*/
  await for (var e in
      /*Stream<dynamic>!*/
      stream) {
    /*dynamic*/ e;
  }
}

/*member: asyncForInInt:futureValueType=dynamic*/
asyncForInInt(Stream<int> stream) async {
  /*current: int!*/
  await for (var e in
      /*Stream<int!>!*/
      stream) {
    /*int!*/
    e;
  }
}

/*member: asyncForInIntToNum:futureValueType=dynamic*/
asyncForInIntToNum(Stream<int> stream) async {
  /*current: int!*/
  await for (num e in
      /*Stream<int!>!*/
      stream) {
    /*num!*/
    e;
  }
}

abstract class CustomIterable implements Iterable<num> {
  Iterator<int> get iterator;
}

customIterable(CustomIterable iterable) {
  /*current: num!*/
  for (var e in
      /*CustomIterable!*/
      iterable) {
    /*num!*/
    e;
  }
}

abstract class CustomStream implements Stream<num> {
  Iterator<int> get iterator;
}

/*member: customStream:futureValueType=dynamic*/
customStream(CustomStream stream) async {
  /*current: num!*/
  await for (var e in
      /*CustomStream!*/
      stream) {
    /*num!*/
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
  /*current: num!*/
  for (var e in
      /*IterableWithCustomIterator!*/
      iterable) {
    /*num!*/
    e;
  }
}

abstract class StreamWithCustomIterator implements Stream<num> {
  CustomIterator get iterator;
}

/*member: customStreamIterator:futureValueType=dynamic*/
customStreamIterator(StreamWithCustomIterator stream) async {
  /*current: num!*/
  await for (var e in
      /*StreamWithCustomIterator!*/
      stream) {
    /*num!*/
    e;
  }
}

void genericIterable<T extends Iterable<T>>(T x) {
  /*current: T!*/
  for (var y in
      /*T!*/
      x) {
    /*T!*/ y;
  }
}

/*member: genericStream:futureValueType=void*/
void genericStream<T extends Stream<T>>(T x) async {
  /*current: T!*/
  await for (var y in
      /*T!*/
      x) {
    /*T!*/ y;
  }
}
