// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'class_test.dart' as class_;
import 'const_test.dart' as const_;
import 'default_value_test.dart' as default_value;
import 'duplicate_declaration_test.dart' as duplicate_declaration;
import 'enum_test.dart' as enum_;
import 'extension_test.dart' as extension_;
import 'extension_type_test.dart' as extension_type;
import 'formal_parameter_test.dart' as formal_parameter;
import 'function_type_annotation_test.dart' as function_type_annotation;
import 'library_export_test.dart' as library_export;
import 'library_fragment_test.dart' as library_fragment;
import 'library_import_test.dart' as library_import;
import 'library_test.dart' as library_;
import 'local_declarations_test.dart' as local_declarations;
import 'metadata_test.dart' as metadata;
import 'mixin_test.dart' as mixin_;
import 'non_synthetic_test.dart' as non_synthetic;
import 'offsets_test.dart' as offsets;
import 'part_include_test.dart' as part_include;
import 'record_type_test.dart' as record_type;
import 'since_sdk_version_test.dart' as since_sdk_version;
import 'top_level_function_test.dart' as top_level_function;
import 'top_level_variable_test.dart' as top_level_variable;
import 'type_alias_test.dart' as type_alias;
import 'type_inference_test.dart' as type_inference;
import 'types_test.dart' as types;

main() {
  defineReflectiveSuite(() {
    class_.main();
    const_.main();
    default_value.main();
    duplicate_declaration.main();
    enum_.main();
    extension_.main();
    extension_type.main();
    formal_parameter.main();
    function_type_annotation.main();
    library_export.main();
    library_fragment.main();
    library_import.main();
    library_.main();
    local_declarations.main();
    metadata.main();
    mixin_.main();
    non_synthetic.main();
    offsets.main();
    part_include.main();
    record_type.main();
    since_sdk_version.main();
    top_level_function.main();
    top_level_variable.main();
    type_alias.main();
    type_inference.main();
    types.main();
  }, name: 'elements');
}
