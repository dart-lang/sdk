// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M
  show VM, IsolateRef, Target, VMUpdateEvent;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/nav/menu.dart';
import 'package:observatory/src/elements/nav/menu_item.dart';

class NavVMMenuElement extends HtmlElement implements Renderable {
  static const tag = const Tag<NavVMMenuElement>('nav-vm-menu',
                     dependencies: const [NavMenuElement.tag,
                                          NavMenuItemElement.tag]);

  RenderingScheduler _r;

  Stream<RenderedEvent<NavVMMenuElement>> get onRendered => _r.onRendered;

  Stream<M.VMUpdateEvent> _updates;
  StreamSubscription _updatesSubscription;

  bool _last;
  M.VM _vm;
  M.Target _target;
  bool get last => _last;
  M.VM get vm => _vm;
  M.Target get target => _target;
  set last(bool value) => _last = _r.checkAndReact(_last, value);

  factory NavVMMenuElement(M.VM vm, Stream<M.VMUpdateEvent> updates,
      {bool last: false, M.Target target, RenderingQueue queue}) {
    assert(vm != null);
    assert(updates != null);
    assert(last != null);
    NavVMMenuElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._vm = vm;
    e._updates = updates;
    e._last = last;
    e._target = target;
    return e;
  }

  NavVMMenuElement.created() : super.created() { createShadowRoot(); }

  @override
  void attached() {
    super.attached();
    _r.enable();
    _updatesSubscription = _updates
      .listen((M.VMUpdateEvent e) { _vm = e.vm; _r.dirty(); });
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    shadowRoot.children = [];
    assert(_updatesSubscription != null);
    _updatesSubscription.cancel();
    _updatesSubscription = null;
  }

  void render() {
    final String name = (target == null) ? vm.name
                                         : '${vm.name}@${target.name}';
    /// TODO(cbernaschina) use the isolate repository.
    shadowRoot.children = [
      new NavMenuElement(name, link: Uris.vm(), last: last, queue: _r.queue)
        ..children = (
          _vm.isolates.map((M.IsolateRef isolate) {
            return new NavMenuItemElement(isolate.name, queue: _r.queue,
                link: Uris.inspect(isolate));
          }).toList()
          ..add(new ContentElement())
        )
    ];
  }
}
