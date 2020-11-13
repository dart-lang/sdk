// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:logging/logging.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/utils.dart';

class LoggingListElement extends CustomElement implements Renderable {
  late RenderingScheduler<LoggingListElement> _r;

  Stream<RenderedEvent<LoggingListElement>> get onRendered => _r.onRendered;

  late M.IsolateRef _isolate;
  late M.EventRepository _events;
  late StreamSubscription _subscription;
  Level _level = Level.ALL;
  final _logs = <Map>[];

  M.IsolateRef get isolate => _isolate;
  Level get level => _level;

  set level(Level value) => _level = _r.checkAndReact(_level, value);

  factory LoggingListElement(M.IsolateRef isolate, M.EventRepository events,
      {RenderingQueue? queue}) {
    assert(isolate != null);
    assert(events != null);
    LoggingListElement e = new LoggingListElement.created();
    e._r = new RenderingScheduler<LoggingListElement>(e, queue: queue);
    e._isolate = isolate;
    e._events = events;
    return e;
  }

  LoggingListElement.created() : super.created('logging-list');

  @override
  attached() {
    super.attached();
    _r.enable();
    _subscription = _events.onLoggingEvent.listen((e) {
      if (e.isolate.id == _isolate.id) {
        _logs.add(e.logRecord);
        if (_shouldBeVisible(_logs.last)) {
          _r.dirty();
        }
      }
    });
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    children = <Element>[];
    _subscription.cancel();
  }

  void render() {
    children = _logs
        .where(_shouldBeVisible)
        .map<Element>((logRecord) => new DivElement()
          ..classes = ['logItem', logRecord['level'].name]
          ..children = <Element>[
            new SpanElement()
              ..classes = ['level']
              ..text = logRecord['level'].name,
            new SpanElement()
              ..classes = ['time']
              ..text = Utils.formatDateTime(logRecord['time']),
            new SpanElement()
              ..classes = ['message']
              ..text = logRecord["message"].valueAsString
          ])
        .toList();
  }

  bool _shouldBeVisible(Map record) => _level.compareTo(record['level']) <= 0;
}
