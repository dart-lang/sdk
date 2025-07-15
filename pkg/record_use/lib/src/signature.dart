// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';

import '../record_use_internal.dart' show CallWithArguments;
import 'constant.dart';
import 'helper.dart'; // Assuming helper.dart contains the deepEquals function

/// Represents the signature of a Dart method, categorizing its parameters.
///
/// This is a stop-gap due to https://github.com/dart-lang/sdk/issues/60597,
/// and this code should be removed once that bug is fixed.
// TODO(mosum): Delete this code
class Signature {
  /// List of required positional parameter names.
  final List<String> positionalParameters;

  /// List of optional positional parameter names, enclosed in `[]`.
  final List<String> positionalOptionalParameters;

  /// List of required named parameter names, preceded by `required`.
  final List<String> namedParameters;

  /// List of optional named parameter names, enclosed in `{}`.
  final List<String> namedOptionalParameters;

  /// Creates a new [Signature] instance.
  const Signature({
    required this.positionalParameters,
    required this.positionalOptionalParameters,
    required this.namedParameters,
    required this.namedOptionalParameters,
  });

  ({List<Constant?> positional, Map<String, Constant?> named}) parseArguments(
    CallWithArguments call,
  ) {
    final positionalArguments = <Constant?>[];
    final namedArguments = <String, Constant?>{};
    final names = [
      ...positionalParameters,
      ...positionalOptionalParameters,
      ...namedParameters,
      ...namedOptionalParameters,
    ];
    if (call.positionalArguments.length + call.namedArguments.length !=
        names.length) {
      throw FormatException(
        '''
Invalid number of arguments - $names vs ${call.positionalArguments} and ${call.namedArguments}''',
      );
    }
    final sortedNames = names.sorted();
    final mapping = <String, Constant?>{};
    for (var i = 0; i < sortedNames.length; i++) {
      final name = sortedNames[i];
      mapping[name] = call.namedArguments[name] ?? call.positionalArguments[i];
    }
    for (var name in names) {
      var constant = mapping[name];
      if (positionalParameters.contains(name) ||
          positionalOptionalParameters.contains(name)) {
        positionalArguments.add(constant);
      } else if (namedParameters.contains(name) ||
          namedOptionalParameters.contains(name)) {
        namedArguments[name] = constant;
      }
    }
    return (named: namedArguments, positional: positionalArguments);
  }

  /// Parses a Dart method signature string and returns a [Signature] instance.
  ///
  /// The signature string should follow the standard Dart method signature
  /// syntax, including return type, method name, and parameter list enclosed in
  /// parentheses. This parser attempts to correctly identify positional,
  /// optional positional, required named, and optional named parameters,
  /// extracting only their names.
  /// It handles basic type annotations and default values but might not cover
  /// all edge cases of complex Dart type syntax.
  ///
  /// Example:
  /// ```dart
  /// final signatureString = '''String greet(String name,
  /// [String? greeting = "Hello"])''';
  /// final signature = Signature.parseMethodSignature(signatureString);
  /// print(signature.positionalParameters); // Output: [name]
  /// print(signature.positionalOptionalParameters); // Output: [greeting]
  /// print(signature.namedParameters); // Output: []
  /// print(signature.namedOptionalParameters); // Output: []
  /// ```
  ///
  /// Throws a [FormatException] if the provided [signature] string does not
  /// match the expected basic method signature format.
  factory Signature.parseMethodSignature(String signature) {
    var firstParensIndex = signature.indexOf('(');
    int? lastParensIndex = signature.lastIndexOf(')');
    if (firstParensIndex == -1 || lastParensIndex == -1) {
      throw const FormatException('Invalid signature format');
    }
    final parameterString = signature
        .substring(firstParensIndex + 1, lastParensIndex)
        .split('\n')
        .map((line) => line.trim())
        .whereNot((line) => line.startsWith('//'))
        .join('\n');

    final positionalParams = <String>[];
    final positionalOptionalParams = <String>[];
    final namedParams = <String>[];
    final namedOptionalParams = <String>[];

    if (parameterString.isNotEmpty) {
      var inOptionalPositional = false;
      var inNamed = false;

      var i = 0;
      while (i < parameterString.length) {
        var start = i;
        var bracketCounter = 0;
        for (; i < parameterString.length; i++) {
          if (parameterString[i] == '<') {
            bracketCounter++;
          } else if (parameterString[i] == '>') {
            bracketCounter--;
          } else if (parameterString[i] == ',' && bracketCounter == 0) {
            break;
          }
        }
        var param = parameterString.substring(start, i);
        i++;

        param = param.trim();
        if (param.isEmpty) {
          continue;
        }

        if (param.startsWith('[')) {
          inOptionalPositional = true;
          param = param.substring(1).trim();
        } else if (param.startsWith('{')) {
          inNamed = true;
          param = param.substring(1).trim();
        }
        if (param.endsWith(']')) {
          param = param.substring(0, param.length - 1).trim();
        } else if (param.endsWith('}')) {
          param = param.substring(0, param.length - 1).trim();
        }

        if (inOptionalPositional) {
          positionalOptionalParams.add(_extractParameterName(param));
        } else if (inNamed) {
          var req = 'required ';
          if (param.startsWith(req)) {
            namedParams.add(_extractParameterName(param.substring(req.length)));
          } else {
            namedOptionalParams.add(_extractParameterName(param));
          }
        } else {
          positionalParams.add(_extractParameterName(param));
        }
      }
    }

    // Extract only the name for positional parameters
    final positionalNames =
        positionalParams.map(_extractParameterName).toList();
    final positionalOptionalNames =
        positionalOptionalParams.map(_extractParameterName).toList();

    return Signature(
      positionalParameters: positionalNames,
      positionalOptionalParameters: positionalOptionalNames,
      namedParameters: namedParams,
      namedOptionalParameters: namedOptionalParams,
    );
  }

  /// Extracts the parameter name from a parameter declaration string.
  ///
  /// This method splits the declaration by the `=` sign to remove default
  /// values and then by spaces, taking the last part as the parameter name.
  /// This is a simple heuristic and might not work perfectly for all complex
  /// type annotations.
  static String _extractParameterName(String parameterDeclaration) {
    return parameterDeclaration.split('=').first.trim().split(' ').last;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Signature &&
          runtimeType == other.runtimeType &&
          deepEquals(positionalParameters, other.positionalParameters) &&
          deepEquals(
            positionalOptionalParameters,
            other.positionalOptionalParameters,
          ) &&
          deepEquals(namedParameters, other.namedParameters) &&
          deepEquals(namedOptionalParameters, other.namedOptionalParameters);

  @override
  int get hashCode => Object.hash(
    positionalParameters.hashCode,
    positionalOptionalParameters.hashCode,
    namedParameters.hashCode,
    namedOptionalParameters.hashCode,
  );

  @override
  String toString() {
    return '''
Signature(
  positionalParameters: $positionalParameters,
  positionalOptionalParameters: $positionalOptionalParameters,
  namedParameters: $namedParameters,
  namedOptionalParameters: $namedOptionalParameters
)''';
  }
}
