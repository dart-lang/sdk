// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library universe;

import '../closure.dart';
import '../elements/elements.dart';
import '../dart2jslib.dart';
import '../dart_types.dart';
import '../types/types.dart';
import '../tree/tree.dart';
import '../util/util.dart';
import '../js/js.dart' as js;

part 'function_set.dart';
part 'full_function_set.dart';
part 'selector_map.dart';

class Universe {
  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: Elements are declaration elements.
   */
  // TODO(karlklose): these sets should be merged.
  final Set<ClassElement> instantiatedClasses;
  final Set<DartType> instantiatedTypes;

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: Elements are declaration elements.
   */
  final Set<FunctionElement> staticFunctionsNeedingGetter;
  final Map<SourceString, Set<Selector>> invokedNames;
  final Map<SourceString, Set<Selector>> invokedGetters;
  final Map<SourceString, Set<Selector>> invokedSetters;

  /**
   * Fields accessed. Currently only the codegen knows this
   * information. The resolver is too conservative when seeing a
   * getter and only registers an invoked getter.
   */
  final Set<Element> fieldGetters;

  /**
   * Fields set. See comment in [fieldGetters].
   */
  final Set<Element> fieldSetters;
  final Set<DartType> isChecks;

  bool usingFactoryWithTypeArguments = false;

  Universe() : instantiatedClasses = new Set<ClassElement>(),
               instantiatedTypes = new Set<DartType>(),
               staticFunctionsNeedingGetter = new Set<FunctionElement>(),
               invokedNames = new Map<SourceString, Set<Selector>>(),
               invokedGetters = new Map<SourceString, Set<Selector>>(),
               invokedSetters = new Map<SourceString, Set<Selector>>(),
               fieldGetters = new Set<Element>(),
               fieldSetters = new Set<Element>(),
               isChecks = new Set<DartType>();

  bool hasMatchingSelector(Set<Selector> selectors,
                           Element member,
                           Compiler compiler) {
    if (selectors == null) return false;
    for (Selector selector in selectors) {
      if (selector.appliesUnnamed(member, compiler)) return true;
    }
    return false;
  }

  bool hasInvocation(Element member, Compiler compiler) {
    return hasMatchingSelector(invokedNames[member.name], member, compiler);
  }

  bool hasInvokedGetter(Element member, Compiler compiler) {
    return hasMatchingSelector(invokedGetters[member.name], member, compiler);
  }

  bool hasInvokedSetter(Element member, Compiler compiler) {
    return hasMatchingSelector(invokedSetters[member.name], member, compiler);
  }

  bool hasFieldGetter(Element member, Compiler compiler) {
    return fieldGetters.contains(member);
  }

  bool hasFieldSetter(Element member, Compiler compiler) {
    return fieldSetters.contains(member);
  }
}

class SelectorKind {
  final String name;
  const SelectorKind(this.name);

  static const SelectorKind GETTER = const SelectorKind('getter');
  static const SelectorKind SETTER = const SelectorKind('setter');
  static const SelectorKind CALL = const SelectorKind('call');
  static const SelectorKind OPERATOR = const SelectorKind('operator');
  static const SelectorKind INDEX = const SelectorKind('index');

  String toString() => name;
}

class Selector {
  final SelectorKind kind;
  final SourceString name;
  final LibraryElement library; // Library is null for non-private selectors.

  // The numbers of arguments of the selector. Includes named arguments.
  final int argumentCount;
  final List<SourceString> namedArguments;
  final List<SourceString> orderedNamedArguments;

  Selector(
      this.kind,
      SourceString name,
      LibraryElement library,
      this.argumentCount,
      [List<SourceString> namedArguments = const <SourceString>[]])
    : this.name = name,
      this.library = name.isPrivate() ? library : null,
      this.namedArguments = namedArguments,
      this.orderedNamedArguments = namedArguments.isEmpty
          ? namedArguments
          : <SourceString>[] {
    assert(!name.isPrivate() || library != null);
  }

  Selector.getter(SourceString name, LibraryElement library)
      : this(SelectorKind.GETTER, name, library, 0);

  Selector.getterFrom(Selector selector)
      : this(SelectorKind.GETTER, selector.name, selector.library, 0);

  Selector.setter(SourceString name, LibraryElement library)
      : this(SelectorKind.SETTER, name, library, 1);

