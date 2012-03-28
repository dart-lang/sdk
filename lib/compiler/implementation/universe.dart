// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Universe {
  Map<Element, String> generatedCode;
  Map<Element, String> generatedBailoutCode;
  final Set<ClassElement> instantiatedClasses;
  final Set<SourceString> instantiatedClassInstanceFields;
  final Set<FunctionElement> staticFunctionsNeedingGetter;
  final Map<SourceString, Set<Selector>> invokedNames;
  final Set<SourceString> invokedGetters;
  final Set<SourceString> invokedSetters;
  final Map<String, LibraryElement> libraries;
  // TODO(ngeoffray): This should be a Set<Type>.
  final Set<Element> isChecks;

  Universe() : generatedCode = new Map<Element, String>(),
               generatedBailoutCode = new Map<Element, String>(),
               libraries = new Map<String, LibraryElement>(),
               instantiatedClasses = new Set<ClassElement>(),
               instantiatedClassInstanceFields = new Set<SourceString>(),
               staticFunctionsNeedingGetter = new Set<FunctionElement>(),
               invokedNames = new Map<SourceString, Set<Selector>>(),
               invokedGetters = new Set<SourceString>(),
               invokedSetters = new Set<SourceString>(),
               isChecks = new Set<Element>();

  void addGeneratedCode(WorkItem work, String code) {
    generatedCode[work.element] = code;
  }

  void addBailoutCode(WorkItem work, String code) {
    generatedBailoutCode[work.element] = code;
  }
}

class SelectorKind {
  final String name;
  const SelectorKind(this.name);

  static final SelectorKind GETTER = const SelectorKind('getter');
  static final SelectorKind SETTER = const SelectorKind('setter');
  static final SelectorKind INVOCATION = const SelectorKind('invocation');
  static final SelectorKind OPERATOR = const SelectorKind('operator');
  static final SelectorKind INDEX = const SelectorKind('index');

  toString() => name;
}

class Selector implements Hashable {
  // The numbers of arguments of the selector. Includes named
  // arguments.
  final int argumentCount;
  final SelectorKind kind;
  const Selector(this.kind, this.argumentCount);

  int hashCode() => argumentCount + 1000 * namedArguments.length;
  List<SourceString> get namedArguments() => const <SourceString>[];
  int get namedArgumentCount() => 0;
  int get positionalArgumentCount() => argumentCount;

  static final Selector GETTER = const Selector(SelectorKind.GETTER, 0);
  static final Selector SETTER = const Selector(SelectorKind.SETTER, 1);
  static final Selector UNARY_OPERATOR =
      const Selector(SelectorKind.OPERATOR, 0);
  static final Selector BINARY_OPERATOR =
      const Selector(SelectorKind.OPERATOR, 1);
  static final Selector INDEX = const Selector(SelectorKind.INDEX, 1);
  static final Selector INDEX_SET = const Selector(SelectorKind.INDEX, 2);
  static final Selector INDEX_AND_INDEX_SET =
      const Selector(SelectorKind.INDEX, 2);
  static final Selector GETTER_AND_SETTER =
      const Selector(SelectorKind.SETTER, 1);
  static final Selector INVOCATION_0 =
      const Selector(SelectorKind.INVOCATION, 0);
  static final Selector INVOCATION_1 =
      const Selector(SelectorKind.INVOCATION, 1);
  static final Selector INVOCATION_2 =
      const Selector(SelectorKind.INVOCATION, 2);

  bool applies(FunctionParameters parameters) {
    if (argumentCount > parameters.parameterCount) return false;
    int requiredParameterCount = parameters.requiredParameterCount;
    int optionalParameterCount = parameters.optionalParameterCount;

    bool hasOptionalParameters = !parameters.optionalParameters.isEmpty();
    if (namedArguments.isEmpty()) {
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
           !remainingNamedParameters.isEmpty();
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

  /**
   * Returns [:true:] if the selector and the [element] match; [:false:]
   * otherwise.
   */
  bool addSendArgumentsToList(Send send,
                              List list,
                              FunctionParameters parameters,
                              compileArgument(Node argument),
                              compileConstant(Element element)) {
    void addMatchingSendArgumentsToList(Link<Node> link) {
      for (; !link.isEmpty(); link = link.tail) {
        list.add(compileArgument(link.head));
      }
    }

    if (!this.applies(parameters)) return false;
    if (this.positionalArgumentCount == parameters.parameterCount) {
      addMatchingSendArgumentsToList(send.arguments);
      return true;
    }

    // If there are named arguments, provide them in the order
    // expected by the called function, which is the source order.

    // Visit positional arguments and add them to the list.
    Link<Node> arguments = send.arguments;
    int positionalArgumentCount = this.positionalArgumentCount;
    for (int i = 0;
         i < positionalArgumentCount;
         arguments = arguments.tail, i++) {
      list.add(compileArgument(arguments.head));
    }

    // Visit named arguments and add them into a temporary list.
    List namedArguments = [];
    for (; !arguments.isEmpty(); arguments = arguments.tail) {
      NamedArgument namedArgument = arguments.head;
      namedArguments.add(compileArgument(namedArgument.expression));
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
         !remainingNamedParameters.isEmpty();
         remainingNamedParameters = remainingNamedParameters.tail) {
      Element parameter = remainingNamedParameters.head;
      int foundIndex = -1;
      for (int i = 0; i < this.namedArguments.length; i++) {
        SourceString name = this.namedArguments[i];
        if (name == parameter.name) {
          foundIndex = i;
          break;
        }
      }
      if (foundIndex != -1) {
        list.add(namedArguments[foundIndex]);
      } else {
        list.add(compileConstant(parameter)); 
      }
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
    return argumentCount == other.argumentCount
           && namedArguments.length == other.namedArguments.length
           && sameNames(namedArguments, other.namedArguments);
  }

  List<SourceString> getOrderedNamedArguments() => namedArguments;

  toString() => '$kind $argumentCount';
}

class Invocation extends Selector {
  final List<SourceString> namedArguments;
  List<SourceString> orderedNamedArguments;
  int get namedArgumentCount() => namedArguments.length;
  int get positionalArgumentCount() => argumentCount - namedArgumentCount;

  Invocation(int argumentCount,
             [List<SourceString> names = const <SourceString>[]])
      : super(SelectorKind.INVOCATION, argumentCount),
        namedArguments = names,
        orderedNamedArguments = const <SourceString>[];

  List<SourceString> getOrderedNamedArguments() {
    if (namedArguments.isEmpty()) return namedArguments;
    // We use the empty const List as a sentinel.
    if (!orderedNamedArguments.isEmpty()) return orderedNamedArguments;

    List<SourceString> list = new List<SourceString>.from(namedArguments);
    list.sort((SourceString first, SourceString second) {
      return first.slowToString().compareTo(second.slowToString());
    });
    orderedNamedArguments = list;
    return orderedNamedArguments;
  }
}
