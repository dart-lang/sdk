// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IsolateStubs=MintMakerPromiseWithStubsTest.dart:Mint,Purse

#library("MintMakerPromiseWithStubsTest-generatedTest");
#import("../../isolate/src/TestFramework.dart");

/* class = Mint (tests/stub-generator/src/MintMakerPromiseWithStubsTest.dart/MintMakerPromiseWithStubsTest.dart: 10) */

interface Mint$Proxy extends Proxy {
  Purse$Proxy createPurse(int balance);
}

class Mint$ProxyImpl extends ProxyImpl implements Mint$Proxy {
  Mint$ProxyImpl(Promise<SendPort> port) : super.forReply(port) { }
  Mint$ProxyImpl.forIsolate(Proxy isolate) : super.forReply(isolate.call([null])) { }
  factory Mint$ProxyImpl.createIsolate() {
    Proxy isolate = new Proxy.forIsolate(new Mint$Dispatcher$Isolate());
    return new Mint$ProxyImpl.forIsolate(isolate);
  }
  factory Mint$ProxyImpl.localProxy(Mint obj) {
    return new Mint$ProxyImpl(new Promise<SendPort>.fromValue(Dispatcher.serve(new Mint$Dispatcher(obj))));
  }

  Purse$Proxy createPurse(int balance) {
    return new Purse$ProxyImpl(this.call(["createPurse", balance]));
  }
}

class Mint$Dispatcher extends Dispatcher<Mint> {
  Mint$Dispatcher(Mint thing) : super(thing) { }

  void process(var message, void reply(var response)) {
    String command = message[0];
    if (command == "Mint") {
    } else if (command == "createPurse") {
      int balance = message[1];
      Purse createPurse = target.createPurse(balance);
      SendPort port = Dispatcher.serve(new Purse$Dispatcher(createPurse));
      reply(port);
    } else {
      // TODO(kasperl,benl): Somehow throw an exception instead.
      reply("Exception: command '" + command + "' not understood by Mint.");
    }
  }
}

class Mint$Dispatcher$Isolate extends Isolate {
  Mint$Dispatcher$Isolate() : super() { }

  void main() {
    this.port.receive(void _(var message, SendPort replyTo) {
      Mint thing = new Mint();
      SendPort port = Dispatcher.serve(new Mint$Dispatcher(thing));
      Proxy proxy = new Proxy.forPort(replyTo);
      proxy.send([port]);
    });
  }
}

/* class = Purse (tests/stub-generator/src/MintMakerPromiseWithStubsTest.dart/MintMakerPromiseWithStubsTest.dart: 18) */

interface Purse$Proxy extends Proxy {
  Promise<int> queryBalance();

  Purse$Proxy sproutPurse();

  Promise<int> deposit(int amount, Purse$Proxy source);
}

class Purse$ProxyImpl extends ProxyImpl implements Purse$Proxy {
  Purse$ProxyImpl(Promise<SendPort> port) : super.forReply(port) { }
  Purse$ProxyImpl.forIsolate(Proxy isolate) : super.forReply(isolate.call([null])) { }
  factory Purse$ProxyImpl.createIsolate() {
    Proxy isolate = new Proxy.forIsolate(new Purse$Dispatcher$Isolate());
    return new Purse$ProxyImpl.forIsolate(isolate);
  }
  factory Purse$ProxyImpl.localProxy(Purse obj) {
    return new Purse$ProxyImpl(new Promise<SendPort>.fromValue(Dispatcher.serve(new Purse$Dispatcher(obj))));
  }

  Promise<int> queryBalance() {
    return this.call(["queryBalance"]);
  }

  Purse$Proxy sproutPurse() {
    return new Purse$ProxyImpl(this.call(["sproutPurse"]));
  }

  Promise<int> deposit(int amount, Purse$Proxy source) {
    return new PromiseProxy<int>(this.call(["deposit", amount, source]));
  }
}

class Purse$Dispatcher extends Dispatcher<Purse> {
  Purse$Dispatcher(Purse thing) : super(thing) { }

