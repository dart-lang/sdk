// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library flag_list_element;

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/src/elements/view_footer.dart';

class FlagListElement extends HtmlElement implements Renderable {
  static const tag =
      const Tag<FlagListElement>('flag-list', dependencies: const [
    NavNotifyElement.tag,
    NavRefreshElement.tag,
    NavTopMenuElement.tag,
    NavVMMenuElement.tag,
    ViewFooterElement.tag,
  ]);

  RenderingScheduler _r;

  Stream<RenderedEvent<FlagListElement>> get onRendered => _r.onRendered;

  M.VMRef _vm;
  M.EventRepository _events;
  M.FlagsRepository _repository;
  M.NotificationRepository _notifications;
  Iterable<M.Flag> _flags;

  M.VMRef get vm => _vm;

  factory FlagListElement(M.VMRef vm, M.EventRepository events,
      M.FlagsRepository repository, M.NotificationRepository notifications,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(events != null);
    assert(repository != null);
    assert(notifications != null);
    FlagListElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._vm = vm;
    e._events = events;
    e._repository = repository;
    e._notifications = notifications;
    return e;
  }

  FlagListElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _refresh();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    children = [];
    _r.disable(notify: true);
  }

  void render() {
    final content = <Element>[];
    if (_flags == null) {
      content.add(new HeadingElement.h1()..text = 'Loading Flags...');
    } else {
      final modified = _flags.where(_isModified);
      final unmodified = _flags.where(_isUnmodified);

      if (modified.isNotEmpty) {
        content.add(new HeadingElement.h1()..text = 'Modified Flags');
        content.add(new BRElement());
        content.addAll(modified.expand(_renderFlag));
        content.add(new HRElement());
      }

      content.add(new HeadingElement.h1()..text = 'Unmodified Flags');
      content.add(new BRElement());

      if (unmodified.isEmpty) {
        content.add(new HeadingElement.h2()..text = 'None');
      } else {
        content.addAll(unmodified.expand(_renderFlag));
      }
    }

    children = [
      navBar([
        new NavTopMenuElement(queue: _r.queue),
        new NavVMMenuElement(_vm, _events, queue: _r.queue),
        navMenu('flags', link: Uris.flags()),
        new NavRefreshElement(queue: _r.queue)
          ..onRefresh.listen((e) async {
            e.element.disabled = true;
            try {
              await _refresh();
            } finally {
              e.element.disabled = false;
            }
          }),
        new NavNotifyElement(_notifications, queue: _r.queue)
      ]),
      new DivElement()
        ..classes = ['content-centered']
        ..children = content,
      new ViewFooterElement(queue: _r.queue)
    ];
  }

  Future _refresh() {
    return _repository.list().then((flags) {
      _flags = flags;
      _r.dirty();
    });
  }

  static bool _isModified(M.Flag flag) => flag.modified;
  static bool _isUnmodified(M.Flag flag) => !flag.modified;

  static List<Element> _renderFlag(M.Flag flag) {
    return [
      new SpanElement()
        ..classes = ['comment']
        ..text = '// ${flag.comment}',
      new DivElement()
        ..classes =
            flag.modified ? ['flag', 'modified'] : ['flag', 'unmodified']
        ..children = [
          new SpanElement()
            ..classes = ['name']
            ..text = flag.name,
          new SpanElement()..text = '=',
          new SpanElement()
            ..classes = ['value']
            ..text = flag.valueAsString ?? 'NULL'
        ],
      new BRElement(),
    ];
  }
}
