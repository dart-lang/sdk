// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/type_system.dart';

class ExtensionMemberResolver {
  final ResolverVisitor _resolver;
  ExtensionMemberResolver(this._resolver);

  Scope get _nameScope => _resolver.nameScope;

  TypeSystem get _typeSystem => _resolver.typeSystem;

  /// Return the most specific extension or `null` if no single one can be
  /// identified.
  ExtensionElement chooseMostSpecificExtension(
      List<ExtensionElement> extensions, InterfaceType receiverType) {
    //
    // https://github.com/dart-lang/language/blob/master/accepted/future-releases/static-extension-methods/feature-specification.md#extension-conflict-resolution:
    //
    // If more than one extension applies to a specific member invocation, then
    // we resort to a heuristic to choose one of the extensions to apply. If
    // exactly one of them is "more specific" than all the others, that one is
    // chosen. Otherwise it is a compile-time error.
    //
    // An extension with on type clause T1 is more specific than another
    // extension with on type clause T2 iff
    //
    // 1. T2 is declared in a platform library, and T1 is not, or
    // 2. they are both declared in platform libraries or both declared in
    //    non-platform libraries, and
    // 3. the instantiated type (the type after applying type inference from the
    //    receiver) of T1 is a subtype of the instantiated type of T2 and either
    //    not vice versa, or
    // 4. the instantiate-to-bounds type of T1 is a subtype of the
    //    instantiate-to-bounds type of T2 and not vice versa.
    //

    int moreSpecific(ExtensionElement e1, ExtensionElement e2) {
      var t1 = _instantiateToBounds(e1.extendedType);
      var t2 = _instantiateToBounds(e2.extendedType);

      bool inSdk(DartType type) {
        if (type.isDynamic || type.isVoid) {
          return true;
        }
        return t2.element.library.isInSdk;
      }

      if (inSdk(t2)) {
        //  1. T2 is declared in a platform library, and T1 is not
        if (!inSdk(t1)) {
          return -1;
        }
      } else if (inSdk(t1)) {
        return 1;
      }

      // 2. they are both declared in platform libraries or both declared in
      //    non-platform libraries, and
      if (_subtypeOf(t1, t2)) {
        // 3. the instantiated type (the type after applying type inference from the
        //    receiver) of T1 is a subtype of the instantiated type of T2 and either
        //    not vice versa
        if (!_subtypeOf(t2, t1)) {
          return -1;
        } else {
          // or:
          // 4. the instantiate-to-bounds type of T1 is a subtype of the
          //    instantiate-to-bounds type of T2 and not vice versa.

          // todo(pq): implement

        }
      } else if (_subtypeOf(t2, t1)) {
        if (!_subtypeOf(t1, t2)) {
          return 1;
        }
      }

      return 0;
    }

    extensions.sort(moreSpecific);

    // If the first extension is definitively more specific, return it.
    if (moreSpecific(extensions[0], extensions[1]) == -1) {
      return extensions[0];
    }

    // Otherwise fail.
    return null;
  }

  /// Return an extension for this [type] that matches the given [name] in the
  /// current scope; if the match is ambiguous, report an error.
  ExtensionElement findExtension(
      InterfaceType type, String name, Expression target) {
    var extensions = getApplicableExtensions(type, name);
    if (extensions.length == 1) {
      return extensions[0];
    }
    if (extensions.length > 1) {
      ExtensionElement extension =
          chooseMostSpecificExtension(extensions, type);
      if (extension != null) {
        return extension;
      }
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.AMBIGUOUS_EXTENSION_METHOD_ACCESS,
        target,
        [
          name,
          extensions[0].name,
          extensions[1].name,
        ],
      );
    }

    return null;
  }

  /// Return extensions for this [type] that match the given [name] in the
  /// current scope.
  List<ExtensionElement> getApplicableExtensions(DartType type, String name) {
    final List<ExtensionElement> extensions = [];
    void checkElement(Element element, ExtensionElement extension) {
      if (element.displayName == name && !extensions.contains(extension)) {
        extensions.add(extension);
      }
    }

    var targetType = _instantiateToBounds(type);
    for (var extension in _nameScope.extensions) {
      var extensionType = _instantiateToBounds(extension.extendedType);
      if (_subtypeOf(targetType, extensionType)) {
        for (var accessor in extension.accessors) {
          checkElement(accessor, extension);
        }
        for (var method in extension.methods) {
          checkElement(method, extension);
        }
      }
    }
    return extensions;
  }

  /// Ask the type system to instantiate the given type to its bounds.
  DartType _instantiateToBounds(DartType type) =>
      _typeSystem.instantiateToBounds(type);

  /// Ask the type system for a subtype check.
  bool _subtypeOf(DartType type1, DartType type2) =>
      _typeSystem.isSubtypeOf(type1, type2);
}
