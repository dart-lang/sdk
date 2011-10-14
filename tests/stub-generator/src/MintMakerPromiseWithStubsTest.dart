// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IsolateStubs=MintMakerPromiseWithStubsTest.dart:Mint,Purse

interface Mint factory MintImpl {

  Mint();

  Purse createPurse(int balance);

}

interface Purse factory PurseImpl {

  Purse();

  int queryBalance();
  Purse sproutPurse();
  int deposit(int amount, Purse$Proxy source);

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

  int deposit(int amount, Purse$Proxy proxy) {
    if (amount < 0) throw "Ha ha";
    // Because we are in the same isolate as the other purse, we can
    // retrieve the proxy's local PurseImpl object and act on it
    // directly. Further, a forged purse will not be convertible, and
    // so an attempt to use it will fail.
    PurseImpl source = proxy.dynamic.local;
    if (source._balance < amount) throw "Not enough dough.";
    _balance += amount;
    source._balance -= amount;
    return _balance;
  }

  Mint _mint;
  int _balance;

}

class MintMakerPromiseWithStubsTest {

  static void testMain() {
    Mint$Proxy mint = new Mint$ProxyImpl.createIsolate();
    Purse$Proxy purse = mint.createPurse(100);
    expectEquals(100, purse.queryBalance());

    Purse$Proxy sprouted = purse.sproutPurse();
    expectEquals(0, sprouted.queryBalance());

    // FIXME(benl): We should not have to manually order the calls
    // like this.
    Promise<int> result = sprouted.deposit(5, purse);
    expectEquals(5, result);
    result.addCompleteHandler((_) {
      expectEquals(0 + 5, sprouted.queryBalance());
      expectEquals(100 - 5, purse.queryBalance());

      result = sprouted.deposit(42, purse);
      expectEquals(5 + 42, result);
      result.addCompleteHandler((_) {
        expectEquals(0 + 5 + 42, sprouted.queryBalance());
        expectEquals(100 - 5 - 42, purse.queryBalance());
        expectDone(8);
      });
    });
  }

  static List<Promise> results;

  static void expectEquals(int expected, Promise<int> promise) {
    if (results === null) {
      results = new List<Promise>();
    }
    results.add(promise.then((int actual) {
      //print("done $expected/$actual");
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
  MintMakerPromiseWithStubsTest.testMain();
}
