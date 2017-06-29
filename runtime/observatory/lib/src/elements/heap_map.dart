// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library heap_map_element;

import 'dart:async';
import 'dart:html';
import 'dart:math';
import 'package:observatory/models.dart' as M;
import 'package:observatory/service.dart' as S;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';

class HeapMapElement extends HtmlElement implements Renderable {
  static const tag = const Tag<HeapMapElement>('heap-map', dependencies: const [
    NavTopMenuElement.tag,
    NavVMMenuElement.tag,
    NavIsolateMenuElement.tag,
    NavRefreshElement.tag,
    NavNotifyElement.tag,
  ]);

  RenderingScheduler<HeapMapElement> _r;

  Stream<RenderedEvent<HeapMapElement>> get onRendered => _r.onRendered;

  M.VM _vm;
  M.IsolateRef _isolate;
  M.EventRepository _events;
  M.NotificationRepository _notifications;
  M.VMRef get vm => _vm;
  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;

  factory HeapMapElement(M.VM vm, M.IsolateRef isolate,
      M.EventRepository events, M.NotificationRepository notifications,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(isolate != null);
    assert(events != null);
    assert(notifications != null);
    HeapMapElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    return e;
  }

  HeapMapElement.created() : super.created();

  @override
  attached() {
    super.attached();
    _r.enable();
    _refresh();
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    children = [];
  }

  CanvasElement _canvas;
  var _fragmentationData;
  double _pageHeight;
  final _classIdToColor = {};
  final _colorToClassId = {};
  final _classIdToName = {};

  static final _freeColor = [255, 255, 255, 255];
  static final _pageSeparationColor = [0, 0, 0, 255];
  static const _PAGE_SEPARATION_HEIGHT = 4;
  // Many browsers will not display a very tall canvas.
  // TODO(koda): Improve interface for huge heaps.
  static const _MAX_CANVAS_HEIGHT = 6000;

  String _status;
  S.ServiceMap _fragmentation;

