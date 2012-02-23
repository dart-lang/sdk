// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLDocument extends Document {

  final Element activeElement;

  String alinkColor;

  HTMLAllCollection all;

  String bgColor;

  final String compatMode;

  String designMode;

  String dir;

  final HTMLCollection embeds;

  String fgColor;

  String linkColor;

  final HTMLCollection plugins;

  final HTMLCollection scripts;

  String vlinkColor;

  void captureEvents();

  void clear();

  void close();

  bool hasFocus();

  void open();

  void releaseEvents();

  void write(String text);

  void writeln(String text);
}
