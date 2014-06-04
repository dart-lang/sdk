// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library heap_map_element;

import 'dart:async';
import 'dart:html';
import 'dart:math';
import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

// A reference to a particular pixel of ImageData.
class PixelReference {
  final _data;
  var _dataIndex;
  static const NUM_COLOR_COMPONENTS = 4;

  PixelReference(ImageData data, Point<int> point)
      : _data = data,
        _dataIndex = (point.y * data.width + point.x) * NUM_COLOR_COMPONENTS;

  PixelReference._fromDataIndex(this._data, this._dataIndex);

  Point<int> get point =>
      new Point(index % _data.width, index ~/ _data.width);

  void set color(Iterable<int> color) {
    _data.data.setRange(
        _dataIndex, _dataIndex + NUM_COLOR_COMPONENTS, color);
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

@CustomTag('heap-map')
class HeapMapElement extends ObservatoryElement {
  var _fragmentationCanvas;
  var _fragmentationData;
  var _pageHeight;
  var _classIdToColor = {};
  var _colorToClassId = {};
  var _classIdToName = {};

  static final _freeColor = [255, 255, 255, 255];
  static final _pageSeparationColor = [0, 0, 0, 255];
  static const _PAGE_SEPARATION_HEIGHT = 4;

  @observable String status;
  @published ServiceMap fragmentation;

  HeapMapElement.created() : super.created() {
  }

  void enteredView() {
    super.enteredView();
    _fragmentationCanvas = shadowRoot.querySelector("#fragmentation");
    _fragmentationCanvas.onMouseMove.listen(_handleMouseMove);
    _fragmentationCanvas.onMouseDown.listen(_handleClick);
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
    for (var member in classList['members']) {
      if (member is! Class) {
        Logger.root.info('$member');
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
    var pagePixels = _pageHeight * _fragmentationData.width;
    var index = new PixelReference(_fragmentationData, point).index;
    var pageIndex = index ~/ pagePixels;
    var pageOffset = index % pagePixels;
    var pages = fragmentation['pages'];
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
    return new ObjectInfo(int.parse(page['object_start']) +
                          pageOffset * fragmentation['unit_size_bytes'],
        size * fragmentation['unit_size_bytes']);
  }

  void _handleMouseMove(MouseEvent event) {
    var info = _objectAt(event.offset);
    var addressString = '${info.size}B @ 0x${info.address.toRadixString(16)}';
    var className = _classNameAt(event.offset);
    status = (className == '') ? '-' : '$className $addressString';
  }

  void _handleClick(MouseEvent event) {
    var address = _objectAt(event.offset).address.toRadixString(16);
    window.location.hash = "/${fragmentation.isolate.link}/address/$address";
  }

  void _updateFragmentationData() {
    if (fragmentation == null || _fragmentationCanvas == null) {
      return;
    }
    _updateClassList(
        fragmentation['class_list'], fragmentation['free_class_id']);
    var pages = fragmentation['pages'];
    var width = _fragmentationCanvas.parent.client.width;
    _pageHeight = _PAGE_SEPARATION_HEIGHT +
        fragmentation['page_size_bytes'] ~/
        fragmentation['unit_size_bytes'] ~/ width;
    var height = _pageHeight * pages.length;
    _fragmentationData =
        _fragmentationCanvas.context2D.createImageData(width, height);
    _fragmentationCanvas.width = _fragmentationData.width;
    _fragmentationCanvas.height = _fragmentationData.height;
    _renderPages(0);
  }

  // Renders and draws asynchronously, one page at a time to avoid
  // blocking the UI.
  void _renderPages(int startPage) {
    var pages = fragmentation['pages'];
    status = 'Loaded $startPage of ${pages.length} pages';
    if (startPage >= pages.length) {
      return;
    }
    var startY = startPage * _pageHeight;
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
    var endY = startY + _pageHeight;
    while (pixel.point.y < endY) {
      pixel.color = _pageSeparationColor;
      pixel = pixel.next();
    }
    _fragmentationCanvas.context2D.putImageData(
        _fragmentationData, 0, 0, 0, startY, _fragmentationData.width, endY);
    // Continue with the next page, asynchronously.
    new Future(() {
      _renderPages(startPage + 1);
    });
  }

  void refresh(var done) {
    if (fragmentation == null) {
      return;
    }
    fragmentation.isolate.get('heapmap').then((ServiceMap response) {
      assert(response['type'] == 'HeapMap');
      fragmentation = response;
    }).catchError((e, st) {
      Logger.root.info('$e $st');
    }).whenComplete(done);
  }

  void fragmentationChanged(oldValue) {
    // Async, in case enteredView has not yet run (observed in JS version).
    new Future(() {
      _updateFragmentationData();
    });
  }
}