// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

StringBuffer themes = new StringBuffer();

void main(List<String> arguments) {
  print('part of trydart.themes;\n');
  arguments.forEach(extractTheme);
  print('''
/// List of known themes. The default is the first theme.
const List<Theme> THEMES = const <Theme> [
    const Theme(),
$themes];''');
}

final DECORATION_PATTERN = new RegExp(r'^ *<([a-z][^ ]+)[ ]');

String attr(String name, String line) {
  var match = new RegExp('$name'r'="([^"]*)"').firstMatch(line);
  if (match == null) return null;
  return match[1];
}

void extractTheme(String filename) {
  bool openedTheme = false;
  for (String line in new File(filename).readAsLinesSync()) {
    if (line.startsWith('<colorTheme')) {
      openTheme(line, filename);
      openedTheme = true;
    } else if (line.startsWith('</colorTheme>')) {
      if (!openedTheme) throw 'Theme not found in $filename';
      closeTheme();
      openedTheme = false;
    } else if (DECORATION_PATTERN.hasMatch(line)) {
      if (!openedTheme) throw 'Theme not found in $filename';
      printDecoration(line);
    }
  }
}

openTheme(String line, String filename) {
  var name = attr('name', line);
  var author = attr('author', line);
  if (name == null) name = 'Untitled';
  if (name == 'Default') name = 'Dart Editor';
  var declaration = name.replaceAll(new RegExp('[^a-zA-Z0-9_]'), '_');
  themes.write('    const ${declaration}Theme(),\n');
  print('/// $name theme extracted from');
  print('/// $filename.');
  if (author != null) {
    print('/// Author: $author.');
  }
  print("""
class ${declaration}Theme extends Theme {
  const ${declaration}Theme();

  String get name => '$name';
""");
}

closeTheme() {
  print('}\n');
}

printDecoration(String line) {
  String name = DECORATION_PATTERN.firstMatch(line)[1];
  if (name == 'class') name = 'className';
  if (name == 'enum') name = 'enumName';
  StringBuffer properties = new StringBuffer();
  var color = attr('color', line);
  if (color != null) {
    properties.write("color: '$color'");
  }
  var bold = attr('bold', line) == 'true';
  if (bold) {
    if (!properties.isEmpty) properties.write(', ');
    properties.write('bold: true');
  }
  print('  Decoration get $name => const Decoration($properties);');
}