  void render() {
    if (_canvas == null) {
      _canvas = new CanvasElement()
        ..width = 1
        ..height = 1
        ..onMouseMove.listen(_handleMouseMove)
        ..onMouseDown.listen(_handleClick);
    }

    // Set hover text to describe the object under the cursor.
    _canvas.title = _status;

    children = [
      navBar([
        new NavTopMenuElement(queue: _r.queue),
        new NavVMMenuElement(_vm, _events, queue: _r.queue),
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue),
        navMenu('heap map'),
        new NavRefreshElement(label: 'GC', queue: _r.queue)
          ..onRefresh.listen((_) => _refresh(gc: true)),
        new NavRefreshElement(queue: _r.queue)
          ..onRefresh.listen((_) => _refresh()),
        new NavNotifyElement(_notifications, queue: _r.queue)
      ]),
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = [
          new HeadingElement.h2()..text = _status,
          new HRElement(),
        ],
      new DivElement()
        ..classes = ['flex-row']
        ..children = [_canvas]
    ];
  }

  // Encode color as single integer, to enable using it as a map key.
  int _packColor(Iterable<int> color) {
    int packed = 0;
    for (var component in color) {
      packed = packed * 256 + component;
    }
    return packed;
  }

  void _addClass(int classId, String name, Iterable<int> color) {
    _classIdToName[classId] = name.split('@')[0];
    _classIdToColor[classId] = color;
    _colorToClassId[_packColor(color)] = classId;
  }

  void _updateClassList(classList, int freeClassId) {
    for (var member in classList['classes']) {
      if (member is! S.Class) {
        // TODO(turnidge): The printing for some of these non-class
        // members is broken.  Fix this:
        //
        // Logger.root.info('$member');
        print('Ignoring non-class in class list');
        continue;
      }
      var classId = int.parse(member.id.split('/').last);
      var color = _classIdToRGBA(classId);
      _addClass(classId, member.name, color);
    }
    _addClass(freeClassId, 'Free', _freeColor);
    _addClass(0, '', _pageSeparationColor);
  }

  Iterable<int> _classIdToRGBA(int classId) {
    // TODO(koda): Pick random hue, but fixed saturation and value.
    var rng = new Random(classId);
    return [rng.nextInt(128), rng.nextInt(128), rng.nextInt(128), 255];
  }

  String _classNameAt(Point<int> point) {
    var color = new PixelReference(_fragmentationData, point).color;
    return _classIdToName[_colorToClassId[_packColor(color)]];
  }

  ObjectInfo _objectAt(Point<int> point) {
    if (_fragmentation == null || _canvas == null) {
      return null;
    }
    var pagePixels = _pageHeight * _fragmentationData.width;
    var index = new PixelReference(_fragmentationData, point).index;
    var pageIndex = index ~/ pagePixels;
    var pageOffset = index % pagePixels;
    var pages = _fragmentation['pages'];
    if (pageIndex < 0 || pageIndex >= pages.length) {
      return null;
    }
    // Scan the page to find start and size.
    var page = pages[pageIndex];
    var objects = page['objects'];
    var offset = 0;
    var size = 0;
    for (var i = 0; i < objects.length; i += 2) {
      size = objects[i];
      offset += size;
      if (offset > pageOffset) {
        pageOffset = offset - size;
        break;
      }
    }
    return new ObjectInfo(
        int.parse(page['objectStart']) +
            pageOffset * _fragmentation['unitSizeBytes'],
        size * _fragmentation['unitSizeBytes']);
  }

  void _handleMouseMove(MouseEvent event) {
    var info = _objectAt(event.offset);
    if (info == null) {
      _status = '';
      _r.dirty();
      return;
    }
    var addressString = '${info.size}B @ 0x${info.address.toRadixString(16)}';
    var className = _classNameAt(event.offset);
    _status = (className == '') ? '-' : '$className $addressString';
    _r.dirty();
  }

  void _handleClick(MouseEvent event) {
    final isolate = _isolate as S.Isolate;
    final address = _objectAt(event.offset).address.toRadixString(16);
    isolate.getObjectByAddress(address).then((result) {
      if (result.type != 'Sentinel') {
        new AnchorElement(
                href: Uris.inspect(_isolate, object: result as S.HeapObject))
            .click();
      }
    });
  }

  void _updateFragmentationData() {
    if (_fragmentation == null || _canvas == null) {
      return;
    }
    _updateClassList(
        _fragmentation['classList'], _fragmentation['freeClassId']);
    var pages = _fragmentation['pages'];
    var width = max(_canvas.parent.client.width, 1);
    _pageHeight = _PAGE_SEPARATION_HEIGHT +
        _fragmentation['pageSizeBytes'] ~/
            _fragmentation['unitSizeBytes'] ~/
            width;
    var height = min(_pageHeight * pages.length, _MAX_CANVAS_HEIGHT);
    _fragmentationData = _canvas.context2D.createImageData(width, height);
    _canvas.width = _fragmentationData.width;
    _canvas.height = _fragmentationData.height;
    _renderPages(0);
  }

  // Renders and draws asynchronously, one page at a time to avoid
  // blocking the UI.
  void _renderPages(int startPage) {
    var pages = _fragmentation['pages'];
    _status = 'Loaded $startPage of ${pages.length} pages';
    _r.dirty();
    var startY = startPage * _pageHeight;
    var endY = startY + _pageHeight;
    if (startPage >= pages.length || endY > _fragmentationData.height) {
      return;
    }
    var pixel = new PixelReference(_fragmentationData, new Point(0, startY));
    var objects = pages[startPage]['objects'];
    for (var i = 0; i < objects.length; i += 2) {
      var count = objects[i];
      var classId = objects[i + 1];
      var color = _classIdToColor[classId];
      while (count-- > 0) {
        pixel.color = color;
        pixel = pixel.next();
      }
    }
    while (pixel.point.y < endY) {
      pixel.color = _pageSeparationColor;
      pixel = pixel.next();
    }
    _canvas.context2D.putImageData(
        _fragmentationData, 0, 0, 0, startY, _fragmentationData.width, endY);
    // Continue with the next page, asynchronously.
    new Future(() {
      _renderPages(startPage + 1);
    });
  }

  Future _refresh({gc: false}) {
    final isolate = _isolate as S.Isolate;
    var params = {};
    if (gc) {
      params['gc'] = 'full';
    }
    return isolate
        .invokeRpc('_getHeapMap', params)
        .then((S.ServiceMap response) {
      assert(response['type'] == 'HeapMap');
      _fragmentation = response;
      _updateFragmentationData();
    });
  }
}

// A reference to a particular pixel of ImageData.
class PixelReference {
  final _data;
  var _dataIndex;
  static const NUM_COLOR_COMPONENTS = 4;

  PixelReference(ImageData data, Point<int> point)
      : _data = data,
        _dataIndex = (point.y * data.width + point.x) * NUM_COLOR_COMPONENTS;

  PixelReference._fromDataIndex(this._data, this._dataIndex);

  Point<int> get point => new Point(index % _data.width, index ~/ _data.width);

  void set color(Iterable<int> color) {
    _data.data.setRange(_dataIndex, _dataIndex + NUM_COLOR_COMPONENTS, color);
  }

  Iterable<int> get color =>
      _data.data.getRange(_dataIndex, _dataIndex + NUM_COLOR_COMPONENTS);

  // Returns the next pixel in row-major order.
  PixelReference next() => new PixelReference._fromDataIndex(
      _data, _dataIndex + NUM_COLOR_COMPONENTS);

  // The row-major index of this pixel.
  int get index => _dataIndex ~/ NUM_COLOR_COMPONENTS;
}

class ObjectInfo {
  final address;
  final size;
  ObjectInfo(this.address, this.size);
}
