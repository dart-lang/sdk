// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class State<T extends StatefulWidget> {}

class StatefulWidget {}

mixin MyMixin<T, W extends StatefulWidget> on State<W> {
  void listenToEvents(Stream<MyModel<T>> stream) {
    stream.listen((event) {});
  }
}

class MyModel<T> {
  MyModel(this.data);

  final T data;
}

typedef MyMixinTypedef = MyMixin<String, MyWidget>;

class MyWidget extends StatefulWidget {}

// TODO: hover over `listenToEvents` and observe the tooltip

// Case 1: without additional typedef
// produces `void listenToEvents(Stream<MyModel<String>> stream)`

class MyWidgetState1 extends State<MyWidget> with MyMixin<String, MyWidget> {
  void doSomething() {
    listenToEvents(Stream.value(MyModel('foo')));
  }
}

// Case 2: with typedef for the mixin
// produces `void listenToEvents(Stream<MyModel<dynamic>> stream)`

class MyWidgetState2 extends State<MyWidget> with MyMixinTypedef {
  void doSomething() {
    listenToEvents(Stream.value(MyModel('foo')));
  }
}
