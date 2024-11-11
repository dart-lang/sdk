// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/metadata/ast.dart' as shared;
import 'package:_fe_analyzer_shared/src/metadata/parser.dart' as shared;
import 'package:_fe_analyzer_shared/src/metadata/scope.dart' as shared;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/scope.dart';

/// Returns the [shared.Expression] for the constant initializer of [reference].
shared.Expression? getFieldInitializer(shared.FieldReference reference) {
  if (reference is _VariableReference) {
    var element = reference._element;
    if (element is VariableElementImpl) {
      return parseFieldInitializer(element);
    }
  }
  assert(false,
      "Unexpected field reference $reference (${reference.runtimeType})");
  return null;
}

/// Creates a [shared.Expression] for the [annotation].
///
/// If [delayLookupForTesting] is `true`, identifiers are not looked up in their
/// corresponding scopes. This means that the return expression will contain
/// [shared.UnresolvedIdentifier] nodes, as if the identifier wasn't in scope.
/// A subsequent call to [shared.Expression.resolve] will perform the lookup
/// a create the resolved expression. This is used in testing to mimic the
/// scenario in which the declaration is added to the scope via macros.
shared.Expression parseAnnotation(ElementAnnotationImpl annotation,
    {bool delayLookupForTesting = false}) {
  var compilationUnit = annotation.compilationUnit;
  var annotationImpl = annotation.annotationAst;
  var uri = compilationUnit.source.uri;
  // TODO(johnniwinther): Find the right scope for non-top-level annotations.
  var scope = _Scope(compilationUnit);
  var references = _References();
  // The token stream might have been detached, so we ensure an EOF while
  // parsing the annotation.
  var endTokenNext = annotationImpl.endToken.next;
  annotationImpl.endToken.next ??= Token.eof(-1);
  var expression = shared.parseAnnotation(
      annotationImpl.atSign, uri, scope, references,
      isDartLibrary: uri.isScheme("dart") || uri.isScheme("org-dartlang-sdk"),
      delayLookupForTesting: delayLookupForTesting);
  annotationImpl.endToken.next = endTokenNext;
  return expression;
}

/// Creates a [shared.Expression] for the initializer of the constant
/// [variable].
///
/// If [delayLookupForTesting] is `true`, identifiers are not looked up in their
/// corresponding scopes. This means that the return expression will contain
/// [shared.UnresolvedIdentifier] nodes, as if the identifier wasn't in scope.
/// A subsequent call to [shared.Expression.resolve] will perform the lookup
/// a create the resolved expression. This is used in testing to mimic the
/// scenario in which the declaration is added to the scope via macros.
shared.Expression? parseFieldInitializer(VariableElementImpl variable,
    {bool delayLookupForTesting = false}) {
  var initializer = variable.constantInitializer;
  if (initializer == null) return null;
  var enclosingElement = variable.enclosingElement3;
  while (enclosingElement != null) {
    if (enclosingElement is CompilationUnitElementImpl) {
      var uri = enclosingElement.source.uri;
      // TODO(johnniwinther): Find the right scope for class members.
      var scope = _Scope(enclosingElement);
      var references = _References();
      // The token stream might have been detached, so we ensure an EOF while
      // parsing the annotation.
      var endTokenNext = initializer.endToken.next;
      initializer.endToken.next ??= Token.eof(-1);
      var expression = shared.parseExpression(
          initializer.beginToken, uri, scope, references,
          isDartLibrary:
              uri.isScheme("dart") || uri.isScheme("org-dartlang-sdk"),
          delayLookupForTesting: delayLookupForTesting);
      initializer.endToken.next = endTokenNext;
      return expression;
    }
    enclosingElement = enclosingElement.enclosingElement3;
  }
  return null;
}

