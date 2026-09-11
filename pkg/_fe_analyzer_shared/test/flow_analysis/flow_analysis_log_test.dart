// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Unit tests of the flow analysis log infrastructure.
library;

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis_log.dart';
import 'package:_fe_analyzer_shared/src/type_inference/promotion_key_store.dart';
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

    test('Empty log', () {
      var logBuilder = FlowAnalysisLogBuilder();
      check(logBuilder.finish().getThisBinding(0)).isNull;
    });

    test('Nontrivial queries', () {
      var logBuilder = FlowAnalysisLogBuilder()
        ..thisBindingChanged((PromotionKey(2), _t('double')), offset: 20)
        ..thisBindingChanged((PromotionKey(3), _t('Object')), offset: 30)
        ..thisBindingChanged((PromotionKey(4), _t('Null')), offset: 40);
      var log = logBuilder.finish();
      check(log.getThisBinding(0)).isNull;
      check(log.getThisBinding(20)).isNull;
      check(log.getThisBinding(21)).equals((PromotionKey(2), _t('double')));
      check(log.getThisBinding(30)).equals((PromotionKey(2), _t('double')));
      check(log.getThisBinding(31)).equals((PromotionKey(3), _t('Object')));
      check(log.getThisBinding(40)).equals((PromotionKey(3), _t('Object')));
      check(log.getThisBinding(41)).equals((PromotionKey(4), _t('Null')));
    });

    test('Check offsets in order', () {
      if (!assertionsEnabled) return;
      var logBuilder = FlowAnalysisLogBuilder()
        ..thisBindingChanged((PromotionKey(2), _t('double')), offset: 20)
        ..thisBindingChanged((PromotionKey(3), _t('Object')), offset: 30);
      check(
        () => logBuilder.thisBindingChanged((
          PromotionKey(4),
          _t('Null'),
        ), offset: 25),
      ).throws<AssertionError>();
      check(() => logBuilder.checkOffset(25)).throws<AssertionError>();
      // allowOutOfOrderOffsets relaxes the order check for the next offset
      // only.
      logBuilder.allowOutOfOrderOffsets();
      logBuilder.thisBindingChanged((PromotionKey(4), _t('Null')), offset: 25);
      check(
        () => logBuilder.thisBindingChanged((
          PromotionKey(4),
          _t('Null'),
        ), offset: 23),
      ).throws<AssertionError>();
      logBuilder.allowOutOfOrderOffsets();
      logBuilder.checkOffset(23);
      check(() => logBuilder.checkOffset(22)).throws<AssertionError>();
    });

    test('Queries handle out-of-order offsets', () {
      var logBuilder = FlowAnalysisLogBuilder()
        ..thisBindingChanged((PromotionKey(4), _t('Null')), offset: 40)
        ..allowOutOfOrderOffsets()
        ..thisBindingChanged((PromotionKey(3), _t('Object')), offset: 30)
        ..allowOutOfOrderOffsets()
        ..thisBindingChanged((PromotionKey(2), _t('double')), offset: 20);
      var log = logBuilder.finish();
      check(log.getThisBinding(0)).isNull;
      check(log.getThisBinding(20)).isNull;
      check(log.getThisBinding(21)).equals((PromotionKey(2), _t('double')));
      check(log.getThisBinding(30)).equals((PromotionKey(2), _t('double')));
      check(log.getThisBinding(31)).equals((PromotionKey(3), _t('Object')));
      check(log.getThisBinding(40)).equals((PromotionKey(3), _t('Object')));
      check(log.getThisBinding(41)).equals((PromotionKey(4), _t('Null')));
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
        PromotionKey(0),
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
        PromotionKey(0),
        PromotionModel.fresh(assigned: false, ssaNode: null),
      );
      var flowModel2 = flowModel0.updatePromotionInfo(
        helper,
        PromotionKey(1),
        PromotionModel.fresh(assigned: false, ssaNode: null),
      );
      var logBuilder = FlowAnalysisLogBuilder()
        ..promotionInfoChanged(flowModel1.promotionInfo, offset: 20)
        ..allowOutOfOrderOffsets()
        ..promotionInfoChanged(flowModel2.promotionInfo, offset: 10);
      var log = logBuilder.finish();
      check(log.getPromotionInfo(5)).isNull;
      check(log.getPromotionInfo(15)).identicalTo(flowModel2.promotionInfo);
      check(log.getPromotionInfo(25)).identicalTo(flowModel1.promotionInfo);
    });
  });

  group('This promotion:', () {
    test('via PromotionInfo', () {
      var helper = _FlowModelHelper();
      var flowModel0 = FlowModel(Reachability.initial);
      var ssaNode = SsaNode();
      var flowModel1 = flowModel0.updatePromotionInfo(
        helper,
        PromotionKey(0),
        PromotionModel(
          promotedTypes: [_t('num')],
          tested: [],
          assigned: true,
          unassigned: false,
          ssaNode: ssaNode,
        ),
      );
      var flowModel2 = flowModel1.updatePromotionInfo(
        helper,
        PromotionKey(0),
        PromotionModel(
          promotedTypes: [_t('num'), _t('int')],
          tested: [],
          assigned: true,
          unassigned: false,
          ssaNode: ssaNode,
        ),
      );
      var logBuilder = FlowAnalysisLogBuilder()
        ..thisBindingChanged((PromotionKey(0), _t('Object')), offset: 0)
        ..promotionInfoChanged(flowModel1.promotionInfo, offset: 10)
        ..promotionInfoChanged(flowModel2.promotionInfo, offset: 20);
      check(logBuilder.finish().lookupThisType(offset: 5)).equals(_t('Object'));
      check(logBuilder.finish().lookupThisType(offset: 15)).equals(_t('num'));
      check(logBuilder.finish().lookupThisType(offset: 25)).equals(_t('int'));
    });

    test('via rebinding of `this`', () {
      var helper = _FlowModelHelper();
      var flowModel0 = FlowModel(Reachability.initial);
      var flowModel1 = flowModel0.updatePromotionInfo(
        helper,
        PromotionKey(0),
        PromotionModel(
          promotedTypes: [_t('int')],
          tested: [],
          assigned: true,
          unassigned: false,
          ssaNode: SsaNode(),
        ),
      );
      var logBuilder = FlowAnalysisLogBuilder()
        ..thisBindingChanged((PromotionKey(0), _t('Object')), offset: 0)
        ..promotionInfoChanged(flowModel1.promotionInfo, offset: 10)
        ..thisBindingChanged((PromotionKey(1), _t('num')), offset: 20);
      check(logBuilder.finish().lookupThisType(offset: 15)).equals(_t('int'));
      check(logBuilder.finish().lookupThisType(offset: 25)).equals(_t('num'));
    });
  });
}

class _FlowModelHelper with FlowModelHelper {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SharedTypeView _t(String s) => SharedTypeView(Type(s));
