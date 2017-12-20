// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

var tests = <IsolateTest>[
  (Isolate isolate) =>
      isolate.getTypeArgumentsList(false).then((ServiceMap allTypeArgs) {
        var allTypeArgsTableSize =
            allTypeArgs['canonicalTypeArgumentsTableSize'];
        var allTypeArgsTableUsed =
            allTypeArgs['canonicalTypeArgumentsTableUsed'];
        var allTypeArgsList = allTypeArgs['typeArguments'];
        expect(allTypeArgsList, isNotNull);
        // Check size >= used.
        expect(
            allTypeArgsTableSize, greaterThanOrEqualTo(allTypeArgsTableUsed));
        return isolate
            .getTypeArgumentsList(true)
            .then((ServiceMap instantiatedTypeARgs) {
          var instantiatedTypeArgsTableSize =
              instantiatedTypeARgs['canonicalTypeArgumentsTableSize'];
          var instantiatedTypeArgsTableUsed =
              instantiatedTypeARgs['canonicalTypeArgumentsTableUsed'];
          // Check size >= used.
          expect(instantiatedTypeArgsTableSize,
              greaterThanOrEqualTo(instantiatedTypeArgsTableUsed));
          // Check that |instantiated| <= |all|
          var instantiatedTypeArgsList = instantiatedTypeARgs['typeArguments'];
          expect(instantiatedTypeArgsList, isNotNull);
          expect(allTypeArgsList.length,
              greaterThanOrEqualTo(instantiatedTypeArgsList.length));
          // Check that we can 'get' this object again.
          var firstType = allTypeArgsList[0];
          return isolate.getObject(firstType.id).then((TypeArguments type) {
            expect(firstType.name, type.name);
          });
        });
      }),
];

main(args) => runIsolateTests(args, tests);
