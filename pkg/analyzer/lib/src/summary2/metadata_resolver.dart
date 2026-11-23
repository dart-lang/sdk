// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/ast_resolver.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/link.dart';

class MetadataResolver {
  final Linker _linker;
  final LibraryBuilder _libraryBuilder;
  final LinkingUnit _linkingUnit;

  /// The resolver for annotations, and the scope that it was created for.
  ///
  /// Creating a resolver and its visitors costs more than resolving a typical
  /// annotation, such as `@override`, so it is reused while the scope stays
  /// the same, for example for all annotations of members of a class.
  ({Scope scope, AstResolver resolver})? _astResolverCache;

  new(this._linker, this._libraryBuilder, this._linkingUnit);

  void resolve() {
    var libraryScope = _linkingUnit.fragment.scope;
    for (var directive in _linkingUnit.node.directives) {
      for (var annotation in directive.metadata) {
        _resolveAnnotation(annotation, libraryScope);
      }
      if (directive is ExportDirectiveImpl) {
        // We access export directive metadata while building scopes.
        // But for the current library cycle the metadata was not resolved yet.
        // Now that we resolved it, reset the cache.
        directive.libraryExport!.metadata.resetCache();
      }
    }

    for (var (:annotation, :scope) in _linkingUnit.declarationAnnotations) {
      _resolveAnnotation(annotation, scope);
    }
  }

  /// Returns the resolver for annotations in [scope].
  AstResolver _astResolver(Scope scope) {
    var cache = _astResolverCache;
    if (cache != null && identical(cache.scope, scope)) {
      return cache.resolver;
    }

    var resolver = AstResolver.forLinking(
      inheritance: _linker.inheritance,
      libraryFragment: _linkingUnit.fragment,
      nameScope: scope,
      analysisOptions: _libraryBuilder.kind.file.analysisOptions,
      enclosingClassElement: null,
      enclosingExecutableElement: null,
    );
    _astResolverCache = (scope: scope, resolver: resolver);
    return resolver;
  }

  void _resolveAnnotation(AnnotationImpl node, Scope scope) {
    if (node.elementAnnotation is ElementAnnotationImpl) {
      _astResolver(scope).resolveAnnotation(node);
    }
  }
}
