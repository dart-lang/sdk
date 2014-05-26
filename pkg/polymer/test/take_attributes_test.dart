// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';

@CustomTag('x-foo')
class XFoo extends PolymerElement {
  XFoo.created() : super.created();

  @published bool boolean = false;
  @published num number = 42;
  @published String str = "don't panic";
}

@CustomTag('x-bar')
class XBar extends PolymerElement {
  XBar.created() : super.created();

  @observable bool boolean = false;
  @observable num number = 42;
  @observable String str = "don't panic";
}

@CustomTag('x-zot')
class XZot extends XBar {
  XZot.created() : super.created();
  @observable num number = 84;
}

@CustomTag('x-date')
class XDate extends PolymerElement {
  XDate.created() : super.created();
  @observable var value = new DateTime(2013, 9, 25);
}

@CustomTag('x-array')
class XArray extends PolymerElement {
  XArray.created() : super.created();
  @observable List values;
}

@CustomTag('x-obj')
class XObj extends PolymerElement {
  XObj.created() : super.created();
  @observable var values = {};
}

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('take attributes', () {
    queryXTag(x) => document.querySelector(x);

    expect(queryXTag("#foo0").boolean, true);
    expect(queryXTag("#foo1").boolean, false);
    expect(queryXTag("#foo2").boolean, true);
    expect(queryXTag("#foo3").boolean, false);
    // this one is only 'truthy'
    expect(queryXTag("#foo4").boolean, true);
    // this one is also 'truthy', but should it be?
    expect(queryXTag("#foo5").boolean, true);
    //
    expect(queryXTag("#foo0").number, 42);
    expect(queryXTag("#foo0").str, "don't panic");
    //
    expect(queryXTag("#bar0").boolean, true);
    expect(queryXTag("#bar1").boolean, false);
    expect(queryXTag("#bar2").boolean, true);
    expect(queryXTag("#bar3").boolean, false);
    // this one is only 'truthy'
    expect(queryXTag("#bar4").boolean, true);
    // this one is also 'truthy', but should it be?
    expect(queryXTag("#bar5").boolean, true);
    //
    expect(queryXTag("#bar0").number, 42);
    expect(queryXTag("#bar0").str, "don't panic");
    //
    expect(queryXTag("#zot0").boolean, true);
    expect(queryXTag("#zot1").boolean, false);
    expect(queryXTag("#zot2").boolean, true);
    expect(queryXTag("#zot3").boolean, false);
    // this one is only 'truthy'
    expect(queryXTag("#zot4").boolean, true);
    // this one is also 'truthy', but should it be?
    expect(queryXTag("#zot5").boolean, true);
    //
    // Issue 14096 - field initializers are in the incorrect order.
    // This should be expecting 84.
    //expect(queryXTag("#zot0").number, 84);
    expect(queryXTag("#zot6").number, 185);
    expect(queryXTag("#zot0").str, "don't panic");
    //
    // Date deserialization tests
    expect(queryXTag("#date1").value, new DateTime(2014, 12, 25));
    expect(queryXTag("#date2").value, isNot(equals(new DateTime(2014, 12, 25))),
        reason: 'Dart does not support this format');
    expect(queryXTag("#date3").value, new DateTime(2014, 12, 25, 11, 45));
    expect(queryXTag("#date4").value, new DateTime(2014, 12, 25, 11, 45, 30));
    // Failures on Firefox. Need to fix this with custom parsing
    //expect(String(queryXTag("#date5").value), String(new Date(2014, 11, 25, 11, 45, 30)));
    //
    // milliseconds in the Date string not supported on Firefox
    //expect(queryXTag("#date5").value.getMilliseconds(), new Date(2014, 11, 25, 11, 45, 30, 33).getMilliseconds());
    //
    // Array deserialization tests
    expect(queryXTag("#arr1").values, [0, 1, 2]);
    expect(queryXTag("#arr2").values, [33]);
    // Object deserialization tests
    expect(queryXTag("#obj1").values, { 'name': 'Brandon',
        'nums': [1, 22, 33] });
    expect(queryXTag("#obj2").values, { "color": "Red" });
    expect(queryXTag("#obj3").values, { 'movie': 'Buckaroo Banzai',
        'DOB': '07/31/1978' });
  });
});
