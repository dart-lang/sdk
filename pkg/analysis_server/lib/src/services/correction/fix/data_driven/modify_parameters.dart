// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/change.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/code_template.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/parameter_reference.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:meta/meta.dart';

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
  /// pre-existing optional positional parameters after the ones being added.
  final CodeTemplate argumentValue;

  /// Initialize a newly created parameter modification to represent the
  /// addition of a parameter. If provided, the [argumentValue] will be used as
  /// the value of the new argument in invocations of the function.
  AddParameter(this.index, this.name, this.isRequired, this.isPositional,
      this.argumentValue)
      : assert(index >= 0),
        assert(name != null);
}

/// The data related to an executable element whose parameters have been
/// modified.
class ModifyParameters extends Change<_Data> {
  /// A list of the modifications being made.
  final List<ParameterModification> modifications;

  /// Initialize a newly created transform to modifications to the parameter
  /// list of a function.
  ModifyParameters({@required this.modifications})
      : assert(modifications != null),
        assert(modifications.isNotEmpty);

  @override
  void apply(DartFileEditBuilder builder, DataDrivenFix fix, _Data data) {
    var argumentList = data.argumentList;
    var arguments = argumentList.arguments;
    var argumentCount = arguments.length;
    var templateContext = TemplateContext(argumentList.parent, fix.utils);
    var newNamed = <AddParameter>[];
    var indexToNewArgumentMap = <int, AddParameter>{};
    var argumentsToInsert = <int>[];
    var argumentsToDelete = <int>[];
    var remainingArguments = [for (var i = 0; i < argumentCount; i++) i];
    for (var modification in modifications) {
      if (modification is AddParameter) {
        var index = modification.index;
        indexToNewArgumentMap[index] = modification;
        if (modification.isPositional) {
          argumentsToInsert.add(index);
        } else if (modification.isRequired) {
          newNamed.add(modification);
        } else {
          var requiredIfCondition =
              modification.argumentValue?.requiredIfCondition;
          if (requiredIfCondition != null &&
              requiredIfCondition.evaluateIn(templateContext)) {
            newNamed.add(modification);
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
      }
    }
    argumentsToInsert.sort();
    newNamed.sort((first, second) => first.name.compareTo(second.name));

    /// Write to the [builder] the argument associated with a single
    /// [parameter].
    void writeArgument(DartEditBuilder builder, AddParameter parameter) {
      if (!parameter.isPositional) {
        builder.write(parameter.name);
        builder.write(': ');
      }
      parameter.argumentValue.writeOn(builder, templateContext);
    }

    var insertionRanges = argumentsToInsert.contiguousSubRanges.toList();
    var deletionRanges = argumentsToDelete.contiguousSubRanges.toList();
    if (insertionRanges.isNotEmpty) {
      /// Write to the [builder] the new arguments in the [insertionRange]. If
      /// [needsInitialComma] is `true` then we need to write a comma before the
      /// first of the new arguments.
      void writeInsertionRange(DartEditBuilder builder,
          _IndexRange insertionRange, bool needsInitialComma) {
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
          writeArgument(builder, parameter);
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
      var offset = arguments[arguments.length - 1].end;
      while (nextInsertionRange < insertionRanges.length) {
        var insertionRange = insertionRanges[nextInsertionRange];
        var lower = insertionRange.lower;
        var upper = insertionRange.upper;
        while (upper >= lower && !indexToNewArgumentMap[upper].isRequired) {
          upper--;
        }
        if (upper >= lower) {
          builder.addInsertion(offset, (builder) {
            writeInsertionRange(builder, _IndexRange(lower, upper), true);
          });
        }
        nextInsertionRange++;
      }
    }
    //
    // Insert arguments for required named parameters.
    //
    if (newNamed.isNotEmpty) {
      int offset;
      var needsInitialComma = false;
      if (remainingArguments.isEmpty && argumentsToInsert.isEmpty) {
        offset = argumentList.rightParenthesis.offset;
      } else {
        offset = arguments[arguments.length - 1].end;
        needsInitialComma = true;
      }
      builder.addInsertion(offset, (builder) {
        for (var i = 0; i < newNamed.length; i++) {
          if (i > 0 || needsInitialComma) {
            builder.write(', ');
          }
          writeArgument(builder, newNamed[i]);
        }
      });
    }
    //
    // The remaining deletion ranges are now ready to be removed.
    //
    for (var subRange in deletionRanges) {
      builder.addDeletion(range.argumentRange(
          argumentList, subRange.lower, subRange.upper, true));
    }
  }

  @override
  _Data validate(DataDrivenFix fix) {
    var node = fix.node;
    var parent = node.parent;
    if (parent is InvocationExpression) {
      var argumentList = parent.argumentList;
      return _Data(argumentList);
    } else if (parent is Label) {
      var argumentList = parent.parent.parent;
      if (argumentList is ArgumentList) {
        return _Data(argumentList);
      }
    }
    return null;
  }

  /// Return the range from the list of [ranges] that contains the given
  /// [index], or `null` if there is no such range.
  _IndexRange _rangeContaining(List<_IndexRange> ranges, int index) {
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
  Expression _realArgument(Expression argument) =>
      argument.parent is NamedExpression ? argument.parent : argument;
}

/// A modification related to a parameter.
abstract class ParameterModification {}

/// The removal of an existing parameter.
class RemoveParameter extends ParameterModification {
  /// The parameter that was removed.
  final ParameterReference parameter;

  /// Initialize a newly created parameter modification to represent the removal
  /// of an existing [parameter].
  RemoveParameter(this.parameter) : assert(parameter != null);
}

/// The data returned when updating an invocation site.
class _Data {
  /// The argument list to be updated.
  final ArgumentList argumentList;

  /// Initialize a newly created data object with the data needed to update an
  /// invocation site.
  _Data(this.argumentList);
}

/// A range of indexes within a list.
class _IndexRange {
  /// The index of the first element in the range.
  final int lower;

  /// The index of the last element in the range. This will be the same as the
  /// [lower] if there is a single element in the range.
  final int upper;

  /// Initialize a newly created range.
  _IndexRange(this.lower, this.upper);

  /// Return the number of indices in this range.
  int get count => upper - lower + 1;

  @override
  String toString() => '[$lower..$upper]';
}

extension on List<int> {
  Iterable<_IndexRange> get contiguousSubRanges sync* {
    if (isEmpty) {
      return;
    }
    var lower = this[0];
    var previous = lower;
    var index = 1;
    while (index < length) {
      var current = this[index];
      if (current == previous + 1) {
        previous = current;
      } else {
        yield _IndexRange(lower, previous);
        lower = previous = current;
      }
      index++;
    }
    yield _IndexRange(lower, previous);
  }
}
