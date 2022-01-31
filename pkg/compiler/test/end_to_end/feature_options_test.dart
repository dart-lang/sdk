// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test the command line options of dart2js.

import 'package:expect/expect.dart';

import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/options.dart' show FeatureOptions, FeatureOption;

class TestFeatureOptions extends FeatureOptions {
  FeatureOption f1 = FeatureOption('f1');
  FeatureOption noF2 = FeatureOption('f2', isNegativeFlag: true);
  FeatureOption sf1 = FeatureOption('sf1');
  FeatureOption sf2 = FeatureOption('sf2');
  FeatureOption noSf3 = FeatureOption('sf3', isNegativeFlag: true);
  FeatureOption noSf4 = FeatureOption('sf4', isNegativeFlag: true);
  FeatureOption cf1 = FeatureOption('cf1');
  FeatureOption cf2 = FeatureOption('cf2');
  FeatureOption noCf3 = FeatureOption('cf3', isNegativeFlag: true);
  FeatureOption noCf4 = FeatureOption('cf4', isNegativeFlag: true);

  @override
  List<FeatureOption> shipped;

  @override
  List<FeatureOption> shipping;

  @override
  List<FeatureOption> canary;

  // Initialize feature lists.
  TestFeatureOptions() {
    shipped = [f1, noF2];
    shipping = [sf1, sf2, noSf3, noSf4];
    canary = [cf1, cf2, noCf3, noCf4];
  }
}

TestFeatureOptions test(List<String> flags) {
  var tfo = TestFeatureOptions();
  tfo.parse(flags);
  return tfo;
}

void expectShipped(TestFeatureOptions tfo) {
  Expect.isTrue(tfo.f1.isEnabled);
  Expect.isTrue(tfo.noF2.isDisabled);
}

void testShipping() {
  var tfo = test([]);
  expectShipped(tfo);
  Expect.isTrue(tfo.sf1.isEnabled);
  Expect.isTrue(tfo.sf2.isEnabled);
  Expect.isTrue(tfo.noSf3.isDisabled);
  Expect.isTrue(tfo.noSf4.isDisabled);
  Expect.isTrue(tfo.cf1.isDisabled);
  Expect.isTrue(tfo.cf2.isDisabled);
  Expect.isTrue(tfo.noCf3.isEnabled);
  Expect.isTrue(tfo.noCf4.isEnabled);
}

void testNoShipping() {
  var tfo = test([Flags.noShipping]);
  expectShipped(tfo);
  Expect.isTrue(tfo.sf1.isDisabled);
  Expect.isTrue(tfo.sf2.isDisabled);
  Expect.isTrue(tfo.noSf3.isEnabled);
  Expect.isTrue(tfo.noSf4.isEnabled);
  Expect.isTrue(tfo.cf1.isDisabled);
  Expect.isTrue(tfo.cf2.isDisabled);
  Expect.isTrue(tfo.noCf3.isEnabled);
  Expect.isTrue(tfo.noCf4.isEnabled);
}

void testCanary() {
  var tfo = test([Flags.canary]);
  expectShipped(tfo);
  Expect.isTrue(tfo.sf1.isEnabled);
  Expect.isTrue(tfo.sf2.isEnabled);
  Expect.isTrue(tfo.noSf3.isDisabled);
  Expect.isTrue(tfo.noSf4.isDisabled);
  Expect.isTrue(tfo.cf1.isEnabled);
  Expect.isTrue(tfo.cf2.isEnabled);
  Expect.isTrue(tfo.noCf3.isDisabled);
  Expect.isTrue(tfo.noCf4.isDisabled);
}

void testShippingDisabled() {
  var tfo = test(['--no-sf2', '--sf3']);
  expectShipped(tfo);
  Expect.isTrue(tfo.sf1.isEnabled);
  Expect.isTrue(tfo.sf2.isDisabled);
  Expect.isTrue(tfo.noSf3.isEnabled);
  Expect.isTrue(tfo.noSf4.isDisabled);
  Expect.isTrue(tfo.cf1.isDisabled);
  Expect.isTrue(tfo.cf2.isDisabled);
  Expect.isTrue(tfo.noCf3.isEnabled);
  Expect.isTrue(tfo.noCf4.isEnabled);
}

