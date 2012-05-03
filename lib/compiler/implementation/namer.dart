// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Assigns JavaScript identifiers to Dart variables, class-names and members.
 */
class Namer {
  final Compiler compiler;

  static final CLOSURE_INVOCATION_NAME = const SourceString('\$call');
  static final OPERATOR_EQUALS = const SourceString('operator\$eq');

  static Set<String> _jsReserved = null;
  Set<String> get jsReserved() {
    if (_jsReserved === null) {
      _jsReserved = new Set<String>();
      _jsReserved.addAll(JsNames.javaScriptKeywords);
      _jsReserved.addAll(JsNames.reservedPropertySymbols);
    }
    return _jsReserved;
  }

  Map<Element, String> globals;
  Map<String, int> usedGlobals;

  Namer(this.compiler)
      : globals = new Map<Element, String>(),
        usedGlobals = new Map<String, int>();

  final String CURRENT_ISOLATE = "\$";
  final String ISOLATE = "Isolate";
  final String ISOLATE_PROPERTIES = "\$isolateProperties";


  String closureInvocationName(Selector selector) {
    // TODO(floitsch): mangle, while not conflicting with instance names.
    return instanceMethodInvocationName(null, CLOSURE_INVOCATION_NAME,
                                        selector);
  }

  String privateName(LibraryElement lib, SourceString name) {
    if (name.isPrivate()) {
      return '_${getName(lib)}${name.slowToString()}';
    } else {
      return '${name.slowToString()}';
    }
  }

  String instanceMethodName(LibraryElement lib, SourceString name, int arity) {
    return '${privateName(lib, name)}\$$arity';
  }

  String instanceMethodInvocationName(LibraryElement lib, SourceString name,
                                      Selector selector) {
    // TODO(floitsch): mangle, while preserving uniqueness.
    StringBuffer buffer = new StringBuffer();
    List<SourceString> names = selector.getOrderedNamedArguments();
    for (SourceString argumentName in names) {
      buffer.add(@'$');
      argumentName.printOn(buffer);
    }
    return '${privateName(lib, name)}\$${selector.argumentCount}$buffer';
  }

  String instanceFieldName(LibraryElement lib, SourceString name) {
    String proposedName = privateName(lib, name);
    return safeName(proposedName);
  }

  String setterName(LibraryElement lib, SourceString name) {
    return 'set\$${privateName(lib, name)}';
  }

  String getterName(LibraryElement lib, SourceString name) {
    return 'get\$${privateName(lib, name)}';
  }

  String getFreshGlobalName(String proposedName) {
    int usedCount = usedGlobals[proposedName];
    if (usedCount === null) {
      // No element with this name has been used before.
      usedGlobals[proposedName] = 1;
      return proposedName;
    } else {
      // Not the first time we see this name. Append a number to make it unique.
      String name;
      do {
        usedCount++;
        name = '$proposedName$usedCount';
      } while (usedGlobals[name] !== null);
      usedGlobals[proposedName] = usedCount;
      return name;
    }
  }

  /**
   * Returns a preferred JS-id for the given top-level or static element.
   * The returned id is guaranteed to be a valid JS-id.
   */
  String _computeGuess(Element element) {
    assert(!element.isInstanceMember());
    LibraryElement lib = element.getLibrary();
    if (element.kind == ElementKind.GENERATIVE_CONSTRUCTOR) {
      FunctionElement functionElement = element;
      return instanceMethodName(lib, element.name,
                                functionElement.parameterCount(compiler));
    } else {
      // TODO(floitsch): deal with named constructors.
      String name;
      if (Elements.isStaticOrTopLevel(element)) {
        name = element.name.slowToString();
      } else if (element.kind == ElementKind.GETTER) {
        name = getterName(lib, element.name);
      } else if (element.kind == ElementKind.SETTER) {
        name = setterName(lib, element.name);
      } else if (element.kind == ElementKind.FUNCTION) {
        FunctionElement functionElement = element;
        name = element.name.slowToString();
        name = '$name\$${functionElement.parameterCount(compiler)}';
      } else if (element.kind === ElementKind.LIBRARY) {
        name = 'lib';
      } else {
        name = element.name.slowToString();
      }
      // Prefix the name with '$' if it is reserved.
      return safeName(name);
    }
  }

  String getBailoutName(Element element) {
    return '${getName(element)}\$bailout';
  }

  /**
   * Returns a preferred JS-id for the given element. The returned id is
   * guaranteed to be a valid JS-id. Globals and static fields are furthermore
   * guaranteed to be unique.
   *
   * For accessing statics consider calling
   * [isolateAccess]/[isolateBailoutAccess] or [isolatePropertyAccess] instead.
   */
  String getName(Element element) {
    if (element.isInstanceMember()) {
      if (element.kind == ElementKind.GENERATIVE_CONSTRUCTOR_BODY) {
        ConstructorBodyElement bodyElement = element;
        SourceString name = bodyElement.constructor.name;
        return instanceMethodName(element.getLibrary(),
                                  name, bodyElement.parameterCount(compiler));
      } else if (element.kind == ElementKind.FUNCTION) {
        FunctionElement functionElement = element;
        return instanceMethodName(element.getLibrary(),
                                  element.name,
                                  functionElement.parameterCount(compiler));
      } else if (element.kind == ElementKind.GETTER) {
        return getterName(element.getLibrary(), element.name);
      } else if (element.kind == ElementKind.SETTER) {
        return setterName(element.getLibrary(), element.name);
      } else {
        return instanceFieldName(element.getLibrary(), element.name);
      }
    } else {
      // Dealing with a top-level or static element.
      String cached = globals[element];
      if (cached !== null) return cached;

      String guess = _computeGuess(element);
      switch (element.kind) {
        case ElementKind.VARIABLE:
        case ElementKind.PARAMETER:
          // The name is not guaranteed to be unique.
          return guess;

        case ElementKind.GENERATIVE_CONSTRUCTOR:
        case ElementKind.FUNCTION:
        case ElementKind.CLASS:
        case ElementKind.FIELD:
        case ElementKind.GETTER:
        case ElementKind.SETTER:
        case ElementKind.TYPEDEF:
        case ElementKind.LIBRARY:
          String result = getFreshGlobalName(guess);
          globals[element] = result;
          return result;

        default:
          compiler.internalError('getName for unknown kind: ${element.kind}',
                                 node: element.parseNode(compiler));
      }
    }
  }

  String isolatePropertiesAccess(Element element) {
    return "$ISOLATE.$ISOLATE_PROPERTIES.${getName(element)}";
  }

  String isolatePropertiesAccessForConstant(String constantName) {
    return "$ISOLATE.$ISOLATE_PROPERTIES.$constantName";
  }

  String isolateAccess(Element element) {
    return "$CURRENT_ISOLATE.${getName(element)}";
  }

  String isolateBailoutAccess(Element element) {
    return '${isolateAccess(element)}\$bailout';
  }

  String operatorIs(Element element) {
    return 'is\$${getName(element)}';
  }

  String safeName(String name) {
    if (jsReserved.contains(name) || name.startsWith('\$')) {
      name = "\$$name";
      assert(!jsReserved.contains(name));
    }
    return name;
  }
}
