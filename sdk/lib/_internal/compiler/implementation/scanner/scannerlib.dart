// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library scanner;

import 'dart:collection' show IterableBase, HashSet;

import '../dart_types.dart' show DynamicType;
import '../elements/elements.dart';

import '../elements/modelx.dart' show
    ClassElementX,
    ConstructorElementX,
    DeclarationSite,
    ElementX,
    FieldElementX,
    FunctionElementX,
    MetadataAnnotationX,
    MixinApplicationElementX,
    TypedefElementX,
    VariableElementX,
    VariableList;

import '../elements/visitor.dart'
    show ElementVisitor;
import '../dart2jslib.dart';
import '../native_handler.dart' as native;
import '../string_validator.dart';
import '../tree/tree.dart';
import '../util/characters.dart';
import '../util/util.dart';
import '../source_file.dart' show SourceFile, Utf8BytesSourceFile;
import 'dart:convert' show UTF8, UNICODE_BOM_CHARACTER_RUNE;
import 'dart:typed_data' show Uint8List;

part 'class_element_parser.dart';
part 'keyword.dart';
part 'listener.dart';
part 'parser.dart';
part 'parser_task.dart';
part 'partial_parser.dart';
part 'scanner.dart';
part 'scanner_task.dart';
part 'array_based_scanner.dart';
part 'utf8_bytes_scanner.dart';
part 'string_scanner.dart';
part 'token.dart';
