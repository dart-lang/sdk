// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A way to test heap snapshot loading and analysis outside of Observatory, and
// to handle snapshots that require more memory to analyze than is available in
// a web browser.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:observatory_2/object_graph.dart';

Future<SnapshotGraph> load(String uri) async {
  final ws = await WebSocket.connect(uri,
      compression: CompressionOptions.compressionOff);

  final getVM = new Completer<String>();
  final reader = new SnapshotReader();

  reader.onProgress.listen(print);

  ws.listen((dynamic response) {
    if (response is String) {
      response = json.decode(response);
      if (response['id'] == 1) {
        getVM.complete(response['result']['isolates'][0]['id']);
      }
    } else if (response is List<int>) {
      response = new Uint8List.fromList(response);
      final dataOffset =
          new ByteData.view(response.buffer).getUint32(0, Endian.little);
      dynamic metadata = new Uint8List.view(response.buffer, 4, dataOffset - 4);
      final data = new Uint8List.view(
          response.buffer, dataOffset, response.length - dataOffset);
      metadata = utf8.decode(metadata);
      metadata = json.decode(metadata);
      var event = metadata['params']['event'];
      if (event['kind'] == 'HeapSnapshot') {
        bool last = event['last'] == true;
        reader.add(data);
        if (last) {
          reader.close();
          ws.close();
        }
      }
    }
  });

  ws.add(json.encode({
    'jsonrpc': '2.0',
    'method': 'getVM',
    'params': {},
    'id': 1,
  }));

  final String isolateId = await getVM.future;

  ws.add(json.encode({
    'jsonrpc': '2.0',
    'method': 'streamListen',
    'params': {'streamId': 'HeapSnapshot'},
    'id': 2,
  }));
  ws.add(json.encode({
    'jsonrpc': '2.0',
    'method': 'requestHeapSnapshot',
    'params': {'isolateId': isolateId},
    'id': 3,
  }));

  return reader.done;
}

String makeData(dynamic root) {
  // 'root' can be arbitrarily deep, so we can't directly represent it as a
  // JSON tree, which cause a stack overflow here encoding it and in the JS
  // engine decoding it. Instead we flatten the tree into a list of tuples with
  // a parent pointer and re-inflate it in JS.
  final indices = <dynamic, int>{};
  final preorder = <dynamic>[];
  preorder.add(root);

  for (var index = 0; index < preorder.length; index++) {
    final object = preorder[index];
    preorder.addAll(object.children);
  }

  final flattened = <dynamic>[];
  for (var index = 0; index < preorder.length; index++) {
    final object = preorder[index];
    indices[object] = index;

    flattened.add(object.description);
    flattened.add(object.klass.name);
    flattened.add(object.retainedSize);
    if (index == 0) {
      flattened.add(null);
    } else {
      flattened.add(indices[object.parent] as int);
    }
  }

  return json.encode(flattened);
}

var css = '''
.treemapTile {
    position: absolute;
    box-sizing: border-box;
    border: solid 1px;
    font-size: 10;
    text-align: center;
    overflow: hidden;
    white-space: nowrap;
    cursor: default;
}
''';

