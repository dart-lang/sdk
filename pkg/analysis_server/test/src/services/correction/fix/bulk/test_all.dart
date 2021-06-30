// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor_test.dart' as bulk_fix_processor;
import 'convert_to_is_not_test.dart' as convert_to_is_not;
import 'data_driven_test.dart' as data_driven;
import 'remove_type_annotation_test.dart' as remove_type_annotation;
import 'remove_unnecessary_const_test.dart' as remove_unnecessary_const;
import 'remove_unnecessary_new_test.dart' as remove_unnecessary_new;
import 'remove_unnecessary_string_interpolation_test.dart'
    as remove_unnecessary_string_interpolation;
import 'rename_to_camel_case_test.dart' as rename_to_camel_case;
import 'replace_colon_with_equals_test.dart' as replace_colon_with_equals;
import 'replace_final_with_const_test.dart' as replace_final_with_const;
import 'replace_new_with_const_test.dart' as replace_new_with_const;
import 'replace_null_with_closure_test.dart' as replace_null_with_closure;
import 'replace_with_conditional_assignment_test.dart'
    as replace_with_conditional_assignment;
import 'replace_with_is_empty_test.dart' as replace_with_is_empty;
import 'replace_with_tear_off_test.dart' as replace_with_tear_off;
import 'replace_with_var_test.dart' as replace_with_var;
import 'sort_child_properties_last_test.dart' as sort_child_properties_last;
import 'use_curly_braces_test.dart' as use_curly_braces;
import 'use_is_not_empty_test.dart' as use_is_not_empty;
import 'use_rethrow_test.dart' as use_rethrow;

void main() {
  defineReflectiveSuite(() {
    bulk_fix_processor.main();
    convert_to_is_not.main();
    data_driven.main();
    remove_type_annotation.main();
    remove_unnecessary_const.main();
    remove_unnecessary_new.main();
    remove_unnecessary_string_interpolation.main();
    rename_to_camel_case.main();
    replace_with_conditional_assignment.main();
    replace_colon_with_equals.main();
    replace_final_with_const.main();
    replace_new_with_const.main();
    replace_null_with_closure.main();
    replace_with_is_empty.main();
    replace_with_tear_off.main();
    replace_with_var.main();
    sort_child_properties_last.main();
    use_curly_braces.main();
    use_is_not_empty.main();
    use_rethrow.main();
  }, name: 'bulk');
}
