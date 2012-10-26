// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library universe;

import '../closure.dart';
import '../elements/elements.dart';
import '../dart2jslib.dart';
import '../runtime_types.dart';
import '../tree/tree.dart';
import '../util/util.dart';

part 'function_set.dart';
part 'partial_type_tree.dart';
part 'selector_map.dart';

class Universe {
  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: Key elements are declaration elements.
   */
  Map<Element, CodeBuffer> generatedCode;

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: Key elements are declaration elements.
   */
  Map<Element, CodeBuffer> generatedBailoutCode;

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: Elements are declaration elements.
   */
  final Set<ClassElement> instantiatedClasses;

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: Elements are declaration elements.
   */
  final Set<FunctionElement> staticFunctionsNeedingGetter;
  final Map<SourceString, Set<Selector>> invokedNames;
  final Map<SourceString, Set<Selector>> invokedGetters;
  final Map<SourceString, Set<Selector>> invokedSetters;
  final Map<SourceString, Set<Selector>> fieldGetters;
  final Map<SourceString, Set<Selector>> fieldSetters;
  final Set<DartType> isChecks;
  final RuntimeTypeInformation rti;

  Universe() : generatedCode = new Map<Element, CodeBuffer>(),
               generatedBailoutCode = new Map<Element, CodeBuffer>(),
               instantiatedClasses = new Set<ClassElement>(),
               staticFunctionsNeedingGetter = new Set<FunctionElement>(),
               invokedNames = new Map<SourceString, Set<Selector>>(),
               invokedGetters = new Map<SourceString, Set<Selector>>(),
               invokedSetters = new Map<SourceString, Set<Selector>>(),
               fieldGetters = new Map<SourceString, Set<Selector>>(),
               fieldSetters = new Map<SourceString, Set<Selector>>(),
               isChecks = new Set<DartType>(),
               rti = new RuntimeTypeInformation();

  void addGeneratedCode(WorkItem work, CodeBuffer codeBuffer) {
    assert(invariant(work.element, work.element.isDeclaration));
    generatedCode[work.element] = codeBuffer;
  }

  void addBailoutCode(WorkItem work, CodeBuffer codeBuffer) {
    assert(invariant(work.element, work.element.isDeclaration));
    generatedBailoutCode[work.element] = codeBuffer;
  }

