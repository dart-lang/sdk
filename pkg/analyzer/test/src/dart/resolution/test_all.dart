// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assignment_test.dart' as assignment_test;
import 'class_test.dart' as class_test;
import 'comment_test.dart' as comment_test;
import 'constant_test.dart' as constant_test;
import 'enum_test.dart' as enum_test;
import 'flow_analysis_test.dart' as flow_analysis_test;
import 'for_element_test.dart' as for_element_test;
import 'for_in_test.dart' as for_in_test;
import 'generic_type_alias_test.dart' as generic_type_alias_test;
import 'import_prefix_test.dart' as import_prefix_test;
import 'instance_creation_test.dart' as instance_creation_test;
import 'instance_member_inference_class_test.dart'
    as instance_member_inference_class_test;
import 'instance_member_inference_mixin_test.dart'
    as instance_member_inference_mixin_test;
import 'method_invocation_test.dart' as method_invocation_test;
import 'mixin_test.dart' as mixin_test;
import 'non_nullable_test.dart' as non_nullable_test;
import 'optional_const_test.dart' as optional_const_test;
import 'property_access_test.dart' as property_access_test;
import 'top_type_inference_test.dart' as top_type_inference_test;
import 'type_inference/test_all.dart' as type_inference;

main() {
  defineReflectiveSuite(() {
    assignment_test.main();
    class_test.main();
    comment_test.main();
    constant_test.main();
    enum_test.main();
    flow_analysis_test.main();
    for_element_test.main();
    for_in_test.main();
    generic_type_alias_test.main();
    import_prefix_test.main();
    instance_creation_test.main();
    instance_member_inference_class_test.main();
    instance_member_inference_mixin_test.main();
    method_invocation_test.main();
    mixin_test.main();
    non_nullable_test.main();
    optional_const_test.main();
    property_access_test.main();
    top_type_inference_test.main();
    type_inference.main();
  }, name: 'resolution');
}
