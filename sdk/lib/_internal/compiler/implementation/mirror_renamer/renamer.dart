// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mirror_renamer;

class MirrorRenamer {
  static const String MIRROR_HELPER_CLASS = 'MirrorHelper';
  static const String MIRROR_HELPER_GET_NAME_FUNCTION = 'getName';
  static const String MIRROR_HELPER_LIBRARY_NAME = 'mirror_helper.dart';
  static const String MIRROR_HELPER_LIBRARY_PREFIX = 'm';
  static const String MIRROR_HELPER_CLASS_FULLY_QUALIFIED_NAME =
      '$MIRROR_HELPER_LIBRARY_PREFIX.$MIRROR_HELPER_CLASS';

  static void handleStaticSend(Map<Node, String> renames, Element element,
                               Send node, Compiler compiler) {
  if (element == compiler.mirrorSystemGetNameFunction) {
    renames[node.selector] = MIRROR_HELPER_GET_NAME_FUNCTION;
    renames[node.receiver] = MIRROR_HELPER_CLASS_FULLY_QUALIFIED_NAME;
    }
 }

  static void addMirrorHelperImport(Map<LibraryElement, String> imports) {
    Uri mirrorHelperUri = new Uri(path: MIRROR_HELPER_LIBRARY_NAME);
    // TODO(zarah): Remove this hack! LibraryElementX should not be created
    // outside the library loader. When actual mirror helper library
    // is created, change to load that.
    LibraryElement mirrorHelperLib = new LibraryElementX(
        new Script(mirrorHelperUri, null));
    imports.putIfAbsent(mirrorHelperLib, () => MIRROR_HELPER_LIBRARY_PREFIX);
  }
}