  bool hasMatchingSelector(Set<Selector> selectors,
                           Element member,
                           Compiler compiler) {
    if (selectors == null) return false;
    for (Selector selector in selectors) {
      if (selector.applies(member, compiler)) return true;
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
    return hasMatchingSelector(fieldGetters[member.name], member, compiler);
  }

  bool hasFieldSetter(Element member, Compiler compiler) {
    return hasMatchingSelector(fieldSetters[member.name], member, compiler);
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

  toString() => name;
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
      : this(SelectorKind.CALL, Compiler.NO_SUCH_METHOD, null, 2);

  bool isGetter() => identical(kind, SelectorKind.GETTER);
  bool isSetter() => identical(kind, SelectorKind.SETTER);
  bool isCall() => identical(kind, SelectorKind.CALL);

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
  DartType get receiverType => null;

  bool applies(Element element, Compiler compiler)
      => appliesUntyped(element, compiler);

  bool appliesUntyped(Element element, Compiler compiler) {
    if (element.isSetter()) return isSetter();
    if (element.isGetter()) return isGetter() || isCall();
    if (element.isField()) return isGetter() || isSetter() || isCall();
    if (isGetter()) return true;

    FunctionElement function = element;
    FunctionSignature parameters = function.computeSignature(compiler);
    if (argumentCount > parameters.parameterCount) return false;
    int requiredParameterCount = parameters.requiredParameterCount;
    int optionalParameterCount = parameters.optionalParameterCount;
    if (positionalArgumentCount < requiredParameterCount) return false;

    if (!parameters.optionalParametersAreNamed) {
      // TODO(5074): Remove this check once we don't accept the
      // deprecated parameter specification.
      if (!Compiler.REJECT_NAMED_ARGUMENT_AS_POSITIONAL) {
        return optionalParametersAppliesDEPRECATED(element, compiler);
      } else {
        // We have already checked that the number of arguments are
        // not greater than the number of parameters. Therefore the
        // number of positional arguments are not greater than the
        // number of parameters.
        assert(positionalArgumentCount <= parameters.parameterCount);
        return namedArguments.isEmpty;
      }
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

  // TODO(5074): Remove this method once we don't accept the
  // deprecated parameter specification.
  bool optionalParametersAppliesDEPRECATED(FunctionElement function,
                                           Compiler compiler) {
    FunctionSignature parameters = function.computeSignature(compiler);
    int requiredParameterCount = parameters.requiredParameterCount;
    int optionalParameterCount = parameters.optionalParameterCount;

    bool hasOptionalParameters = !parameters.optionalParameters.isEmpty;
    if (namedArguments.isEmpty) {
      if (!hasOptionalParameters) {
        return requiredParameterCount == argumentCount;
      } else {
        return argumentCount >= requiredParameterCount &&
            argumentCount <= requiredParameterCount + optionalParameterCount;
      }
    } else {
      if (!hasOptionalParameters) return false;
      Link<Element> remainingNamedParameters = parameters.optionalParameters;
      for (int i = requiredParameterCount; i < positionalArgumentCount; i++) {
        remainingNamedParameters = remainingNamedParameters.tail;
      }
      Set<SourceString> nameSet = new Set<SourceString>();
      for (;
           !remainingNamedParameters.isEmpty;
           remainingNamedParameters = remainingNamedParameters.tail) {
        nameSet.add(remainingNamedParameters.head.name);
      }

      for (SourceString name in namedArguments) {
        if (!nameSet.contains(name)) {
          return false;
        }
        nameSet.remove(name);
      }
      return true;
    }
  }

  // TODO(5074): Remove this method once we don't accept the
  // deprecated parameter specification.
  bool addOptionalArgumentsToListDEPRECATED(Link<Node> arguments,
                                            List list,
                                            FunctionElement element,
                                            compileArgument(Node argument),
                                            compileConstant(Element element),
                                            Compiler compiler) {
    assert(invariant(element, element.isImplementation));
    // If there are named arguments, provide them in the order
    // expected by the called function, which is the source order.
    FunctionSignature parameters = element.computeSignature(compiler);

    // Visit positional arguments and add them to the list.
    for (int i = parameters.requiredParameterCount;
         i < positionalArgumentCount;
         arguments = arguments.tail, i++) {
      list.add(compileArgument(arguments.head));
    }

    // Visit named arguments and add them into a temporary list.
    List compiledNamedArguments = [];
    for (; !arguments.isEmpty; arguments = arguments.tail) {
      NamedArgument namedArgument = arguments.head;
      compiledNamedArguments.add(compileArgument(namedArgument.expression));
    }

    Link<Element> remainingNamedParameters = parameters.optionalParameters;
    // Skip the optional parameters that have been given in the
    // positional arguments.
    for (int i = parameters.requiredParameterCount;
         i < positionalArgumentCount;
         i++) {
      remainingNamedParameters = remainingNamedParameters.tail;
    }

    // Loop over the remaining named parameters, and try to find
    // their values: either in the temporary list or using the
    // default value.
    for (;
         !remainingNamedParameters.isEmpty;
         remainingNamedParameters = remainingNamedParameters.tail) {
      Element parameter = remainingNamedParameters.head;
      int foundIndex = namedArguments.indexOf(parameter.name);
      if (foundIndex != -1) {
        list.add(compiledNamedArguments[foundIndex]);
      } else {
        list.add(compileConstant(parameter));
      }
    }
  }


  /**
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
      // TODO(5074): Remove this check once we don't accept the
      // deprecated parameter specification.
      if (!Compiler.REJECT_NAMED_ARGUMENT_AS_POSITIONAL) {
        addOptionalArgumentsToListDEPRECATED(
            arguments, list, element, compileArgument, compileConstant,
            compiler);
      } else {
        parameters.forEachOptionalParameter((element) {
          if (!arguments.isEmpty) {
            list.add(compileArgument(arguments.head));
            arguments = arguments.tail;
          } else {
            list.add(compileConstant(element));
          }
        });
      }
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
    return identical(receiverType, other.receiverType)
        && equalsUntyped(other);
  }

  bool equalsUntyped(Selector other) {
    return name == other.name
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
        if (i != 0) result.add(', ');
        result.add(namedArguments[i].slowToString());
      }
      return "[$result]";
    }
    return '';
  }

  String toString() {
    String named = '';
    String type = '';
    if (namedArgumentCount > 0) named = ', named=${namedArgumentsToString()}';
    if (receiverType != null) type = ', type=$receiverType';
    return 'Selector($kind, ${name.slowToString()}, '
           'arity=$argumentCount$named$type)';
  }
}

class TypedSelector extends Selector {
  /**
   * The type of the receiver. Any subtype of that type can be the
   * target of the invocation.
   */
  final DartType receiverType;

  TypedSelector(DartType this.receiverType, Selector selector)
    : super(selector.kind,
            selector.name,
            selector.library,
            selector.argumentCount,
            selector.namedArguments);

  /**
   * Check if [element] will be the one used at runtime when being
   * invoked on an instance of [cls].
   */
  bool hasElementIn(ClassElement cls, Element element) {
    Element resolved = cls.lookupMember(element.name);
    if (identical(resolved, element)) return true;
    if (resolved == null) return false;
    if (identical(resolved.kind, ElementKind.ABSTRACT_FIELD)) {
      AbstractFieldElement field = resolved;
      if (identical(element, field.getter) || identical(element, field.setter)) {
        return true;
      } else {
        ClassElement otherCls = field.getEnclosingClass();
        // We have not found a match, but another class higher in the
        // hierarchy may define the getter or the setter.
        return hasElementIn(otherCls.superclass, element);
      }
    }
    return false;
  }

  bool applies(Element element, Compiler compiler) {
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

    ClassElement self = receiverType.element;
    if (other.implementsInterface(self) || other.isSubclassOf(self)) {
      return appliesUntyped(element, compiler);
    }

    if (!self.isInterface() && self.isSubclassOf(other)) {
      // Resolve an invocation of [element.name] on [self]. If it
      // is found, this selector is a candidate.
      return hasElementIn(self, element) && appliesUntyped(element, compiler);
    }

    return false;
  }
}
