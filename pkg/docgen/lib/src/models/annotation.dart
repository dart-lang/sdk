// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.models.annotation;

import '../exports/source_mirrors.dart';

import '../exports/dart2js_mirrors.dart' show ResolvedNode;

import '../library_helpers.dart';

import 'library.dart';
import 'mirror_based.dart';

import 'dart:mirrors';
import 'package:compiler/implementation/tree/tree.dart';

/// Holds the name of the annotation, and its parameters.
class Annotation extends MirrorBased<ClassMirror> {
  /// The class of this annotation.
  DeclarationMirror mirror;
  Send node;
  final Library owningLibrary;
  List<String> parameters;

  Annotation(ResolvedNode resolvedNode, this.owningLibrary) {
    parameters = [];
    getMirrorForResolvedNode(resolvedNode, (m, n) { mirror = m; node = n;},
        (String param) => parameters.add(param));
  }

  String getMirrorForResolvedNode(ResolvedNode node, callbackFunc,
      paramCallbackFunc) {
    ResolvedNodeMirrorFinder finder = new ResolvedNodeMirrorFinder(node,
        callbackFunc, paramCallbackFunc);
    finder.unparse(node.node);
    return finder.result;
  }

  Map toMap() => {
    'name': owningLibrary.packagePrefix +
        getDocgenObject(mirror, owningLibrary).docName,
    'parameters': parameters
  };
}

class ResolvedNodeMirrorFinder extends Unparser {
  final ResolvedNode resolvedNode;
  final Function annotationMirrorCallback;
  final Function parameterValueCallback;
  int recursionLevel;

  ResolvedNodeMirrorFinder(this.resolvedNode, this.annotationMirrorCallback,
      this.parameterValueCallback) : recursionLevel = 0;

  visitSend(Send node) {
    if (recursionLevel == 0) {
      var m = resolvedNode.resolvedMirror(node.selector);
      annotationMirrorCallback(m, node);
    } else {
      Operator op = node.selector.asOperator();
      String opString = op != null ? op.source : null;
      bool spacesNeeded =
          identical(opString, 'is') || identical(opString, 'as');
      if (node.isPrefix) visit(node.selector);
          unparseSendReceiver(node, spacesNeeded: spacesNeeded);
          if (!node.isPrefix && !node.isIndex) visit(node.selector);
          if (spacesNeeded) sb.write(' ');
          // Also add a space for sequences like x + +1 and y - -y.
          // TODO(ahe): remove case for '+' when we drop the support for it.
          if (node.argumentsNode != null && (identical(opString, '-')
              || identical(opString, '+'))) {
            var beginToken = node.argumentsNode.getBeginToken();
            if (beginToken != null &&
                identical(beginToken.stringValue, opString)) {
              sb.write(' ');
            }
          }
    }
    recursionLevel++;
    visit(node.argumentsNode);
    recursionLevel--;
  }

  unparseNodeListFrom(NodeList node, var from) {
    if (from.isEmpty) return;

    visit(from.head);

    for (var link = from.tail; !link.isEmpty; link = link.tail) {
      if (recursionLevel >= 2) {
        parameterValueCallback(sb.toString());
        sb.clear();
      }
      visit(link.head);
    }
    if (recursionLevel >= 2) {
      parameterValueCallback(sb.toString());
      sb.clear();
    }
  }

  visitNodeList(NodeList node) {
    addToken(node.beginToken);
    if (recursionLevel == 1) sb.clear();
    if (node.nodes != null) {
      recursionLevel++;
      unparseNodeListFrom(node, node.nodes);
      recursionLevel--;
    }
    if (node.endToken != null) write(node.endToken.value);
  }
}
