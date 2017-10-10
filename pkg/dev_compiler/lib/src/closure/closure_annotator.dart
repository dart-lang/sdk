// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;

import '../js_ast/js_ast.dart' as JS show Node, TypeRef;

import 'closure_annotation.dart';

/// Mixin that can generate [ClosureAnnotation]s for Dart elements and types.
abstract class ClosureAnnotator {
  TypeProvider get types;

  JS.TypeRef emitTypeRef(DartType type);

  // TODO(ochafik): Handle destructured params when Closure supports it.
  ClosureAnnotation closureAnnotationFor(JS.Node node, AnnotatedNode original,
      Element e, String namedArgsMapName) {
    // Note: Dart and Closure privacy are not compatible: don't set `isPrivate: e.isPrivate`.
    return new ClosureAnnotation(
        comment: original?.documentationComment?.toSource(),
        // Note: we don't set isConst here because Closure's constness and
        // Dart's are not really compatible.
        isFinal: e is VariableElement && (e.isFinal || e.isConst),
        type: e is VariableElement
            ? emitTypeRef(e.type /*, forceTypeDefExpansion: true*/)
            : null,
        superType: e is ClassElement ? emitTypeRef(e.supertype) : null,
        interfaces:
            e is ClassElement ? e.interfaces.map(emitTypeRef).toList() : null,
        isOverride: e.isOverride,
        isTypedef: e is FunctionTypeAliasElement);
  }
}
