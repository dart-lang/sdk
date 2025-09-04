// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:front_end/src/codes/type_labeler.dart';
library;

import 'dart:io' show File, exitCode;

import "package:_fe_analyzer_shared/src/messages/severity.dart"
    show severityEnumNames;
import 'package:yaml/yaml.dart' show loadYaml;

/// Map assigning each possible template parameter a [_TemplateParameterType].
///
/// TODO(paulberry): Change the format of `messages.yaml` so that the template
/// parameters, and their types, are stated explicitly, as they are in the
/// analyzer's `messages.yaml` file. Then this constant will not be needed.
const _templateParameterNameToType = {
  'character': _TemplateParameterType.character,
  'unicode': _TemplateParameterType.unicode,
  'name': _TemplateParameterType.name,
  'name2': _TemplateParameterType.name,
  'name3': _TemplateParameterType.name,
  'name4': _TemplateParameterType.name,
  'nameOKEmpty': _TemplateParameterType.nameOKEmpty,
  'names': _TemplateParameterType.names,
  'lexeme': _TemplateParameterType.token,
  'lexeme2': _TemplateParameterType.token,
  'string': _TemplateParameterType.string,
  'string2': _TemplateParameterType.string,
  'string3': _TemplateParameterType.string,
  'stringOKEmpty': _TemplateParameterType.stringOKEmpty,
  'type': _TemplateParameterType.type,
  'type2': _TemplateParameterType.type,
  'type3': _TemplateParameterType.type,
  'type4': _TemplateParameterType.type,
  'uri': _TemplateParameterType.uri,
  'uri2': _TemplateParameterType.uri,
  'uri3': _TemplateParameterType.uri,
  'count': _TemplateParameterType.int,
  'count2': _TemplateParameterType.int,
  'count3': _TemplateParameterType.int,
  'count4': _TemplateParameterType.int,
  'constant': _TemplateParameterType.constant,
  'num1': _TemplateParameterType.num,
  'num2': _TemplateParameterType.num,
  'num3': _TemplateParameterType.num,
};

Uri computeSharedGeneratedFile(Uri repoDir) {
  return repoDir.resolve(
    "pkg/_fe_analyzer_shared/lib/src/messages/codes_generated.dart",
  );
}

Uri computeCfeGeneratedFile(Uri repoDir) {
  return repoDir.resolve(
    "pkg/front_end/lib/src/codes/cfe_codes_generated.dart",
  );
}

class Messages {
  final String sharedMessages;
  final String cfeMessages;

  Messages(this.sharedMessages, this.cfeMessages);
}

Messages generateMessagesFilesRaw(Uri repoDir) {
  Uri messagesFile = repoDir.resolve("pkg/front_end/messages.yaml");
  Map<dynamic, dynamic> yaml = loadYaml(
    new File.fromUri(messagesFile).readAsStringSync(),
  );
  StringBuffer sharedMessages = new StringBuffer();
  StringBuffer cfeMessages = new StringBuffer();

  const String preamble1 = """
// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

""";

  const String preamble2 = """

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/front_end/messages.yaml' and defer to it for the
// commands to update this file.

// ignore_for_file: lines_longer_than_80_chars
""";

  sharedMessages.writeln(preamble1);
  sharedMessages.writeln(preamble2);
  sharedMessages.writeln("""
part of 'codes.dart';
""");

  cfeMessages.writeln(preamble1);
  cfeMessages.writeln("""

""");
  cfeMessages.writeln(preamble2);
  cfeMessages.writeln("""
part of 'cfe_codes.dart';
""");

  bool hasError = false;
  int largestIndex = 0;
  final indexNameMap = new Map<int, String>();

  List<String> keys = yaml.keys.cast<String>().toList()..sort();
  for (String name in keys) {
    var description = yaml[name];
    while (description is String) {
      description = yaml[description];
    }
    Map<dynamic, dynamic>? map = description;
    if (map == null) {
      throw "No 'problemMessage:' in key $name.";
    }
    var index = map['index'];
    if (index != null) {
      if (index is! int || index < 1) {
        print(
          'Error: Expected positive int for "index:" field in $name,'
          ' but found $index',
        );
        hasError = true;
        index = -1;
        // Continue looking for other problems.
      } else {
        String? otherName = indexNameMap[index];
        if (otherName != null) {
          print(
            'Error: The "index:" field must be unique, '
            'but is the same for $otherName and $name',
          );
          hasError = true;
          // Continue looking for other problems.
        } else {
          indexNameMap[index] = name;
          if (largestIndex < index) {
            largestIndex = index;
          }
        }
      }
    }
    Template template;
    try {
      template = _TemplateCompiler(
        name: name,
        index: index,
        description: description,
      ).compile();
    } catch (e, st) {
      Error.throwWithStackTrace('Error while compiling $name: $e', st);
    }
    if (template.isShared) {
      sharedMessages.writeln(template.text);
    } else {
      cfeMessages.writeln(template.text);
    }
  }
  if (largestIndex > indexNameMap.length) {
    print(
      'Error: The "index:" field values should be unique, consecutive'
      ' whole numbers starting with 1.',
    );
    hasError = true;
    // Fall through to print more information.
  }
  if (hasError) {
    exitCode = 1;
    print('The largest index is $largestIndex');
    final sortedIndices = indexNameMap.keys.toList()..sort();
    int nextAvailableIndex = largestIndex + 1;
    for (int index = 1; index <= sortedIndices.length; ++index) {
      if (sortedIndices[index - 1] != index) {
        nextAvailableIndex = index;
        break;
      }
    }
    print('The next available index is ${nextAvailableIndex}');
    return new Messages('', '');
  }

  return new Messages("$sharedMessages", "$cfeMessages");
}

