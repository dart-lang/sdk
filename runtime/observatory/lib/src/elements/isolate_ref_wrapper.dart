// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';

import 'package:observatory/app.dart';
import 'package:observatory/models.dart' show IsolateUpdateEvent;
import 'package:observatory/mocks.dart' show IsolateUpdateEventMock;
import 'package:observatory/service_html.dart' show Isolate;
import 'package:observatory/src/elements/isolate_ref.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';

@bindable
class IsolateRefElementWrapper extends HtmlElement {

  static const binder = const Binder<IsolateRefElementWrapper>(const {
      'ref': #ref
    });

  static const tag = const Tag<IsolateRefElementWrapper>('isolate-ref');

  final StreamController<IsolateUpdateEvent> _updatesController =
    new StreamController<IsolateUpdateEvent>();
  Stream<IsolateUpdateEvent> _updates;
  StreamSubscription _subscription;

  Isolate _isolate;
  Isolate get ref => _isolate;
  void set ref(Isolate ref) { _isolate = ref; _detached(); _attached(); }

  IsolateRefElementWrapper.created() : super.created() {
    _updates = _updatesController.stream.asBroadcastStream();
    binder.registerCallback(this);
    createShadowRoot();
    render();
  }

  @override
  void attached() {
    super.attached();
    _attached();
  }

  void _attached() {
    if (ref != null) {
      _subscription = ref.changes.listen((_) {
        _updatesController.add(new IsolateUpdateEventMock(isolate: ref));
      });
    }
    render();
  }

  @override
  void detached() {
    super.detached();
    _detached();
  }

  void _detached() {
    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
    }
  }

  void render() {
    shadowRoot.children = [];
    if (ref == null) return;

    shadowRoot.children = [
      new StyleElement()
        ..text = '''
        isolate-ref-wrapped > a[href]:hover {
            text-decoration: underline;
        }
        isolate-ref-wrapped > a[href] {
            color: #0489c3;
            text-decoration: none;
        }''',
      new IsolateRefElement(_isolate, _updates,
                                 queue: ObservatoryApplication.app.queue)
    ];
  }
}
