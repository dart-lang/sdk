// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mirror_renamer;

import '../dart2jslib.dart' show Script, Compiler;
import '../tree/tree.dart';
import '../scanner/scannerlib.dart' show Token;
import '../elements/elements.dart';
import '../dart_backend/dart_backend.dart' show DartBackend,
                                                PlaceholderCollector;

part 'renamer.dart';

class MirrorRenamer {
  const MirrorRenamer();

  LibraryElement get helperLibrary => null;

  FunctionElement get getNameFunction => null;

  bool isMirrorHelperLibrary(LibraryElement element) => false;

  void registerStaticSend(Element currentElement, Element target, Node node) {}

  void addRenames(Map<Node, String> renames, List<Node> topLevelNodes,
                  PlaceholderCollector placeholderCollector) {}
}
