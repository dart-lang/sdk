// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart'
    show AnalysisError, ErrorSeverity, StaticWarningCode;
import 'package:analyzer/source/error_processor.dart' show ErrorProcessor;
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:path/path.dart' as path;

// TODO(jmesserly): this code was taken from analyzer_cli.
// It really should be in some common place so we can share it.
// TODO(jmesserly): this shouldn't depend on `context` but we need it to compute
// `errorSeverity` due to some APIs that need fixing.
void sortErrors(AnalysisContext context, List<AnalysisError> errors) {
  errors.sort((AnalysisError error1, AnalysisError error2) {
    // severity
    var severity1 = errorSeverity(context, error1);
    var severity2 = errorSeverity(context, error2);
    int compare = severity2.compareTo(severity1);
    if (compare != 0) return compare;

    // path
    compare = Comparable.compare(error1.source.fullName.toLowerCase(),
        error2.source.fullName.toLowerCase());
    if (compare != 0) return compare;

    // offset
    compare = error1.offset - error2.offset;
    if (compare != 0) return compare;

    // compare message, in worst case.
    return error1.message.compareTo(error2.message);
  });
}

// TODO(jmesserly): this was from analyzer_cli, we should factor it differently.
String formatError(AnalysisContext context, AnalysisError error) {
  var severity = errorSeverity(context, error);
  // Skip hints, some like TODOs are not useful.
  if (severity.ordinal <= ErrorSeverity.INFO.ordinal) return null;

  var lineInfo = context.computeLineInfo(error.source);
  var location = lineInfo.getLocation(error.offset);

  // [warning] 'foo' is not a... (/Users/.../tmp/foo.dart, line 1, col 2)
  return (new StringBuffer()
        ..write('[${severity.displayName}] ')
        ..write(error.message)
        ..write(' (${path.prettyUri(error.source.uri)}')
        ..write(', line ${location.lineNumber}, col ${location.columnNumber})'))
      .toString();
}

