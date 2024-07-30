// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/executable_parameters.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddMissingParameter extends MultiCorrectionProducer {
  AddMissingParameter({required super.context});

  @override
  Future<List<ResolvedCorrectionProducer>> get producers async {
    // `node` is the unmatched argument.
    var argumentList = node.parent;
    if (argumentList is! ArgumentList) {
      return const [];
    }

    var invocation = argumentList.parent;
    if (invocation == null) {
      return const [];
    }

    var executableParameters =
        ExecutableParameters.forInvocation(sessionHelper, invocation);
    if (executableParameters == null) {
      return const [];
    }

    var includeOptional = executableParameters.optionalPositional.isEmpty &&
        executableParameters.named.isEmpty;
    return <ResolvedCorrectionProducer>[
      _AddMissingRequiredPositionalParameter(executableParameters,
          context: context),
      if (includeOptional)
        _AddMissingOptionalPositionalParameter(executableParameters,
            context: context),
    ];
  }
}

/// A correction processor that can make one of the possible changes computed by
/// the [AddMissingParameter] producer.
class _AddMissingOptionalPositionalParameter extends _AddMissingParameter {
  _AddMissingOptionalPositionalParameter(
    super.executableParameters, {
    required super.context,
  });

  @override
  FixKind get fixKind => DartFixKind.ADD_MISSING_PARAMETER_POSITIONAL;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var prefix = _executableParameters.required.isNotEmpty ? ', [' : '[';
    if (_executableParameters.required.isNotEmpty) {
      var prevNode = await _executableParameters
          .getParameterNode(_executableParameters.required.last);
      await _addParameter(builder, prevNode?.end, prefix, ']');
    } else {
      var parameterList = await _executableParameters.getParameterList();
      var offset = parameterList?.leftParenthesis.end;
      await _addParameter(builder, offset, prefix, ']');
    }
  }
}

/// A correction processor that can make one of the possible changes computed by
/// the [AddMissingParameter] producer.
abstract class _AddMissingParameter extends ResolvedCorrectionProducer {
  final ExecutableParameters _executableParameters;

  _AddMissingParameter(this._executableParameters, {required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  Future<void> _addParameter(
      ChangeBuilder builder, int? offset, String prefix, String suffix) async {
    // node is the unmatched argument.
    var argumentList = node.parent;
    if (argumentList is! ArgumentList) {
      return;
    }
    List<Expression> arguments = argumentList.arguments;
    var numRequired = _executableParameters.required.length;
    if (numRequired >= arguments.length) {
      return;
    }
    var argument = arguments[numRequired];
    if (offset != null) {
      await builder.addDartFileEdit(_executableParameters.file, (builder) {
        builder.addInsertion(offset, (builder) {
          builder.write(prefix);
          builder.writeParameterMatchingArgument(
              argument, numRequired, <String>{});
          builder.write(suffix);
        });
      });
    }
  }
}

/// A correction processor that can make one of the possible changes computed by
/// the [AddMissingParameter] producer.
class _AddMissingRequiredPositionalParameter extends _AddMissingParameter {
  _AddMissingRequiredPositionalParameter(super._executableParameters,
      {required super.context});

  @override
  FixKind get fixKind => DartFixKind.ADD_MISSING_PARAMETER_REQUIRED;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (_executableParameters.required.isNotEmpty) {
      var prevNode = await _executableParameters
          .getParameterNode(_executableParameters.required.last);
      await _addParameter(builder, prevNode?.end, ', ', '');
    } else {
      var parameterList = await _executableParameters.getParameterList();
      var offset = parameterList?.leftParenthesis.end;
      var suffix =
          _executableParameters.executable.parameters.isNotEmpty ? ', ' : '';
      await _addParameter(builder, offset, '', suffix);
    }
  }
}
