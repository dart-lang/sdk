// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/change.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/code_template.dart';
import 'package:analysis_server/src/services/refactoring/framework/formal_parameter.dart';
import 'package:analysis_server/src/utilities/index_range.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// The addition of a new parameter.
class AddParameter extends ParameterModification {
  /// The index of the parameter in the parameter list after the modifications
  /// have been applied.
  final int index;

  /// The name of the parameter that was added.
  final String name;

  /// A flag indicating whether the parameter is a required parameter.
  final bool isRequired;

  /// A flag indicating whether the parameter is a positional parameter.
  final bool isPositional;

  /// The code template used to compute the value of the new argument in
  /// invocations of the function, or `null` if the parameter is optional and no
  /// argument needs to be added. The only time an argument needs to be added
  /// for an optional parameter is if the parameter is positional and there are
  /// preexisting optional positional parameters after the ones being added.
  final CodeTemplate? argumentValue;

  /// Initialize a newly created parameter modification to represent the
  /// addition of a parameter. If provided, the [argumentValue] will be used as
  /// the value of the new argument in invocations of the function.
  AddParameter(this.index, this.name, this.isRequired, this.isPositional,
      this.argumentValue)
      : assert(index >= 0);
}

/// The type change of a parameter.
class ChangeParameterType extends ParameterModification {
  /// The location of the changed parameter.
  final FormalParameterReference reference;

  /// The nullability of the parameter.
  final String nullability;

  /// The code template used to compute the value of the new argument in
  /// invocations of the function, or `null` if the parameter is optional and no
  /// argument needs to be added. The only time an argument needs to be added
  /// for an optional parameter is if the parameter is positional and there are
  /// preexisting optional positional parameters after the ones being added.
  final CodeTemplate? argumentValue;

  ChangeParameterType({
    required this.reference,
    required this.nullability,
    required this.argumentValue,
  });
}

/// The data related to an executable element whose parameters have been
/// modified.
class ModifyParameters extends Change<_Data> {
  /// A list of the modifications being made.
  final List<ParameterModification> modifications;

  /// Initialize a newly created transform to modifications to the parameter
  /// list of a function.
  ModifyParameters({required this.modifications})
      : assert(modifications.isNotEmpty);

