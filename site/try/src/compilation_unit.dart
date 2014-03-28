// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.compilationUnit;

import 'dart:async' show
    Stream,
    StreamController;

class CompilationUnitData {
  final String name;
  String content;

  CompilationUnitData(this.name, this.content);
}

class CompilationUnit extends CompilationUnitData {
  // Extending [CompilationUnitData] allows this class to hide the storage
  // allocated for [content] without introducing new names. The conventional
  // way of acheiving this is to introduce a library-private field, but library
  // privacy isn't without problems.

  static StreamController<CompilationUnit> controller =
      new StreamController<CompilationUnit>(sync: false);

  static Stream<CompilationUnit> get onChanged => controller.stream;

  CompilationUnit(String name, String content)
      : super(name, content);

  void set content(String newContent) {
    if (content != newContent) {
      super.content = newContent;
      controller.add(this);
    }
  }
}
