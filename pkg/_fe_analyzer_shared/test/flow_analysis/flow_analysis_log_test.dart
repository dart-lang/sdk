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
      // Beginning an out of order region relaxes the order check; within the
      // region, offsets must be in order relative to the beginning of the
      // region.
      logBuilder.beginOutOfOrderRegion(
        offset: 10,
        promotionInfo: null,
        thisBinding: null,
      );
      logBuilder.checkOffset(12);
      check(() => logBuilder.checkOffset(11)).throws<AssertionError>();
      logBuilder.endOutOfOrderRegion(offset: 15);
      // And once the region is over, the order check reverts to what it was
      // before the region began.
      check(() => logBuilder.checkOffset(25)).throws<AssertionError>();
      logBuilder.checkOffset(35);
    });

    test('Out of order region is spliced into place', () {
      var logBuilder = FlowAnalysisLogBuilder()
        ..thisBindingChanged((PromotionKey(2), _t('double')), offset: 20)
        ..thisBindingChanged((PromotionKey(4), _t('Null')), offset: 40)
        ..beginOutOfOrderRegion(
          offset: 25,
          promotionInfo: null,
          thisBinding: (PromotionKey(2), _t('double')),
        )
        ..thisBindingChanged((PromotionKey(3), _t('Object')), offset: 30)
        ..endOutOfOrderRegion(offset: 35);
      var log = logBuilder.finish();
      check(log.getThisBinding(0)).isNull;
      check(log.getThisBinding(20)).isNull;
      check(log.getThisBinding(21)).equals((PromotionKey(2), _t('double')));
      check(log.getThisBinding(30)).equals((PromotionKey(2), _t('double')));
      check(log.getThisBinding(31)).equals((PromotionKey(3), _t('Object')));
      check(log.getThisBinding(35)).equals((PromotionKey(3), _t('Object')));
      // After the end of the region, the binding that was in effect (in source
      // order) just before the region is restored.
      check(log.getThisBinding(36)).equals((PromotionKey(2), _t('double')));
      check(log.getThisBinding(40)).equals((PromotionKey(2), _t('double')));
      check(log.getThisBinding(41)).equals((PromotionKey(4), _t('Null')));
    });

    test('Out of order region at the beginning of the log', () {
      var logBuilder = FlowAnalysisLogBuilder()
        ..thisBindingChanged((PromotionKey(4), _t('Null')), offset: 40)
        ..beginOutOfOrderRegion(
          offset: 10,
          promotionInfo: null,
          thisBinding: null,
        )
        ..thisBindingChanged((PromotionKey(3), _t('Object')), offset: 20)
        ..endOutOfOrderRegion(offset: 30);
      var log = logBuilder.finish();
      check(log.getThisBinding(20)).isNull;
      check(log.getThisBinding(21)).equals((PromotionKey(3), _t('Object')));
      check(log.getThisBinding(30)).equals((PromotionKey(3), _t('Object')));
      // Nothing was in effect before the region, so nothing is restored.
      check(log.getThisBinding(31)).isNull;
      check(log.getThisBinding(41)).equals((PromotionKey(4), _t('Null')));
    });

    test('Out of order region with no entries', () {
      var logBuilder = FlowAnalysisLogBuilder()
        ..thisBindingChanged((PromotionKey(2), _t('double')), offset: 20)
        ..thisBindingChanged((PromotionKey(4), _t('Null')), offset: 40)
        ..beginOutOfOrderRegion(
          offset: 25,
          promotionInfo: null,
          thisBinding: (PromotionKey(2), _t('double')),
        )
        ..endOutOfOrderRegion(offset: 35);
      var log = logBuilder.finish();
      // The region should have had no effect on the log at all.
      check(log.getThisBinding(21)).equals((PromotionKey(2), _t('double')));
      check(log.getThisBinding(30)).equals((PromotionKey(2), _t('double')));
      check(log.getThisBinding(36)).equals((PromotionKey(2), _t('double')));
      check(log.getThisBinding(41)).equals((PromotionKey(4), _t('Null')));
    });

    test('Out of order region in an empty log', () {
      // Nothing has been recorded before the region, and the region itself
      // records nothing, so the log should be left empty.
      var logBuilder = FlowAnalysisLogBuilder()
        ..beginOutOfOrderRegion(
          offset: 10,
          promotionInfo: null,
          thisBinding: null,
        )
        ..endOutOfOrderRegion(offset: 20);
      var log = logBuilder.finish();
      check(log.getThisBinding(5)).isNull;
      check(log.getThisBinding(15)).isNull;
      check(log.getThisBinding(25)).isNull;
      check(log.getPromotionInfo(15)).isNull;
    });

    test('Out of order region whose state differs at its start', () {
      // The state in effect at the start of an out of order region is not
      // necessarily the state that was in effect at the end of the preceding
      // construct (in source order), because the region is being visited at a
      // point in time when flow analysis has already processed later code.
      var logBuilder = FlowAnalysisLogBuilder()
        ..thisBindingChanged((PromotionKey(2), _t('double')), offset: 20)
        ..thisBindingChanged((PromotionKey(4), _t('Null')), offset: 40)
        ..beginOutOfOrderRegion(
          offset: 25,
          promotionInfo: null,
          thisBinding: (PromotionKey(5), _t('String')),
        )
        ..endOutOfOrderRegion(offset: 35);
      var log = logBuilder.finish();
      check(log.getThisBinding(21)).equals((PromotionKey(2), _t('double')));
      check(log.getThisBinding(30)).equals((PromotionKey(5), _t('String')));
      check(log.getThisBinding(35)).equals((PromotionKey(5), _t('String')));
      check(log.getThisBinding(36)).equals((PromotionKey(2), _t('double')));
      check(log.getThisBinding(41)).equals((PromotionKey(4), _t('Null')));
    });

    test('Nested out of order regions', () {
      var logBuilder = FlowAnalysisLogBuilder()
        ..thisBindingChanged((PromotionKey(1), _t('double')), offset: 10)
        ..beginOutOfOrderRegion(
          offset: 20,
          promotionInfo: null,
          thisBinding: (PromotionKey(1), _t('double')),
        )
        // An inner region that precedes any entry of the outer region.
        ..beginOutOfOrderRegion(
          offset: 30,
          promotionInfo: null,
          thisBinding: (PromotionKey(2), _t('Object')),
        )
        ..endOutOfOrderRegion(offset: 40)
        ..thisBindingChanged((PromotionKey(3), _t('String')), offset: 50)
        ..endOutOfOrderRegion(offset: 60);
      var log = logBuilder.finish();
      check(log.getThisBinding(11)).equals((PromotionKey(1), _t('double')));
      check(log.getThisBinding(25)).equals((PromotionKey(1), _t('double')));
      check(log.getThisBinding(35)).equals((PromotionKey(2), _t('Object')));
      // After the inner region, the state in effect at the start of the outer
      // region is restored.
      check(log.getThisBinding(45)).equals((PromotionKey(1), _t('double')));
      check(log.getThisBinding(55)).equals((PromotionKey(3), _t('String')));
      // After the outer region, the state in effect before it is restored.
      check(log.getThisBinding(65)).equals((PromotionKey(1), _t('double')));
    });

    test('Nested out of order region that contributes nothing', () {
      // The inner region records no entries, and it begins with the same state
      // the outer region began with, so it should have no effect on the log.
      var logBuilder = FlowAnalysisLogBuilder()
        ..thisBindingChanged((PromotionKey(1), _t('double')), offset: 10)
        ..beginOutOfOrderRegion(
          offset: 20,
          promotionInfo: null,
          thisBinding: (PromotionKey(2), _t('Object')),
        )
        ..beginOutOfOrderRegion(
          offset: 30,
          promotionInfo: null,
          thisBinding: (PromotionKey(2), _t('Object')),
        )
        ..endOutOfOrderRegion(offset: 40)
        ..thisBindingChanged((PromotionKey(3), _t('String')), offset: 50)
        ..endOutOfOrderRegion(offset: 60);
      var log = logBuilder.finish();
      check(log.getThisBinding(11)).equals((PromotionKey(1), _t('double')));
      // The outer region's start state is in effect throughout the inner
      // region, and on both sides of it.
      check(log.getThisBinding(25)).equals((PromotionKey(2), _t('Object')));
      check(log.getThisBinding(35)).equals((PromotionKey(2), _t('Object')));
      check(log.getThisBinding(45)).equals((PromotionKey(2), _t('Object')));
      check(log.getThisBinding(55)).equals((PromotionKey(3), _t('String')));
      // After the outer region, the state in effect before it is restored.
      check(log.getThisBinding(65)).equals((PromotionKey(1), _t('double')));
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
        PromotionModel.fresh(assigned: false, version: null),
      );
      var logBuilder = FlowAnalysisLogBuilder()
        ..promotionInfoChanged(flowModel1.promotionInfo, offset: 10);
      check(
        logBuilder.finish().getPromotionInfo(15),
      ).identicalTo(flowModel1.promotionInfo);
    });

    test('Out of order region', () {
      var helper = _FlowModelHelper();
      var flowModel0 = FlowModel(Reachability.initial);
      var flowModel1 = flowModel0.updatePromotionInfo(
        helper,
        PromotionKey(0),
        PromotionModel.fresh(assigned: false, version: null),
      );
      var flowModel2 = flowModel0.updatePromotionInfo(
        helper,
        PromotionKey(1),
        PromotionModel.fresh(assigned: false, version: null),
      );
      var logBuilder = FlowAnalysisLogBuilder()
        ..promotionInfoChanged(flowModel1.promotionInfo, offset: 20)
        ..beginOutOfOrderRegion(
          offset: 5,
          promotionInfo: null,
          thisBinding: null,
        )
        ..promotionInfoChanged(flowModel2.promotionInfo, offset: 10)
        ..endOutOfOrderRegion(offset: 15);
      var log = logBuilder.finish();
      check(log.getPromotionInfo(5)).isNull;
      check(log.getPromotionInfo(15)).identicalTo(flowModel2.promotionInfo);
      check(log.getPromotionInfo(16)).isNull;
      check(log.getPromotionInfo(25)).identicalTo(flowModel1.promotionInfo);
    });
  });

  group('This promotion:', () {
    test('via PromotionInfo', () {
      var helper = _FlowModelHelper();
      var flowModel0 = FlowModel(Reachability.initial);
      var version = ValueVersion();
      var flowModel1 = flowModel0.updatePromotionInfo(
        helper,
        PromotionKey(0),
        PromotionModel(
          promotedTypes: [_t('num')],
          tested: [],
          assigned: true,
          unassigned: false,
          version: version,
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
          version: version,
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
          version: ValueVersion(),
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