  Selector.unaryOperator(SourceString name)
      : this(SelectorKind.OPERATOR,
             Elements.constructOperatorName(name, true),
             null, 0);

  Selector.binaryOperator(SourceString name)
      : this(SelectorKind.OPERATOR,
             Elements.constructOperatorName(name, false),
             null, 1);

  Selector.index()
      : this(SelectorKind.INDEX,
             Elements.constructOperatorName(const SourceString("[]"), false),
             null, 1);

  Selector.indexSet()
      : this(SelectorKind.INDEX,
             Elements.constructOperatorName(const SourceString("[]="), false),
             null, 2);

  Selector.call(SourceString name,
                LibraryElement library,
                int arity,
                [List<SourceString> named = const []])
      : this(SelectorKind.CALL, name, library, arity, named);

  Selector.callClosure(int arity, [List<SourceString> named = const []])
      : this(SelectorKind.CALL, Compiler.CALL_OPERATOR_NAME, null,
             arity, named);

  Selector.callClosureFrom(Selector selector)
      : this(SelectorKind.CALL, Compiler.CALL_OPERATOR_NAME, null,
             selector.argumentCount, selector.namedArguments);

  Selector.callConstructor(SourceString constructorName,
                           LibraryElement library)
      : this(SelectorKind.CALL,
             constructorName,
             library,
             0,
             const []);

  Selector.callDefaultConstructor(LibraryElement library)
      : this(SelectorKind.CALL, const SourceString(""), library, 0, const []);

  // TODO(kasperl): This belongs somewhere else.
  Selector.noSuchMethod()
      : this(SelectorKind.CALL, Compiler.NO_SUCH_METHOD, null,
             Compiler.NO_SUCH_METHOD_ARG_COUNT);

  bool isGetter() => identical(kind, SelectorKind.GETTER);
  bool isSetter() => identical(kind, SelectorKind.SETTER);
  bool isCall() => identical(kind, SelectorKind.CALL);
  bool isClosureCall() {
    SourceString callName = Compiler.CALL_OPERATOR_NAME;
    return isCall() && name == callName;
  }

  bool isIndex() => identical(kind, SelectorKind.INDEX) && argumentCount == 1;
  bool isIndexSet() => identical(kind, SelectorKind.INDEX) && argumentCount == 2;

  bool isOperator() => identical(kind, SelectorKind.OPERATOR);
  bool isUnaryOperator() => isOperator() && argumentCount == 0;
  bool isBinaryOperator() => isOperator() && argumentCount == 1;

  /** Check whether this is a call to 'assert'. */
  bool isAssert() => isCall() && identical(name.stringValue, "assert");

  int get hashCode => argumentCount + 1000 * namedArguments.length;
  int get namedArgumentCount => namedArguments.length;
  int get positionalArgumentCount => argumentCount - namedArgumentCount;

  bool get hasExactMask => false;
  TypeMask get mask => null;
  Selector get asUntyped => this;

  /**
   * The member name for invocation mirrors created from this selector.
   */
  String get invocationMirrorMemberName =>
      isSetter() ? '${name.slowToString()}=' : name.slowToString();

  int get invocationMirrorKind {
    const int METHOD = 0;
    const int GETTER = 1;
    const int SETTER = 2;
    int kind = METHOD;
    if (isGetter()) {
      kind = GETTER;
    } else if (isSetter()) {
      kind = SETTER;
    }
    return kind;
  }

  bool appliesUnnamed(Element element, Compiler compiler) {
    assert(sameNameHack(element, compiler));
    return appliesUntyped(element, compiler);
  }

