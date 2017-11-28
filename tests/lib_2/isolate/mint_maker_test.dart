// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library MintMakerTest;

import 'dart:async';
import 'dart:isolate';
import 'package:unittest/unittest.dart';
import "remote_unittest_helper.dart";

class Mint {
  Map<SendPort, Purse> _registry;
  SendPort port;

  Mint() : _registry = new Map<SendPort, Purse>() {
    ReceivePort mintPort = new ReceivePort();
    port = mintPort.sendPort;
    serveMint(mintPort);
  }

  void serveMint(ReceivePort port) {
    port.listen((message) {
      int balance = message[0];
      Purse purse = createPurse(balance);
      message[1].send(purse.port);
    });
  }

  Purse createPurse(int balance) {
    Purse purse = new Purse(this, balance);
    _registry[purse.port] = purse;
    return purse;
  }

  Purse lookupPurse(SendPort port) {
    return _registry[port];
  }
}

class MintWrapper {
  SendPort _mint;
  MintWrapper(SendPort this._mint) {}

  void createPurse(int balance, handlePurse(PurseWrapper purse)) {
    ReceivePort reply = new ReceivePort();
    reply.first.then((SendPort purse) {
      handlePurse(new PurseWrapper(purse));
    });
    _mint.send([balance, reply.sendPort]);
  }
}

class Purse {
  Mint mint;
  int balance;
  SendPort port;

  Purse(this.mint, this.balance) {
    ReceivePort recipient = new ReceivePort();
    port = recipient.sendPort;
    servePurse(recipient);
  }

  void servePurse(ReceivePort recipient) {
    recipient.listen((message) {
      String command = message[0];
      if (command == "balance") {
        SendPort replyTo = message.last;
        replyTo.send(queryBalance());
      } else if (command == "deposit") {
        Purse source = mint.lookupPurse(message[2]);
        deposit(message[1], source);
      } else if (command == "sprout") {
        SendPort replyTo = message.last;
        Purse result = sproutPurse();
        replyTo.send(result.port);
      } else {
        // TODO: Send an exception back.
        throw new UnsupportedError("Unsupported commend: $command");
      }
    });
  }

  int queryBalance() {
    return balance;
  }

  Purse sproutPurse() {
    return mint.createPurse(0);
  }

  void deposit(int amount, Purse source) {
    // TODO: Throw an exception if the source purse doesn't hold
    // enough dough.
    balance += amount;
    source.balance -= amount;
  }
}

class PurseWrapper {
  SendPort _purse;

  PurseWrapper(this._purse) {}

  void _sendReceive(message, replyHandler(reply)) {
    ReceivePort reply = new ReceivePort();
    _purse.send([message, reply.sendPort]);
    reply.first.then(replyHandler);
  }

  void queryBalance(handleBalance(int balance)) {
    _sendReceive("balance", handleBalance);
  }

  void sproutPurse(handleSprouted(PurseWrapper sprouted)) {
    _sendReceive("sprout", (SendPort sprouted) {
      handleSprouted(new PurseWrapper(sprouted));
    });
  }

  void deposit(PurseWrapper source, int amount) {
    _purse.send(["deposit", amount, source._purse]);
  }
}

mintMakerWrapper(SendPort replyPort) {
  ReceivePort receiver = new ReceivePort();
  replyPort.send(receiver.sendPort);
  receiver.listen((SendPort replyTo) {
    Mint mint = new Mint();
    replyTo.send(mint.port);
  });
}

class MintMakerWrapper {
  final SendPort _port;

  static Future<MintMakerWrapper> create() {
    ReceivePort reply = new ReceivePort();
    return Isolate
        .spawn(mintMakerWrapper, reply.sendPort)
        .then((_) => reply.first.then((port) => new MintMakerWrapper._(port)));
  }

  MintMakerWrapper._(this._port);

  void makeMint(handleMint(MintWrapper mint)) {
    ReceivePort reply = new ReceivePort();
    reply.first.then((SendPort mint) {
      handleMint(new MintWrapper(mint));
    });
    _port.send(reply.sendPort);
  }
}

_checkBalance(PurseWrapper wrapper, expected) {
  wrapper.queryBalance(expectAsync((int balance) {
    expect(balance, equals(expected));
  }));
}

void main([args, port]) {
  if (testRemote(main, port)) return;
  test("creating purse, deposit, and query balance", () {
    MintMakerWrapper.create().then(expectAsync((mintMaker) {
      mintMaker.makeMint(expectAsync((MintWrapper mint) {
        mint.createPurse(100, expectAsync((PurseWrapper purse) {
          _checkBalance(purse, 100);
          purse.sproutPurse(expectAsync((PurseWrapper sprouted) {
            _checkBalance(sprouted, 0);
            _checkBalance(purse, 100);

            sprouted.deposit(purse, 5);
            _checkBalance(sprouted, 0 + 5);
            _checkBalance(purse, 100 - 5);

            sprouted.deposit(purse, 42);
            _checkBalance(sprouted, 0 + 5 + 42);
            _checkBalance(purse, 100 - 5 - 42);
          }));
        }));
      }));
    }));
  });
}
