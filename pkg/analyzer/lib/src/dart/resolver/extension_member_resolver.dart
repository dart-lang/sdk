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

  DartType get _dynamicType => _typeProvider.dynamicType;

  Scope get _nameScope => _resolver.nameScope;

  TypeProvider get _typeProvider => _resolver.typeProvider;

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

    /// Return `true` if the [elementName] matches the target [name], taking
    /// into account the `=` on the end of the names of setters.
    bool matchesName(String elementName) {
      if (elementName.endsWith('=') && !name.endsWith('=')) {
        elementName = elementName.substring(0, elementName.length - 1);
      }
      return elementName == name;
    }

    /// Add the given [extension] to the list of [extensions] if it defined a
    /// member whose name matches the target [name].
    void checkExtension(ExtensionElement extension) {
      for (var accessor in extension.accessors) {
        if (matchesName(accessor.name)) {
          extensions.add(extension);
          return;
        }
      }
      for (var method in extension.methods) {
        if (matchesName(method.name)) {
          extensions.add(extension);
          return;
        }
      }
    }

    var targetType = _instantiateToBounds(type);
    for (var extension in _nameScope.extensions) {
      var extensionType = _instantiateToBounds(extension.extendedType);
      if (_subtypeOf(targetType, extensionType)) {
        checkExtension(extension);
      }
    }
    return extensions;
  }

  /// Given the generic [extension] element, and the [receiverType] to which
  /// this extension is applied, infer the type arguments that correspond to
  /// the extension type parameters.
  ///
  /// If the extension is used in [ExtensionOverride], the [typeArguments] of
  /// the override are provided, and take precedence over inference.
  List<DartType> inferTypeArguments(
    ExtensionElement extension,
    DartType receiverType, {
    TypeArgumentList typeArguments,
  }) {
    var typeParameters = extension.typeParameters;
    if (typeParameters.isEmpty) {
      return const <DartType>[];
    }

    if (typeArguments != null) {
      var arguments = typeArguments.arguments;
      if (arguments.length == typeParameters.length) {
        return arguments.map((a) => a.type).toList();
      } else {
        // TODO(scheglov) Report an error.
        return List.filled(typeParameters.length, _dynamicType);
      }
    } else {
      if (receiverType != null) {
        var inferrer = GenericInferrer(
          _typeProvider,
          _typeSystem,
          typeParameters,
        );
        inferrer.constrainArgument(
          receiverType,
          extension.extendedType,
          'extendedType',
        );
        return inferrer.infer(typeParameters);
      } else {
        return List.filled(typeParameters.length, _dynamicType);
      }
    }
  }

  /// Ask the type system to instantiate the given type to its bounds.
  DartType _instantiateToBounds(DartType type) =>
      _typeSystem.instantiateToBounds(type);

  /// Ask the type system for a subtype check.
  bool _subtypeOf(DartType type1, DartType type2) =>
      _typeSystem.isSubtypeOf(type1, type2);
}
