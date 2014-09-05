// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library microlytics.test;

import 'package:expect/expect.dart';
import 'package:microlytics/microlytics.dart';

import 'test_channel.dart';

void main() {
  testBasicEventRead();
  testBasicNegativeEventRead();
  testBasicTimingRead();
  testBasicTimingMultiread();
}

void testBasicEventRead() {
    TestChannel c = new TestChannel();
    AnalyticsLogger logger = new AnalyticsLogger(
      c,
      "2cfac780-31e2-11e4-8c21-0800200c9a66",
      "UA-53895644-1",
      "TestApp",
      "0.42");
    logger.logAnonymousEvent("video", "play");
    Expect.isTrue(c.contains(
      "v=1"
      "&tid=UA-53895644-1"
      "&cid=2cfac780-31e2-11e4-8c21-0800200c9a66"
      "&an=TestApp"
      "&av=0.42"
      "&t=event"
      "&ec=video"
      "&ea=play"));
}

void testBasicNegativeEventRead() {
      TestChannel c = new TestChannel();
      AnalyticsLogger logger = new AnalyticsLogger(
        c,
        "2cfac780-31e2-11e4-8c21-0800200c9a66",
        "UA-53895644-1",
        "TestApp",
        "0.42");
      logger.logAnonymousEvent("video", "play");
      Expect.isFalse(c.contains(
        "v=1"
        "&tid=UA-53895644-1"
        "&cid=2cfac780-31e2-11e4-8c21-0800200c9a66"
        "&an=TestApp"
        "&av=XXX"
        "&t=event"
        "&ec=video"
        "&ea=play"));
}

void testBasicTimingRead() {
    TestChannel c = new TestChannel();
    AnalyticsLogger logger = new AnalyticsLogger(
        c,
        "2cfac780-31e2-11e4-8c21-0800200c9a66",
        "UA-53895644-1",
        "TestApp",
        "0.42");
    logger.logAnonymousTiming("video", "delay", 157);
    Expect.isTrue(c.contains(
        "v=1"
        "&tid=UA-53895644-1"
        "&cid=2cfac780-31e2-11e4-8c21-0800200c9a66"
        "&an=TestApp"
        "&av=0.42"
        "&t=timing"
        "&utc=video"
        "&utv=delay"
        "&utt=157"));
}

void testBasicTimingMultiread() {
      TestChannel c = new TestChannel();
      AnalyticsLogger logger = new AnalyticsLogger(
        c,
        "2cfac780-31e2-11e4-8c21-0800200c9a66",
        "UA-53895644-1",
        "TestApp",
        "0.42");
      logger.logAnonymousTiming("video", "delay", 159);
      logger.logAnonymousTiming("video", "delay", 152);
      Expect.isTrue(c.contains(
        "v=1"
        "&tid=UA-53895644-1"
        "&cid=2cfac780-31e2-11e4-8c21-0800200c9a66"
        "&an=TestApp"
        "&av=0.42"
        "&t=timing"
        "&utc=video"
        "&utv=delay"
        "&utt=152"));
      Expect.isTrue(c.contains(
        "v=1"
        "&tid=UA-53895644-1"
        "&cid=2cfac780-31e2-11e4-8c21-0800200c9a66"
        "&an=TestApp"
        "&av=0.42"
        "&t=timing"
        "&utc=video"
        "&utv=delay"
        "&utt=159"));
      Expect.isFalse(c.contains(
        "v=1"
        "&tid=UA-53895644-1"
        "&cid=2cfac780-31e2-11e4-8c21-0800200c9a66"
        "&an=TestApp"
        "&av=0.42"
        "&t=timing"
        "&utc=video"
        "&utv=delay"
        "&utt=19"));
}