shared.Proto _elementToProto(Element element, String name) {
  if (element is ClassElement) {
    var reference = _ClassReference(element);
    return shared.ClassProto(reference, _ClassScope(element, reference));
  } else if (element is PropertyAccessorElement) {
    VariableElement? variableElement = element.variable2;
    if (variableElement != null) {
      return shared.FieldProto(_VariableReference(variableElement));
    }
  } else if (element is FunctionElement) {
    return shared.FunctionProto(_FunctionReference(element));
  } else if (element is MethodElement) {
    return shared.FunctionProto(_FunctionReference(element));
  } else if (element is VariableElement) {
    return shared.FieldProto(_VariableReference(element));
  } else if (element is PrefixElement) {
    return shared.PrefixProto(name, _PrefixScope(element));
  } else if (element.kind == ElementKind.DYNAMIC) {
    return shared.DynamicProto(const _DynamicReference());
  } else if (element is TypeAliasElement) {
    var reference = _TypedefReference(element);
    return shared.TypedefProto(reference, _TypedefScope(element, reference));
  } else if (element is ExtensionElement) {
    var reference = _ExtensionReference(element);
    return shared.ExtensionProto(
        reference, _ExtensionScope(element, reference));
  } else if (element is ExtensionTypeElement) {
    var reference = _ExtensionTypeReference(element);
    return shared.ExtensionTypeProto(
        reference, _ExtensionTypeScope(element, reference));
  } else if (element is EnumElement) {
    var reference = _EnumReference(element);
    return shared.EnumProto(reference, _EnumScope(element, reference));
  } else if (element is MixinElement) {
    var reference = _MixinReference(element);
    return shared.MixinProto(reference, _MixinScope(element, reference));
  }

  // TODO(johnniwinther): Support extension types.
  throw UnsupportedError(
      "Unsupported element $element (${element.runtimeType}) for '$name'.");
}

class _ClassReference extends shared.ClassReference {
  final ClassElement _element;

  _ClassReference(this._element);

  @override
  String get name => _element.name;
}

final class _ClassScope extends shared.BaseClassScope {
  final ClassElement _classElement;

  @override
  final _ClassReference classReference;

  _ClassScope(this._classElement, this.classReference);

  @override
  shared.Proto lookup(String name,
      [List<shared.TypeAnnotation>? typeArguments]) {
    var constructor = _classElement.getNamedConstructor(name);
    if (constructor != null) {
      return createConstructorProto(
          typeArguments, _ConstructorReference(constructor));
    }
    Element? member = _classElement.augmented.getField(name);
    member ??= _classElement.augmented.getMethod(name);
    return createMemberProto(typeArguments, name, member, _elementToProto);
  }
}

class _ConstructorReference extends shared.ConstructorReference {
  final ConstructorElement _element;

  _ConstructorReference(this._element);

  @override
  String get name => _element.name.isEmpty ? 'new' : _element.name;
}

class _DynamicReference extends shared.TypeReference {
  const _DynamicReference();

  @override
  String get name => 'dynamic';
}

class _EnumReference extends shared.EnumReference {
  final EnumElement _element;

  _EnumReference(this._element);

  @override
  String get name => _element.name;
}

final class _EnumScope extends shared.BaseEnumScope {
  final EnumElement _enumElement;

  @override
  final _EnumReference enumReference;

  _EnumScope(this._enumElement, this.enumReference);

  @override
  shared.Proto lookup(String name,
      [List<shared.TypeAnnotation>? typeArguments]) {
    Element? member = _enumElement.augmented.getField(name);
    member ??= _enumElement.augmented.getMethod(name);
    return createMemberProto(typeArguments, name, member, _elementToProto);
  }
}

class _ExtensionReference extends shared.ExtensionReference {
  final ExtensionElement _element;

  _ExtensionReference(this._element);

  @override
  String get name => _element.name!;
}

final class _ExtensionScope extends shared.BaseExtensionScope {
  final ExtensionElement _extensionElement;

  @override
  final _ExtensionReference extensionReference;

  _ExtensionScope(this._extensionElement, this.extensionReference);

  @override
  shared.Proto lookup(String name,
      [List<shared.TypeAnnotation>? typeArguments]) {
    Element? member = _extensionElement.augmented.getField(name);
    member ??= _extensionElement.augmented.getMethod(name);
    return createMemberProto(typeArguments, name, member, _elementToProto);
  }
}

class _ExtensionTypeReference extends shared.ExtensionTypeReference {
  final ExtensionTypeElement _element;

