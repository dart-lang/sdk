// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.src.codegen.js_names;

import 'package:dev_compiler/src/js/js_ast.dart';
import 'package:dev_compiler/src/js/keywords.dart';

/// Marker subclass for temporary variables.
/// We treat these as being in a different scope from other identifiers, and
/// rename them so they don't collide. See [JSNamer].
// TODO(jmesserly): move into js_ast? add a boolean to Identifier?
class JSTemporary extends Identifier {
  JSTemporary(String name) : super(name);
}

/// This class has two purposes:
/// * rename JS identifiers to avoid keywords.
/// * rename temporary variables to avoid colliding with user-specified names.
///
/// We use a very simple algorithm:
/// * collect all names
/// * visit the tree, choosing unique names for things we need to rename
///
/// We assume the scoping is already correct (if the isTemporary bit is
/// considered as part of the name), so we can do both of these renames
/// globally, with no regard to where the name was declared or which precise
/// identifier it was bound to.
// TODO(jmesserly): some future transforms, like ES6->5, might want a name bound
// tree, but we can defer that until needed.
class JSNamer extends LocalNamer {
  final usedNames = new Set<String>();
  final renames = new Map<String, String>();

  JSNamer(Node node) {
    node.accept(new _NameCollector(usedNames));
  }

  String getName(Identifier node) {
    var name = node.name;
    if (node is JSTemporary) {
      return _rename(name, valid: true);
    } else if (isJsKeyword(name)) {
      return _rename(name, valid: false);
    }
    return name;
  }

  String _rename(String name, {bool valid}) {
    var candidate = renames[name];
    if (candidate != null) return candidate;

    // Try to use the temp's name, otherwise rename.
    if (valid && usedNames.add(name)) {
      candidate = name;
    } else {
      // This assumes that collisions are rare, hence linear search.
      // If collisions become common we need a better search.
      // TODO(jmesserly): what's the most readable scheme here? Maybe 1-letter
      // names in some cases?
      candidate = name == 'function' ? 'func' : '${name}\$';
      for (int i = 0; !usedNames.add(candidate); i++) {
        candidate = '${name}\$$i';
      }
    }
    return renames[name] = candidate;
  }

  void enterScope(Node node) {}
  void leaveScope() {}
}

/// Collects all names used in the visited tree.
class _NameCollector extends BaseVisitor {
  final Set<String> names;
  _NameCollector(this.names);
  visitIdentifier(Identifier node) {
    if (node is! JSTemporary) names.add(node.name);
  }
}