final RegExp placeholderPattern = new RegExp(
  "#\([-a-zA-Z0-9_]+\)(?:%\([0-9]*\)\.\([0-9]+\))?",
);

/// Returns a fresh identifier that is not yet present in [usedNames], and adds
/// it to [usedNames].
///
/// The name [nameHint] is used if it is available. Otherwise a new name is
/// chosen by appending characters to it.
String _newName({required Set<String> usedNames, required String nameHint}) {
  if (usedNames.add(nameHint)) return nameHint;
  for (var i = 0; ; i++) {
    var name = "${nameHint}_$i";
    if (usedNames.add(name)) return name;
  }
}

class Template {
  final String text;
  final isShared;

  Template(this.text, {this.isShared}) : assert(isShared != null);
}

/// Information about how to convert the CFE's internal representation of a
/// template parameter to a string.
///
/// Instances of this class should implement [==] and [hashCode] so that they
/// can be used as keys in a [Map].
sealed class _Conversion {
  /// Returns Dart code that applies the conversion to a template parameter
  /// having the given [name] and [type].
  ///
  /// If no conversion is needed, returns `null`.
  String? toCode({required String name, required _TemplateParameterType type});
}

/// A [_Conversion] that makes use of the [TypeLabeler] class.
class _LabelerConversion implements _Conversion {
  /// The name of the [TypeLabeler] method to call.
  final String methodName;

  const _LabelerConversion(this.methodName);

  @override
  int get hashCode => Object.hash(runtimeType, methodName.hashCode);

  @override
  bool operator ==(Object other) =>
      other is _LabelerConversion && other.methodName == methodName;

  @override
  String toCode({required String name, required _TemplateParameterType type}) =>
      'labeler.$methodName($name)';
}

/// A [_Conversion] that acts on [num], applying formatting parameters specified
/// in the template.
class _NumericConversion implements _Conversion {
  /// If non-null, the number of digits to show after the decimal point.
  final int? fractionDigits;

  /// The minimum number of characters of output to be generated.
  ///
  /// If the number does not require this many characters to display, extra
  /// padding characters are inserted to the left.
  final int padWidth;

  /// If `true`, '0' is used for padding (see [padWidth]); otherwise ' ' is
  /// used.
  final bool padWithZeros;

  _NumericConversion({
    required this.fractionDigits,
    required this.padWidth,
    required this.padWithZeros,
  });

  @override
  int get hashCode => Object.hash(
    runtimeType,
    fractionDigits.hashCode,
    padWidth.hashCode,
    padWithZeros.hashCode,
  );

  @override
  bool operator ==(Object other) =>
      other is _NumericConversion &&
      other.fractionDigits == fractionDigits &&
      other.padWidth == padWidth &&
      other.padWithZeros == padWithZeros;

  @override
  String? toCode({required String name, required _TemplateParameterType type}) {
    if (type != _TemplateParameterType.num) {
      throw 'format suffix may only be applied to parameters of type num';
    }
    return 'conversions.formatNumber($name, fractionDigits: $fractionDigits, '
        'padWidth: $padWidth, padWithZeros: $padWithZeros)';
  }

  /// Creates a [_NumericConversion] from the given regular expression [match].
  ///
  /// [match] should be the result of matching [placeholderPattern] to the
  /// template string.
  ///
  /// Returns `null` if no special numeric conversion is needed.
  static _NumericConversion? from(Match match) {
    String? padding = match[2];
    String? fractionDigitsStr = match[3];

    int? fractionDigits = fractionDigitsStr == null
        ? null
        : int.parse(fractionDigitsStr);
    if (padding != null && padding.isNotEmpty) {
      return _NumericConversion(
        fractionDigits: fractionDigits,
        padWidth: int.parse(padding),
        padWithZeros: padding.startsWith('0'),
      );
    } else if (fractionDigits != null) {
      return _NumericConversion(
        fractionDigits: fractionDigits,
        padWidth: 0,
        padWithZeros: false,
      );
    } else {
      return null;
    }
  }
}

