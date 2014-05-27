// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library io_view_element;

import 'dart:async';
import 'observatory_element.dart';
import 'service_ref.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

@CustomTag('io-view')
class IOViewElement extends ObservatoryElement {
  @published ServiceMap io;

  IOViewElement.created() : super.created();

  void refresh(var done) {
    io.reload().whenComplete(done);
  }
}

@CustomTag('io-http-server-list-view')
class IOHttpServerListViewElement extends ObservatoryElement {
  @published ServiceMap list;

  IOHttpServerListViewElement.created() : super.created();

  void refresh(var done) {
    list.reload().whenComplete(done);
  }
}

@CustomTag('io-http-server-ref')
class IOHttpServerRefElement extends ServiceRefElement {
  IOHttpServerRefElement.created() : super.created();
}

@CustomTag('io-http-server-view')
class IOHttpServerViewElement extends ObservatoryElement {
  // TODO(ajohnsen): Create a HttpServer object.
  @published ServiceMap httpServer;
  Timer _updateTimer;

  IOHttpServerViewElement.created() : super.created();

  void refresh(var done) {
    httpServer.reload().whenComplete(done);
  }

  void _updateHttpServer() {
    refresh(() {
      if (_updateTimer != null) {
        _updateTimer = new Timer(new Duration(seconds: 1), _updateHttpServer);
      }
    });
  }

  void enteredView() {
    super.enteredView();
    // Start a timer to update the isolate summary once a second.
    _updateTimer = new Timer(new Duration(seconds: 1), _updateHttpServer);
  }

  void leftView() {
    super.leftView();
    if (_updateTimer != null) {
      _updateTimer.cancel();
      _updateTimer = null;
    }
  }
}

@CustomTag('io-socket-ref')
class IOSocketRefElement extends ServiceRefElement {
  IOSocketRefElement.created() : super.created();
}

@CustomTag('io-socket-list-view')
class IOSocketListViewElement extends ObservatoryElement {
  @published ServiceMap list;

  IOSocketListViewElement.created() : super.created();

  void refresh(var done) {
    list.reload().whenComplete(done);
  }
}

@CustomTag('io-socket-view')
class IOSocketViewElement extends ObservatoryElement {
  @published ServiceMap socket;

  IOSocketViewElement.created() : super.created();

  void refresh(var done) {
    socket.reload().whenComplete(done);
  }
}

@CustomTag('io-random-access-file-list-view')
class IORandomAccessFileListViewElement extends ObservatoryElement {
  @published ServiceMap list;

  IORandomAccessFileListViewElement.created() : super.created();

  void refresh(var done) {
    list.reload().whenComplete(done);
  }
}

@CustomTag('io-random-access-file-ref')
class IORandomAccessFileRefElement extends ServiceRefElement {
  IORandomAccessFileRefElement.created() : super.created();
}

@CustomTag('io-random-access-file-view')
class IORandomAccessFileViewElement extends ObservatoryElement {
  // TODO(ajohnsen): Create a RandomAccessFile object.
  @published ServiceMap file;
  Timer _updateTimer;

  IORandomAccessFileViewElement.created() : super.created();

  void refresh(var done) {
    file.reload().whenComplete(done);
  }

  void _updateFile() {
    refresh(() {
      if (_updateTimer != null) {
        _updateTimer = new Timer(new Duration(seconds: 1), _updateFile);
      }
    });
  }

  void enteredView() {
    super.enteredView();
    // Start a timer to update the isolate summary once a second.
    _updateTimer = new Timer(new Duration(seconds: 1), _updateFile);
  }

  void leftView() {
    super.leftView();
    if (_updateTimer != null) {
      _updateTimer.cancel();
      _updateTimer = null;
    }
  }
}

@CustomTag('io-process-list-view')
class IOProcessListViewElement extends ObservatoryElement {
  @published ServiceMap list;

  IOProcessListViewElement.created() : super.created();

  void refresh(var done) {
    list.reload().whenComplete(done);
  }
}

@CustomTag('io-process-ref')
class IOProcessRefElement extends ServiceRefElement {
  // Only display the process name when small is set.
  @published bool small = false;
  IOProcessRefElement.created() : super.created();
}

@CustomTag('io-process-view')
class IOProcessViewElement extends ObservatoryElement {
  // TODO(ajohnsen): Create a Process object.
  @published ServiceMap process;
  Timer _updateTimer;

  IOProcessViewElement.created() : super.created();

  void refresh(var done) {
    process.reload().whenComplete(done);
  }

  void _updateFile() {
    refresh(() {
      if (_updateTimer != null) {
        _updateTimer = new Timer(new Duration(seconds: 1), _updateFile);
      }
    });
  }

  void enteredView() {
    super.enteredView();
    // Start a timer to update the isolate summary once a second.
    _updateTimer = new Timer(new Duration(seconds: 1), _updateFile);
  }

  void leftView() {
    super.leftView();
    if (_updateTimer != null) {
      _updateTimer.cancel();
      _updateTimer = null;
    }
  }
}