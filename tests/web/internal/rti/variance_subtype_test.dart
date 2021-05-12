// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=variance

import 'dart:_foreign_helper' show JS;
import 'dart:_rti' as rti;

import 'subtype_utils.dart';

const typeRulesJson = r'''
{
  "int": {"num": []}
}
''';
final typeRules = JS('=Object', 'JSON.parse(#)', typeRulesJson);

const typeParameterVariancesJson = '''
{
  "Covariant": [${rti.Variance.covariant}],
  "Contravariant": [${rti.Variance.contravariant}],
  "Invariant": [${rti.Variance.invariant}],
  "MultiVariant":[${rti.Variance.legacyCovariant}, ${rti.Variance.invariant},
  ${rti.Variance.contravariant}, ${rti.Variance.covariant}]
}
''';
final typeParameterVariances =
    JS('=Object', 'JSON.parse(#)', typeParameterVariancesJson);

main() {
  rti.testingAddRules(universe, typeRules);
  rti.testingAddTypeParameterVariances(universe, typeParameterVariances);
  testInterfacesWithVariance();
  testInterfacesWithVariance(); // Ensure caching didn't change anything.
}

void testInterfacesWithVariance() {
  strictSubtype('LegacyCovariant<int>', 'LegacyCovariant<num>');
  strictSubtype('Covariant<int>', 'Covariant<num>');
  strictSubtype('Contravariant<num>', 'Contravariant<int>');
  equivalent('Invariant<num>', 'Invariant<num>');
  unrelated('Invariant<int>', 'Invariant<num>');
  unrelated('Invariant<num>', 'Invariant<int>');
  strictSubtype(
      'MultiVariant<int,num,num,int>', 'MultiVariant<num,num,int,num>');
}
