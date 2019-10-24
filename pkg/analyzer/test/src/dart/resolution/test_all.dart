// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assignment_test.dart' as assignment;
import 'ast_rewrite_test.dart' as ast_rewrite;
import 'class_alias_test.dart' as class_alias;
import 'class_test.dart' as class_resolution;
import 'comment_test.dart' as comment;
import 'constant_test.dart' as constant;
import 'constructor_test.dart' as constructor;
import 'enum_test.dart' as enum_resolution;
import 'export_test.dart' as export_;
import 'extension_method_test.dart' as extension_method;
import 'extension_override_test.dart' as extension_override;
import 'for_element_test.dart' as for_element;
import 'for_in_test.dart' as for_in;
import 'function_expression_invocation_test.dart'
    as function_expression_invocation;
import 'function_type_alias_test.dart' as function_type_alias;
import 'generic_function_type_test.dart' as generic_function_type;
import 'generic_type_alias_test.dart' as generic_type_alias;
import 'import_prefix_test.dart' as import_prefix;
import 'index_expression_test.dart' as index_expression;
import 'instance_creation_test.dart' as instance_creation;
import 'instance_member_inference_class_test.dart'
    as instance_member_inference_class;
import 'instance_member_inference_mixin_test.dart'
    as instance_member_inference_mixin;
import 'local_variable_test.dart' as local_variable;
import 'metadata_test.dart' as metadata;
import 'method_invocation_test.dart' as method_invocation;
import 'mixin_test.dart' as mixin_resolution;
import 'namespace_test.dart' as namespace;
import 'non_nullable_test.dart' as non_nullable;
import 'optional_const_test.dart' as optional_const;
import 'property_access_test.dart' as property_access;
import 'top_type_inference_test.dart' as top_type_inference;
import 'type_inference/test_all.dart' as type_inference;

main() {
  defineReflectiveSuite(() {
    assignment.main();
    ast_rewrite.main();
    class_alias.main();
    class_resolution.main();
    comment.main();
    constant.main();
    constructor.main();
    enum_resolution.main();
    export_.main();
    extension_method.main();
    extension_override.main();
    for_element.main();
    for_in.main();
    function_expression_invocation.main();
    function_type_alias.main();
    generic_function_type.main();
    generic_type_alias.main();
    import_prefix.main();
    index_expression.main();
    instance_creation.main();
    instance_member_inference_class.main();
    instance_member_inference_mixin.main();
    local_variable.main();
    metadata.main();
    method_invocation.main();
    mixin_resolution.main();
    namespace.main();
    non_nullable.main();
    optional_const.main();
    property_access.main();
    top_type_inference.main();
    type_inference.main();
  }, name: 'resolution');
}
