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
import 'package:observatory/app.dart';

/// Displays an Error response.
@CustomTag('heap-map')
class HeapMapElement extends ObservatoryElement {
  var _fragmentationCanvas;
  var _fragmentationData;

  @observable String status;
  @published ServiceMap fragmentation;

  HeapMapElement.created() : super.created() {
  }

  void enteredView() {
    super.enteredView();
    _fragmentationCanvas = shadowRoot.querySelector("#fragmentation");
  }

  List<int> _classIdToRGBA(int classId) {
    if (classId == fragmentation['free_class_id']) {
      return [255, 255, 255, 255];
    } else {
      // TODO(koda): Pick random hue, but fixed saturation and value.
      var rng = new Random(classId);
      return [rng.nextInt(128),
              rng.nextInt(128),
              rng.nextInt(128),
              255];
    }
  }

  void _updateFragmentationData() {
    if (fragmentation == null || _fragmentationCanvas == null) {
      return;
    }
    var pages = fragmentation['pages'];
    // Calculate dimensions.
    var numPixels = 0;
    var colorMap = {};
    for (var page in pages) {
      for (int i = 0; i < page.length; i += 2) {
        numPixels += page[i];
        var classId = page[i + 1];
        colorMap.putIfAbsent(classId, () => _classIdToRGBA(classId));
      }
    }
    var width = _fragmentationCanvas.parent.client.width;
    var height = (numPixels + width - 1) ~/ width;
    // Render image.
    _fragmentationData =
        _fragmentationCanvas.context2D.createImageData(width, height);
    _fragmentationCanvas.width = _fragmentationData.width;
    _fragmentationCanvas.height = _fragmentationData.height;
    _renderPages(0, 0, colorMap);
  }

  // Renders and draws asynchronously, one page at a time to avoid
  // blocking the UI.
  void _renderPages(int startPage, int dataIndex, var colorMap) {
    var pages = fragmentation['pages'];
    status = 'Loaded $startPage of ${pages.length} pages';
    if (startPage >= pages.length) {
      return;
    }
    var width = _fragmentationData.width;
    var dirtyBegin = (dataIndex / 4) ~/ width;
    var page = pages[startPage];
    for (var i = 0; i < page.length; i += 2) {
      var count = page[i];
      var color = colorMap[page[i + 1]];
      for (var j = 0; j < count; ++j) {
        for (var component in color) {
          _fragmentationData.data[dataIndex++] = component;
        }
      }
    }
    var dirtyEnd = (dataIndex / 4 + width - 1) ~/ width;
    _fragmentationCanvas.context2D.putImageData(
        _fragmentationData, 0, 0, 0, dirtyBegin, width, dirtyEnd - dirtyBegin);
    // Continue with the next page, asynchronously.
    new Future(() {
      _renderPages(startPage + 1, dataIndex, colorMap);
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