ErrorSeverity errorSeverity(AnalysisContext context, AnalysisError error) {
  var code = error.errorCode;
  if (code is StaticWarningCode) {
    // TODO(jmesserly): many more warnings need to be promoted for soundness.
    // Also code generation will blow up finding null types/elements for many
    // of these, or we rely on them to produce valid optimizations.
    switch (code.name) {
      case 'AMBIGUOUS_IMPORT':
      case 'ARGUMENT_TYPE_NOT_ASSIGNABLE':
      case 'ARGUMENT_TYPE_NOT_ASSIGNABLE_STATIC_WARNING':
      case 'ASSIGNMENT_TO_CONST':
      case 'ASSIGNMENT_TO_FINAL':
      case 'ASSIGNMENT_TO_FINAL_NO_SETTER':
      case 'ASSIGNMENT_TO_FUNCTION':
      case 'ASSIGNMENT_TO_METHOD':
      case 'ASSIGNMENT_TO_TYPE':
      case 'CASE_BLOCK_NOT_TERMINATED':
      case 'CAST_TO_NON_TYPE':
      case 'CONCRETE_CLASS_WITH_ABSTRACT_MEMBER':
      case 'CONFLICTING_DART_IMPORT':
      case 'CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER':
      case 'CONFLICTING_INSTANCE_METHOD_SETTER':
      case 'CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER':
      case 'CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER':
      case 'CONFLICTING_STATIC_SETTER_AND_INSTANCE_MEMBER':
      case 'CONST_WITH_ABSTRACT_CLASS':
      case 'CONST_WITH_INVALID_TYPE_PARAMETERS':
      case 'EQUAL_KEYS_IN_MAP':
      case 'EXPORT_DUPLICATED_LIBRARY_NAMED':
      case 'EXTRA_POSITIONAL_ARGUMENTS':
      case 'FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION':
      case 'FIELD_INITIALIZER_NOT_ASSIGNABLE':
      case 'FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE':
      case 'FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR':
      case 'FUNCTION_WITHOUT_CALL':
      case 'IMPORT_DUPLICATED_LIBRARY_NAMED':
      case 'IMPORT_OF_NON_LIBRARY':
      case 'INCONSISTENT_METHOD_INHERITANCE_GETTER_AND_METHOD':
      case 'INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC':
      case 'INVALID_GETTER_OVERRIDE_RETURN_TYPE':
      case 'INVALID_METHOD_OVERRIDE_NAMED_PARAM_TYPE':
      case 'INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE':
      case 'INVALID_METHOD_OVERRIDE_OPTIONAL_PARAM_TYPE':
      case 'INVALID_METHOD_OVERRIDE_RETURN_TYPE':
      case 'INVALID_METHOD_OVERRIDE_TYPE_PARAMETERS':
      case 'INVALID_METHOD_OVERRIDE_TYPE_PARAMETER_BOUND':
      case 'INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED':
      case 'INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL':
      case 'INVALID_OVERRIDE_NAMED':
      case 'INVALID_OVERRIDE_POSITIONAL':
      case 'INVALID_OVERRIDE_REQUIRED':
      case 'INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE':
      case 'LIST_ELEMENT_TYPE_NOT_ASSIGNABLE':
      case 'MAP_KEY_TYPE_NOT_ASSIGNABLE':
      case 'MAP_VALUE_TYPE_NOT_ASSIGNABLE':
      case 'NEW_WITH_ABSTRACT_CLASS':
      case 'NEW_WITH_INVALID_TYPE_PARAMETERS':
      case 'NEW_WITH_NON_TYPE':
      case 'NEW_WITH_UNDEFINED_CONSTRUCTOR':
      case 'NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT':
      case 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS':
      case 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR':
      case 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE':
      case 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE':
      case 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO':
      case 'NON_TYPE_IN_CATCH_CLAUSE':
      case 'NOT_A_TYPE':
      case 'NOT_ENOUGH_REQUIRED_ARGUMENTS':
      case 'PART_OF_DIFFERENT_LIBRARY':
      case 'REDIRECT_TO_INVALID_FUNCTION_TYPE':
      case 'REDIRECT_TO_INVALID_RETURN_TYPE':
      case 'REDIRECT_TO_MISSING_CONSTRUCTOR':
      case 'REDIRECT_TO_NON_CLASS':
      case 'STATIC_ACCESS_TO_INSTANCE_MEMBER':
      case 'SWITCH_EXPRESSION_NOT_ASSIGNABLE':
      case 'TYPE_ANNOTATION_DEFERRED_CLASS':
      case 'TYPE_PARAMETER_REFERENCED_BY_STATIC':
      case 'TYPE_TEST_WITH_NON_TYPE':
      case 'TYPE_TEST_WITH_UNDEFINED_NAME':
      case 'UNDEFINED_CLASS':
      case 'UNDEFINED_CLASS_BOOLEAN':
      case 'UNDEFINED_GETTER':
      case 'UNDEFINED_GETTER_STATIC_WARNING':
      case 'UNDEFINED_IDENTIFIER':
      case 'UNDEFINED_NAMED_PARAMETER':
      case 'UNDEFINED_SETTER':
      case 'UNDEFINED_SETTER_STATIC_WARNING':
      case 'UNDEFINED_STATIC_METHOD_OR_GETTER':
      case 'UNDEFINED_SUPER_GETTER':
      case 'UNDEFINED_SUPER_GETTER_STATIC_WARNING':
      case 'UNDEFINED_SUPER_SETTER':
      case 'UNDEFINED_SUPER_SETTER_STATIC_WARNING':
      case 'WRONG_NUMBER_OF_TYPE_ARGUMENTS':
        return ErrorSeverity.ERROR;

      // All of the following ones are okay as warnings.
      case 'FINAL_NOT_INITIALIZED':
      case 'FINAL_NOT_INITIALIZED_CONSTRUCTOR_':

      // We don't rely on these for override checking, AFAIK.
      case 'MISMATCHED_GETTER_AND_SETTER_TYPES':
      case 'MISMATCHED_GETTER_AND_SETTER_TYPES_FROM_SUPERTYPE':

      case 'MISSING_ENUM_CONSTANT_IN_SWITCH':
      case 'MIXED_RETURN_TYPES':

      // TODO(jmesserly): I think codegen already handles this for []=.
      // Though we could simplify it if we didn't need to handle this case.
      case 'NON_VOID_RETURN_FOR_OPERATOR':

      case 'NON_VOID_RETURN_FOR_SETTER':
      case 'RETURN_WITHOUT_VALUE':
      case 'STATIC_WARNING':
      case 'VOID_RETURN_FOR_GETTER':
        break;
    }
  }

  // TODO(jmesserly): this Analyzer API totally bonkers, but it's what
  // analyzer_cli and server use.
  //
  // Among the issues with ErrorProcessor.getProcessor:
  // * it needs to be called per-error, so it's a performance trap.
  // * it can return null
  // * using AnalysisError directly is now suspect, it's a correctness trap
  // * it requires an AnalysisContext
  return ErrorProcessor.getProcessor(context, error)?.severity ??
      error.errorCode.errorSeverity;
}
