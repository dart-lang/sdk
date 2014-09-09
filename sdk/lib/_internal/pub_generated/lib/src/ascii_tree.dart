library pub.ascii_tree;
import 'package:path/path.dart' as path;
import 'log.dart' as log;
import 'utils.dart';
String fromFiles(List<String> files, {String baseDir, bool showAllChildren}) {
  var root = {};
  for (var file in files) {
    if (baseDir != null) file = path.relative(file, from: baseDir);
    var parts = path.split(file);
    var directory = root;
    for (var part in path.split(file)) {
      directory = directory.putIfAbsent(part, () => {});
    }
  }
  return fromMap(root, showAllChildren: showAllChildren);
}
String fromMap(Map map, {bool showAllChildren}) {
  var buffer = new StringBuffer();
  _draw(buffer, "", null, map, showAllChildren: showAllChildren);
  return buffer.toString();
}
void _drawLine(StringBuffer buffer, String prefix, bool isLastChild,
    String name) {
  buffer.write(prefix);
  if (name != null) {
    if (isLastChild) {
      buffer.write(log.gray("'-- "));
    } else {
      buffer.write(log.gray("|-- "));
    }
  }
  buffer.writeln(name);
}
String _getPrefix(bool isRoot, bool isLast) {
  if (isRoot) return "";
  if (isLast) return "    ";
  return log.gray("|   ");
}
void _draw(StringBuffer buffer, String prefix, String name, Map children,
    {bool showAllChildren, bool isLast: false}) {
  if (showAllChildren == null) showAllChildren = false;
  if (name != null) _drawLine(buffer, prefix, isLast, name);
  var childNames = ordered(children.keys);
  drawChild(bool isLastChild, String child) {
    var childPrefix = _getPrefix(name == null, isLast);
    _draw(
        buffer,
        '$prefix$childPrefix',
        child,
        children[child],
        showAllChildren: showAllChildren,
        isLast: isLastChild);
  }
  if (name == null || showAllChildren || childNames.length <= 10) {
    for (var i = 0; i < childNames.length; i++) {
      drawChild(i == childNames.length - 1, childNames[i]);
    }
  } else {
    drawChild(false, childNames[0]);
    drawChild(false, childNames[1]);
    drawChild(false, childNames[2]);
    buffer.write(prefix);
    buffer.write(_getPrefix(name == null, isLast));
    buffer.writeln(log.gray('| (${childNames.length - 6} more...)'));
    drawChild(false, childNames[childNames.length - 3]);
    drawChild(false, childNames[childNames.length - 2]);
    drawChild(true, childNames[childNames.length - 1]);
  }
}
