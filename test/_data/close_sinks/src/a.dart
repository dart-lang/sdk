// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: prefer_initializing_formals
// ignore_for_file: unnecessary_new
// ignore_for_file: unnecessary_this
// ignore_for_file: unused_field
// ignore_for_file: unused_local_variable
// ignore_for_file: use_setters_to_change_properties

import 'dart:async';
import 'dart:io';

class MockIOSink implements Sink {
  @override
  void add(data) {}

  @override
  void close() {}
}

IOSink outSink = stdout;
void inScope() {
  IOSink currentOut = outSink;
}

class A {
  IOSink _sinkA; // LINT
  void init(String filename) {
    _sinkA = new File(filename).openWrite();
  }
}

class B {
  IOSink _sinkB;
  void init(String filename) {
    _sinkB = new File(filename).openWrite(); // OK
  }

  void dispose(filename) {
    _sinkB.close();
  }
}

class B1 {
  Socket _socketB1;
  Future init(String filename) async {
    _socketB1 = await Socket.connect(null /*address*/, 1234); // OK
  }

  void dispose(String filename) {
    _socketB1.destroy();
  }
}

class C {
  final IOSink _sinkC; // OK

  C(this._sinkC);
}

class C1 {
  final IOSink _sinkC1; // OK
  final Object unrelated;

  C1.initializer(IOSink sink, blah)
      : this._sinkC1 = sink,
        this.unrelated = blah;
}

class C2 {
  IOSink _sinkC2; // OK

  void initialize(IOSink sink) {
    this._sinkC2 = sink;
  }
}

class C3 {
  IOSink _sinkC3; // OK

  void initialize(IOSink sink) {
    _sinkC3 = sink;
  }
}

class D {
  IOSink init(String filename) {
    IOSink _sinkF = new File(filename).openWrite(); // OK
    return _sinkF;
  }
}

void someFunction() {
  IOSink _sinkSomeFunction; // LINT
}

void someFunctionOK() {
  IOSink _sinkFOK; // OK
  _sinkFOK.close();
}

IOSink someFunctionReturningIOSink() {
  IOSink _sinkF = new File('filename').openWrite(); // OK
  return _sinkF;
}

void startChunkedConversion(Socket sink) {
  Sink stringSink;
  if (sink is IOSink) {
    stringSink = sink;
  } else {
    stringSink = new MockIOSink();
  }
}

void onListen(Stream<int> stream) {
  StreamController controllerListen = new StreamController();
  stream.listen((int event) {
    event.toString();
  }, onError: controllerListen.addError, onDone: controllerListen.close);
}

void someFunctionClosing(StreamController controller) {}

void controllerPassedAsArgument() {
  StreamController controllerArgument = new StreamController();
  someFunctionClosing(controllerArgument);
}

void fluentInvocation() {
  StreamController cascadeController = new StreamController()
    ..add(null)
    ..close();
}

class CascadeSink {
  StreamController cascadeController = new StreamController(); // OK

  void closeSink() {
    cascadeController
      ..add(null)
      ..close();
  }
}
