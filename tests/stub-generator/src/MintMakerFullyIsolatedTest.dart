// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IsolateStubs=MintMakerFullyIsolatedTest.dart:Mint,Purse,PowerfulPurse

#import("../../isolate/src/TestFramework.dart");

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
