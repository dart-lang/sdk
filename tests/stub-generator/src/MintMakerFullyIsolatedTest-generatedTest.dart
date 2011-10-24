// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IsolateStubs=MintMakerFullyIsolatedTest.dart:Mint,Purse,PowerfulPurse

#import("../../isolate/src/TestFramework.dart");

/* class = Purse (tests/stub-generator/src/MintMakerFullyIsolatedTest.dart/MintMakerFullyIsolatedTest.dart: 9) */

interface Purse$Proxy {
  Promise<int> queryBalance();

  Purse$Proxy sproutPurse();

  Promise<int> deposit(int amount, Purse$Proxy source);
}

class Purse$ProxyImpl extends Proxy implements Purse$Proxy {
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
    return new Purse$ProxyImpl(new PromiseProxy<SendPort>(this.call(["sproutPurse"])));
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
      Purse$Proxy sproutPurse = target.sproutPurse();
      reply(sproutPurse);
    } else if (command == "deposit") {
      int amount = message[1];
      List<Promise<SendPort>> promises = new List<Promise<SendPort>>();
      promises.add(new PromiseProxy<SendPort>(new Promise<SendPort>.fromValue(message[2])));
      Promise done = new Promise();
      done.waitFor(promises, 1);
      done.addCompleteHandler((_) {
        Purse$Proxy source = new Purse$ProxyImpl(promises[0]);
        Promise<int> deposit = target.deposit(amount, source);
        reply(deposit);
      });
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

/* class = PowerfulPurse (tests/stub-generator/src/MintMakerFullyIsolatedTest.dart/MintMakerFullyIsolatedTest.dart: 18) */

interface PowerfulPurse$Proxy {
  void init(Mint$Proxy mint, int balance);

  Promise<int> grab(int amount);

  Purse$Proxy weak();
}

class PowerfulPurse$ProxyImpl extends Proxy implements PowerfulPurse$Proxy {
  PowerfulPurse$ProxyImpl(Promise<SendPort> port) : super.forReply(port) { }
  PowerfulPurse$ProxyImpl.forIsolate(Proxy isolate) : super.forReply(isolate.call([null])) { }
  factory PowerfulPurse$ProxyImpl.createIsolate() {
    Proxy isolate = new Proxy.forIsolate(new PowerfulPurse$Dispatcher$Isolate());
    return new PowerfulPurse$ProxyImpl.forIsolate(isolate);
  }
  factory PowerfulPurse$ProxyImpl.localProxy(PowerfulPurse obj) {
    return new PowerfulPurse$ProxyImpl(new Promise<SendPort>.fromValue(Dispatcher.serve(new PowerfulPurse$Dispatcher(obj))));
  }

  void init(Mint$Proxy mint, int balance) {
    this.send(["init", mint, balance]);
  }

  Promise<int> grab(int amount) {
    return this.call(["grab", amount]);
  }

  Purse$Proxy weak() {
    return new Purse$ProxyImpl(this.call(["weak"]));
  }
}

class PowerfulPurse$Dispatcher extends Dispatcher<PowerfulPurse> {
  PowerfulPurse$Dispatcher(PowerfulPurse thing) : super(thing) { }

  void process(var message, void reply(var response)) {
    String command = message[0];
    if (command == "PowerfulPurse") {
    } else if (command == "init") {
      List<Promise<SendPort>> promises = new List<Promise<SendPort>>();
      promises.add(new PromiseProxy<SendPort>(new Promise<SendPort>.fromValue(message[1])));
      int balance = message[2];
      Promise done = new Promise();
      done.waitFor(promises, 1);
      done.addCompleteHandler((_) {
        Mint$Proxy mint = new Mint$ProxyImpl(promises[0]);
        target.init(mint, balance);
      });
    } else if (command == "grab") {
      int amount = message[1];
      int grab = target.grab(amount);
      reply(grab);
    } else if (command == "weak") {
      Purse weak = target.weak();
      SendPort port = Dispatcher.serve(new Purse$Dispatcher(weak));
      reply(port);
    } else {
      // TODO(kasperl,benl): Somehow throw an exception instead.
      reply("Exception: command '" + command + "' not understood by PowerfulPurse.");
    }
  }
}

class PowerfulPurse$Dispatcher$Isolate extends Isolate {
  PowerfulPurse$Dispatcher$Isolate() : super() { }

  void main() {
    this.port.receive(void _(var message, SendPort replyTo) {
      PowerfulPurse thing = new PowerfulPurse();
      SendPort port = Dispatcher.serve(new PowerfulPurse$Dispatcher(thing));
      Proxy proxy = new Proxy.forPort(replyTo);
      proxy.send([port]);
    });
  }
}

/* class = Mint (tests/stub-generator/src/MintMakerFullyIsolatedTest.dart/MintMakerFullyIsolatedTest.dart: 28) */

interface Mint$Proxy {
  Purse$Proxy createPurse(int balance);

  PowerfulPurse$Proxy promote(Purse$Proxy purse);
}

class Mint$ProxyImpl extends Proxy implements Mint$Proxy {
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
    return new Purse$ProxyImpl(new PromiseProxy<SendPort>(this.call(["createPurse", balance])));
  }

  PowerfulPurse$Proxy promote(Purse$Proxy purse) {
    return new PowerfulPurse$ProxyImpl(new PromiseProxy<SendPort>(this.call(["promote", purse])));
  }
}

