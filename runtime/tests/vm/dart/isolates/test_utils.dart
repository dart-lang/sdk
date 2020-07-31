// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'internal.dart';

final bool isDebugMode = Platform.script.path.contains('Debug');
final bool isSimulator = Platform.script.path.contains('SIM');

// Implements recursive summation:
//   sum(n) => n == 0 ? 0
//                    : 1 + sum(n-1);
Future sumRecursive(List args) async {
  final SendPort port = args[0];
  final n = args[1];
  if (n == 0) {
    port.send(0);
  } else {
    final rp = ReceivePort();
    await Isolate.spawn(sumRecursive, [rp.sendPort, n - 1]);
    port.send(1 + (await rp.first));
  }
}

// Implements recursive summation via tail calls:
//   sum(n, s) => n == 0 ? s
//                       : sum(n-1, s+1);
Future sumRecursiveTailCall(List args) async {
  final SendPort port = args[0];
  final n = args[1];
  final s = args[2];
  if (n == 0) {
    port.send(s);
  } else {
    await Isolate.spawn(sumRecursiveTailCall, [port, n - 1, s + 1]);
  }
}

// Implements recursive summation via tail calls:
//   fib(n) => n <= 1 ? 1
//                    : fib(n-1) + fib(n-2);
Future fibonacciRecursive(List args) async {
  final SendPort port = args[0];
  final n = args[1];
  if (n <= 1) {
    port.send(1);
    return;
  }
  final left = ReceivePort();
  final right = ReceivePort();
  await Future.wait([
    Isolate.spawn(fibonacciRecursive, [left.sendPort, n - 1]),
    Isolate.spawn(fibonacciRecursive, [right.sendPort, n - 2]),
  ]);
  final results = await Future.wait([left.first, right.first]);
  port.send(results[0] + results[1]);
}

enum Command { kRun, kRunAndClose, kClose }

abstract class RingElement {
  Future run(SendPort nextNeighbour, StreamIterator prevNeighbour);
}

class Ring {
  final int size;
  final List<StreamIterator> receivePorts;
  final List<SendPort> controlSendPorts;
  final List<SendPort> dataSendPorts;

  Ring(this.size, this.receivePorts, this.controlSendPorts, this.dataSendPorts);

  static Future<Ring> create(int n) async {
    final ports = <StreamIterator>[];
    final spawnFutures = <Future>[];
    for (int i = 0; i < n; ++i) {
      final port = ReceivePort();
      ports.add(StreamIterator(port));
      spawnFutures
          .add(Isolate.spawn(_ringEntry, port.sendPort, debugName: 'ring-$i'));
    }
    await Future.wait(spawnFutures);
    final controlSendPorts = <SendPort>[];
    final dataSendPorts = <SendPort>[];
    for (int i = 0; i < n; ++i) {
      final si = ports[i];
      await si.moveNext();
      controlSendPorts.add(si.current[0]);
      dataSendPorts.add(si.current[1]);
    }

    return Ring(n, ports, controlSendPorts, dataSendPorts);
  }

  static Future _ringEntry(SendPort port) async {
    final rpControl = ReceivePort();
    final rpData = ReceivePort();
    port.send([rpControl.sendPort, rpData.sendPort]);

    final siControl = StreamIterator(rpControl);
    final siData = StreamIterator(rpData);
    while (await siControl.moveNext()) {
      final List args = siControl.current;
      final command = args[0];
      switch (command) {
        case Command.kRun:
          final RingElement re = args[1];
          final SendPort nextNeighbor = args[2];
          port.send(await re.run(nextNeighbor, siData));
          break;
        case Command.kRunAndClose:
          final RingElement re = args[1];
          final SendPort nextNeighbor = args[2];
          port.sendAndExit(await re.run(nextNeighbor, siData));
          break;
        case Command.kClose:
          port.send('done');
          rpControl.close();
          rpData.close();
          return;
      }
    }

    throw 'bug';
  }

  Future<List> run(RingElement buildRingElement(int id)) async {
    for (int i = 0; i < size; i++) {
      final nextNeighbor = dataSendPorts[(i + 1) % size];
      controlSendPorts[i]
          .send([Command.kRun, buildRingElement(i), nextNeighbor]);
    }

    final results = await Future.wait(receivePorts.map((si) async {
      await si.moveNext();
      return si.current;
    }).toList());

    return results;
  }

  Future<List> runAndClose(RingElement buildRingElement(int id)) async {
    for (int i = 0; i < size; i++) {
      final nextNeighbor = dataSendPorts[(i + 1) % size];
      controlSendPorts[i]
          .send([Command.kRunAndClose, buildRingElement(i), nextNeighbor]);
    }

    final results = await Future.wait(receivePorts.map((si) async {
      await si.moveNext();
      return si.current;
    }).toList());
    finalize();
    return results;
  }

  Future close() async {
    for (int i = 0; i < size; i++) {
      controlSendPorts[i].send([Command.kClose]);
    }
    final results = await Future.wait(receivePorts.map((si) async {
      await si.moveNext();
      return si.current;
    }).toList());
    finalize();
    return results;
  }

  void finalize() async {
    for (int i = 0; i < size; ++i) {
      await receivePorts[i].cancel();
    }
  }
}

class Tree {
  final int value;
  final Tree? left;
  final Tree? right;

  Tree(this.value, this.left, this.right);

  int get sum => value + (left?.sum ?? 0) + (right?.sum ?? 0);

  Tree get copy => Tree(value, left?.copy, right?.copy);
}

Tree buildTree(int n) {
  if (n == 0) return Tree(0, null, null);
  Tree left = Tree(0, null, null);
  Tree right = Tree(0, null, null);
  for (int i = 1; i < n; ++i) {
    left = Tree(1, left, right);
    right = left.copy;
  }
  return Tree(1, left, right);
}
