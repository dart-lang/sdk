part of dart.core;
 abstract class Invocation {Symbol get memberName;
 List get positionalArguments;
 Map<Symbol, dynamic> get namedArguments;
 bool get isMethod;
 bool get isGetter;
 bool get isSetter;
 bool get isAccessor => isGetter || isSetter;
}
