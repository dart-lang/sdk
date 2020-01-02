// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
// todo (pq): re-introduce check when analyzer >0.39.3-dev is published
//  group('check for incompatible rules:', () {
//    registerLintRules();
//    for (var rule in Analyzer.facade.registeredRules) {
//      test(rule.name, () async {
//        for (var incompatibleRule in lintDetail.incompatibleRules) {
//          final ruleDetail = lintCache.findDetailsById(incompatibleRule);
//          expect(ruleDetail, isNotNull,
//              reason:
//                  'No rule found for id: $incompatibleRule (check for typo?)');
//          expect(ruleDetail.incompatibleRules, contains(lintDetail.id),
//              reason:
//                  '${ruleDetail.id} should declare ${lintDetail.id} as `@IncompatibleWith` but does not.');
//        }
//      });
//    }
//  });
}
