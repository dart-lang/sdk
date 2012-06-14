// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Any abstract representation of a dart element.  This includes
 * [Library], [Type] and [Member].
 */
class Element implements Hashable {
  // TODO(jimhug): Make name final when we can do it for Library.
  /** The user-visible name of this [Element]. */
  String name;

  /** A safe name to use for this [Element] in generated JS code. */
  String _jsname;

  /** The lexically/logically enclosing [Element] for lookups. */
  Element _enclosingElement;

  Element(this.name, this._enclosingElement) {
    if (name !== null) {
      String mangled = mangleJsName();
      assert(!mangled.contains(':'));
      _jsname = mangled;
    }
  }

  // TODO - walk tree
  Library get library() => null;

  /** A source location for messages to the user about this [Element]. */
  SourceSpan get span() => null;

  /** Should this element be treated as native JS? */
  bool get isNative() => false;

  int hashCode() => name.hashCode();

  /** Will return a safe name to refer to this element with in JS code. */
  String get jsname() => _jsname;

  /** The native name of this element if it has one. */
  String get nativeName() => _jsname;

  /** Avoid the native name if hidden native. */
  bool get avoidNativeName() => false;

  /**
   * [jsname] priority of this element, if two elements conflict.
   * Higher one gets the name.
   */
  int get jsnamePriority() => isNative ? 2 : (library.isCore ? 1 : 0);

  /** Resolve types and other references in the [Element]. */
  void resolve() {}

  /**
   * By default we mangle the JS name of an element to avoid
   * giving them names that clash with JS keywords.
   */
  String mangleJsName() => world.toJsIdentifier(name);

  /**
   * Any type parameters that this element defines to setup a generic
   * type resolution context.  This is currently used for both generic
   * types and the semi-magical generic factory methods - but it will
   * not be used for any other members in the current dart language.
   */
  // TODO(jimhug): Confirm whether or not these are still on factories.
  List<ParameterType> get typeParameters() => null;

  List<Type> get typeArgsInOrder() => const [];

  // TODO(jimhug): Probably kill this.
  Element get enclosingElement() =>
    _enclosingElement == null ? library : _enclosingElement;

  // TODO(jimhug): Absolutely kill this one.
  set enclosingElement(Element e) => _enclosingElement = e;

  Type lookupTypeParam(String name) {
    if (typeParameters == null) return null;

    for (int i=0; i < typeParameters.length; i++) {
      if (typeParameters[i].name == name) {
        return typeArgsInOrder[i];
      }
    }
    return null;
  }


  /**
   * Resolves [node] in the context of this element.  Will
   * search up the tree of [enclosingElement] to look for matches.
   * If [typeErrors] then types that are not found will create errors,
   * otherwise they will only signal warnings.
   */
  Type resolveType(TypeReference node, bool typeErrors, bool allowTypeParams) {
    if (node == null) return world.varType;

    // TODO(jmesserly): if we failed to resolve a type, we need a way to save
    // that it was an error, so we don't try to resolve it again and show the
    // same message twice.

    if (node is SimpleTypeReference) {
      var ret = node.dynamic.type;
      if (ret == world.voidType) {
        world.error('"void" only allowed as return type', node.span);
        return world.varType;
      }
      return ret;
    } else if (node is NameTypeReference) {
      NameTypeReference typeRef = node;
      String name;
      if (typeRef.names != null) {
        name = typeRef.names.last().name;
      } else {
        name = typeRef.name.name;
      }
      var typeParamType = lookupTypeParam(name);
      if (typeParamType != null) {
        if (!allowTypeParams) {
          world.error('using type parameter in illegal context.', node.span);
        }
        return typeParamType;
      }

      return enclosingElement.resolveType(node, typeErrors, allowTypeParams);
    } else if (node is GenericTypeReference) {
      GenericTypeReference typeRef = node;
      // TODO(jimhug): Expand the handling of typeErrors to generics and funcs
      var baseType = resolveType(typeRef.baseType, typeErrors,
          allowTypeParams);
      //!!!print('resolving generic: ${baseType.name}');
      if (!baseType.isGeneric) {
        world.error('${baseType.name} is not generic', typeRef.span);
        return world.varType;
      }
      if (typeRef.typeArguments.length != baseType.typeParameters.length) {
        world.error('wrong number of type arguments', typeRef.span);
        return world.varType;
      }
      var typeArgs = [];
      for (int i=0; i < typeRef.typeArguments.length; i++) {
        typeArgs.add(resolveType(typeRef.typeArguments[i], typeErrors,
            allowTypeParams));
      }
      return baseType.getOrMakeConcreteType(typeArgs);
    } else if (node is FunctionTypeReference) {
      FunctionTypeReference typeRef = node;
      var name = '';
      if (typeRef.func.name != null) {
        name = typeRef.func.name.name;
      }
      return library.getOrAddFunctionType(this, name, typeRef.func, null);
    }
    world.internalError('unexpected TypeReference', node.span);
  }
}

/**
 * An [Element] representing something in the top level JavaScript environment.
 */
class ExistingJsGlobal extends Element {
  /** The element causing this alias. */
  final Element declaringElement;

  ExistingJsGlobal(name, this.declaringElement) : super(name, null);

  /** Should this element be treated as native JS? */
  bool get isNative() => true;

  /** This must be the highest possible priority. */
  int get jsnamePriority() => 10;

  /** A source location for messages to the user about this [Element]. */
  SourceSpan get span() => declaringElement.span;

  /** A library for messages. */
  Library get library() => declaringElement.library;

}
