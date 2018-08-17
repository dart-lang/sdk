// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'severity.dart' show Severity;

import 'messages.dart' as msg;

Severity rewriteSeverity(
    Severity severity, msg.Code<Object> code, Uri fileUri) {
  if (severity != Severity.ignored) {
    if (code == msg.codeFinalFieldNotInitialized) {
      // TODO(johnniwinther): Use external getters instead of final fields.
      // See https://github.com/dart-lang/sdk/issues/33762
      for (String path in [
        "/pkg/dev_compiler/tool/input_sdk/private/js_string.dart",
        "/sdk/lib/html/dart2js/html_dart2js.dart",
        "/sdk/lib/svg/dart2js/svg_dart2js.dart",
        "/sdk/lib/_internal/js_runtime/lib/native_typed_data.dart"
      ]) {
        if (fileUri.path.endsWith(path)) {
          return Severity.ignored;
        }
      }
    }
    return severity;
  }

  String path = fileUri.path;
  String fastaPath = "/pkg/front_end/lib/src/fasta/";
  int index = path.indexOf(fastaPath);
  if (index == -1) {
    fastaPath = "/pkg/front_end/tool/_fasta/";
    index = path.indexOf(fastaPath);
    if (index == -1) return severity;
  }
  if (code == msg.codeUseOfDeprecatedIdentifier) {
    // TODO(ahe): Remove the exceptions below.
    // We plan to remove all uses of deprecated identifiers from Fasta. The
    // strategy is to remove files from the list below one by one. To get
    // started on cleaning up a given file, simply remove it from the list
    // below and compile Fasta with itself to get a list of remaining call
    // sites.
    switch (path.substring(fastaPath.length + index)) {
      case "command_line.dart":
      case "command_line_reporting.dart":
      case "deprecated_problems.dart":
      case "entry_points.dart":
      case "kernel/body_builder.dart":
      case "kernel/expression_generator.dart":
      case "kernel/kernel_expression_generator.dart":
      case "kernel/kernel_expression_generator_impl.dart":
      case "kernel/kernel_procedure_builder.dart":
      case "kernel/kernel_type_variable_builder.dart":
      case "source/diet_listener.dart":
      case "source/source_library_builder.dart":
      case "source/source_loader.dart":
      case "source/stack_listener.dart":
        return severity;
    }
  } else if (code == msg.codeMissingExplicitTypeArguments) {
    // TODO(ahe): Remove the exceptions below.
    // We're not sure if we want to require that all types have explicit type
    // arguments in Fasta. Regardles, the strategy is to remove files from the
    // list below one by one. To get started on cleaning up a given file,
    // simply remove it from the list below and compile Fasta with itself to
    // get a list of remaining call sites.
    switch (path.substring(fastaPath.length + index)) {
      case "builder/builtin_type_builder.dart":
      case "builder/class_builder.dart":
      case "builder/constructor_reference_builder.dart":
      case "builder/dynamic_type_builder.dart":
      case "builder/field_builder.dart":
      case "builder/formal_parameter_builder.dart":
      case "builder/function_type_alias_builder.dart":
      case "builder/function_type_builder.dart":
      case "builder/library_builder.dart":
      case "builder/member_builder.dart":
      case "builder/metadata_builder.dart":
      case "builder/mixin_application_builder.dart":
      case "builder/named_type_builder.dart":
      case "builder/prefix_builder.dart":
      case "builder/procedure_builder.dart":
      case "builder/type_builder.dart":
      case "builder/type_declaration_builder.dart":
      case "builder/type_variable_builder.dart":
      case "builder/unresolved_type.dart":
      case "builder/void_type_builder.dart":
      case "builder_graph.dart":
      case "compiler_context.dart":
      case "dill/dill_class_builder.dart":
      case "dill/dill_library_builder.dart":
      case "dill/dill_loader.dart":
      case "dill/dill_target.dart":
      case "dill/dill_typedef_builder.dart":
      case "entry_points.dart":
      case "export.dart":
      case "fasta_codes.dart":
      case "import.dart":
      case "incremental_compiler.dart":
      case "kernel/expression_generator.dart":
      case "kernel/expression_generator_helper.dart":
      case "kernel/fangorn.dart":
      case "kernel/forest.dart":
      case "kernel/kernel_class_builder.dart":
      case "kernel/kernel_enum_builder.dart":
      case "kernel/kernel_expression_generator.dart":
      case "kernel/kernel_expression_generator_impl.dart":
      case "kernel/kernel_field_builder.dart":
      case "kernel/kernel_formal_parameter_builder.dart":
      case "kernel/kernel_function_type_alias_builder.dart":
      case "kernel/kernel_function_type_builder.dart":
      case "kernel/kernel_invalid_type_builder.dart":
      case "kernel/kernel_library_builder.dart":
      case "kernel/kernel_mixin_application_builder.dart":
      case "kernel/kernel_named_type_builder.dart":
      case "kernel/kernel_prefix_builder.dart":
      case "kernel/kernel_procedure_builder.dart":
      case "kernel/kernel_shadow_ast.dart":
      case "kernel/kernel_target.dart":
      case "kernel/kernel_type_builder.dart":
      case "kernel/kernel_type_variable_builder.dart":
      case "kernel/load_library_builder.dart":
      case "kernel/metadata_collector.dart":
      case "kernel/type_algorithms.dart":
      case "kernel/verifier.dart":
      case "loader.dart":
      case "scanner/error_token.dart":
      case "scanner/recover.dart":
      case "scope.dart":
      case "source/diet_listener.dart":
      case "source/outline_builder.dart":
      case "source/source_class_builder.dart":
      case "source/source_library_builder.dart":
      case "source/source_loader.dart":
      case "source/stack_listener.dart":
      case "target_implementation.dart":
      case "type_inference/interface_resolver.dart":
      case "type_inference/type_inference_engine.dart":
      case "type_inference/type_inferrer.dart":
      case "type_inference/type_schema.dart":
      case "util/link.dart":
      case "util/link_implementation.dart":
        return severity;
    }
  }
  return Severity.error;
}
