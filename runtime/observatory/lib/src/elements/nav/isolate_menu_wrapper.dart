// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';

import 'package:observatory/app.dart';
import 'package:observatory/service.dart';
import 'package:observatory/mocks.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';

@bindable
class NavIsolateMenuElementWrapper extends HtmlElement {
  static const binder = const Binder<NavIsolateMenuElementWrapper>(const {
      'last':  #last, 'isolate': #isolate
    });

  static const tag =
    const Tag<NavIsolateMenuElementWrapper>('isolate-nav-menu');

  final StreamController<M.IsolateUpdateEvent> _updatesController =
    new StreamController<M.IsolateUpdateEvent>();
  Stream<M.IsolateUpdateEvent> _updates;
  StreamSubscription _subscription;

  bool _last = false;
  Isolate _isolate;
  bool get last => _last;
  Isolate get isolate => _isolate;
  set last(bool value) {
    _last = value; render();
  }
  set isolate(Isolate value) {
    _isolate = value;  _detached(); _attached();
  }

  NavIsolateMenuElementWrapper.created() : super.created() {
    _updates = _updatesController.stream.asBroadcastStream();
    binder.registerCallback(this);
    _last = _getBoolAttribute('last');
    createShadowRoot();
    render();
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
      _subscription = _isolate.changes.listen((_) {
        _updatesController.add(new IsolateUpdateEventMock(isolate: isolate));
      });
    }
    render();
  }

  void _detached() {
    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
    }
  }

  void render() {
    shadowRoot.children = [];
    if (_isolate == null || _last == null) return;

    shadowRoot.children = [
      new NavIsolateMenuElement(isolate, _updates, last: last,
                                 queue: ObservatoryApplication.app.queue)
        ..children = [new ContentElement()]
    ];
  }

  bool _getBoolAttribute(String name) {
    final String value = getAttribute(name);
    return !(value == null || value == 'false');
  }
}