class Mint$Dispatcher extends Dispatcher<Mint> {
  Mint$Dispatcher(Mint thing) : super(thing) { }

  void process(var message, void reply(var response)) {
    String command = message[0];
    if (command == "Mint") {
    } else if (command == "createPurse") {
      int balance = message[1];
      Purse$Proxy createPurse = target.createPurse(balance);
      reply(createPurse);
    } else if (command == "promote") {
      List<Promise<SendPort>> promises = new List<Promise<SendPort>>();
      promises.add(new PromiseProxy<SendPort>(new Promise<SendPort>.fromValue(message[1])));
      Promise done = new Promise();
      done.waitFor(promises, 1);
      done.addCompleteHandler((_) {
        Purse$Proxy purse = new Purse$ProxyImpl(promises[0]);
        PowerfulPurse$Proxy promote = target.promote(purse);
        reply(promote);
      });
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
interface Purse {
  Purse();
  int queryBalance();
  Purse$Proxy sproutPurse();
  // The deposit has not completed until the promise completes. If we
  // supported Promise<void> then this could use that.
  Promise<int> deposit(int amount, Purse$Proxy source);
}

interface PowerfulPurse extends Purse factory PurseImpl {
  PowerfulPurse();

  void init(Mint$Proxy mint, int balance);
  // Return an int so we can wait for it to complete. Shame we can't
  // have a Promise<void>.
  int grab(int amount);
  Purse weak();
}

interface Mint factory MintImpl {
  Mint();

  Purse$Proxy createPurse(int balance);
  PowerfulPurse$Proxy promote(Purse$Proxy purse);
}

// Because promises can't be used as keys in maps until they have
// completed, provide a wrapper. Note that if any key promise fails to
// resolve, then get()'s return may also fail to resolve.  Also,
// although the logic is fine, this can't be used for a
// ProxyMap. Perhaps both Proxy and Promise should inherit from
// Completable?
// NB: not tested and known to be buggy. Will fix in a future change.
class PromiseMap<S extends Promise, T> {

  PromiseMap() {
    _map = new Map<S, T>();
    _incomplete = new Set<S>();
  }

  T add(S s, T t) {
    _incomplete.add(s);
    s.addCompleteHandler((_) {
      _map[s] = t;
      _incomplete.remove(s);
    });
    return t;
  }

  Promise<T> find(S s) {
    T t = _map[s];
    if (t != null)
      return new Promise<T>.fromValue(t);
    Promise<T> p = new Promise<T>();
    int counter = _incomplete.length;
    p.join(_incomplete, bool (S completed) {
      if (completed != s) {
        if (--counter == 0) {
          p.complete(null);
          return true;
        }
        return false;
      }
      p.complete(_map[s]);
      return true;
    });
    return p;
  }

  Set<S> _incomplete;
  Map<S, T> _map;

}

class MintImpl implements Mint {

  MintImpl() {
    //print('mint');
    if (_power == null)
      _power = new Map<Purse$Proxy, PowerfulPurse$Proxy>();
  }

  Purse$Proxy createPurse(int balance) {
    //print('createPurse');
    PowerfulPurse$ProxyImpl purse =
      new PowerfulPurse$ProxyImpl.createIsolate();
    Mint$Proxy thisProxy = new Mint$ProxyImpl.localProxy(this);
    purse.init(thisProxy, balance);

    Purse$Proxy weakPurse = purse.weak();
    weakPurse.addCompleteHandler(() {
      //print('cP1');
      _power[weakPurse] = purse;
      //print('cP2');
    });
    return weakPurse;
  }

  PowerfulPurse$Proxy promote(Purse$Proxy purse) {
    // FIXME(benl): we should be using a PromiseMap here. But we get
    // away with it in this test for now.
    //print('promote $purse/${_power[purse]}');
    return _power[purse];
  }

  static Map<Purse$Proxy, PowerfulPurse$Proxy> _power;
}

class PurseImpl implements PowerfulPurse {

  // FIXME(benl): autogenerate constructor, get rid of init(...).
  // Note that this constructor should not exist in the public interface
  // PurseImpl(this._mint, this._balance) { }
  PurseImpl() { }

  init(Mint$Proxy mint, int balance) {
    this._mint = mint;
    this._balance = balance;
  }

  int queryBalance() {
    return _balance;
  }

  Purse$Proxy sproutPurse() {
    //print('sprout');
    return _mint.createPurse(0);
  }

  Promise<int> deposit(int amount, Purse$Proxy proxy) {
    //print('deposit');
    Promise<int> grabbed = _mint.promote(proxy).grab(amount);
    Promise<int> done = new Promise<int>();
    grabbed.then((int) {
      //print("deposit done");
      _balance += amount;
      done.complete(_balance);
    });
    return done;
  }

  int grab(int amount) {
    //print("grab");
    if (_balance < amount) throw "Not enough dough.";
    _balance -= amount;
    return amount;
  }

  Purse weak() {
    return this;
  }

  Mint$Proxy _mint;
  int _balance;

}

class MintMakerFullyIsolatedTest {

  static void testMain(TestExpectation expect) {
    Mint$Proxy mint = new Mint$ProxyImpl.createIsolate();
    Purse$Proxy purse = mint.createPurse(100);
    // FIXME(benl): how do I write this?
    //PowerfulPurse$Proxy power = (PowerfulPurse$Proxy)purse;
    //expectEqualsStr("xxx", power.grab());
    Promise<int> balance = purse.queryBalance();
    expect.completesWithValue(balance, 100);

    Purse$Proxy sprouted = purse.sproutPurse();
    expect.completesWithValue(sprouted.queryBalance(), 0);

    Promise<int> done = sprouted.deposit(5, purse);
    Promise<int> d3 = expect.completesWithValue(done, 5);
    Promise<int> inner = new Promise<int>();
    Promise<int> inner2 = new Promise<int>();
    // FIXME(benl): it should not be necessary to wait here, I think,
    // but without this, the tests seem to execute prematurely.
    Promise<int> d1 = done.then((val) {
      expect.completesWithValue(sprouted.queryBalance(), 0 + 5);
      expect.completesWithValue(purse.queryBalance(), 100 - 5);

      done = sprouted.deposit(42, purse); 
      expect.completesWithValue(done, 5 + 42);
      Promise<int> d2 = done.then((val) {
        expect.completesWithValue(sprouted.queryBalance(), 0 + 5 + 42)
          .then((int value) => inner.complete(0));
        expect.completesWithValue(purse.queryBalance(), 100 - 5 - 42)
          .then((int value) => inner2.complete(0));
      });
      expect.completes(d2);
    });
    expect.completes(d1);
    Promise<int> allDone = new Promise<int>();
    allDone.waitFor([d3, inner, inner2], 3);
    allDone.then((_) => expect.succeeded());
  }

}

main() {
  runTests([MintMakerFullyIsolatedTest.testMain]);
}