/// The result of parsing a [placeholderPattern] match in a template string.
class _ParsedPlaceholder {
  /// The name of the template parameter.
  ///
  /// This is the identifier that immediately follows the `#`.
  final String name;

  /// The type of the corresponding template parameter.
  final _TemplateParameterType templateParameterType;

  /// The conversion that should be applied to the template parameter.
  final _Conversion? conversion;

  /// Builds a [_ParsedPlaceholder] from the given [match] of
  /// [placeholderPattern].
  factory _ParsedPlaceholder.fromMatch(Match match) {
    String name = match[1]!;

    var templateParameterType = _templateParameterNameToType[name];
    if (templateParameterType == null) {
      throw "Unhandled placeholder in template: '$name'";
    }

    return _ParsedPlaceholder._(
      name: name,
      templateParameterType: templateParameterType,
      conversion:
          _NumericConversion.from(match) ?? templateParameterType.conversion,
    );
  }

  _ParsedPlaceholder._({
    required this.name,
    required this.templateParameterType,
    required this.conversion,
  });

  @override
  int get hashCode => Object.hash(name, templateParameterType, conversion);

  @override
  bool operator ==(Object other) =>
      other is _ParsedPlaceholder &&
      other.name == name &&
      other.templateParameterType == templateParameterType &&
      other.conversion == conversion;
}

/// A [_Conversion] that invokes a top level function via the `conversions`
/// import prefix.
class _SimpleConversion implements _Conversion {
  /// The name of the function to be invoked.
  final String functionName;

  const _SimpleConversion(this.functionName);

  @override
  int get hashCode => Object.hash(runtimeType, functionName.hashCode);

  @override
  bool operator ==(Object other) =>
      other is _SimpleConversion && other.functionName == functionName;

  @override
  String toCode({required String name, required _TemplateParameterType type}) =>
      'conversions.$functionName($name)';
}

class _TemplateCompiler {
  final String name;
  final int? index;
  final String problemMessage;
  final String? correctionMessage;
  final List<String> analyzerCodes;
  final String? severity;

  late final Set<_ParsedPlaceholder> parsedPlaceholders = placeholderPattern
      .allMatches("$problemMessage\n${correctionMessage ?? ''}")
      .map(_ParsedPlaceholder.fromMatch)
      .toSet();
  final List<String> withArgumentsStatements = [];

  _TemplateCompiler({
    required this.name,
    required this.index,
    required Map<Object?, Object?> description,
  }) : problemMessage =
           _decodeMessage(description['problemMessage']) ??
           (throw 'Error: missing problemMessage'),
       correctionMessage = _decodeMessage(description['correctionMessage']),
       analyzerCodes = _decodeAnalyzerCode(description['analyzerCode']),
       severity = _decodeSeverity(description['severity']);

