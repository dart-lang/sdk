library options;

import 'package:collection/wrappers.dart';

/**
 * A command-line option. Includes both flags and options which take a value.
 */
class Option {
  final String name;
  final String abbreviation;
  final List<String> allowed;
  final defaultValue;
  final Function callback;
  final String help;
  final Map<String, String> allowedHelp;
  final bool isFlag;
  final bool negatable;
  final bool allowMultiple;
  final bool hide;

  Option(this.name, this.abbreviation, this.help, List<String> allowed,
      Map<String, String> allowedHelp, this.defaultValue, this.callback,
      {this.isFlag, this.negatable, this.allowMultiple: false,
      this.hide: false}) :
        this.allowed = allowed == null ?
            null : new UnmodifiableListView(allowed),
        this.allowedHelp = allowedHelp == null ?
            null : new UnmodifiableMapView(allowedHelp) {

    if (name.isEmpty) {
      throw new ArgumentError('Name cannot be empty.');
    } else if (name.startsWith('-')) {
      throw new ArgumentError('Name $name cannot start with "-".');
    }

    // Ensure name does not contain any invalid characters.
    if (_invalidChars.hasMatch(name)) {
      throw new ArgumentError('Name "$name" contains invalid characters.');
    }

    if (abbreviation != null) {
      if (abbreviation.length != 1) {
        throw new ArgumentError('Abbreviation must be null or have length 1.');
      } else if(abbreviation == '-') {
        throw new ArgumentError('Abbreviation cannot be "-".');
      }

      if (_invalidChars.hasMatch(abbreviation)) {
        throw new ArgumentError('Abbreviation is an invalid character.');
      }
    }
  }

  static final _invalidChars = new RegExp(r'''[ \t\r\n"'\\/]''');
}
