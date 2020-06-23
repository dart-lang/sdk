// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

var tests = <IsolateTest>[
  (Isolate isolate) =>
      isolate.getTypeArgumentsList(false).then((dynamic allTypeArgs) {
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
            .then((dynamic instantiatedTypeArgs) {
          var instantiatedTypeArgsTableSize =
              instantiatedTypeArgs['canonicalTypeArgumentsTableSize'];
          var instantiatedTypeArgsTableUsed =
              instantiatedTypeArgs['canonicalTypeArgumentsTableUsed'];
          // Check size >= used.
          expect(instantiatedTypeArgsTableSize,
              greaterThanOrEqualTo(instantiatedTypeArgsTableUsed));
          // Check that |instantiated| <= |all|
          var instantiatedTypeArgsList = instantiatedTypeArgs['typeArguments'];
          expect(instantiatedTypeArgsList, isNotNull);
          expect(allTypeArgsList.length,
              greaterThanOrEqualTo(instantiatedTypeArgsList.length));
          // Check that we can 'get' this object again.
          var firstType = allTypeArgsList[0];
          return isolate.getObject(firstType.id).then((ServiceObject object) {
            TypeArguments type = object;
            expect(firstType.name, type.name);
          });
        });
      }),
];

main(args) => runIsolateTests(args, tests);
