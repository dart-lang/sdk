// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.
library engine.utilities.dart;
/**
 * The enumeration `ParameterKind` defines the different kinds of parameters. There are two
 * basic kinds of parameters: required and optional. Optional parameters are further divided into
 * two kinds: positional optional and named optional.
 *
 * @coverage dart.engine.utilities
 */
class ParameterKind implements Comparable<ParameterKind> {
  static final ParameterKind REQUIRED = new ParameterKind('REQUIRED', 0, false);
  static final ParameterKind POSITIONAL = new ParameterKind('POSITIONAL', 1, true);
  static final ParameterKind NAMED = new ParameterKind('NAMED', 2, true);
  static final List<ParameterKind> values = [REQUIRED, POSITIONAL, NAMED];

  /// The name of this enum constant, as declared in the enum declaration.
  final String name;

  /// The position in the enum declaration.
  final int ordinal;

  /**
   * A flag indicating whether this is an optional parameter.
   */
  bool _isOptional2 = false;

  /**
   * Initialize a newly created kind with the given state.
   *
   * @param isOptional `true` if this is an optional parameter
   */
  ParameterKind(this.name, this.ordinal, bool isOptional) {
    this._isOptional2 = isOptional;
  }

  /**
   * Return `true` if this is an optional parameter.
   *
   * @return `true` if this is an optional parameter
   */
  bool get isOptional => _isOptional2;
  int compareTo(ParameterKind other) => ordinal - other.ordinal;
  int get hashCode => ordinal;
  String toString() => name;
}