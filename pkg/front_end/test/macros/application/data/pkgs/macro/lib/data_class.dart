// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'dart:collection';

macro

class DataClass implements ClassDeclarationsMacro, ClassDefinitionMacro {
  const DataClass();

  FutureOr<void> buildDeclarationsForClass(IntrospectableClassDeclaration clazz,
      MemberDeclarationBuilder builder) async {
    Uri dartCore = Uri.parse('dart:core');
    Identifier objectIdentifier =
    await builder.resolveIdentifier(dartCore, 'Object');
    Identifier boolIdentifier =
    await builder.resolveIdentifier(dartCore, 'bool');
    Identifier intIdentifier =
    await builder.resolveIdentifier(dartCore, 'int');
    Identifier stringIdentifier =
    await builder.resolveIdentifier(dartCore, 'String');

    List<FieldDeclaration> fields = await builder.fieldsOf(clazz);
    List<Object> constructorParts = ['const ', clazz.identifier.name, '({'];
    String comma = '';
    for (FieldDeclaration field in fields) {
      constructorParts.addAll([comma, 'required this.', field.identifier]);
      comma = ', ';
    }
    constructorParts.add('});');
    builder.declareInType(new DeclarationCode.fromParts(constructorParts));

    builder.declareInType(new DeclarationCode.fromParts([
      'external ', intIdentifier, ' get hashCode;']));
    builder.declareInType(new DeclarationCode.fromParts([
      'external ',
      boolIdentifier,
      ' operator ==(',
      objectIdentifier,
      ' other);'
    ]));
    builder.declareInType(new DeclarationCode.fromParts([
      'external ', stringIdentifier, ' toString();']));
  }

  FutureOr<void> buildDefinitionForClass(IntrospectableClassDeclaration clazz,
      TypeDefinitionBuilder builder) async {
    Uri dartCore = Uri.parse('dart:core');
    Identifier identicalIdentifier =
    await builder.resolveIdentifier(dartCore, 'identical');

    List<FieldDeclaration> fields = await builder.fieldsOf(clazz);
    List<MethodDeclaration> methods = await builder.methodsOf(clazz);

    FunctionDefinitionBuilder hashCodeBuilder = await builder.buildMethod(
        methods
            .firstWhere((e) => e.identifier.name == 'hashCode')
            .identifier);
    FunctionDefinitionBuilder equalsBuilder = await builder.buildMethod(
        methods
            .firstWhere((e) => e.identifier.name == '==')
            .identifier);
    FunctionDefinitionBuilder toStringBuilder = await builder.buildMethod(
        methods
            .firstWhere((e) => e.identifier.name == 'toString')
            .identifier);

    List<Object> hashCodeParts = ['''{
    return '''
    ];

    List<Object> equalsParts = ['''{
    if (''', identicalIdentifier, '''(this, other)) return true;
    return other is ${clazz.identifier.name}'''
    ];

    List<Object> toStringParts = ['''{
    return "${clazz.identifier.name}('''
    ];

    bool first = true;
    for (FieldDeclaration field in fields) {
      if (!first) {
        hashCodeParts.add(' ^ ');
        toStringParts.add(',');
      }
      // TODO(johnniwinther): Generate different code for collection typed
      // fields.
      hashCodeParts.addAll([field.identifier, '.hashCode']);

      equalsParts.addAll(
          [' && ', field.identifier, ' == other.', field.identifier]);

      toStringParts.addAll(
          ['${field.identifier.name}=\${', field.identifier, '}']);

      first = false;
    }

    hashCodeParts.add(''';
  }''');

    equalsParts.add(''';
  }''');

    toStringParts.add(''')";
  }''');

    hashCodeBuilder.augment(new FunctionBodyCode.fromParts(hashCodeParts));
    equalsBuilder.augment(new FunctionBodyCode.fromParts(equalsParts));
    toStringBuilder.augment(new FunctionBodyCode.fromParts(toStringParts));
  }
}
