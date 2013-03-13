// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.utilities.dart;


/**
 * The enumeration {@code ParameterKind} defines the different kinds of parameters. There are two
 * basic kinds of parameters: required and optional. Optional parameters are further divided into
 * two kinds: positional optional and named optional.
 * @coverage dart.engine.utilities
 */
class ParameterKind {
  static final ParameterKind REQUIRED = new ParameterKind('REQUIRED', 0, false);
  static final ParameterKind POSITIONAL = new ParameterKind('POSITIONAL', 1, true);
  static final ParameterKind NAMED = new ParameterKind('NAMED', 2, true);
  static final List<ParameterKind> values = [REQUIRED, POSITIONAL, NAMED];
  final String __name;
  final int __ordinal;
  int get ordinal => __ordinal;
  /**
   * A flag indicating whether this is an optional parameter.
   */
  bool _isOptional2 = false;
  /**
   * Initialize a newly created kind with the given state.
   * @param isOptional {@code true} if this is an optional parameter
   */
  ParameterKind(this.__name, this.__ordinal, bool isOptional) {
    this._isOptional2 = isOptional;
  }
  /**
   * Return {@code true} if this is an optional parameter.
   * @return {@code true} if this is an optional parameter
   */
  bool isOptional() => _isOptional2;
  String toString() => __name;
}