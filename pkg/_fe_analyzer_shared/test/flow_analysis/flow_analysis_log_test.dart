// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Unit tests of the flow analysis log infrastructure.
library;

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis_log.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';

import '../mini_types.dart';

main() {
  bool assertionsEnabled = false;
  assert(assertionsEnabled = true);

  setUp(() {
    TypeRegistry.init();
  });

  tearDown(() {
    TypeRegistry.uninit();
  });

  group('Core infrastructure:', () {
    // Much of the core infrastructure of FlowAnalysisLog is shared by
    // `getPromotionInfo` and `getThisBinding`. This core infrastrcture is
    // tested via `getThisBinding`, since it stores integers, so it takes less
    // work to write the tests.

    test('Empty log with no initial `this` binding', () {
      var logBuilder = FlowAnalysisLogBuilder();
      check(logBuilder.finish().getThisBinding(0)).isNull();
    });

    test('Empty log with initial `this` binding', () {
      var logBuilder = FlowAnalysisLogBuilder()..recordInitialThisBinding(10);
      check(logBuilder.finish().getThisBinding(0)).equals(10);
    });

    test('Nontrivial queries', () {
      var logBuilder = FlowAnalysisLogBuilder()
        ..recordInitialThisBinding(1)
        ..thisBindingChanged(2, offset: 20)
        ..thisBindingChanged(3, offset: 30)
        ..thisBindingChanged(4, offset: 40);
      var log = logBuilder.finish();
      check(log.getThisBinding(0)).equals(1);
      check(log.getThisBinding(20)).equals(1);
      check(log.getThisBinding(21)).equals(2);
      check(log.getThisBinding(30)).equals(2);
      check(log.getThisBinding(31)).equals(3);
      check(log.getThisBinding(40)).equals(3);
      check(log.getThisBinding(41)).equals(4);
    });

    test('Check offsets in order', () {
      if (!assertionsEnabled) return;
      var logBuilder = FlowAnalysisLogBuilder()
        ..recordInitialThisBinding(1)
        ..thisBindingChanged(2, offset: 20)
        ..thisBindingChanged(3, offset: 30);
      check(
        () => logBuilder.thisBindingChanged(4, offset: 25),
      ).throws<AssertionError>();
      check(() => logBuilder.checkOffset(25)).throws<AssertionError>();
      // allowOutOfOrderOffsets relaxes the order check for the next offset
      // only.
      logBuilder.allowOutOfOrderOffsets();
      logBuilder.thisBindingChanged(4, offset: 25);
      check(
        () => logBuilder.thisBindingChanged(4, offset: 23),
      ).throws<AssertionError>();
      logBuilder.allowOutOfOrderOffsets();
      logBuilder.checkOffset(23);
      check(() => logBuilder.checkOffset(22)).throws<AssertionError>();
    });

    test('Queries handle out-of-order offsets', () {
      var logBuilder = FlowAnalysisLogBuilder()
        ..recordInitialThisBinding(1)
        ..thisBindingChanged(4, offset: 40)
        ..allowOutOfOrderOffsets()
        ..thisBindingChanged(3, offset: 30)
        ..allowOutOfOrderOffsets()
        ..thisBindingChanged(2, offset: 20);
      var log = logBuilder.finish();
      check(log.getThisBinding(0)).equals(1);
      check(log.getThisBinding(20)).equals(1);
      check(log.getThisBinding(21)).equals(2);
      check(log.getThisBinding(30)).equals(2);
      check(log.getThisBinding(31)).equals(3);
      check(log.getThisBinding(40)).equals(3);
      check(log.getThisBinding(41)).equals(4);
    });
  });

  group('Promotion info:', () {
    test('promotionInfoChanged checks offsets', () {
      var logBuilder = FlowAnalysisLogBuilder()
        ..promotionInfoChanged(null, offset: 20)
        ..promotionInfoChanged(null, offset: 30);
      check(
        () => logBuilder.promotionInfoChanged(null, offset: 25),
      ).throws<AssertionError>();
    });

    test('Nontrivial promotion info query', () {
      var helper = _FlowModelHelper();
      var flowModel0 = FlowModel(Reachability.initial);
      var flowModel1 = flowModel0.updatePromotionInfo(
        helper,
        0,
        PromotionModel.fresh(assigned: false, ssaNode: null),
      );
      var logBuilder = FlowAnalysisLogBuilder()
        ..promotionInfoChanged(flowModel1.promotionInfo, offset: 10);
      check(
        logBuilder.finish().getPromotionInfo(15),
      ).identicalTo(flowModel1.promotionInfo);
    });

    test('Nontrivial sorting', () {
      var helper = _FlowModelHelper();
      var flowModel0 = FlowModel(Reachability.initial);
      var flowModel1 = flowModel0.updatePromotionInfo(
        helper,
        0,
        PromotionModel.fresh(assigned: false, ssaNode: null),
      );
      var flowModel2 = flowModel0.updatePromotionInfo(
        helper,
        1,
        PromotionModel.fresh(assigned: false, ssaNode: null),
      );
      var logBuilder = FlowAnalysisLogBuilder()
        ..promotionInfoChanged(flowModel1.promotionInfo, offset: 20)
        ..allowOutOfOrderOffsets()
        ..promotionInfoChanged(flowModel2.promotionInfo, offset: 10);
      var log = logBuilder.finish();
      check(log.getPromotionInfo(5)).isNull();
      check(log.getPromotionInfo(15)).identicalTo(flowModel2.promotionInfo);
      check(log.getPromotionInfo(25)).identicalTo(flowModel1.promotionInfo);
    });
  });

  group('This promotion:', () {
    test('when no use of `this` was recorded', () {
      var logBuilder = FlowAnalysisLogBuilder();
      check(logBuilder.finish().lookupPromotedThisType(offset: 10)).isNull();
    });

    test('via PromotionInfo', () {
      var helper = _FlowModelHelper();
      var flowModel0 = FlowModel(Reachability.initial);
      var ssaNode = SsaNode();
      var flowModel1 = flowModel0.updatePromotionInfo(
        helper,
        0,
        PromotionModel(
          promotedTypes: [SharedTypeView(Type('num'))],
          tested: [],
          assigned: true,
          unassigned: false,
          ssaNode: ssaNode,
        ),
      );
      var flowModel2 = flowModel1.updatePromotionInfo(
        helper,
        0,
        PromotionModel(
          promotedTypes: [
            SharedTypeView(Type('num')),
            SharedTypeView(Type('int')),
          ],
          tested: [],
          assigned: true,
          unassigned: false,
          ssaNode: ssaNode,
        ),
      );
      var logBuilder = FlowAnalysisLogBuilder()
        ..recordInitialThisBinding(0)
        ..promotionInfoChanged(flowModel1.promotionInfo, offset: 10)
        ..promotionInfoChanged(flowModel2.promotionInfo, offset: 20);
      check(logBuilder.finish().lookupPromotedThisType(offset: 5)).isNull();
      check(
        logBuilder.finish().lookupPromotedThisType(offset: 15),
      ).equals(SharedTypeView(Type('num')));
      check(
        logBuilder.finish().lookupPromotedThisType(offset: 25),
      ).equals(SharedTypeView(Type('int')));
    });

    test('via rebinding of `this`', () {
      var helper = _FlowModelHelper();
      var flowModel0 = FlowModel(Reachability.initial);
      var flowModel1 = flowModel0.updatePromotionInfo(
        helper,
        0,
        PromotionModel(
          promotedTypes: [SharedTypeView(Type('int'))],
          tested: [],
          assigned: true,
          unassigned: false,
          ssaNode: SsaNode(),
        ),
      );
      var logBuilder = FlowAnalysisLogBuilder()
        ..recordInitialThisBinding(0)
        ..promotionInfoChanged(flowModel1.promotionInfo, offset: 10)
        ..thisBindingChanged(1, offset: 20);
      check(
        logBuilder.finish().lookupPromotedThisType(offset: 15),
      ).equals(SharedTypeView(Type('int')));
      check(logBuilder.finish().lookupPromotedThisType(offset: 25)).isNull();
    });
  });
}

class _FlowModelHelper with FlowModelHelper {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
