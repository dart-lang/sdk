// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library flag_list_element;

import 'dart:async';

import 'package:web/web.dart';

import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/element_utils.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';

class FlagListElement extends CustomElement implements Renderable {
  late RenderingScheduler<FlagListElement> _r;

  Stream<RenderedEvent<FlagListElement>> get onRendered => _r.onRendered;

  late M.VMRef _vm;
  late M.EventRepository _events;
  late M.FlagsRepository _repository;
  late M.NotificationRepository _notifications;
  Iterable<M.Flag>? _flags;

  M.VMRef get vm => _vm;

  factory FlagListElement(M.VMRef vm, M.EventRepository events,
      M.FlagsRepository repository, M.NotificationRepository notifications,
      {RenderingQueue? queue}) {
    FlagListElement e = new FlagListElement.created();
    e._r = new RenderingScheduler<FlagListElement>(e, queue: queue);
    e._vm = vm;
    e._events = events;
    e._repository = repository;
    e._notifications = notifications;
    return e;
  }

  FlagListElement.created() : super.created('flag-list');

  @override
  void attached() {
    super.attached();
    _refresh();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    removeChildren();
    _r.disable(notify: true);
  }

  void render() {
    final content = <HTMLElement>[];
    if (_flags == null) {
      content
          .add(new HTMLHeadingElement.h1()..textContent = 'Loading Flags...');
    } else {
      final modified = _flags!.where(_isModified);
      final unmodified = _flags!.where(_isUnmodified);

      if (modified.isNotEmpty) {
        content
            .add(new HTMLHeadingElement.h1()..textContent = 'Modified Flags');
        content.add(new HTMLBRElement());
        content.addAll(modified.expand(_renderFlag));
        content.add(new HTMLHRElement());
      }

      content
          .add(new HTMLHeadingElement.h1()..textContent = 'Unmodified Flags');
      content.add(new HTMLBRElement());

      if (unmodified.isEmpty) {
        content.add(new HTMLHeadingElement.h2()..textContent = 'None');
      } else {
        content.addAll(unmodified.expand(_renderFlag));
      }
    }

    setChildren(<HTMLElement>[
      navBar(<HTMLElement>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm as M.VM, _events, queue: _r.queue).element,
        navMenu('flags', link: Uris.flags()),
        (new NavRefreshElement(queue: _r.queue)
              ..onRefresh.listen((e) async {
                e.element.disabled = true;
                try {
                  await _refresh();
                } finally {
                  e.element.disabled = false;
                }
              }))
            .element,
        new NavNotifyElement(_notifications, queue: _r.queue).element
      ]),
      new HTMLDivElement()
        ..className = 'content-centered'
        ..appendChildren(content),
    ]);
  }

  Future _refresh() {
    return _repository.list().then((flags) {
      _flags = flags;
      _r.dirty();
    });
  }

  static bool _isModified(M.Flag flag) => flag.modified;
  static bool _isUnmodified(M.Flag flag) => !flag.modified;

  static List<HTMLElement> _renderFlag(M.Flag flag) {
    return [
      new HTMLSpanElement()
        ..className = 'comment'
        ..textContent = '// ${flag.comment}',
      new HTMLDivElement()
        ..className = flag.modified ? 'flag modified' : 'flag unmodified'
        ..appendChildren(<HTMLElement>[
          new HTMLSpanElement()
            ..className = 'name'
            ..textContent = flag.name,
          new HTMLSpanElement()..textContent = '=',
          new HTMLSpanElement()
            ..className = 'value'
            ..textContent = flag.valueAsString ?? ''
        ]),
      new HTMLBRElement(),
    ];
  }
}