  _ExtensionTypeReference(this._element);

  @override
  String get name => _element.name;
}

final class _ExtensionTypeScope extends shared.BaseExtensionTypeScope {
  final ExtensionTypeElement _extensionTypeElement;

  @override
  final _ExtensionTypeReference extensionTypeReference;

  _ExtensionTypeScope(this._extensionTypeElement, this.extensionTypeReference);

  @override
  shared.Proto lookup(String name,
      [List<shared.TypeAnnotation>? typeArguments]) {
    var constructor = _extensionTypeElement.getNamedConstructor(name);
    if (constructor != null) {
      return createConstructorProto(
          typeArguments, _ConstructorReference(constructor));
    }
    Element? member = _extensionTypeElement.augmented.getField(name);
    member ??= _extensionTypeElement.augmented.getMethod(name);
    return createMemberProto(typeArguments, name, member, _elementToProto);
  }
}

class _FunctionReference extends shared.FunctionReference {
  final ExecutableElement _element;

  _FunctionReference(this._element);

  @override
  String get name => _element.name;
}

class _MixinReference extends shared.MixinReference {
  final MixinElement _element;

  _MixinReference(this._element);

  @override
  String get name => _element.name;
}

final class _MixinScope extends shared.BaseMixinScope {
  final MixinElement _mixinElement;

  @override
  final _MixinReference mixinReference;

  _MixinScope(this._mixinElement, this.mixinReference);

  @override
  shared.Proto lookup(String name,
      [List<shared.TypeAnnotation>? typeArguments]) {
    Element? member = _mixinElement.augmented.getField(name);
    member ??= _mixinElement.augmented.getMethod(name);
    return createMemberProto(typeArguments, name, member, _elementToProto);
  }
}

class _PrefixScope implements shared.Scope {
  final PrefixElement _prefixElement;

  _PrefixScope(this._prefixElement);

  @override
  shared.Proto lookup(String name) {
    ScopeLookupResult result = _prefixElement.scope.lookup(name);
    Element? getter = result.getter;
    if (getter == null) {
      return shared.UnresolvedIdentifier(this, name);
    } else {
      return _elementToProto(getter, name);
    }
  }
}

class _References implements shared.References {
  @override
  shared.TypeReference get dynamicReference => const _DynamicReference();

  @override
  shared.TypeReference get voidReference => const _VoidReference();
}

class _Scope implements shared.Scope {
  final LibraryFragmentScope _libraryFragmentScope;

  _Scope(CompilationUnitElementImpl compilationUnit)
      : _libraryFragmentScope = LibraryFragmentScope(compilationUnit);

  @override
  shared.Proto lookup(String name) {
    ScopeLookupResult result = _libraryFragmentScope.lookup(name);
    Element? getter = result.getter;
    if (getter == null) {
      return shared.UnresolvedIdentifier(this, name);
    } else {
      return _elementToProto(getter, name);
    }
  }
}

class _TypedefReference implements shared.TypedefReference {
  final TypeAliasElement _element;

  _TypedefReference(this._element);

  @override
  String get name => _element.name;
}

final class _TypedefScope extends shared.BaseTypedefScope {
  final TypeAliasElement _typeAliasElement;

  @override
  final shared.TypedefReference typedefReference;

  _TypedefScope(this._typeAliasElement, this.typedefReference);

  @override
  shared.Proto lookup(String name,
      [List<shared.TypeAnnotation>? typeArguments]) {
    DartType aliasedType = _typeAliasElement.aliasedType;
    if (aliasedType is InterfaceType) {
      var constructor = aliasedType.element.getNamedConstructor(name);
      if (constructor != null) {
        return createConstructorProto(
            typeArguments, _ConstructorReference(constructor));
      }
    }
    return createMemberProto(typeArguments, name);
  }
}

class _VariableReference extends shared.FieldReference {
  final VariableElement _element;

  _VariableReference(this._element);

  @override
  String get name => _element.name;
}

class _VoidReference extends shared.TypeReference {
  const _VoidReference();

  @override
  String get name => 'void';
}
