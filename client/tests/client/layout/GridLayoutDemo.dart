// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * An app for testing the grid layout system.
 */

/** Creates a grid view structure given the CSS styles. */
View createGrid(String css) {
  final styles = _parseExampleStyles(css);

  final gridStyle = styles.remove('grid');

  final children = new List<MockView>();
  for (final id in styles.getKeys()) {
    children.add(new MockView(id, styles[id]));
  }

  return new MockCompositeView('grid', gridStyle, children);
}

void _onLoad() {
  var query = Uri.parseQuery(window.location.search)['q'];
  if (query != null && query.length == 1) {
    query = Uri.decodeComponent(query[0]);
    addGridStyles('100%', '100%', 'margin:0px;');
    final view = createGrid(GridExamples.STYLES[query]);
    view.addToDocument(document.body);
    _addColorStyles();
    printMetrics(query);
  } else {
    final html = new StringBuffer();
    for (String ex in GridExamples.STYLES.getKeys()) {
      html.add('<div><a href="?q=$ex">Grid Example $ex</a></div>');
    }
    document.body.innerHTML = html.toString();
  }
}

void addGridStyles(String width, String height, [String margin = '']) {
  // Use monospace font and fixed line-height so the text size is predictable.
  // TODO(jmesserly): only tested on Chromium Mac/Linux
  Dom.addStyle('''
    body { $margin }
    #grid {
      position: absolute;
      width: $width;
      height: $height;
      border-color: black;
    }
    .grid-item {
      border: solid 2px;
      border-radius: 8px;
      font-family:monospace;
      font-size:16px;
      line-height:20px;
    }
    ''');
}

void _addColorStyles() {
  final grid = document.body.query('#grid');
  final colors = const [ 'darkred', 'darkorange', 'darkgoldenrod',
                         'darkgreen', 'darkblue', 'darkviolet'];
  int c = 0;
  var node = grid.elements[0];
  while (node != null) {
    if (node.id != '') {
      node.style.cssText += "color:" + colors[c++];
    }
    node = node.nextElementSibling;
  }
}

/** Returns a map from view IDs to their CSS property map. */
_parseExampleStyles(String css) {
  final result = new LinkedHashMap<String, Map<String, String>>();
  for (String item in css.split('}')) {
    final parts = item.split('{');
    if (parts.length != 2) {
      continue;
    }
    String id = parts[0].trim().substring(1);
    result[id] = _parseStyleProps(parts[1]);
  }
  return result;
}

/** Parses a set of style properties separated by ";" */
_parseStyleProps(String css) {
  final result = new LinkedHashMap<String, String>();
  for (String prop in css.split(';')) {
    final parts = prop.split(':');
    if (parts.length != 2) {
      continue;
    }
    result[parts[0].trim()] = parts[1].trim();
  }
  return result;
}

class MockCompositeView extends CompositeView {
   MockCompositeView(String id, Map styles, List childViews)
    : super('') {
    node.id = id;
    CollectionUtils.copyMap(customStyle, styles);

    for (final v in childViews) {
      addChild(v);
    }
  }
}

class MockView extends View {
  MockView(String id, Map styles)
      : super.fromNode(new Element.html(
          '<div class="grid-item">MockView-$id</div>')) {
    node.id = id;
    CollectionUtils.copyMap(customStyle, styles);
    // TODO(jmesserly): this is needed to get horizontal content-sizing to work
    Css.setDisplay(node.style, 'inline-block');
  }
}


void printMetrics(String example) {
  final node = document.body.query('#grid');
  String exampleId = example.split(' ')[0];
  final sb = new StringBuffer();
  sb.add('void testSpecExample${exampleId}() {\n');
  sb.add("  verifyExample('$example', {\n");
  final elems = new List.from(node.elements);
  for (Element child in node.elements) {
    _appendMetrics(sb, child, '    ');
  }
  sb.add('  });\n');
  sb.add('}\n\n');
  window.console.log(sb.toString());
}

void _appendMetrics(StringBuffer sb, Element node, [String indent = '']) {
  String id = node.id;
  num left = node.offsetLeft, top = node.offsetTop;
  num width = node.offsetWidth, height = node.offsetHeight;
  sb.add("${indent}'$id': [$left, $top, $width, $height],\n");
}