void testCanaryDisabled() {
  var tfo = test([Flags.canary, '--no-sf2', '--sf3', '--no-cf1', '--cf3']);
  expectShipped(tfo);
  Expect.isTrue(tfo.sf1.isEnabled);
  Expect.isTrue(tfo.sf2.isDisabled);
  Expect.isTrue(tfo.noSf3.isEnabled);
  Expect.isTrue(tfo.noSf4.isDisabled);
  Expect.isTrue(tfo.cf1.isDisabled);
  Expect.isTrue(tfo.cf2.isEnabled);
  Expect.isTrue(tfo.noCf3.isEnabled);
  Expect.isTrue(tfo.noCf4.isDisabled);
}

void testNoShippingEnabled() {
  var tfo = test([Flags.noShipping, '--sf1', '--no-sf3', '--cf2', '--no-cf3']);
  expectShipped(tfo);
  Expect.isTrue(tfo.sf1.isEnabled);
  Expect.isTrue(tfo.sf2.isDisabled);
  Expect.isTrue(tfo.noSf3.isDisabled);
  Expect.isTrue(tfo.noSf4.isEnabled);
  Expect.isTrue(tfo.cf1.isDisabled);
  Expect.isTrue(tfo.cf2.isEnabled);
  Expect.isTrue(tfo.noCf3.isDisabled);
  Expect.isTrue(tfo.noCf4.isEnabled);
}

void testNoCanaryEnabled() {
  var tfo = test(['--cf1', '--no-cf3']);
  expectShipped(tfo);
  Expect.isTrue(tfo.sf1.isEnabled);
  Expect.isTrue(tfo.sf2.isEnabled);
  Expect.isTrue(tfo.noSf3.isDisabled);
  Expect.isTrue(tfo.noSf4.isDisabled);
  Expect.isTrue(tfo.cf1.isEnabled);
  Expect.isTrue(tfo.cf2.isDisabled);
  Expect.isTrue(tfo.noCf3.isDisabled);
  Expect.isTrue(tfo.noCf4.isEnabled);
}

void testFlagCollision() {
  Expect.throwsArgumentError(() => test(['--cf1', '--no-cf1']));
}

void testNoShippedDisable() {
  Expect.throwsArgumentError(() => test(['--no-f1']));
  Expect.throwsArgumentError(() => test(['--f2']));
}

void flavorStringTest(List<String> options, String expectedFlavorString) {
  var tfo = test(options);
  Expect.equals(expectedFlavorString, tfo.flavorString());
}

void flavorStringTests() {
  flavorStringTest([], 'sf1, sf2, no-sf3, no-sf4');
  flavorStringTest(['--no-sf1', '--no-sf2', '--sf3', '--sf4'], '');
  flavorStringTest(['--no-sf1', '--no-sf2', '--sf3'], 'no-sf4');
  flavorStringTest(['--no-sf1', '--sf3', '--sf4'], 'sf2');
  flavorStringTest(['--no-sf1', '--no-sf2', '--sf3', '--sf4', '--cf1'], 'cf1');
  flavorStringTest(['--cf1'], 'sf1, sf2, no-sf3, no-sf4, cf1');
  flavorStringTest(
      ['--no-sf1', '--no-sf2', '--sf3', '--sf4', '--no-cf3'], 'no-cf3');
  flavorStringTest(['--no-cf3'], 'sf1, sf2, no-sf3, no-sf4, no-cf3');
  flavorStringTest(
      ['--no-sf1', '--no-sf2', '--sf3', '--sf4', '--cf1', '--no-cf3'],
      'cf1, no-cf3');
}

void main() {
  // Test feature options functionality.
  testShipping();
  testNoShipping();
  testCanary();
  testShippingDisabled();
  testCanaryDisabled();
  testNoShippingEnabled();
  testNoCanaryEnabled();
  testNoShippingEnabled();
  testFlagCollision();
  testNoShippedDisable();

  // Supplemental tests.
  flavorStringTests();
}