  @override
  // The private type of the [data] parameter is dictated by the signature of
  // the super-method and the class's super-class.
  // ignore: library_private_types_in_public_api
  void apply(DartFileEditBuilder builder, DataDrivenFix fix, _Data data) {
    var argumentList = data.argumentList;
    var invocation = argumentList.parent;
    if (invocation == null) {
      // This should only happen if `validate` didn't check this case.
      return;
    }
    var arguments = argumentList.arguments;
    var argumentCount = arguments.length;
    var templateContext = TemplateContext(invocation, fix.utils);

    var indexToNewArgumentMap = <int, ParameterModification>{};
    var argumentsToInsert = <int>[];
    var argumentsToDelete = <int>[];
    var remainingArguments = [for (var i = 0; i < argumentCount; i++) i];
    for (var modification in modifications) {
      if (modification is AddParameter) {
        var index = modification.index;
        indexToNewArgumentMap[index] = modification;
        if (modification.isPositional || modification.isRequired) {
          argumentsToInsert.add(index);
        } else {
          var requiredIfCondition =
              modification.argumentValue?.requiredIfCondition;
          if (requiredIfCondition != null &&
              requiredIfCondition.evaluateIn(templateContext) == true) {
            argumentsToInsert.add(index);
          }
        }
      } else if (modification is RemoveParameter) {
        var argument = modification.parameter.argumentFrom(argumentList);
        // If there is no argument corresponding to the parameter then we assume
        // that the parameter was optional (and absent) and don't try to remove
        // it.
        if (argument != null) {
          var index = arguments.indexOf(_realArgument(argument));
          argumentsToDelete.add(index);
          remainingArguments.remove(index);
        }
      } else if (modification is ChangeParameterType) {
        var reference = modification.reference;
        var argument = reference.argumentFrom(argumentList);
        if (argument == null) {
          // If there is no argument corresponding to the parameter then we assume
          // that the parameter was absent.
          var index = reference is PositionalFormalParameterReference
              ? reference.index
              : remainingArguments.last + 1;
          remainingArguments.add(index);
          indexToNewArgumentMap[index] = modification;
          argumentsToInsert.add(index);
        } else {
          // Check and replace null value arguments.
          if (argument is NullLiteral) {
            var argumentValue = modification.argumentValue;
            if (argumentValue != null) {
              builder.addReplacement(
                  SourceRange(argument.offset, argument.length), (builder) {
                argumentValue.writeOn(builder, templateContext);
              });
            }
          }
        }
      }
    }
    argumentsToInsert.sort();
    argumentsToDelete.sort();

    /// Write to the [builder] the argument associated with a single
    /// [parameter].
    void writeArgument(DartEditBuilder builder, AddParameter parameter) {
      var argumentValue = parameter.argumentValue;
      if (argumentValue != null) {
        if (!parameter.isPositional) {
          builder.write(parameter.name);
          builder.write(': ');
        }
        argumentValue.writeOn(builder, templateContext);
      }
    }

    /// Write to the [builder] the change associated with a single
    /// [parameter].
    void writeChangeArgument(
        DartEditBuilder builder, ChangeParameterType parameter) {
      var argumentValue = parameter.argumentValue;
      if (argumentValue != null) {
        switch (parameter.reference) {
          case NamedFormalParameterReference(:final name):
            builder.write(name);
            builder.write(': ');
          case PositionalFormalParameterReference():
          // Nothing.
        }
        argumentValue.writeOn(builder, templateContext);
      }
    }

    var insertionRanges = IndexRange.contiguousSubRanges(argumentsToInsert);
    var deletionRanges = IndexRange.contiguousSubRanges(argumentsToDelete);
    if (insertionRanges.isNotEmpty) {
      /// Write to the [builder] the new arguments in the [insertionRange]. If
      /// [needsInitialComma] is `true` then we need to write a comma before the
      /// first of the new arguments.
      void writeInsertionRange(DartEditBuilder builder,
          IndexRange insertionRange, bool needsInitialComma) {
        var needsComma = needsInitialComma;
        for (var argumentIndex = insertionRange.lower;
            argumentIndex <= insertionRange.upper;
            argumentIndex++) {
          if (needsComma) {
            builder.write(', ');
          } else {
            needsComma = true;
          }
          var parameter = indexToNewArgumentMap[argumentIndex];
          if (parameter != null) {
            switch (parameter) {
              case AddParameter():
                writeArgument(builder, parameter);
              case ChangeParameterType():
                writeChangeArgument(builder, parameter);
            }
          }
        }
      }

      var nextRemaining = 0;
      var nextInsertionRange = 0;
      var insertionCount = 0;
      while (nextRemaining < remainingArguments.length &&
          nextInsertionRange < insertionRanges.length) {
        var remainingIndex = remainingArguments[nextRemaining];
        var insertionRange = insertionRanges[nextInsertionRange];
        var insertionIndex = insertionRange.lower;
        if (insertionIndex <= remainingIndex + insertionCount) {
          // There are arguments that need to be inserted before the next
          // remaining argument.
          var deletionRange =
              _rangeContaining(deletionRanges, insertionIndex - 1);
          if (deletionRange == null) {
            // The insertion range doesn't overlap a deletion range, so insert
            // the added arguments before the argument whose index is
            // `remainingIndex`.
            int offset;
            var needsInitialComma = false;
            if (insertionIndex > 0) {
              offset = arguments[remainingIndex - 1].end;
              needsInitialComma = true;
            } else {
              offset = arguments[remainingIndex].offset;
            }
            builder.addInsertion(offset, (builder) {
              writeInsertionRange(builder, insertionRange, needsInitialComma);
              if (insertionIndex == 0) {
                builder.write(', ');
              }
            });
          } else {
            // The insertion range overlaps a deletion range, so replace the
            // arguments in the deletion range with the arguments in the
            // insertion range.
            var replacementRange = range.argumentRange(
                argumentList, deletionRange.lower, deletionRange.upper, false);
            builder.addReplacement(replacementRange, (builder) {
              writeInsertionRange(builder, insertionRange, false);
            });
            deletionRanges.remove(deletionRange);
          }
          insertionCount += insertionRange.count;
          nextInsertionRange++;
        } else {
          // There are no arguments that need to be inserted before the next
          // remaining argument, so just move past the next remaining argument.
          nextRemaining++;
        }
      }
      // The remaining insertion ranges might include new required arguments
      // that need to be inserted after the last argument.
      var offset = arguments.isEmpty
          ? argumentList.leftParenthesis.end
          : arguments[arguments.length - 1].end;
      while (nextInsertionRange < insertionRanges.length) {
        var insertionRange = insertionRanges[nextInsertionRange];
        var lower = insertionRange.lower;
        var upper = insertionRange.upper;
        var parameter = indexToNewArgumentMap[upper]!;
        switch (parameter) {
          // Changing the type of parameter to non null indicates that a value
          // must be passed in, regardless of whether is it positional or
          // required.
          case AddParameter():
            while (upper >= lower &&
                (parameter.isPositional && !parameter.isRequired)) {
              upper--;
            }
          case ChangeParameterType():
            while (upper >= lower) {
              upper--;
            }
        }
        if (upper >= lower) {
          builder.addInsertion(offset, (builder) {
            writeInsertionRange(builder, IndexRange(lower, upper),
                nextRemaining > 0 || insertionCount > 0);
          });
        }
        nextInsertionRange++;
        insertionCount++;
      }
    }
    //
    // The remaining deletion ranges are now ready to be removed.
    //
    for (var subRange in deletionRanges) {
      var lower = subRange.lower;
      var upper = subRange.upper;
      if (lower == 0 &&
          upper == arguments.length - 1 &&
          insertionRanges.isNotEmpty) {
        // We're removing all of the existing arguments but we've already
        // inserted new arguments between the parentheses. We need to handle
        // this case specially because the default code would cause a
        // `ConflictingEditException`.
        builder.addDeletion(range.startEnd(arguments[lower], arguments[upper]));
      } else {
        builder
            .addDeletion(range.argumentRange(argumentList, lower, upper, true));
      }
    }
  }

