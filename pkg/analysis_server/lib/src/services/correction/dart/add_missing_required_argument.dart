// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:collection/collection.dart';

class AddMissingRequiredArgument extends ResolvedCorrectionProducer {
  /// The number of the parameters missing.
  late int _missingParameters;

  AddMissingRequiredArgument({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // Not a stand-alone fix; requires follow-up actions.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => ['$_missingParameters', _plural];

  @override
  FixKind get fixKind => DartFixKind.addMissingRequiredArgument;

  /// All the diagnostic codes that this fix can be applied to.
  List<DiagnosticCode> get _codesWhereThisIsValid {
    var producerGenerators = [AddMissingRequiredArgument.new];
    var nonLintProducers = registeredFixGenerators.warningProducers;
    return [
      for (var MapEntry(:key, :value) in nonLintProducers.entries)
        if (value.containsAny(producerGenerators)) key,
    ];
  }

  String get _plural => _missingParameters == 1 ? '' : 's';

  @override
  Future<void> compute(ChangeBuilder builder) async {
    InstanceCreationExpression? creation;
    Element? targetElement;
    ArgumentList? argumentList;

    if (node is SimpleIdentifier ||
        node is ConstructorName ||
        node is NamedType) {
      var invocation = node.parent;
      if (invocation is MethodInvocation) {
        targetElement = invocation.methodName.element;
        argumentList = invocation.argumentList;
      } else {
        creation = invocation?.thisOrAncestorOfType();
        if (creation != null) {
          targetElement = creation.constructorName.element;
          argumentList = creation.argumentList;
        }
      }
    }

    var diagnostic = this.diagnostic;
    if (diagnostic == null) {
      return;
    }

    var validCodes = _codesWhereThisIsValid;
    var diagnostics = unitResult.diagnostics.where(
      (e) => diagnostic.sameRangeAs(e) && validCodes.contains(e.diagnosticCode),
    );

    // Should not happen since the current diagnostic is in the list of errors
    // where this fix is valid.
    if (diagnostics.isEmpty) {
      assert(false, 'No valid diagnostics found, but expected at least one.');
      diagnostics = [diagnostic];
    }

    // This should only trigger once and the disposition of the valid
    // diagnostics in the unit should always be the same.
    if (diagnostics.first != diagnostic) {
      return;
    }

    _missingParameters = diagnostics.length;

    if (argumentList == null || targetElement is! ExecutableElement) {
      return;
    }
    var arguments = argumentList.arguments;

    int offset;
    var insertLeadingComma = false;
    var insertFlutterTrailingComma = true;
    var insertBetweenFlutterParams = false;
    if (arguments.isEmpty) {
      offset = argumentList.leftParenthesis.end;
    } else {
      var lastArgument = arguments.last;
      offset = lastArgument.end;
      insertLeadingComma = true;
      if (creation.isWidgetExpression) {
        // If the last argument is a `child:` or `children:` parameter in a
        // Flutter widget, insert the new parameter(s) before it.
        if (lastArgument is NamedExpression) {
          if (lastArgument.isChildArgument || lastArgument.isChildrenArgument) {
            offset = lastArgument.offset;
            insertBetweenFlutterParams = true;
            // Insert a leading comma if we are have a case like:
            // ```dart
            // MyWidget(other: 1, child: ...,)
            // ```
            // so that we get:
            // ```dart
            // MyWidget(other: 1, newParam: ..., child: ...,)
            // ```
            // since the offset is at the end of `other: 1`.
            insertLeadingComma = arguments.length > 1;
          }
        }
        if (lastArgument.endToken.next case Token(
          type: TokenType.COMMA,
        ) when !insertBetweenFlutterParams) {
          // If there is a trailing comma after the last argument, don't add
          // another one.
          insertFlutterTrailingComma = false;
        }
      }
    }

    Map<String, DefaultArgument?> parameters = {};
    for (var diagnostic in diagnostics) {
      // Format: "Missing required argument 'foo'."
      var messageParts = diagnostic.problemMessage
          .messageText(includeUrl: false)
          .split("'");
      if (messageParts.length < 2) {
        return;
      }

      var parameterName = messageParts[1];

      var missingParameter = targetElement.formalParameters.firstWhereOrNull(
        (p) => p.name == parameterName,
      );
      if (missingParameter == null) {
        assert(
          false,
          'Could not find parameter $parameterName, but expected since it was '
          'reported as missing.',
        );
        continue;
      }

      var codeStyleOptions = getCodeStyleOptions(unitResult.file);
      var defaultValue = getDefaultStringParameterValue(
        missingParameter,
        codeStyleOptions.preferredQuoteForStrings,
      );

      parameters[parameterName] = defaultValue;
    }

    var parametersLength = parameters.length;

    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(offset, (builder) {
        if (insertLeadingComma) {
          builder.write(', ');
        }
        var entries = parameters.entries.toList();
        var childOrChildren = entries.firstWhereOrNull(
          (e) => const {'child', 'children'}.contains(e.key),
        );
        if (childOrChildren != null) {
          // If there is a child: or children: parameter, insert it last.
          entries.remove(childOrChildren);
          entries.add(childOrChildren);
        }
        entries.forEachIndexed((index, entry) {
          var MapEntry(key: parameterName, value: defaultValue) = entry;

          builder.write('$parameterName: ');

          // Use defaultValue.cursorPosition if it's not null.
          if (defaultValue != null) {
            var text = defaultValue.text;
            var cursorPosition = defaultValue.cursorPosition;
            if (cursorPosition != null) {
              builder.write(text.substring(0, cursorPosition));
              builder.selectHere();
              builder.write(text.substring(cursorPosition));
            } else {
              builder.addSimpleLinkedEdit('VALUE', text);
            }
          } else {
            builder.addSimpleLinkedEdit('VALUE', 'null');
          }

          if (index < parametersLength - 1) {
            builder.write(', ');
          } else if (insertBetweenFlutterParams) {
            // Insert a trailing comma after Flutter instance creation params.
            builder.writeln(',');
            // Insert indent before the child: or children: param.
            var indent = utils.getLinePrefix(offset);
            builder.write(indent);
          } else if (creation.isWidgetExpression &&
              insertFlutterTrailingComma) {
            // If this is a Flutter widget, format with a trailing comma.
            builder.write(',');
          }
        });
      });
    });
  }
}

extension<T> on Iterable<T> {
  bool containsAny(Iterable<T> values) {
    return values.any((v) => contains(v));
  }
}

extension on Diagnostic {
  bool sameRangeAs(Diagnostic other) {
    return offset == other.offset && length == other.length;
  }
}