  bool appliesUntyped(Element element, Compiler compiler) {
    assert(sameNameHack(element, compiler));
    if (Elements.isUnresolved(element)) return false;
    if (name.isPrivate() && library != element.getLibrary()) return false;
    if (element.isForeign(compiler)) return true;
    if (element.isSetter()) return isSetter();
    if (element.isGetter()) return isGetter() || isCall();
    if (element.isField()) {
      return isSetter()
          ? !element.modifiers.isFinalOrConst()
          : isGetter() || isCall();
    }
    if (isGetter()) return true;
    if (isSetter()) return false;

    FunctionElement function = element;
    FunctionSignature parameters = function.computeSignature(compiler);
    if (argumentCount > parameters.parameterCount) return false;
    int requiredParameterCount = parameters.requiredParameterCount;
    int optionalParameterCount = parameters.optionalParameterCount;
    if (positionalArgumentCount < requiredParameterCount) return false;

    if (!parameters.optionalParametersAreNamed) {
      // We have already checked that the number of arguments are
      // not greater than the number of parameters. Therefore the
      // number of positional arguments are not greater than the
      // number of parameters.
      assert(positionalArgumentCount <= parameters.parameterCount);
      return namedArguments.isEmpty;
    } else {
      if (positionalArgumentCount > requiredParameterCount) return false;
      assert(positionalArgumentCount == requiredParameterCount);
      if (namedArgumentCount > optionalParameterCount) return false;
      Set<SourceString> nameSet = new Set<SourceString>();
      parameters.optionalParameters.forEach((Element element) {
        nameSet.add(element.name);
      });
      for (SourceString name in namedArguments) {
        if (!nameSet.contains(name)) return false;
        // TODO(5213): By removing from the set we are checking
        // that we are not passing the name twice. We should have this
        // check in the resolver also.
        nameSet.remove(name);
      }
      return true;
    }
  }

  bool sameNameHack(Element element, Compiler compiler) {
    // TODO(ngeoffray): Remove workaround checks.
    return element == compiler.assertMethod
        || element.isConstructor()
        || name == element.name;
  }

  bool applies(Element element, Compiler compiler) {
    if (!sameNameHack(element, compiler)) return false;
    return appliesUnnamed(element, compiler);
  }

  /**
   * Fills [list] with the arguments in a defined order.
   *
   * [compileArgument] is a function that returns a compiled version
   * of an argument located in [arguments].
   *
   * [compileConstant] is a function that returns a compiled constant
   * of an optional argument that is not in [arguments.
   *
   * Returns [:true:] if the selector and the [element] match; [:false:]
   * otherwise.
   *
   * Invariant: [element] must be the implementation element.
   */
  bool addArgumentsToList(Link<Node> arguments,
                          List list,
                          FunctionElement element,
                          compileArgument(Node argument),
                          compileConstant(Element element),
                          Compiler compiler) {
    assert(invariant(element, element.isImplementation));
    if (!this.applies(element, compiler)) return false;

    FunctionSignature parameters = element.computeSignature(compiler);
    parameters.forEachRequiredParameter((element) {
      list.add(compileArgument(arguments.head));
      arguments = arguments.tail;
    });

    if (!parameters.optionalParametersAreNamed) {
      parameters.forEachOptionalParameter((element) {
        if (!arguments.isEmpty) {
          list.add(compileArgument(arguments.head));
          arguments = arguments.tail;
        } else {
          list.add(compileConstant(element));
        }
      });
    } else {
      // Visit named arguments and add them into a temporary list.
      List compiledNamedArguments = [];
      for (; !arguments.isEmpty; arguments = arguments.tail) {
        NamedArgument namedArgument = arguments.head;
        compiledNamedArguments.add(compileArgument(namedArgument.expression));
      }
      // Iterate over the optional parameters of the signature, and try to
      // find them in [compiledNamedArguments]. If found, we use the
      // value in the temporary list, otherwise the default value.
      parameters.orderedOptionalParameters.forEach((element) {
        int foundIndex = namedArguments.indexOf(element.name);
        if (foundIndex != -1) {
          list.add(compiledNamedArguments[foundIndex]);
        } else {
          list.add(compileConstant(element));
        }
      });
    }
    return true;
  }

  static bool sameNames(List<SourceString> first, List<SourceString> second) {
    for (int i = 0; i < first.length; i++) {
      if (first[i] != second[i]) return false;
    }
    return true;
  }

  bool operator ==(other) {
    if (other is !Selector) return false;
    return mask == other.mask && equalsUntyped(other);
  }

  bool equalsUntyped(Selector other) {
    return name == other.name
           && kind == other.kind
           && identical(library, other.library)
           && argumentCount == other.argumentCount
           && namedArguments.length == other.namedArguments.length
           && sameNames(namedArguments, other.namedArguments);
  }

  List<SourceString> getOrderedNamedArguments() {
    if (namedArguments.isEmpty) return namedArguments;
    if (!orderedNamedArguments.isEmpty) return orderedNamedArguments;

    orderedNamedArguments.addAll(namedArguments);
    orderedNamedArguments.sort((SourceString first, SourceString second) {
      return first.slowToString().compareTo(second.slowToString());
    });
    return orderedNamedArguments;
  }

