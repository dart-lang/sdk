/// Support code for the tests in this directory.
library support;

import 'dart:io';
import 'dart:collection';
import 'package:path/path.dart' as path;
import 'package:html5lib/src/treebuilder.dart';
import 'package:html5lib/dom.dart';
import 'package:html5lib/dom_parsing.dart';

typedef TreeBuilder TreeBuilderFactory(bool namespaceHTMLElements);

Map _treeTypes;
Map<String, TreeBuilderFactory> get treeTypes {
  if (_treeTypes == null) {
    // TODO(jmesserly): add DOM here once it's implemented
    _treeTypes = { "simpletree": (useNs) => new TreeBuilder(useNs) };
  }
  return _treeTypes;
}

final testDataDir = Platform.script.resolve('data').toFilePath();

Iterable<String> getDataFiles(String subdirectory) {
  var dir = new Directory(path.join(testDataDir, subdirectory));
  return dir.listSync().where((f) => f is File).map((f) => f.path);
}

// TODO(jmesserly): make this class simpler. We could probably split on
// "\n#" instead of newline and remove a lot of code.
class TestData extends IterableBase<Map> {
  final String _text;
  final String newTestHeading;

  TestData(String filename, [this.newTestHeading = "data"])
      // Note: can't use readAsLinesSync here because it splits on \r
      : _text = new File(filename).readAsStringSync();

  // Note: in Python this was a generator, but since we can't do that in Dart,
  // it's easier to convert it into an upfront computation.
  Iterator<Map> get iterator => _getData().iterator;

  List<Map> _getData() {
    var data = <String, String>{};
    var key = null;
    var result = <Map>[];
    var lines = _text.split('\n');
    int numLines = lines.length;
    // Remove trailing newline to match Python
    if (lines.last == '') {
      lines.removeLast();
    }
    for (var line in lines) {
      var heading = sectionHeading(line);
      if (heading != null) {
        if (data.length > 0 && heading == newTestHeading) {
          // Remove trailing newline
          data[key] = data[key].substring(0, data[key].length - 1);
          result.add(normaliseOutput(data));
          data = <String, String>{};
        }
        key = heading;
        data[key] = "";
      } else if (key != null) {
        data[key] = '${data[key]}$line\n';
      }
    }

    if (data.length > 0) {
      result.add(normaliseOutput(data));
    }
    return result;
  }

  /// If the current heading is a test section heading return the heading,
  /// otherwise return null.
  static String sectionHeading(String line) {
    return line.startsWith("#") ? line.substring(1).trim() : null;
  }

  static Map normaliseOutput(Map data) {
    // Remove trailing newlines
    data.forEach((key, value) {
      if (value.endsWith("\n")) {
        data[key] = value.substring(0, value.length - 1);
      }
    });
    return data;
  }
}

/// Serialize the [document] into the html5 test data format.
testSerializer(Document document) {
  return (new TestSerializer()..visit(document)).toString();
}

/// Serializes the DOM into test format. See [testSerializer].
class TestSerializer extends TreeVisitor {
  final StringBuffer _str;
  int _indent = 0;
  String _spaces = '';

  TestSerializer() : _str = new StringBuffer();

  String toString() => _str.toString();

  int get indent => _indent;

  set indent(int value) {
    if (_indent == value) return;

    var arr = new List<int>(value);
    for (int i = 0; i < value; i++) {
      arr[i] = 32;
    }
    _spaces = new String.fromCharCodes(arr);
    _indent = value;
  }

  void _newline() {
    if (_str.length > 0) _str.write('\n');
    _str.write('|$_spaces');
  }

  visitNodeFallback(Node node) {
    _newline();
    _str.write(node);
    visitChildren(node);
  }

  visitChildren(Node node) {
    indent += 2;
    for (var child in node.nodes) visit(child);
    indent -= 2;
  }

  visitDocument(Document node) {
    indent += 1;
    for (var child in node.nodes) visit(child);
    indent -= 1;
  }

  visitElement(Element node) {
    _newline();
    _str.write(node);
    if (node.attributes.length > 0) {
      indent += 2;
      var keys = new List.from(node.attributes.keys);
      keys.sort((x, y) => x.compareTo(y));
      for (var key in keys) {
        var v = node.attributes[key];
        if (key is AttributeName) {
          AttributeName attr = key;
          key = "${attr.prefix} ${attr.name}";
        }
        _newline();
        _str.write('$key="$v"');
      }
      indent -= 2;
    }
    visitChildren(node);
  }
}
