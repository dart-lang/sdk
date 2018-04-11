// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Client component to display [GlobalResult]s as a web app.
library dart2js_info.bin.inference.client;

import 'dart:convert';
import 'dart:html' hide Entry;

import 'package:charcode/charcode.dart';
import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/string_edit_buffer.dart';

AllInfo data;
main() async {
  data = new AllInfoJsonCodec()
      .decode(jsonDecode(await HttpRequest.getString('/data')));

  routeByHash();
  window.onHashChange.listen((_) => routeByHash());
}

/// Does basic routing for the client UI.
routeByHash() {
  var hash = window.location.hash;
  if (hash.isEmpty || hash == '#' || hash == '#!') {
    handleHomePage();
  } else if (hash.startsWith('#!')) {
    handleFileView(hash.substring(2));
  }
}

/// Renders the home screen: a list of files with results.
handleHomePage() {
  var files = UrlRetriever.run(data);
  var html = new StringBuffer()..write('<ul>');
  for (var file in files) {
    html.write('<li> <a href="#!$file">$file</a></li>');
  }
  html.write('</ul>');
  document.body.setInnerHtml('$html', treeSanitizer: NodeTreeSanitizer.trusted);
}

/// Renders the results of a single file: the code with highlighting for each
/// send.
handleFileView(String path) async {
  var contents = await HttpRequest.getString('file/$path');
  var visitor = new SendHighlighter(path, contents);
  data.accept(visitor);
  var code = '${visitor.code}';
  document.body.setInnerHtml('''
      <div class="grid">
        <div class="main code">$code</div>
        <div id="selections" class="right code"></div>
      </div>
      ''', treeSanitizer: NodeTreeSanitizer.trusted);

  var div = document.querySelector('#selections');
  visitAllMetrics((metric, _) {
    if (metric is GroupedMetric || metric.name == 'reachable functions') return;
    var cssClassName = _classNameForMetric(metric);
    var node = new Element.html('<div>'
        '<span class="send $cssClassName inactive">${metric.name}</span>'
        '</div>');
    node.children[0].onClick.listen((_) {
      document.querySelectorAll('.$cssClassName').classes.toggle('inactive');
    });
    div.append(node);
  });
}

/// Extracts urls for all files mentioned in the results.
class UrlRetriever extends RecursiveInfoVisitor {
  List<String> _paths = [];

  static List<String> run(AllInfo results) {
    var visitor = new UrlRetriever();
    results.accept(visitor);
    return visitor._paths;
  }

  @override
  visitLibrary(LibraryInfo info) {
    _paths.add(info.uri.path);
    super.visitLibrary(info);
  }

  @override
  visitFunction(FunctionInfo info) {
    var path = info.measurements?.uri?.path;
    if (path != null) _paths.add(path);
  }
}

/// Visitors that highlights every send in the text of a file using HTML
/// `<span>` tags.
class SendHighlighter extends RecursiveInfoVisitor {
  final String path;
  final StringEditBuffer code;

  SendHighlighter(this.path, String contents)
      : code = new StringEditBuffer(contents) {
    code.insert(0, '<span class="line">');
    for (int i = 0; i < contents.length; i++) {
      if (contents.codeUnitAt(i) == $lt) {
        code.replace(i, i + 1, '&lt;');
      } else if (contents.codeUnitAt(i) == $gt) {
        code.replace(i, i + 1, '&gt;');
      } else if (contents.codeUnitAt(i) == $lf) {
        code.insert(i + 1, '</span><span class="line">');
      }
    }
    code.insert(contents.length, '</span>');
  }

  @override
  Null visitFunction(FunctionInfo function) {
    if (function.measurements?.uri?.path != path) return null;
    var entries = function.measurements.entries;
    for (var metric in entries.keys) {
      if (metric is GroupedMetric) continue;
      var cssClassName = _classNameForMetric(metric);
      for (var entry in entries[metric]) {
        code.insert(entry.begin, '<span class="send ${cssClassName} inactive">',
            -entry.end);
        code.insert(entry.end, '</span>');
      }
    }
    return null;
  }
}

_classNameForMetric(Metric metric) => metric.name.replaceAll(' ', '-');
