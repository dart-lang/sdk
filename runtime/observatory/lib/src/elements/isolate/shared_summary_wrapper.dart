// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/app.dart';
import 'package:observatory/service.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';
import 'package:observatory/src/elements/isolate/shared_summary.dart';

@bindable
class IsolateSharedSummaryElementWrapper extends HtmlElement {
  static const binder = const Binder<IsolateSharedSummaryElementWrapper>(const {
      'isolate': #isolate
    });

  static const tag =
      const Tag<IsolateSharedSummaryElementWrapper>('isolate-shared-summary');

  IsolateSharedSummaryElementWrapper.created() : super.created() {
    binder.registerCallback(this);
    createShadowRoot();
    render();
  }

  Isolate _isolate;
  StreamSubscription _subscription;

  Isolate get isolate => _isolate;

  void set isolate(Isolate value) {
    _isolate = value;
    _detached();
    _attached();
  }

  @override
  void attached() {
    super.attached();
    _attached();
  }

  @override
  void detached() {
    super.detached();
    _detached();
  }

  void _attached() {
    if (_isolate != null) {
      _subscription = _isolate.changes.listen((_) { render(); });
    }
    render();
  }

  void _detached() {
    _subscription?.cancel();
    _subscription = null;
  }

  void render() {
    if (_isolate == null) {
      return;
    }
    shadowRoot.children = [
      new StyleElement()
        ..text = '''
        a[href] {
          color: #0489c3;
          text-decoration: none;
        }
        a[href]:hover {
          text-decoration: underline;
        }
        .memberList {
          display: table;
        }
        .memberItem {
          display: table-row;
        }
        .memberName, .memberValue {
          display: table-cell;
          vertical-align: top;
          padding: 3px 0 3px 1em;
          font: 400 14px 'Montserrat', sans-serif;
        }
        isolate-shared-summary-wrapped {
          display: block;
        }
        isolate-shared-summary-wrapped > .summary {
          height: 300px;
          position: relative;
        }
        isolate-shared-summary-wrapped .menu {
          float: right;
          top: 0;
          right: 0;
        }
        isolate-shared-summary-wrapped isolate-counter-chart {
          position: absolute;
          left: 0;
          top: 0;
          right: 230px;
          clear: both;
        }
        isolate-shared-summary-wrapped .errorBox {
          background-color: #f5f5f5;
          border: 1px solid #ccc;
          padding: 2em;
          font-family: consolas, courier, monospace;
          font-size: 1em;
          line-height: 1.2em;
          white-space: pre;
        }
        isolate-counter-chart {
          display: block;
          position: relative;
          height: 300px;
          min-width: 350px;
        }
        isolate-counter-chart > div.host {
          position: absolute;
          left: 0;
          bottom: 20px;
          top: 5px;
          right: 250px;
        }
        isolate-counter-chart > div.legend {
          position: absolute;
          width: 250px;
          top: 0;
          right: 0;
          bottom: 0;
          overflow-y: auto;
        }
        .type-pie-rdr > .chart-legend-color {
          border-radius: 6px;
        }
        .chart-legend-row, .chart-legend-more {
          width: 100%;
          display: flex;
          font-size: 14px;
          margin-bottom: 16px;
          position: relative;
          cursor: default;
        }
        .chart-legend-row:hover, .chart-legend-more:hover {
          font-weight: bold;
        }
        .chart-legend-color, .chart-legend-more-color {
          width: 12px;
          height: 12px;
          margin: auto 8px;
          border-radius: 2px;
        }
        .chart-legend-label {
          overflow: hidden;
          text-overflow: ellipsis;
          max-width: 120px;
          flex: 1;
        }
        ''',
      new IsolateSharedSummaryElement(_isolate,
                                      queue: ObservatoryApplication.app.queue)
    ];
  }
}
