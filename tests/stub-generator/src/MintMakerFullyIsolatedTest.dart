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
  Promise<PowerfulPurse$Proxy> promote(Purse$Proxy purse);
}

// Because promises can't be used as keys in maps until they have
// completed, provide a wrapper. Note that if any key promise fails to
// resolve, then get()'s return may also fail to resolve. Right now, a
// Proxy can also be used since it has (kludgily) been made to inherit
// from Promise. Perhaps both Proxy and Promise should inherit from
// Completable?
// Note that we cannot extend Set rather than Collection because, for
// example, Set.remove() returns bool, whereas this will have to
// return Promise<bool>.
class PromiseSet<T extends Promise> implements Collection<T> {

  PromiseSet() {
    _set = new List<T>();
  }

  PromiseSet.fromList(this._set);

  void add(T t) {
    print("ProxySet.add");
    for (T x in _set) {
      if (x === t)
        return;
    }
    if (t.hasValue()) {
      for (T x in _set) {
        if (x.hasValue() && x == t)
          return;
      }
    }
    _set.add(t);
    t.addCompleteHandler((_) {
      // Remove any duplicates.
      _remove(t, 1);
    });
  }

  void _remove(T t, int threshold) {
    print("PromiseSet.remove $threshold");
    int count = 0;
    for (int n = 0; n < _set.length; ++n)
      if (_set[n].hasValue() && _set[n] == t)
        if (++count > threshold) {
          print("  remove $n");
          _set.removeRange(n, 1);
          --n;
        }
  }

  void remove(T t) {
    t.addCompleteHandler((_) {
      _remove(t, 0);
    });
  }

  int get length() => _set.length;
  void forEach(void f(T element)) { _set.forEach(f); }
  PromiseSet<T> filter(bool f(T element)) {
    return new PromiseSet<T>.fromList(_set.filter(f));
  }
  bool every(bool f(T element)) => _set.every(f);
  bool some(bool f(T element)) => _set.some(f);
  bool isEmpty() => _set.isEmpty();
  Iterator<T> iterator() => _set.iterator();

  List<T> _set;
    
} 


class PromiseMap<S extends Promise, T> {

  PromiseMap() {
    _map = new Map<S, T>();
    _incomplete = new PromiseSet<S>();
  }

  T add(S s, T t) {
    print("PromiseMap.add");
    _incomplete.add(s);
    s.addCompleteHandler((_) {
      print("PromiseMap.add move to map");
      _map[s] = t;
      _incomplete.remove(s);
    });
    return t;
  }

  Promise<T> find(S s) {
    print("PromiseMap.find");
    Promise<T> result = new Promise<T>();
    s.addCompleteHandler((_) {
      print("PromiseMap.find s completed");
      T t = _map[s];
      if (t != null) {
        print("  immediate");
        result.complete(t);
        return;
      }
      // Otherwise, we need to wait for map[s] to complete...
      int counter = _incomplete.length;
      if (counter == 0) {
        print("  none incomplete");
        result.complete(null);
        return;
      }
      result.join(_incomplete, bool (S completed) {
        if (completed != s) {
          if (--counter == 0) {
            print("PromiseMap.find failed");
            result.complete(null);
            return true;
          }
          print("PromiseMap.find miss");
          return false;
        }
        print("PromiseMap.find complete");
        result.complete(_map[s]);
        return true;
      });
    });
    return result;
  }

  PromiseSet<S> _incomplete;
  Map<S, T> _map;

}


class MintImpl implements Mint {

  MintImpl() {
    print('mint');
    if (_power == null)
      _power = new PromiseMap<Purse$Proxy, PowerfulPurse$Proxy>();
  }

  Purse$Proxy createPurse(int balance) {
    print('createPurse');
    PowerfulPurse$ProxyImpl purse =
      new PowerfulPurse$ProxyImpl.createIsolate();
    Mint$Proxy thisProxy = new Mint$ProxyImpl.localProxy(this);
    purse.init(thisProxy, balance);

    Purse$Proxy weakPurse = purse.weak();
    weakPurse.addCompleteHandler((_) {
      print('cP1');
      _power.add(weakPurse, purse);
      print('cP2');
    });
    return weakPurse;
  }

  Promise<PowerfulPurse$Proxy> promote(Purse$Proxy purse) {
    print('promote $purse');
    return _power.find(purse);
  }

  static PromiseMap<Purse$Proxy, PowerfulPurse$Proxy> _power;
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
    print('sprout');
    return _mint.createPurse(0);
  }

  Promise<int> deposit(int amount, Purse$Proxy proxy) {
    print('deposit');
    Promise<PowerfulPurse$Proxy> powerful = _mint.promote(proxy);

    Promise<int> result = new Promise<int>();
    powerful.then((_) {
      Promise<int> grabbed = powerful.value.grab(amount);
      grabbed.then((int grabbedAmount) {
        _balance += grabbedAmount;
        result.complete(_balance);
      });
    });

    return result;
  }

  int grab(int amount) {
    print("grab");
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

      return 0;
    });
    expect.completesWithValue(d1, 0);
    Promise<int> allDone = new Promise<int>();
    allDone.waitFor([d3, inner, inner2], 3);
    allDone.then((_) {
      expect.succeeded();
      print("##DONE##");
    });
  }

}

main() {
  runTests([MintMakerFullyIsolatedTest.testMain]);
}