  String namedArgumentsToString() {
    if (namedArgumentCount > 0) {
      StringBuffer result = new StringBuffer();
      for (int i = 0; i < namedArgumentCount; i++) {
        if (i != 0) result.write(', ');
        result.write(namedArguments[i].slowToString());
      }
      return "[$result]";
    }
    return '';
  }

  String toString() {
    String named = '';
    String type = '';
    if (namedArgumentCount > 0) named = ', named=${namedArgumentsToString()}';
    if (mask != null) type = ', mask=$mask';
    return 'Selector($kind, ${name.slowToString()}, '
           'arity=$argumentCount$named$type)';
  }
}

class TypedSelector extends Selector {
  final Selector asUntyped;
  final TypeMask mask;

  TypedSelector(this.mask, Selector selector)
      : asUntyped = selector.asUntyped,
        super(selector.kind,
              selector.name,
              selector.library,
              selector.argumentCount,
              selector.namedArguments) {
    // Invariant: Typed selector can not be based on a malformed type.
    assert(mask.isEmpty || !identical(mask.base.kind, TypeKind.MALFORMED_TYPE));
    assert(asUntyped.mask == null);
  }

  TypedSelector.exact(DartType base, Selector selector)
      : this(new TypeMask.exact(base), selector);

  TypedSelector.subclass(DartType base, Selector selector)
      : this(new TypeMask.subclass(base), selector);

  TypedSelector.subtype(DartType base, Selector selector)
      : this(new TypeMask.subtype(base), selector);

  bool get hasExactMask => mask.isExact;

  /**
   * Check if [element] will be the one used at runtime when being
   * invoked on an instance of [cls].
   */
  bool hasElementIn(ClassElement cls, Element element) {
    // Use the [:implementation] of [cls] in case [element]
    // is in the patch class. Also use [:implementation:] of [element]
    // because our function set only stores declarations.
    Element result = cls.implementation.lookupSelector(this);
    return result == null
        ? false
        : result.implementation == element.implementation;
  }

  bool appliesUnnamed(Element element, Compiler compiler) {
    assert(sameNameHack(element, compiler));
    // [TypedSelector] are only used after resolution.
    assert(compiler.phase > Compiler.PHASE_RESOLVING);
    if (!element.isMember()) return false;

    // A closure can be called through any typed selector:
    // class A {
    //   get foo => () => 42;
    //   bar() => foo(); // The call to 'foo' is a typed selector.
    // }
    ClassElement other = element.getEnclosingClass();
    if (identical(other.superclass, compiler.closureClass)) {
      return appliesUntyped(element, compiler);
    }

    if (mask.isEmpty) {
      if (!mask.isNullable) return false;
      return hasElementIn(compiler.backend.nullImplementation, element)
          && appliesUntyped(element, compiler);
    }

    // TODO(kasperl): Can't we just avoid creating typed selectors
    // based of function types?
    Element self = mask.base.element;
    if (self.isTypedef()) {
      // A typedef is a function type that doesn't have any
      // user-defined members.
      return false;
    }

    if (compiler.backend.isNullImplementation(other)) {
      return mask.isNullable && appliesUntyped(element, compiler);
    } else if (mask.isExact) {
      return hasElementIn(self, element) && appliesUntyped(element, compiler);
    } else if (mask.isSubclass) {
      return (hasElementIn(self, element)
              || other.isSubclassOf(self)
              || compiler.world.hasAnySubclassThatMixes(self, other))
          && appliesUntyped(element, compiler);
    } else {
      assert(mask.isSubtype);
      if (other.implementsInterface(self)
          || other.isSubclassOf(self)
          || compiler.world.hasAnySubclassThatMixes(self, other)
          || compiler.world.hasAnySubclassThatImplements(other, mask.base)) {
        return appliesUntyped(element, compiler);
      }

      // If [self] is a subclass of [other], it inherits the
      // implementation of [element].
      ClassElement cls = self;
      if (cls.isSubclassOf(other)) {
        // Resolve an invocation of [element.name] on [self]. If it
        // is found, this selector is a candidate.
        return hasElementIn(cls, element) && appliesUntyped(element, compiler);
      }
    }
    return false;
  }
}