  void process(var message, void reply(var response)) {
    String command = message[0];
    if (command == "Purse") {
    } else if (command == "queryBalance") {
      int queryBalance = target.queryBalance();
      reply(queryBalance);
    } else if (command == "sproutPurse") {
      Purse sproutPurse = target.sproutPurse();
      SendPort port = Dispatcher.serve(new Purse$Dispatcher(sproutPurse));
      reply(port);
    } else if (command == "deposit") {
      int amount = message[1];
      List<Promise<SendPort>> promises = new List<Promise<SendPort>>();
      promises.add(new PromiseProxy<SendPort>(new Promise<SendPort>.fromValue(message[2])));
      Purse$Proxy source = new Purse$ProxyImpl(promises[0]);
      Promise<int> deposit = target.deposit(amount, source);
      reply(deposit);
    } else {
      // TODO(kasperl,benl): Somehow throw an exception instead.
      reply("Exception: command '" + command + "' not understood by Purse.");
    }
  }
}

class Purse$Dispatcher$Isolate extends Isolate {
  Purse$Dispatcher$Isolate() : super() { }

  void main() {
    this.port.receive(void _(var message, SendPort replyTo) {
      Purse thing = new Purse();
      SendPort port = Dispatcher.serve(new Purse$Dispatcher(thing));
      Proxy proxy = new Proxy.forPort(replyTo);
      proxy.send([port]);
    });
  }
}
interface Mint factory MintImpl {

  Mint();

  Purse createPurse(int balance);

}

interface Purse factory PurseImpl {

  Purse();

  int queryBalance();
  Purse sproutPurse();
  Promise<int> deposit(int amount, Purse$Proxy source);

}

class MintImpl implements Mint {

  MintImpl() { }

  Purse createPurse(int balance) {
    PurseImpl purse = new PurseImpl();
    purse.init(this, balance);

    return purse;
  }

}

class PurseImpl implements Purse {

  PurseImpl() { }
  // TODO(benl): implement stub constructors.
  // Note that this constructor should _not_ be in the Purse interface,
  // only this isolate is trusted to construct purses.
  //PurseImpl(this._mint, this._balance) { }
  void init(Mint mint, int balance) {
    this._mint = mint;
    this._balance = balance;
  }

  int queryBalance() {
    return _balance;
  }

  Purse sproutPurse() {
    return _mint.createPurse(0);
  }

  Promise<int> deposit(int amount, Purse$Proxy proxy) {
    if (amount < 0) throw "Ha ha";
    // Because we are in the same isolate as the other purse, we can
    // retrieve the proxy's local PurseImpl object and act on it
    // directly. Further, a forged purse will not be convertible, and
    // so an attempt to use it will fail.
    Promise<int> balance = new Promise<int>();
    proxy.addCompleteHandler((_) {
      PurseImpl source = proxy.dynamic.local;
      if (source._balance < amount) throw "Not enough dough.";
      _balance += amount;
      source._balance -= amount;
      balance.complete(_balance);
    });
    return balance;
  }

  Mint _mint;
  int _balance;

}

class MintMakerPromiseWithStubsTest {

  static void testMain(TestExpectation expect) {
    Mint$Proxy mint = new Mint$ProxyImpl.createIsolate();
    Purse$Proxy purse = mint.createPurse(100);
    expect.completesWithValue(purse.queryBalance(), 100);

    Purse$Proxy sprouted = purse.sproutPurse();
    expect.completesWithValue(sprouted.queryBalance(), 0);

    // FIXME(benl): We should not have to manually order the calls
    // like this.
    Promise<int> result = sprouted.deposit(5, purse);
    Promise p1 = expect.completesWithValue(result, 5);
    Promise<bool> p2 = new Promise<bool>();
    Promise<bool> p3 = new Promise<bool>();
    Promise<bool> p4 = new Promise<bool>();
    Promise<bool> p5 = new Promise<bool>();
    Promise<bool> p6 = new Promise<bool>();
    result.addCompleteHandler((_) {
      expect.completesWithValue(sprouted.queryBalance(), 0 + 5)
        .then((_) => p2.complete(true));
      expect.completesWithValue(purse.queryBalance(), 100 - 5)
        .then((_) => p3.complete(true));

      result = sprouted.deposit(42, purse);
      expect.completesWithValue(result, 5 + 42).then((_) => p4.complete(true));
      result.addCompleteHandler((_) {
        expect.completesWithValue(sprouted.queryBalance(), 0 + 5 + 42)
          .then((_) => p5.complete(true));
        expect.completesWithValue(purse.queryBalance(), 100 - 5 - 42)
          .then((_) => p6.complete(true));
        });
    });
    Promise<bool> done = new Promise<bool>();
    done.waitFor([p1, p2, p3, p4, p5, p6], 6);
    done.then((_) {
      expect.succeeded();
      print("##DONE##");
    });
  }

}

main() {
  runTests([MintMakerPromiseWithStubsTest.testMain]);
}
