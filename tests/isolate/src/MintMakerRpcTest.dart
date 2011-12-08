// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/***
 * Background:
 *
 * There are two "target" classes here that are the actual implementation
 * of some service that performs some function.  These "target" classes
 * do not know about ports, isolates or rpc.  They expose a local (usually
 * synchronous) interface to perform some task.  In this example, the "target"
 * classes are very simple:
 *
 *    Mint - creates new Purse objects with an initial amount of money
 *    Purse - holds an amount of money, and supports making deposits
 *        by taking money out of another purse.
 *
 * The point of this example is to show how to create a new Dart isolate
 * and run Mint and Purse objects in that isolate, and communicate with
 * these objects with a SendPort/ReceivePort message/reply conversation,
 * where command arguments are marshalled and unmarshalled by RpcProxy and
 * RpcReceiver objects.
 *
 * This example also shows:
 *     1. how the messages in the conversation can refer to target
 *          objects besides the direct recipient of the message
 *     2. how target objects can throw exceptions and these are propagated back
 *          through the SendPort/ReceivePort channel and back to the Future
 *          object that is waiting for the reply.
 *
 * Classes:
 *
 *    Mint - used to create Purse objects
 *    Purse - holds a bank balance, supports depositing money from another Purse
 *    MintReceiver - listens on a ReceivePort and forwards commands to Mint
 *    PurseReceiver - listens on a ReceivePort and forwards commands to Purse
 *    MintProxy - sends commands to a SendPort (which is connected to a
 *        MintReceiver)
 *    PurseProxy - sends commands to a SendPort (which is connected to a
 *        PurseReceiver)
 *    MintIsolate - used to spawn a new Isolate and return the initial MintProxy
 *
 * Base classes used: (these are defined in proxy.dart)
 *    RpcReceiver - MintReceiver and PurseReceiver derive from RpcReceiver to
 *         get behavior common to all Receivers.
 *    RpcProxy - MintProxy and PurseProxy derive from RpcProxy to get behavior
 *         common to all proxies
 *
 * Explanation:
 *
 * We make a "receiver" object (MintReceiver and PurseReceiver) for each
 * target object that is being exposed.  Each "receiver" object gets
 * its own ReceivePort, where it listen for messages that it interprets
 * as commands for its target object.
 *
 * When a command is received by a receiver, the receiver calls the appropriate
 * method on the the target object.  The receiver object runs in the same
 * isolate as its target object.  This isolate is called the "service" isolate.
 *
 * RpcProxy objects run in the "client" isolate.  Each proxy object has a
 * SendPort which is connected to the ReceivePort of a corresponding receiver
 * object.
 *
 * So, a MintProxy object (running in the "client" isolate) is connected
 * to a MintReceiver object (running in the "service" isolate) which is
 * connected to a Mint target object (also running in the "service" isolate).
 *
 * Startup/Shutdown:
 *
 * The MintIsolate has a method open that spawns a new isolate and returns
 * a MintProxy object.
 *
 * To shut down the MintIsolate, call 'close' on the MintProxy object.  This
 * will close all receive ports of all receivers in the isolate, which will
 * cause the mint isolate to shutdown.
 */

class Mint {
  Mint();
  Purse createPurse(int initialBalance) {
    return new Purse(initialBalance);
  }
}

class Purse {
  int _balance;

  Purse(this._balance) {}

  int queryBalance() {
    return _balance;
  }

  int deposit(int amount, Purse source) {
    if (source._balance < amount) {
      throw "OverdraftException";
    }
    source._balance -= amount;
    _balance += amount;
    return _balance;
  }
}


class MintProxy extends RpcProxy {
  MintProxy(Future<SendPort> sendPort) : super(sendPort) { }
  Future<PurseProxy> createPurse(int initialBalance) {
    return sendCommand("createPurse", [initialBalance], (sendPort) {
      Completer<SendPort> completer = new Completer();
      completer.complete(sendPort);
      return new PurseProxy(completer.future);
    });
  }
  Future<String> close() {
    return sendCommand("close", null, null);
  }
}

class MintReceiver extends RpcReceiver<Mint> {
  MintReceiver(ReceivePort receivePort) : super(new Mint(), receivePort) {}
  Object receiveCommand(String command, List args) {
    switch(command) {
      case "createPurse":
        int balance = args[0];
        Purse purse = target.createPurse(balance);
        return new PurseReceiver(purse, new ReceivePort());
      case "close":
        RpcReceiver.closeAll();
        return "close command processed";
      default:
          throw "MintReceiver unrecognized command";
      }
  }
}

class PurseProxy extends RpcProxy {
  PurseProxy(Future<SendPort> sendPort) : super(sendPort) { }
  Future<int> queryBalance() {
    return sendCommand("queryBalance", null, null);
  }
  Future<int> deposit(int amount, PurseProxy from) {
    return sendCommand("deposit", [amount, from], null);
  }
}

class PurseReceiver extends RpcReceiver<Purse> {

  PurseReceiver(Purse purse, ReceivePort receivePort) : super(purse, receivePort) {}

  Object receiveCommand(String command, List args) {
    switch(command) {
      case "queryBalance":
        return target.queryBalance();
      case "deposit":
        int amount = args[0];
        Purse fromPurse = args[1];
        return target.deposit(amount, fromPurse);
      default:
        throw "PurseReceiver unrecognized command";
    }
  }
}

class MintIsolate extends Isolate {
  MintIsolate() : super.light() {}

  MintProxy open() {
    return new MintProxy(spawn());
  }

  void main() {
    ReceivePort receivePort = port;
    new MintReceiver(receivePort);
  }
}

class MintTest {
  static void testMain() {
    print("starting test");
    MintProxy mint = new MintIsolate().open();
    mint.createPurse(100).then((PurseProxy purse1) {
      purse1.queryBalance().then((int balance) {
        Expect.equals(100, balance);
        mint.createPurse(0).then((PurseProxy purse2) {
          purse2.queryBalance().then((int balance) {
            Expect.equals(0, balance);
            purse2.deposit(5, purse1).then((int newBalance) {
              Expect.equals(0 + 5, newBalance);
              purse1.queryBalance().then((int balance) {
                Expect.equals(100 - 5, balance);
              });
              purse2.deposit(42, purse1).then((int newBalance) {
                int balance2 = newBalance;
                Expect.equals(0 + 5 + 42, balance2);
                purse1.queryBalance().then((int balance) {
                  int balance1 = balance;
                  Expect.equals(100 - 5 - 42, balance);
                  // Now try to deposit more money into purse1 than
                  // is currently in purse2.  Make sure we get an exception
                  // doing this.
                  Future<int> badBalance = purse1.deposit(1000, purse2);
                  badBalance.then((int newBalance) {
                    // Should never arrive here because there are
                    // insufficient funds to actually do the deposit
                    Expect.fail("did not detect overdraft");
                  });
                  badBalance.handleException((Object exception) {
                    if (exception.toString().contains(
                        "OverdraftException", 0)) {
                      print("Correctly detected overdraft.");
                      // Check that the balance in each purse is unchanged from
                      // before we attempted to do the overdraft.
                      purse1.queryBalance().then((int balance) {
                        Expect.equals(balance, balance1);
                        purse2.queryBalance().then((int balance) {
                          Expect.equals(balance, balance2);
                          // OK, we're all done now, close down the mint isolate
                          mint.close().then((reply) {
                            print(reply);
                          });
                        });
                      });
                      return true;
                    } else {
                      return false;
                    }
                  });
                });
              });
            });
          });
        });
      });
    });
    print ("exit main");
  }
}

main() {
  MintTest.testMain();
}