  @override
  // The private return type is dictated by the signature of the super-method
  // and the class's super-class.
  // ignore: library_private_types_in_public_api
  _Data? validate(DataDrivenFix fix) {
    var node = fix.node;
    var parent = node.parent;
    var grandParent = parent?.parent;
    var greatGrandParent = grandParent?.parent;
    if (parent is InvocationExpression) {
      var argumentList = parent.argumentList;
      return _Data(argumentList);
    } else if (parent is Label) {
      var argumentList = grandParent?.parent;
      if (argumentList is ArgumentList) {
        return _Data(argumentList);
      }
    } else if (grandParent is InvocationExpression) {
      var argumentList = grandParent.argumentList;
      return _Data(argumentList);
    } else if (parent is NamedType &&
        grandParent is ConstructorName &&
        greatGrandParent is InstanceCreationExpression) {
      var argumentList = greatGrandParent.argumentList;
      return _Data(argumentList);
    } else if (parent is NamedExpression &&
        greatGrandParent is InstanceCreationExpression) {
      var argumentList = greatGrandParent.argumentList;
      return _Data(argumentList);
    } else if (grandParent is InstanceCreationExpression) {
      var argumentList = grandParent.argumentList;
      return _Data(argumentList);
    }
    return null;
  }

  /// Return the range from the list of [ranges] that contains the given
  /// [index], or `null` if there is no such range.
  IndexRange? _rangeContaining(List<IndexRange> ranges, int index) {
    for (var range in ranges) {
      if (index >= range.lower && index <= range.upper) {
        return range;
      }
    }
    return null;
  }

  /// Return the element of the argument list whose value is the given
  /// [argument]. If the argument is the child of a named expression, then that
  /// will be the named expression, otherwise it will be the argument itself.
  Expression _realArgument(Expression argument) {
    var parent = argument.parent;
    return parent is NamedExpression ? parent : argument;
  }
}

/// A modification related to a parameter.
abstract class ParameterModification {}

/// The removal of an existing parameter.
class RemoveParameter extends ParameterModification {
  /// The parameter that was removed.
  final FormalParameterReference parameter;

  /// Initialize a newly created parameter modification to represent the removal
  /// of an existing [parameter].
  RemoveParameter(this.parameter);
}

/// The data returned when updating an invocation site.
class _Data {
  /// The argument list to be updated.
  final ArgumentList argumentList;

  /// Initialize a newly created data object with the data needed to update an
  /// invocation site.
  _Data(this.argumentList);
}
