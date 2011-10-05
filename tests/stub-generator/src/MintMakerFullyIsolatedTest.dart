// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IsolateStubs=MintMakerFullyIsolatedTest.dart:Mint,Purse

interface Purse factory PurseImpl {
  Purse();
  // FIXME(benl): need to autogen constructors...
  void init(Mint$Proxy mint, int balance);
  int queryBalance();
  Purse$Proxy sproutPurse();
  void deposit(int amount, Purse$Proxy source);
}

interface Mint factory MintImpl {
  Mint();

  Purse$Proxy createPurse(int balance);
}

class MintImpl implements Mint {

  MintImpl() { }

  Purse$Proxy createPurse(int balance) {
    Purse$Proxy purse = new Purse$ProxyImpl.createIsolate();
    Mint$Proxy thisProxy = new Mint$ProxyImpl.localProxy(this);
    purse.init(thisProxy, balance);
    return purse;
  }

}

class PurseImpl implements Purse {

  // FIXME(benl): autogenerate constructor, get rid of init(...).
  //PurseImpl(this._mint, this._balance) { }
  PurseImpl() { }

  init(Mint$Proxy mint, int balance) {
    this._mint = mint;
    this._balance = balance;
  }

  int queryBalance() {
    return _balance;
  }

  Purse$Proxy sproutPurse() {
    return _mint.createPurse(0);
  }

  void deposit(int amount, Purse$Proxy proxy) {
    Purse$ProxyImpl impl = proxy.dynamic;
    PurseImpl source = impl.local;
    if (source._balance < amount) throw "Not enough dough.";
    _balance += amount;
    source._balance -= amount;
  }

  Mint$Proxy _mint;
  int _balance;

}

class MintMakerFullyIsolatedTest {

  static void testMain() {
    Mint$Proxy mint = new Mint$ProxyImpl.createIsolate();
    Purse$Proxy purse = mint.createPurse(100);
    expectEquals(100, purse.queryBalance());

    Purse$Proxy sprouted = purse.sproutPurse();
    expectEquals(0, sprouted.queryBalance());

    sprouted.deposit(5, purse);
    expectEquals(0 + 5, sprouted.queryBalance());
    expectEquals(100 - 5, purse.queryBalance());

    sprouted.deposit(42, purse);
    expectEquals(0 + 5 + 42, sprouted.queryBalance());
    expectEquals(100 - 5 - 42, purse.queryBalance());

    expectDone(6);
  }

  static List<Promise> results;

  static void expectEquals(int expected, Promise<int> promise) {
    if (results === null) {
      results = new List<Promise>();
    }
    results.add(promise.then((int actual) {
      Expect.equals(expected, actual);
    }));
  }

  static void expectDone(int n) {
    if (results === null) {
      Expect.equals(0, n);
      print('##DONE##');
    } else {
      Promise done = new Promise();
      done.waitFor(results, results.length);
      done.then((ignored) {
        Expect.equals(n, results.length);
        print('##DONE##');
      });
    }
  }

}

main() {
  MintMakerFullyIsolatedTest.testMain();
}
