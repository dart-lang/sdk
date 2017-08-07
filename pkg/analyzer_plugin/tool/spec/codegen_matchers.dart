// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Code generation for the file "matchers.dart".
 */
import 'dart:convert';

import 'package:analyzer/src/codegen/tools.dart';

import 'api.dart';
import 'from_html.dart';
import 'implied_types.dart';
import 'to_html.dart';

final GeneratedFile target = new GeneratedFile(
    'test/integration/support/protocol_matchers.dart', (String pkgPath) {
  CodegenMatchersVisitor visitor = new CodegenMatchersVisitor(readApi(pkgPath));
  return visitor.collectCode(visitor.visitApi);
});

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
      : toHtmlVisitor = new ToHtmlVisitor(api),
        super(api) {
    codeGeneratorSettings.commentLineLength = 79;
    codeGeneratorSettings.languageName = 'dart';
  }

  /**
   * Create a matcher for the part of the API called [name], optionally
   * clarified by [nameSuffix].  The matcher should verify that its input
   * matches the given [type].
   */
  void makeMatcher(ImpliedType impliedType) {
    context = impliedType.humanReadableName;
    docComment(toHtmlVisitor.collectHtml(() {
      toHtmlVisitor.p(() {
        toHtmlVisitor.write(context);
      });
      if (impliedType.type != null) {
        toHtmlVisitor.showType(null, impliedType.type);
      }
    }));
    write('final Matcher ${camelJoin(['is', impliedType.camelName])} = ');
    if (impliedType.type == null) {
      write('isNull');
    } else {
      visitTypeDecl(impliedType.type);
    }
    writeln(';');
    writeln();
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
  visitApi() {
    outputHeader(year: '2017');
    writeln();
    writeln('/**');
    writeln(' * Matchers for data types defined in the analysis server API');
    writeln(' */');
    writeln("import 'package:test/test.dart';");
    writeln();
    writeln("import 'integration_tests.dart';");
    writeln();
    List<ImpliedType> impliedTypes = computeImpliedTypes(api).values.toList();
    impliedTypes.sort((ImpliedType first, ImpliedType second) =>
        first.camelName.compareTo(second.camelName));
    for (ImpliedType impliedType in impliedTypes) {
      makeMatcher(impliedType);
    }
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
    writeln('new LazyMatcher(() => new MatchesJsonObject(');
    indent(() {
      write('${JSON.encode(context)}, ');
      Iterable<TypeObjectField> requiredFields =
          typeObject.fields.where((TypeObjectField field) => !field.optional);
      outputObjectFields(requiredFields);
      List<TypeObjectField> optionalFields = typeObject.fields
          .where((TypeObjectField field) => field.optional)
          .toList();
      if (optionalFields.isNotEmpty) {
        write(', optionalFields: ');
        outputObjectFields(optionalFields);
      }
    });
    write('))');
  }

  @override
  void visitTypeReference(TypeReference typeReference) {
    String typeName = typeReference.typeName;
    if (typeName == 'long') {
      typeName = 'int';
    }
    write(camelJoin(['is', typeName]));
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