  Template compile() {
    bool hasLabeler = parsedPlaceholders.any(
      (p) => p.conversion is _LabelerConversion,
    );
    bool canBeShared = !hasLabeler;

    var codeArguments = <String>[
      if (index != null)
        'index: $index'
      else if (analyzerCodes.isNotEmpty)
        // If "index:" is defined, then "analyzerCode:" should not be generated
        // in the front end. See comment in messages.yaml
        'analyzerCodes: <String>["${analyzerCodes.join('", "')}"]',
      if (severity != null) 'severity: CfeSeverity.$severity',
    ];

    if (parsedPlaceholders.isEmpty) {
      codeArguments.add('problemMessage: r"""$problemMessage"""');
      if (correctionMessage != null) {
        codeArguments.add('correctionMessage: r"""$correctionMessage"""');
      }

      return new Template("""
// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode code$name =
    const MessageCode(\"$name\", ${codeArguments.join(', ')},);
""", isShared: canBeShared);
    }

    var usedNames = {
      'conversions',
      'labeler',
      ...parsedPlaceholders.map((p) => p.name),
    };
    if (hasLabeler) {
      withArgumentsStatements.add("TypeLabeler labeler = new TypeLabeler();");
    }
    var interpolators = <_ParsedPlaceholder, String>{};
    for (var p in parsedPlaceholders) {
      if (p.conversion?.toCode(name: p.name, type: p.templateParameterType)
          case var conversion?) {
        var interpolator = interpolators[p] = _newName(
          usedNames: usedNames,
          nameHint: p.name,
        );
        withArgumentsStatements.add("var $interpolator = $conversion;");
      } else {
        interpolators[p] = p.name;
      }
    }

    String interpolate(String text) {
      text = text
          .replaceAll(r"$", r"\$")
          .replaceAllMapped(
            placeholderPattern,
            (Match m) =>
                "\${${interpolators[_ParsedPlaceholder.fromMatch(m)]}}",
          );
      return "\"\"\"$text\"\"\"";
    }

    List<String> templateArguments = <String>[];
    templateArguments.add('\"$name\"');
    templateArguments.add('problemMessageTemplate: r"""$problemMessage"""');
    if (correctionMessage != null) {
      templateArguments.add(
        'correctionMessageTemplate: r"""$correctionMessage"""',
      );
    }

    templateArguments.add("withArgumentsOld: _withArgumentsOld$name");
    templateArguments.add("withArguments: _withArguments$name");
    templateArguments.addAll(codeArguments);

    String message = interpolate(problemMessage);
    if (hasLabeler) {
      message += " + labeler.originMessages";
    }
    var arguments = parsedPlaceholders
        .map((p) => "'${p.name}': ${p.name}")
        .toList();

    List<String> messageArguments = <String>[
      "problemMessage: ${message}",
      if (correctionMessage case var correctionMessage?)
        "correctionMessage: ${interpolate(correctionMessage)}",
      "arguments: { ${arguments.join(', ')}, }",
    ];

    if (codeArguments.isNotEmpty) {
      codeArguments.add("");
    }

    var positionalParameters = parsedPlaceholders
        .map((p) => '${p.templateParameterType.cfeType} ${p.name}')
        .toList();
    var namedParameters = parsedPlaceholders
        .map((p) => 'required ${p.templateParameterType.cfeType} ${p.name}')
        .toList();
    var oldToNewArguments = parsedPlaceholders
        .map((p) => '${p.name}: ${p.name}')
        .toList();
    return new Template("""
// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(${positionalParameters.join(', ')}),
  Message Function({${namedParameters.join(', ')}})
> code$name = const Template(${templateArguments.join(', ')},);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArguments$name({${namedParameters.join(', ')}}) {
  ${withArgumentsStatements.join('\n  ')}
  return new Message(
     code$name,
     ${messageArguments.join(', ')},);
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOld$name(${positionalParameters.join(', ')}) =>
    _withArguments$name(${oldToNewArguments.join(', ')});
""", isShared: canBeShared);
  }

  static List<String> _decodeAnalyzerCode(Object? yamlEntry) {
    switch (yamlEntry) {
      case null:
        return const [];
      case String():
        return [yamlEntry];
      case List():
        return yamlEntry.cast<String>();
      default:
        throw 'Bad analyzerCode type: ${yamlEntry.runtimeType}';
    }
  }

  static String? _decodeMessage(Object? yamlEntry) {
    switch (yamlEntry) {
      case null:
        return null;
      case String():
        // Remove trailing whitespace. This is necessary for templates defined
        // with `|` (verbatim) as they always contain a trailing newline that we
        // don't want.
        return yamlEntry.trimRight();
      default:
        throw 'Bad message type: ${yamlEntry.runtimeType}';
    }
  }

  static String? _decodeSeverity(Object? yamlEntry) {
    switch (yamlEntry) {
      case null:
        return null;
      case String():
        return severityEnumNames[yamlEntry] ??
            (throw "Unknown severity '$yamlEntry'");
      default:
        throw 'Bad severity type: ${yamlEntry.runtimeType}';
    }
  }
}

/// Enum describing the types of template parameters supported by front_end
/// diagnostic codes.
///
/// Each instance of this enum carries information about the type of the CFE's
/// internal representation of the parameter and how to convert it to a string.
enum _TemplateParameterType {
  character(
    cfeType: 'String',
    conversion: _SimpleConversion('validateCharacter'),
  ),
  unicode(cfeType: 'int', conversion: _SimpleConversion('codePointToUnicode')),
  name(
    cfeType: 'String',
    conversion: _SimpleConversion('validateAndDemangleName'),
  ),
  nameOKEmpty(
    cfeType: 'String',
    conversion: _SimpleConversion('nameOrUnnamed'),
  ),
  names(
    cfeType: 'List<String>',
    conversion: _SimpleConversion('validateAndItemizeNames'),
  ),
  string(cfeType: 'String', conversion: _SimpleConversion('validateString')),
  stringOKEmpty(
    cfeType: 'String',
    conversion: _SimpleConversion('stringOrEmpty'),
  ),
  token(cfeType: 'Token', conversion: _SimpleConversion('tokenToLexeme')),
  type(cfeType: 'DartType', conversion: _LabelerConversion('labelType')),
  uri(cfeType: 'Uri', conversion: _SimpleConversion('relativizeUri')),
  int(cfeType: 'int'),
  constant(
    cfeType: 'Constant',
    conversion: _LabelerConversion('labelConstant'),
  ),
  num(cfeType: 'num', conversion: _SimpleConversion('formatNumber'));

  final String cfeType;
  final _Conversion? conversion;

  const _TemplateParameterType({required this.cfeType, this.conversion});
}
