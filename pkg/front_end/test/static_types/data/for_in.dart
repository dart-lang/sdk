// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe|dart2js.library: nnbd=false*/
/*cfe:nnbd.library: nnbd=true*/

forInDynamicList(dynamic list) {
  /*current: dynamic*/
  for (var e in
      /*cfe|dart2js.as: Iterable<dynamic>*/
      /*cfe:nnbd.as: Iterable<dynamic>!*/
      /*dynamic*/ list) {
    /*dynamic*/ e;
  }
}

forInDynamic(List<dynamic> list) {
  /*current: dynamic*/
  for (var e in
      /*cfe|dart2js.List<dynamic>*/
      /*cfe:nnbd.List<dynamic>!*/ list) {
    /*dynamic*/ e;
  }
}

forInInt(List<int> list) {
  /*current: int*/
  for (var e in
      /*cfe|dart2js.List<int>*/
      /*cfe:nnbd.List<int!>!*/ list) {
    /*int*/
    e;
  }
}

forInIntToNum(List<int> list) {
  /*current: int*/
  for (num e in
      /*cfe|dart2js.List<int>*/
      /*cfe:nnbd.List<int!>!*/ list) {
    /*cfe|dart2js.num*/
    /*cfe:nnbd.num!*/
    e;
  }
}

asyncForInDynamicStream(dynamic stream) async {
  /*current: dynamic*/
  await for (var e in
      /*cfe|dart2js.as: Stream<dynamic>*/
      /*cfe:nnbd.as: Stream<dynamic>!*/
      /*dynamic*/ stream) {
    /*dynamic*/ e;
  }
}

asyncForInDynamic(Stream<dynamic> stream) async {
  /*current: dynamic*/
  await for (var e in
      /*cfe|dart2js.Stream<dynamic>*/
      /*cfe:nnbd.Stream<dynamic>!*/
      stream) {
    /*dynamic*/ e;
  }
}

asyncForInInt(Stream<int> stream) async {
  /*current: int*/
  await for (var e in
      /*cfe|dart2js.Stream<int>*/
      /*cfe:nnbd.Stream<int!>!*/
      stream) {
    /*int*/
    e;
  }
}

asyncForInIntToNum(Stream<int> stream) async {
  /*current: int*/
  await for (num e in
      /*cfe|dart2js.Stream<int>*/
      /*cfe:nnbd.Stream<int!>!*/
      stream) {
    /*cfe|dart2js.num*/
    /*cfe:nnbd.num!*/
    e;
  }
}

abstract class CustomIterable implements Iterable<num> {
  Iterator<int> get iterator;
}

customIterable(CustomIterable iterable) {
  /*cfe|dart2js.current: num*/
  /*cfe:nnbd.current: num!*/
  for (var e in
      /*cfe|dart2js.CustomIterable*/
      /*cfe:nnbd.CustomIterable!*/
      iterable) {
    /*cfe|dart2js.num*/
    /*cfe:nnbd.num!*/
    e;
  }
}

abstract class CustomStream implements Stream<num> {
  Iterator<int> get iterator;
}

customStream(CustomStream stream) async {
  /*cfe|dart2js.current: num*/
  /*cfe:nnbd.current: num!*/
  await for (var e in
      /*cfe|dart2js.CustomStream*/
      /*cfe:nnbd.CustomStream!*/
      stream) {
    /*cfe|dart2js.num*/
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
  /*cfe|dart2js.current: num*/
  /*cfe:nnbd.current: num!*/
  for (var e in
      /*cfe|dart2js.IterableWithCustomIterator*/
      /*cfe:nnbd.IterableWithCustomIterator!*/
      iterable) {
    /*cfe|dart2js.num*/
    /*cfe:nnbd.num!*/
    e;
  }
}

abstract class StreamWithCustomIterator implements Stream<num> {
  CustomIterator get iterator;
}

customStreamIterator(StreamWithCustomIterator stream) async {
  /*cfe|dart2js.current: num*/
  /*cfe:nnbd.current: num!*/
  await for (var e in
      /*cfe|dart2js.StreamWithCustomIterator*/
      /*cfe:nnbd.StreamWithCustomIterator!*/
      stream) {
    /*cfe|dart2js.num*/
    /*cfe:nnbd.num!*/
    e;
  }
}