var js = '''
function hash(string) {
  // Jenkin's one_at_a_time.
  let h = string.length;
  for (let i = 0; i < string.length; i++) {
    h += string.charCodeAt(i);
    h += h << 10;
    h ^= h >> 6;
  }
  h += h << 3;
  h ^= h >> 11;
  h += h << 15;
  return h;
}

function color(string) {
  let hue = hash(string) % 360;
  return "hsl(" + hue + ",60%,60%)";
}

function prettySize(size) {
  if (size < 1024) return size + "B";
  size /= 1024;
  if (size < 1024) return size.toFixed(1) + "KiB";
  size /= 1024;
  if (size < 1024) return size.toFixed(1) + "MiB";
  size /= 1024;
  return size.toFixed(1) + "GiB";
}

function prettyPercent(fraction) {
  return (fraction * 100).toFixed(1);
}

function createTreemapTile(v, width, height, depth) {
  let div = document.createElement("div");
  div.className = "treemapTile";
  div.style["background-color"] = color(v.type);
  div.ondblclick = function(event) {
    event.stopPropagation();
    if (depth == 0) {
      let dom = v.parent;
      if (dom == undefined) {
        // Already at root.
      } else {
        showDominatorTree(dom);  // Zoom out.
      }
    } else {
      showDominatorTree(v);  // Zoom in.
    }
  };

  let left = 0;
  let top = 0;

  const kPadding = 5;
  const kBorder = 1;
  left += kPadding - kBorder;
  top += kPadding - kBorder;
  width -= 2 * kPadding;
  height -= 2 * kPadding;

  let label = v.name + " [" + prettySize(v.size) + "]";
  div.title = label;

  if (width < 10 || height < 10) {
    // Too small: don't render label or children.
    return div;
  }

  div.appendChild(document.createTextNode(label));
  const kLabelHeight = 9;
  top += kLabelHeight;
  height -= kLabelHeight;

  if (depth > 2) {
    // Too deep: don't render children.
    return div;
  }
  if (width < 4 || height < 4) {
    // Too small: don't render children.
    return div;
  }

  let children = new Array();
  v.children.forEach(function(c) {
    // Size 0 children seem to confuse the layout algorithm (accumulating
    // rounding errors?).
    if (c.size > 0) {
      children.push(c);
    }
  });
  children.sort(function (a, b) {
    return b.size - a.size;
  });

  const scale = width * height / v.size;

  // Bruls M., Huizing K., van Wijk J.J. (2000) Squarified Treemaps. In: de
  // Leeuw W.C., van Liere R. (eds) Data Visualization 2000. Eurographics.
  // Springer, Vienna.
  for (let rowStart = 0;  // Index of first child in the next row.
       rowStart < children.length;) {
    // Prefer wider rectangles, the better to fit text labels.
    const GOLDEN_RATIO = 1.61803398875;
    let verticalSplit = (width / height) > GOLDEN_RATIO;

    let space;
    if (verticalSplit) {
      space = height;
    } else {
      space = width;
    }

    let rowMin = children[rowStart].size * scale;
    let rowMax = rowMin;
    let rowSum = 0;
    let lastRatio = 0;

    let rowEnd;  // One after index of last child in the next row.
    for (rowEnd = rowStart; rowEnd < children.length; rowEnd++) {
      let size = children[rowEnd].size * scale;
      if (size < rowMin) rowMin = size;
      if (size > rowMax) rowMax = size;
      rowSum += size;

      let ratio = Math.max((space * space * rowMax) / (rowSum * rowSum),
                           (rowSum * rowSum) / (space * space * rowMin));
      if ((lastRatio != 0) && (ratio > lastRatio)) {
        // Adding the next child makes the aspect ratios worse: remove it and
        // add the row.
        rowSum -= size;
        break;
      }
      lastRatio = ratio;
    }

    let rowLeft = left;
    let rowTop = top;
    let rowSpace = rowSum / space;

    for (let i = rowStart; i < rowEnd; i++) {
      let child = children[i];
      let size = child.size * scale;

      let childWidth;
      let childHeight;
      if (verticalSplit) {
        childWidth = rowSpace;
        childHeight = size / childWidth;
      } else {
        childHeight = rowSpace;
        childWidth = size / childHeight;
      }

      let childDiv = createTreemapTile(child, childWidth, childHeight, depth + 1);
      childDiv.style.left = rowLeft + "px";
      childDiv.style.top = rowTop + "px";
      // Oversize the final div by kBorder to make the borders overlap.
      childDiv.style.width = (childWidth + kBorder) + "px";
      childDiv.style.height = (childHeight + kBorder) + "px";
      div.appendChild(childDiv);

      if (verticalSplit)
        rowTop += childHeight;
      else
        rowLeft += childWidth;
    }

    if (verticalSplit) {
      left += rowSpace;
      width -= rowSpace;
    } else {
      top += rowSpace;
      height -= rowSpace;
    }

    rowStart = rowEnd;
  }

  return div;
}

function setBody(div) {
  let body = document.body;
  while (body.firstChild) {
    body.removeChild(body.firstChild);
  }
  body.appendChild(div);
}

function showDominatorTree(v) {
  let header = document.createElement("div");
  header.textContent = "Dominator Tree";
  header.title =
    "Double click a box to zoom in.\\n" +
    "Double click the outermost box to zoom out.";
  header.className = "headerRow";
  header.style["flex-grow"] = 0;
  header.style["padding"] = "5px";
  header.style["border-bottom"] = "solid 1px";

  let content = document.createElement("div");
  content.style["flex-basis"] = 0;
  content.style["flex-grow"] = 1;

  let column = document.createElement("div");
  column.style["width"] = "100%";
  column.style["height"] = "100%";
  column.style["border"] = "solid 2px";
  column.style["display"] = "flex";
  column.style["flex-direction"] = "column";
  column.appendChild(header);
  column.appendChild(content);

  setBody(column);

  // Add the content div to the document first so the browser will calculate
  // the available width and height.
  let w = content.offsetWidth;
  let h = content.offsetHeight;

  let topTile = createTreemapTile(v, w, h, 0);
  topTile.style.width = w;
  topTile.style.height = h;
  topTile.style.border = "none";
  content.appendChild(topTile);
}

function inflateData(flattened) {
  // 'root' can be arbitrarily deep, so we need to use an explicit stack
  // instead of the call stack.
  let nodes = new Array();
  let i = 0;
  while (i < flattened.length) {
    let node = {
      "name": flattened[i++],
      "type": flattened[i++],
      "size": flattened[i++],
      "children": [],
      "parent": null
    };
    nodes.push(node);

    let parentIndex = flattened[i++];
    if (parentIndex != null) {
      let parent = nodes[parentIndex];
      parent.children.push(node);
      node.parent = parent;
    }
  }

  return nodes[0];
}

var root = __DATA__;
root = inflateData(root);

showDominatorTree(root);
''';

var html = '''
<html>
  <head>
    <title>Dart Heap Snapshot</title>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <style>$css</style>
  </head>
  <body>
    <script>$js</script>
  </body>
</html>
''';

main(List<String> args) async {
  if (args.length < 1) {
    print('Usage: heap_snapshot.dart <vm-service-uri>');
    exitCode = 1;
    return;
  }

  var uri = Uri.parse(args[0]);
  if (uri.scheme == 'http') {
    uri = uri.replace(scheme: 'ws');
  } else if (uri.scheme == 'https') {
    uri = uri.replace(scheme: 'wss');
  }
  if (!uri.path.endsWith('/ws')) {
    uri = uri.resolve('ws');
  }

  final snapshot = await load(uri.toString());

  final dir = await Directory.systemTemp.createTemp('heap-snapshot');
  final path = dir.path + '/merged-dominator.html';
  final file = await File(path).create();
  final tree = makeData(snapshot.mergedRoot);
  await file.writeAsString(html.replaceAll('__DATA__', tree));
  print('Wrote file://' + path);
}
