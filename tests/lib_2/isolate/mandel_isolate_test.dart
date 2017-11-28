// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library MandelIsolateTest;

import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'package:unittest/unittest.dart';
import "remote_unittest_helper.dart";

const TERMINATION_MESSAGE = -1;
const N = 100;
const ISOLATES = 20;

void main([args, port]) {
  if (testRemote(main, port)) return;
  // Test is really slow in debug builds of the VM.
  var configuration = unittestConfiguration;
  configuration.timeout = const Duration(seconds: 480);
  test("Render Mandelbrot in parallel", () {
    final state = new MandelbrotState();
    state._validated.future.then(expectAsync((result) {
      expect(result, isTrue);
    }));
    for (int i = 0; i < min(ISOLATES, N); i++) state.startClient(i);
  });
}

class MandelbrotState {
  MandelbrotState() {
    _result = new List<List<int>>(N);
    _lineProcessedBy = new List<LineProcessorClient>(N);
    _sent = 0;
    _missing = N;
    _validated = new Completer<bool>();
  }

  void startClient(int id) {
    assert(_sent < N);
    int line = _sent++;
    LineProcessorClient.create(this, id).then((final client) {
      client.processLine(line);
    });
  }

  void notifyProcessedLine(LineProcessorClient client, int y, List<int> line) {
    assert(_result[y] == null);
    _result[y] = line;
    _lineProcessedBy[y] = client;

    if (_sent != N) {
      client.processLine(_sent++);
    } else {
      client.shutdown();
    }

    // If all lines have been computed, validate the result.
    if (--_missing == 0) {
      _printResult();
      _validateResult();
    }
  }

  void _validateResult() {
    // TODO(ngeoffray): Implement this.
    _validated.complete(true);
  }

  void _printResult() {
    var output = new StringBuffer();
    for (int i = 0; i < _result.length; i++) {
      List<int> line = _result[i];
      for (int j = 0; j < line.length; j++) {
        if (line[j] < 10) output.write("0");
        output.write(line[j]);
      }
      output.write("\n");
    }
    // print(output);
  }

  List<List<int>> _result;
  List<LineProcessorClient> _lineProcessedBy;
  int _sent;
  int _missing;
  Completer<bool> _validated;
}

class LineProcessorClient {
  MandelbrotState _state;
  int _id;
  SendPort _port;

  LineProcessorClient(this._state, this._id, this._port);

  static Future<LineProcessorClient> create(MandelbrotState state, int id) {
    ReceivePort reply = new ReceivePort();
    return Isolate.spawn(processLines, reply.sendPort).then((_) {
      return reply.first.then((port) {
        return new LineProcessorClient(state, id, port);
      });
    });
  }

  void processLine(int y) {
    ReceivePort reply = new ReceivePort();
    _port.send([y, reply.sendPort]);
    reply.first.then((List<int> message) {
      _state.notifyProcessedLine(this, y, message);
    });
  }

  void shutdown() {
    _port.send(TERMINATION_MESSAGE);
  }
}

List<int> processLine(int y) {
  double inverseN = 2.0 / N;
  double Civ = y * inverseN - 1.0;
  List<int> result = new List<int>(N);
  for (int x = 0; x < N; x++) {
    double Crv = x * inverseN - 1.5;

    double Zrv = Crv;
    double Ziv = Civ;

    double Trv = Crv * Crv;
    double Tiv = Civ * Civ;

    int i = 49;
    do {
      Ziv = (Zrv * Ziv) + (Zrv * Ziv) + Civ;
      Zrv = Trv - Tiv + Crv;

      Trv = Zrv * Zrv;
      Tiv = Ziv * Ziv;
    } while (((Trv + Tiv) <= 4.0) && (--i > 0));

    result[x] = i;
  }
  return result;
}

void processLines(SendPort replyPort) {
  ReceivePort port = new ReceivePort();
  port.listen((message) {
    if (message != TERMINATION_MESSAGE) {
      int line = message[0];
      SendPort replyTo = message[1];
      replyTo.send(processLine(line));
    } else {
      port.close();
    }
  });
  replyPort.send(port.sendPort);
}
