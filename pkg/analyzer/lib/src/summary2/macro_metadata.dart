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

/// Creates a [shared.Expression] for the [annotation].
shared.Expression parseAnnotation(ElementAnnotationImpl annotation) {
  var compilationUnit = annotation.compilationUnit;
  var annotationImpl = annotation.annotationAst;
  var uri = compilationUnit.source.uri;
  var scope = _Scope(compilationUnit);
  var references = _References();
  // The token stream might have been detached, so we ensure an EOF while
  // parsing the annotation.
  var endTokenNext = annotationImpl.endToken.next;
  annotationImpl.endToken.next ??= Token.eof(-1);
  var expression = shared.parseAnnotation(
      annotationImpl.atSign, uri, scope, references,
      isDartLibrary: uri.isScheme("dart") || uri.isScheme("org-dartlang-sdk"));
  annotationImpl.endToken.next = endTokenNext;
  return expression;
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

class _FunctionReference extends shared.FunctionReference {
  final ExecutableElement _element;

  _FunctionReference(this._element);

  @override
  String get name => _element.name;
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
