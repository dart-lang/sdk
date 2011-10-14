// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IsolateStubs=MintMakerFullyIsolatedTest.dart:Mint,Purse,PowerfulPurse

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

  static void testMain() {
    Mint$Proxy mint = new Mint$ProxyImpl.createIsolate();
    Purse$Proxy purse = mint.createPurse(100);
    // FIXME(benl): how do I write this?
    //PowerfulPurse$Proxy power = (PowerfulPurse$Proxy)purse;
    //expectEqualsStr("xxx", power.grab());
    expectEquals(100, purse.queryBalance());

    Purse$Proxy sprouted = purse.sproutPurse();
    expectEquals(0, sprouted.queryBalance());

    Promise<int> done = sprouted.deposit(5, purse);
    // FIXME(benl): it should not be necessary to wait here, I think,
    // but without this, the tests seem to execute prematurely.
    expectEquals(5, done);
    done.then((int) {
      expectEquals(0 + 5, sprouted.queryBalance());
      expectEquals(100 - 5, purse.queryBalance());

      done = sprouted.deposit(42, purse); 
      expectEquals(5 + 42, done);
      done.then((int) {
        expectEquals(0 + 5 + 42, sprouted.queryBalance());
        expectEquals(100 - 5 - 42, purse.queryBalance());

        expectDone(8);
      });
    });
  }

  static List<Promise> results;

  static void expectEqualsStr(String expected, Promise<String> promise) {
    if (results === null) {
      results = new List<Promise>();
    }
    results.add(promise.then((String actual) {
      //print('done ' + expected + '/' + actual);
      Expect.equals(expected, actual);
    }));
  }

  static void expectEquals(int expected, Promise<int> promise) {
    if (results === null) {
      results = new List<Promise>();
    }
    results.add(promise.then((int actual) {
      //print('done ' + expected + '/' + actual);
      Expect.equals(expected, actual);
    }));
  }

  static void expectDone(int n) {
    if (results === null) {
      Expect.equals(0, n);
      //print('##DONE##');
    } else {
      Promise done = new Promise();
      done.waitFor(results, results.length);
      done.then((ignored) { 
        //print('done all ' + n + '/' + results.length);
        Expect.equals(n, results.length);
        //print('##DONE##');
      });
    }
  }

}

main() {
  MintMakerFullyIsolatedTest.testMain();
}
