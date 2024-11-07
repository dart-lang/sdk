// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/refactoring/framework/formal_parameter.dart';
import 'package:analysis_server_plugin/edit/correction_utils.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';

/// Replaces [argumentList] with new code that has arguments as requested
/// by the formal parameter updates, reordering, changing kind, etc.
Future<WriteArgumentsStatus> writeArguments({
  required List<FormalParameterUpdate> formalParameterUpdates,
  required Set<String> removedNamedFormalParameters,
  required ArgumentsTrailingComma trailingComma,
  required ResolvedUnitResult resolvedUnit,
  required ArgumentList argumentList,
  required ChangeBuilder builder,
}) async {
  var utils = CorrectionUtils(resolvedUnit);

  var positionArguments = argumentList.positional;
  var namedArguments = argumentList.namedMap;

  var newArguments = <_Argument>[];
  for (var update in formalParameterUpdates) {
    switch (update) {
      case FormalParameterUpdateExisting(:var reference):
        switch (reference) {
          case NamedFormalParameterReference():
            var name = reference.name;
            var argument = namedArguments.remove(name);
            if (argument == null) {
              continue;
            }
            if (update is FormalParameterUpdateExistingNamed) {
              // TODO(scheglov): maybe support renames
              newArguments.add(_ArgumentAsIs(argument: argument));
            } else {
              newArguments.add(_ArgumentRemoveName(namedExpression: argument));
            }
          case PositionalFormalParameterReference():
            var argument = positionArguments.elementAtOrNull(reference.index);
            if (argument == null) {
              return WriteArgumentsStatusFailure();
            }
            if (update is FormalParameterUpdateExistingNamed) {
              newArguments.add(
                _ArgumentAddName(name: update.name, argument: argument),
              );
            } else {
              newArguments.add(_ArgumentAsIs(argument: argument));
            }
        }
      case FormalParameterUpdateNewNamed():
        newArguments.add(
          _ArgumentNewNamed(name: update.name, valueCode: update.valueCode),
        );
      case FormalParameterUpdateNewPositional():
        newArguments.add(_ArgumentNewPositional(valueCode: update.valueCode));
    }
  }

  // Add remaining named arguments.
  namedArguments.forEach((name, argument) {
    if (removedNamedFormalParameters.contains(name)) {
      return;
    }
    newArguments.add(_ArgumentAsIs(argument: argument));
  });

  await builder.addDartFileEdit(resolvedUnit.path, (builder) {
    builder.addReplacement(range.node(argumentList), (builder) {
      builder.write('(');
      for (var argument in newArguments) {
        switch (argument) {
          case _ArgumentAddName():
            var text = utils.getNodeText(argument.argument);
            builder.write(argument.name);
            builder.write(': ');
            builder.write(text);
          case _ArgumentAsIs():
            var text = utils.getNodeText(argument.argument);
            builder.write(text);
          case _ArgumentNewNamed():
            builder.write(argument.name);
            builder.write(': ');
            builder.write(argument.valueCode);
          case _ArgumentNewPositional():
            builder.write(argument.valueCode);
          case _ArgumentRemoveName():
            var expression = argument.namedExpression.expression;
            var text = utils.getNodeText(expression);
            builder.write(text);
        }
        if (argument != newArguments.last) {
          builder.write(', ');
        } else {
          switch (trailingComma) {
            case ArgumentsTrailingComma.always:
              builder.write(', ');
            case ArgumentsTrailingComma.ifPresent:
              if (argumentList.hasTrailingComma) {
                builder.write(', ');
              }
            case ArgumentsTrailingComma.never:
              break;
          }
        }
      }
      builder.write(')');
    });
    builder.format(range.node(argumentList));
  });

  return WriteArgumentsStatusSuccess();
}

/// The strategy for trailing comma after arguments.
enum ArgumentsTrailingComma {
  /// Always add the trailing comma.
  always,

  /// Keep the trailing comma, if already present.
  ifPresent,

  /// Remove the trailing comma.
  never,
}

/// Formal parameter update.
sealed class FormalParameterUpdate {}

/// Existing formal parameter update.
sealed class FormalParameterUpdateExisting extends FormalParameterUpdate {
  /// The original formal parameter reference.
  final FormalParameterReference reference;

  FormalParameterUpdateExisting({required this.reference});
}

/// Existing named formal parameter update.
final class FormalParameterUpdateExistingNamed
    extends FormalParameterUpdateExisting {
  /// The new name, might be the same as the old one.
  final String name;

  FormalParameterUpdateExistingNamed({
    required super.reference,
    required this.name,
  });
}

/// Existing positional formal parameter update.
final class FormalParameterUpdateExistingPositional
    extends FormalParameterUpdateExisting {
  FormalParameterUpdateExistingPositional({required super.reference});
}

/// New formal parameter.
sealed class FormalParameterUpdateNew extends FormalParameterUpdate {
  final String name;
  final String valueCode;

  FormalParameterUpdateNew({required this.name, required this.valueCode});
}

/// New named formal parameter.
final class FormalParameterUpdateNewNamed extends FormalParameterUpdateNew {
  FormalParameterUpdateNewNamed({
    required super.name,
    required super.valueCode,
  });
}

/// New positional formal parameter.
final class FormalParameterUpdateNewPositional
    extends FormalParameterUpdateNew {
  FormalParameterUpdateNewPositional({
    required super.name,
    required super.valueCode,
  });
}

/// The supertype return types from [writeArguments].
sealed class WriteArgumentsStatus {}

/// The supertype for any failure inside [writeArguments].
///
/// Currently it has no subtypes, but if more specific error message is
/// necessary, with pieces of data (e.g. nodes, names, etc), such subtypes
/// can be added.
final class WriteArgumentsStatusFailure extends WriteArgumentsStatus {}

/// The result that signals the success.
final class WriteArgumentsStatusSuccess extends WriteArgumentsStatus {}

/// The description of how an argument should be written.
sealed class _Argument {}

/// The argument to write as a named expression.
final class _ArgumentAddName extends _Argument {
  final String name;
  final Expression argument;

  _ArgumentAddName({required this.name, required this.argument});
}

/// The argument to write as is, positional or named.
final class _ArgumentAsIs extends _Argument {
  final Expression argument;

  _ArgumentAsIs({required this.argument});
}

/// The new argument.
sealed class _ArgumentNew extends _Argument {
  final String valueCode;

  _ArgumentNew({required this.valueCode});
}

/// The new named argument.
final class _ArgumentNewNamed extends _ArgumentNew {
  final String name;

  _ArgumentNewNamed({required super.valueCode, required this.name});
}

/// The new positional argument.
final class _ArgumentNewPositional extends _ArgumentNew {
  _ArgumentNewPositional({required super.valueCode});
}

/// The argument to write without the name.
final class _ArgumentRemoveName extends _Argument {
  final NamedExpression namedExpression;

  _ArgumentRemoveName({required this.namedExpression});
}

extension on ArgumentList {
  bool get hasTrailingComma {
    var last = arguments.lastOrNull;
    var nextToken = last?.endToken.next;
    return nextToken != null && nextToken.type == TokenType.COMMA;
  }

  Map<String, NamedExpression> get namedMap {
    return Map.fromEntries(
      arguments.whereType<NamedExpression>().map((namedExpression) {
        var name = namedExpression.name.label.name;
        return MapEntry(name, namedExpression);
      }),
    );
  }

  List<Expression> get positional {
    return arguments
        .whereNot((argument) => argument is NamedExpression)
        .toList();
  }
}
