// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLDocument extends Document {

  Element get activeElement();

  String get alinkColor();

  void set alinkColor(String value);

  HTMLAllCollection get all();

  void set all(HTMLAllCollection value);

  String get bgColor();

  void set bgColor(String value);

  String get compatMode();

  String get designMode();

  void set designMode(String value);

  String get dir();

  void set dir(String value);

  HTMLCollection get embeds();

  String get fgColor();

  void set fgColor(String value);

  int get height();

  String get linkColor();

  void set linkColor(String value);

  HTMLCollection get plugins();

  HTMLCollection get scripts();

  String get vlinkColor();

  void set vlinkColor(String value);

  int get width();

  void captureEvents();

  void clear();

  void close();

  bool hasFocus();

  void open();

  void releaseEvents();

  void write(String text);

  void writeln(String text);
}

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Contains the set of standard values returned by HTMLDocument.getReadyState.
 */
interface ReadyState {
  /**
   * Indicates the document is still loading and parsing.
   */
  static final String LOADING = "loading";

  /**
   * Indicates the document is finished parsing but is still loading
   * subresources.
   */
  static final String INTERACTIVE = "interactive";

  /**
   * Indicates the document and all subresources have been loaded.
   */
  static final String COMPLETE = "complete";
}
