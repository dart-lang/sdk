part of dart.core;

abstract class Function {
  @patch static apply(Function function, List positionalArguments,
      [Map<Symbol, dynamic> namedArguments]) {
    return Primitives.applyFunction(function, positionalArguments,
        namedArguments == null ? null : _toMangledNames(namedArguments));
  }
  int get hashCode;
  bool operator ==(Object other);
}
