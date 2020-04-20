// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.messages;

import 'package:kernel/ast.dart' show Library, Location, Component, TreeNode;

import 'compiler_context.dart' show CompilerContext;

export 'fasta_codes.dart';

bool get isVerbose => CompilerContext.current.options.verbose;

Location getLocation(Uri uri, int charOffset) {
  return CompilerContext.current.uriToSource[uri]?.getLocation(uri, charOffset);
}

Location getLocationFromUri(Uri uri, int charOffset) {
  if (charOffset == -1) return null;
  return getLocation(uri, charOffset);
}

String getSourceLine(Location location) {
  if (location == null) return null;
  return CompilerContext.current.uriToSource[location.file]
      ?.getTextLine(location.line);
}

Location getLocationFromNode(TreeNode node) {
  if (node.enclosingComponent == null) {
    TreeNode parent = node;
    while (parent != null && parent is! Library) {
      parent = parent.parent;
    }
    if (parent is Library) {
      Component component = CompilerContext.current.options.target
          .configureComponent(
              new Component(uriToSource: CompilerContext.current.uriToSource));
      component.libraries.add(parent);
      parent.parent = component;
      Location result = node.location;
      component.libraries.clear();
      parent.parent = null;
      return result;
    } else {
      return null;
    }
  } else {
    return node.location;
  }
}
