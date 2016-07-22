// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';

import 'package:observatory/app.dart';
import 'package:observatory/mocks.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/service.dart';
import 'package:observatory/service_common.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';

class NavVMMenuElementWrapper extends HtmlElement {
  static final binder = new Binder<NavVMMenuElementWrapper>(
    const [const Binding('last'), const Binding('vm')]);

  static const tag = const Tag<NavVMMenuElementWrapper>('vm-nav-menu');

  StreamSubscription _subscription;
  StreamController<M.VMUpdateEvent> _updatesController =
      new StreamController<M.VMUpdateEvent>.broadcast();

  bool _last = false;
  VM _vm;
  bool get last => _last;
  VM get vm => _vm;
  set last(bool value) {
    _last = value; render();
  }
  set vm(VM value) {
    _vm = value; _detached(); _attached();
  }

  NavVMMenuElementWrapper.created() : super.created() {
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
    if (_vm != null) {
      _subscription = _vm.changes.listen((_) {
        _updatesController.add(new VMUpdateEventMock(vm: _vm));
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
    if (_vm == null || _last == null) return;

    shadowRoot.children = [
      new NavVMMenuElement(vm, _updatesController.stream, last: last,
          target: (vm as CommonWebSocketVM)?.target,
          queue: ObservatoryApplication.app.queue)
        ..children = [new ContentElement()]
    ];
  }

  bool _getBoolAttribute(String name) {
    final String value = getAttribute(name);
    return !(value == null || value == 'false');
  }
}
