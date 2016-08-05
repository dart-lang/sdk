// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';

typedef HtmlElement VirtualCollectionCreateCallback();
typedef void VirtualCollectionUpdateCallback(HtmlElement el, dynamic item,
    int index);

class VirtualCollectionElement extends HtmlElement implements Renderable {
  static const tag =
      const Tag<VirtualCollectionElement>('virtual-collection');

  RenderingScheduler<VirtualCollectionElement> _r;

  Stream<RenderedEvent<VirtualCollectionElement>> get onRendered =>
      _r.onRendered;

  VirtualCollectionCreateCallback _create;
  VirtualCollectionUpdateCallback _update;
  double _itemHeight;
  int _top;
  double _height;
  List _items;
  StreamSubscription _onScrollSubscription;
  StreamSubscription _onResizeSubscription;

  List get items => _items;

  set items(Iterable value) {
    _items = new List.unmodifiable(value);
    _r.dirty();
  }


  factory VirtualCollectionElement(VirtualCollectionCreateCallback create,
      VirtualCollectionUpdateCallback update, {Iterable items: const [],
      RenderingQueue queue}) {
    assert(create != null);
    assert(update != null);
    assert(items != null);
    VirtualCollectionElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._create = create;
    e._update = update;
    e._items = new List.unmodifiable(items);
    return e;
  }

  VirtualCollectionElement.created() : super.created();

  @override
  attached() {
    super.attached();
    _r.enable();
    _top = 0;
    _height = getBoundingClientRect().height;
    _itemHeight = _computeItemHeight();
    _onScrollSubscription = onScroll.listen(_onScroll);
    _onResizeSubscription = window.onResize.listen(_onResize);
  }

 @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    children = const [];
    _onScrollSubscription.cancel();
    _onResizeSubscription.cancel();
  }

  final DivElement _scroller = new DivElement()..classes = const ['scroller'];
  final DivElement _shifter = new DivElement()..classes = const ['shifter'];

  dynamic getItemFromElement(HtmlElement element) {
    final el_index = _shifter.children.indexOf(element);
    if (el_index < 0) {
      return null;
    }
    final item_index =
      _top + el_index - (_shifter.children.length * _inverse_preload).floor();
    if (0 <= item_index && item_index < items.length) {
      return _items[item_index];
    }
    return null;
  }

  /// The preloaded element before and after the visible area are:
  /// 1/preload_size of the number of items in the visble area.
  /// See shared.css for the "top:-25%;".
  static const int _preload = 2;
  /// L = length of all the elements loaded
  /// l = length of the visible area
  ///
  /// L = l + 2 * l / _preload
  /// l = L * _preload / (_preload + 2)
  ///
  /// tail = l / _preload = L * 1 / (_preload + 2) = L * _inverse_preload
  static const double _inverse_preload = 1 / (_preload + 2);

  void render() {
    _top = (scrollTop / _itemHeight).floor();

    _scroller.style.height = '${_itemHeight*(_items.length)}px';
    _shifter.style.top = '${_itemHeight*_top}px';
    final tail_length = (_height / _itemHeight / _preload).ceil();
    final length = tail_length * 2 + tail_length * _preload;

    if (_shifter.children.length < length) {
      while (_shifter.children.length != length) {
        var e = _create();
        e..style.display = 'hidden';
        _shifter.children.add(e);
      }
      _shifter.style.height = '${_itemHeight*length}px';
      children = [
        _scroller
          ..children = [_shifter]
      ];
    }

    int i = _top - tail_length;
    for (final HtmlElement e in _shifter.children) {
      if (0 <= i && i < _items.length) {
        e..style.display = null;
        _update(e, _items[i], i);
      } else {
        e.style.display = 'hidden';
      }
      i++;
    }
  }

  double _computeItemHeight() {
    final c = children;
    children = [_create()];
    final height = children[0].getBoundingClientRect().height;
    children = c;
    return height;
  }

  void _onScroll(_) {
    if(_r.isDirty) return;
    if ((scrollTop - _top * _itemHeight).abs() >=
         _shifter.children.length * _inverse_preload * _itemHeight) {
      _r.dirty();
    }
  }

  void _onResize(_) {
    _height = getBoundingClientRect().height;
    _r.dirty();
  }
}
