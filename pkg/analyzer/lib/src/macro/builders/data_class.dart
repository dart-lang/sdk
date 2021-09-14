// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/macro/api/code.dart';
import 'package:analyzer/src/macro/api/macro.dart';

class AutoConstructorMacro implements ClassDeclarationMacro {
  const AutoConstructorMacro();

  @override
  void visitClassDeclaration(
    ast.ClassDeclaration node,
    ClassDeclarationBuilder builder,
  ) {
    // TODO(scheglov) Should we provide the element as a parameter?
    var classElement = node.declaredElement!;
    var typeSystem = classElement.library.typeSystem;

    if (classElement.unnamedConstructor != null) {
      throw ArgumentError(
        'Cannot generate a constructor because one already exists',
      );
    }

    var fieldsCode = classElement.fields.map((field) {
      var isNullable = typeSystem.isNullable(field.type);
      var requiredKeyword = isNullable ? '' : 'required ';
      return '${requiredKeyword}this.${field.name}';
    }).join(', ');

    // TODO(scheglov) super constructor

    builder.addToClass(
      Declaration('${classElement.name}({$fieldsCode});'),
    );
  }
}

class DataClassMacro implements ClassDeclarationMacro {
  const DataClassMacro();

  @override
  void visitClassDeclaration(
    ast.ClassDeclaration declaration,
    ClassDeclarationBuilder builder,
  ) {
    const AutoConstructorMacro().visitClassDeclaration(declaration, builder);
    const HashCodeMacro().visitClassDeclaration(declaration, builder);
    const ToStringMacro().visitClassDeclaration(declaration, builder);
  }
}

class HashCodeMacro implements ClassDeclarationMacro {
  const HashCodeMacro();

  @override
  void visitClassDeclaration(
    ast.ClassDeclaration node,
    ClassDeclarationBuilder builder,
  ) {
    var expression = node.declaredElement!.allFields
        .map((e) => '${e.name}.hashCode')
        .join(' ^ ');
    builder.addToClass(
      Declaration('''
  @override
  int get hashCode => $expression;
'''),
    );
  }
}

class ToStringMacro implements ClassDeclarationMacro {
  const ToStringMacro();

  @override
  void visitClassDeclaration(
    ast.ClassDeclaration node,
    ClassDeclarationBuilder builder,
  ) {
    var classElement = node.declaredElement!;
    var fieldsCode = classElement.allFields.map((field) {
      var name = field.name;
      return '$name: \$$name';
    }).join(', ');
    builder.addToClass(
      Declaration('''
  @override
  String toString() => '${classElement.name}($fieldsCode)';
'''),
    );
  }
}

extension on ClassElement {
  Iterable<FieldElement> get allFields sync* {
    for (ClassElement? class_ = this; class_ != null;) {
      yield* class_.fields.where((e) => !e.isSynthetic);
      class_ = class_.supertype?.element;
    }
  }
}
