// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'class_member_test.dart' as class_member;
import 'class_test.dart' as class_;
import 'closure_test.dart' as closure;
import 'constructor_test.dart' as constructor_;
import 'documentation_test.dart' as documentation;
import 'enum_test.dart' as enum_;
import 'extension_member_test.dart' as extension_member;
import 'imported_reference_test.dart' as imported_reference;
import 'label_test.dart' as label;
import 'library_member_test.dart' as library_member;
import 'library_prefix_test.dart' as library_prefix;
import 'library_test.dart' as library_;
import 'local_library_test.dart' as local_library;
import 'local_reference_test.dart' as local_reference;
import 'pattern_variable_test.dart' as pattern_variable;
import 'record_type_test.dart' as record_type;
import 'type_member_test.dart' as type_member;
import 'uri_test.dart' as uri;
import 'variable_name_test.dart' as variable_name;

/// Tests suggestions produced for various kinds of declarations.
void main() {
  defineReflectiveSuite(() {
    class_member.main();
    class_.main();
    closure.main();
    constructor_.main();
    documentation.main();
    enum_.main();
    extension_member.main();
    imported_reference.main();
    label.main();
    library_member.main();
    library_prefix.main();
    library_.main();
    local_library.main();
    local_reference.main();
    pattern_variable.main();
    record_type.main();
    type_member.main();
    uri.main();
    variable_name.main();
  });
}
