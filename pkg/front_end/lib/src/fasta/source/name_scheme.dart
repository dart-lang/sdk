// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../kernel/late_lowering.dart' as late_lowering;

enum FieldNameType { Field, Getter, Setter, IsSetField }

class NameScheme {
  final bool isInstanceMember;
  final String? className;
  final bool isExtensionMember;
  final String? extensionName;
  final Reference? libraryReference;

  NameScheme(
      {required this.isInstanceMember,
      required this.className,
      required this.isExtensionMember,
      required this.extensionName,
      required this.libraryReference})
      // ignore: unnecessary_null_comparison
      : assert(isInstanceMember != null),
        // ignore: unnecessary_null_comparison
        assert(isExtensionMember != null),
        // ignore: unnecessary_null_comparison
        assert(!isExtensionMember || extensionName != null),
        // ignore: unnecessary_null_comparison
        assert(libraryReference != null);

  bool get isStatic => !isInstanceMember;

  Name getFieldName(FieldNameType type, String name,
      {required bool isSynthesized}) {
    // ignore: unnecessary_null_comparison
    assert(isSynthesized != null);
    String text = createFieldName(type, name,
        isInstanceMember: isInstanceMember,
        className: className,
        isExtensionMethod: isExtensionMember,
        extensionName: extensionName,
        isSynthesized: isSynthesized);
    return new Name.byReference(text, libraryReference);
  }

  static String createFieldName(FieldNameType type, String name,
      {required bool isInstanceMember,
      required String? className,
      bool isExtensionMethod: false,
      String? extensionName,
      bool isSynthesized: false}) {
    assert(isSynthesized || type == FieldNameType.Field,
        "Unexpected field name type for non-synthesized field: $type");
    // ignore: unnecessary_null_comparison
    assert(isExtensionMethod || isInstanceMember != null,
        "`isInstanceMember` is null for class member.");
    assert(!(isExtensionMethod && extensionName == null),
        "No extension name provided for extension member.");
    // ignore: unnecessary_null_comparison
    assert(isInstanceMember == null || !(isInstanceMember && className == null),
        "No class name provided for instance member.");
    String baseName;
    if (!isExtensionMethod) {
      baseName = name;
    } else {
      baseName = "${extensionName}|${name}";
    }

    if (!isSynthesized) {
      return baseName;
    } else {
      String namePrefix = late_lowering.lateFieldPrefix;
      if (isInstanceMember) {
        namePrefix = '$namePrefix${className}#';
      }
      switch (type) {
        case FieldNameType.Field:
          return "$namePrefix$baseName";
        case FieldNameType.Getter:
          return baseName;
        case FieldNameType.Setter:
          return baseName;
        case FieldNameType.IsSetField:
          return "$namePrefix$baseName${late_lowering.lateIsSetSuffix}";
      }
    }
  }

  Name getProcedureName(ProcedureKind kind, String name) {
    // ignore: unnecessary_null_comparison
    assert(kind != null);
    return new Name.byReference(
        createProcedureName(
            isExtensionMethod: isExtensionMember,
            isStatic: isStatic,
            kind: kind,
            extensionName: extensionName,
            name: name),
        libraryReference);
  }

  static String createProcedureName(
      {required bool isExtensionMethod,
      required bool isStatic,
      required ProcedureKind kind,
      String? extensionName,
      required String name}) {
    if (isExtensionMethod) {
      assert(extensionName != null);
      String kindInfix = '';
      if (!isStatic) {
        // Instance getter and setter are converted to methods so we use an
        // infix to make their names unique.
        switch (kind) {
          case ProcedureKind.Getter:
            kindInfix = 'get#';
            break;
          case ProcedureKind.Setter:
            kindInfix = 'set#';
            break;
          case ProcedureKind.Method:
          case ProcedureKind.Operator:
            kindInfix = '';
            break;
          case ProcedureKind.Factory:
            throw new UnsupportedError(
                'Unexpected extension method kind ${kind}');
        }
      }
      return '${extensionName}|${kindInfix}${name}';
    } else {
      return name;
    }
  }
}
