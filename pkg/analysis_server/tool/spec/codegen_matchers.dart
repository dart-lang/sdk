// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Code generation for the file "matchers.dart".
 */
library codegen.matchers;

import 'dart:convert';

import 'api.dart';
import 'codegen_tools.dart';
import 'from_html.dart';
import 'to_html.dart';

class CodegenMatchersVisitor extends HierarchicalApiVisitor with CodeGenerator {
  /**
   * Visitor used to produce doc comments.
   */
  final ToHtmlVisitor toHtmlVisitor;

  /**
   * Short human-readable string describing the context of the matcher being
   * created.
   */
  String context;

  CodegenMatchersVisitor(Api api)
      : super(api),
        toHtmlVisitor = new ToHtmlVisitor(api);

  /**
   * Create a matcher for the part of the API called [name], optionally
   * clarified by [nameSuffix].  The matcher should verify that its input
   * matches the given [type].
   */
  void makeMatcher(String name, String nameSuffix, TypeDecl type) {
    context = name;
    List<String> nameParts = ['is'];
    nameParts.addAll(name.split('.'));
    if (nameSuffix != null) {
      context += ' $nameSuffix';
      nameParts.add(nameSuffix);
    }
    docComment(toHtmlVisitor.collectHtml(() {
      toHtmlVisitor.p(() {
        toHtmlVisitor.write(context);
      });
      if (type != null) {
        toHtmlVisitor.showType(null, type);
      }
    }));
    write('final Matcher ${camelJoin(nameParts)} = ');
    if (type == null) {
      write('isNull');
    } else {
      visitTypeDecl(type);
    }
    writeln(';');
    writeln();
  }

  @override
  visitApi() {
    outputHeader();
    writeln();
    writeln('/**');
    writeln(' * Matchers for data types defined in the analysis server API');
    writeln(' */');
    writeln('library test.integration.protocol.matchers;');
    writeln();
    writeln("import 'package:unittest/unittest.dart';");
    writeln();
    writeln("import 'integration_tests.dart';");
    writeln();
    writeln();
    super.visitApi();
  }

  @override
  visitNotification(Notification notification) {
    makeMatcher(notification.longEvent, 'params', notification.params);
  }

  @override
  visitRequest(Request request) {
    makeMatcher(request.longMethod, 'params', request.params);
    makeMatcher(request.longMethod, 'result', request.result);
  }

  @override
  visitRefactoring(Refactoring refactoring) {
    String camelKind = camelJoin(refactoring.kind.toLowerCase().split('_'));
    makeMatcher(camelKind, 'feedback', refactoring.feedback);
    makeMatcher(camelKind, 'options', refactoring.options);
  }

  @override
  visitTypeDefinition(TypeDefinition typeDefinition) {
    makeMatcher(typeDefinition.name, null, typeDefinition.type);
  }

  @override
  visitTypeEnum(TypeEnum typeEnum) {
    writeln('new MatchesEnum(${JSON.encode(context)}, [');
    indent(() {
      bool commaNeeded = false;
      for (TypeEnumValue value in typeEnum.values) {
        if (commaNeeded) {
          writeln(',');
        }
        write('${JSON.encode(value.value)}');
        commaNeeded = true;
      }
      writeln();
    });
    write('])');
  }

  @override
  visitTypeList(TypeList typeList) {
    write('isListOf(');
    visitTypeDecl(typeList.itemType);
    write(')');
  }

  @override
  visitTypeMap(TypeMap typeMap) {
    write('isMapOf(');
    visitTypeDecl(typeMap.keyType);
    write(', ');
    visitTypeDecl(typeMap.valueType);
    write(')');
  }

  @override
  void visitTypeObject(TypeObject typeObject) {
    writeln('new MatchesJsonObject(');
    indent(() {
      write('${JSON.encode(context)}, ');
      Iterable<TypeObjectField> requiredFields = typeObject.fields.where(
          (TypeObjectField field) => !field.optional);
      outputObjectFields(requiredFields);
      List<TypeObjectField> optionalFields = typeObject.fields.where(
          (TypeObjectField field) => field.optional).toList();
      if (optionalFields.isNotEmpty) {
        write(', optionalFields: ');
        outputObjectFields(optionalFields);
      }
    });
    write(')');
  }

  /**
   * Generate a map describing the given set of fields, for use as the
   * 'requiredFields' or 'optionalFields' argument to the [MatchesJsonObject]
   * constructor.
   */
  void outputObjectFields(Iterable<TypeObjectField> fields) {
    if (fields.isEmpty) {
      write('null');
      return;
    }
    writeln('{');
    indent(() {
      bool commaNeeded = false;
      for (TypeObjectField field in fields) {
        if (commaNeeded) {
          writeln(',');
        }
        write('${JSON.encode(field.name)}: ');
        if (field.value != null) {
          write('equals(${JSON.encode(field.value)})');
        } else {
          visitTypeDecl(field.type);
        }
        commaNeeded = true;
      }
      writeln();
    });
    write('}');
  }

  @override
  void visitTypeReference(TypeReference typeReference) {
    write(camelJoin(['is', typeReference.typeName]));
  }

  @override
  void visitTypeUnion(TypeUnion typeUnion) {
    bool commaNeeded = false;
    write('isOneOf([');
    for (TypeDecl choice in typeUnion.choices) {
      if (commaNeeded) {
        write(', ');
      }
      visitTypeDecl(choice);
      commaNeeded = true;
    }
    write('])');
  }
}

final GeneratedFile target = new GeneratedFile(
    '../../test/integration/protocol_matchers.dart', () {
  CodegenMatchersVisitor visitor = new CodegenMatchersVisitor(readApi());
  return visitor.collectCode(visitor.visitApi);
});

/**
 * Translate spec_input.html into protocol_matchers.dart.
 */
main() {
  target.generate();
}
