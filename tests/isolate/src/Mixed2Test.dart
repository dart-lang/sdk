// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing that heavy and light isolates can be mixed.

#library('Mixed2Test');
#import("dart:isolate");
#import('../../../lib/unittest/unittest.dart');

// We want to send a message from the main-isolate to a chain of different
// isolates and then get a reply back.
// In the following description heavy2 is not used, because it is shut down
// just after heaving created heavy2.light1,2 and light3.
// main->
//   heavy1->heavy1.light1->heavy1.light2->heavy1.light3->
//   heavy2.light1->heavy2.light2->heavy2.light3->
//   heavy3->heavy3.pong

class LightRedirect extends Isolate {
  LightRedirect() : super.light();

  void main() {
    this.port.receive((targetPort, ignored) {
      this.port.receive((msg, replyTo) {
        targetPort.send(msg + 1000, replyTo);
        this.port.close();
      });
    });
  }
}

class HeavyIsolate1 extends Isolate {
  HeavyIsolate1() : super.heavy();

  void main() {
    Future<SendPort> light1 = new LightRedirect().spawn();
    Future<SendPort> light2 = new LightRedirect().spawn();
    Future<SendPort> light3 = new LightRedirect().spawn();

    this.port.receive((SendPort heavy2Light1Port, ignored) {
      light3.then((SendPort light3Port) {
        light3Port.send(heavy2Light1Port, null);
        light2.then((SendPort light2Port) {
          light2Port.send(light3Port, null);
          light1.then((SendPort light1Port) {
            light1Port.send(light2Port, null);
            // Next message we receive is the one that must go through the
            // chain.
            this.port.receive((msg, SendPort replyTo) {
              light1Port.send(msg + 1, replyTo);
              this.port.close();
            });
          });
        });
      });
    });
  }
}

class HeavyIsolate2 extends Isolate {
  HeavyIsolate2() : super.heavy();

  void main() {
    Future<SendPort> light1 = new LightRedirect().spawn();
    Future<SendPort> light2 = new LightRedirect().spawn();
    Future<SendPort> light3 = new LightRedirect().spawn();

    this.port.receive((heavy3Port, replyWithLight1Port) {
      light3.then((SendPort light3Port) {
        light3Port.send(heavy3Port, null);
        light2.then((SendPort light2Port) {
          light2Port.send(light3Port, null);
          light1.then((SendPort light1Port) {
            light1Port.send(light2Port, null);
            replyWithLight1Port.send(light1Port, null);
            this.port.close();
          });
        });
      });
    });
  }
}

class LightPong extends Isolate {
  LightPong() : super.light();

  void main() {
    this.port.receive((msg, replyTo) {
      replyTo.send(msg + 499, null);
      this.port.close();
    });
  }
}

class HeavyIsolate3 extends Isolate {
  HeavyIsolate3() : super.heavy();

  void main() {
    Future<SendPort> pong = new LightPong().spawn();
    this.port.receive((msg, replyTo) {
      pong.then((SendPort pongPort) {
        pongPort.send(msg + 30, replyTo);
        this.port.close();
      });
    });
  }
}


main() {
  test("heavy and light isolates can be mixed", () {
    Future<SendPort> heavy1 = new HeavyIsolate1().spawn();
    Future<SendPort> heavy2 = new HeavyIsolate2().spawn();
    Future<SendPort> heavy3 = new HeavyIsolate3().spawn();

    heavy2.then(expectAsync1((SendPort heavy2Port) {
      heavy3.then(expectAsync1((SendPort heavy3Port) {
        heavy2Port.call(heavy3Port).then(expectAsync1((h2l1Port) {
          heavy1.then(expectAsync1((SendPort heavy1Port) {
            heavy1Port.send(h2l1Port, null);
            // ---------------
            // Setup complete.
            // Start the chain-message.
            heavy1Port.call(1).then(expectAsync1((result) {
              Expect.equals(6531, result);
            }));
          }));
        }));
      }));
    }));
  });
}
