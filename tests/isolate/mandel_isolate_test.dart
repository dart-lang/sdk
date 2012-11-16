// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library MandelIsolateTest;
import 'dart:isolate';
import 'dart:math';
import '../../pkg/unittest/lib/unittest.dart';

const TERMINATION_MESSAGE = -1;
const N = 100;
const ISOLATES = 20;

main() {
  test("Render Mandelbrot in parallel", () {
    final state = new MandelbrotState();
    state._validated.future.then(expectAsync1((result) {
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
    final client = new LineProcessorClient(this, id);
    client.processLine(_sent++);
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
        if (line[j] < 10) output.add("0");
        output.add(line[j]);
      }
      output.add("\n");
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

  LineProcessorClient(MandelbrotState this._state, int this._id) {
    _port = spawnFunction(processLines);
  }

  void processLine(int y) {
    _port.call(y).then((List<int> message) {
      _state.notifyProcessedLine(this, y, message);
    });
  }

  void shutdown() {
    _port.send(TERMINATION_MESSAGE, null);
  }

  MandelbrotState _state;
  int _id;
  SendPort _port;
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

void processLines() {
  port.receive((message, SendPort replyTo) {
    if (message == TERMINATION_MESSAGE) {
      assert(replyTo == null);
      port.close();
    } else {
      replyTo.send(processLine(message), null);
    }
  });
}
