// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analysis_server_client/protocol.dart' hide Element;
import 'package:analysis_server_client/server.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:collection/collection.dart';
import 'package:path/path.dart';

Future<void> main() async {
  await _Generator().generate();
}

class _Generator {
  late String newCode;
  late ClassElement parameterKindClass;
  late ClassElement currentClassElement;
  List<_ImplClass> implClasses = [];

  Future<void> generate() async {
    var astUnitResult = await _getAstResolvedUnit();

    newCode = astUnitResult.content;

    var utilitiesLibraryResult = await astUnitResult.session.getLibraryByUri(
      'package:analyzer/src/generated/utilities_dart.dart',
    );
    utilitiesLibraryResult as LibraryElementResult;
    parameterKindClass = utilitiesLibraryResult.element.getClass(
      'ParameterKind',
    )!;

    await _buildImplClasses(astUnitResult);
    _removeGeneratedMembers(astUnitResult);
    _generateAllClassMembers();

    var astPath = _getAstPath();
    newCode = await _formatSortCode(astPath, newCode);

    io.File(astPath).writeAsStringSync(newCode);
  }

  Future<_ImplClass?> _buildImplClass(ClassDeclarationImpl nodeImpl) async {
    var classElement = nodeImpl.declaredFragment!.element;
    var generateObject = classElement.metadata.annotations
        .map((annotation) {
          var generateObject = annotation.computeConstantValue();
          var generateObjectType = generateObject?.type;
          if (generateObjectType?.element?.name != 'GenerateNodeImpl') {
            return null;
          }
          return generateObject;
        })
        .nonNulls
        .firstOrNull;
    if (generateObject == null) {
      return null;
    }

    var entitiesField = generateObject.getField('childEntitiesOrder');
    if (entitiesField == null) {
      return null;
    }

    var entities = entitiesField.toListValue();
    if (entities == null) {
      return null;
    }

    currentClassElement = classElement;
    var interfaceElement = classElement.interfaces.last.element;

    var inheritanceManager = classElement.inheritanceManager;

    var properties = entities
        .map((entity) {
          var propertyName = entity.getField('name')!.toStringValue()!;
          var isSuper = entity.getField('isSuper')!.toBoolValue()!;
          var withOverride = entity.getField('withOverride')!.toBoolValue()!;
          var isNodeListFinal = entity
              .getField('isNodeListFinal')!
              .toBoolValue()!;
          var isTokenFinal = entity.getField('isTokenFinal')!.toBoolValue()!;
          var superNullAssertOverride = entity
              .getField('superNullAssertOverride')!
              .toBoolValue()!;
          var tokenGroupId = entity.getField('tokenGroupId')!.toIntValue();
          var type = entity.getField('type')!.toTypeValue();

          if (type == null) {
            var member = inheritanceManager.getMember(
              interfaceElement,
              Name(null, propertyName),
            );
            if (member case GetterElement getter) {
              type = getter.returnType;
            } else {
              throw StateError('$propertyName: ${member.runtimeType}');
            }
          }
          type as InterfaceType;

          var kind = _PropertyTypeKind.fromType(type);
          if (kind is _PropertyTypeKindNodeList) {
            kind.isWritable = !isNodeListFinal;
          }
          if (kind is _PropertyTypeKindToken) {
            kind.isWritable = !isTokenFinal;
            kind.groupId = tokenGroupId;
          }
          return _Property(
            name: propertyName,
            isSuper: isSuper,
            withOverride: withOverride,
            withOverrideSuperNotNull: superNullAssertOverride,
            type: type,
            typeKind: kind,
          );
        })
        .nonNulls
        .toList();

    return _ImplClass(
      node: nodeImpl,
      interfaceElement: interfaceElement,
      properties: properties,
      leftBracketOffset: nodeImpl.leftBracket.offset,
    );
  }

  Future<void> _buildImplClasses(ResolvedUnitResult astUnitResult) async {
    for (var nodeImpl in astUnitResult.unit.declarations) {
      if (nodeImpl is ClassDeclarationImpl) {
        var implClass = await _buildImplClass(nodeImpl);
        if (implClass != null) {
          implClasses.add(implClass);
        }
      }
    }
  }

  void _generateAccept(_ImplClass implClass, StringBuffer buffer) {
    buffer.write('''\n
  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
    visitor.visit${implClass.interfaceName}(this);
    ''');
  }

  void _generateAllClassMembers() {
    var replacements = <_Replacement>[];
    for (var implClass in implClasses) {
      var offset = implClass.leftBracketOffset + '{'.length;
      var code = _generateSingleClassMembers(implClass);
      replacements.add(_Replacement(offset, offset, code));
    }

    replacements.sort((a, b) => b.offset - a.offset);
    for (var replacement in replacements) {
      newCode =
          newCode.substring(0, replacement.offset) +
          replacement.text +
          newCode.substring(replacement.end);
    }
  }

  void _generateBeginToken(_ImplClass implClass, StringBuffer buffer) {
    if (implClass.isAnnotatedNodeSubclass) {
      if (implClass.doNotGenerateLookupNames.contains(
        'firstTokenAfterCommentAndMetadata',
      )) {
        return;
      }
      buffer.write('''\n
@generated
@override
Token get firstTokenAfterCommentAndMetadata {
''');
    } else {
      if (implClass.doNotGenerateLookupNames.contains('beginToken')) {
        return;
      }
      buffer.write('''\n
@generated
@override
Token get beginToken {
''');
    }

    var foundNonNullProperty = false;
    propertiesLoop:
    for (var i = 0; i < implClass.properties.length; i++) {
      var property = implClass.properties[i];
      if (property.typeKind case _PropertyTypeKindToken tokenKind) {
        if (tokenKind.groupId != null) {
          var groupProperties = <_Property>[];
          while (i < implClass.properties.length) {
            var groupProperty = implClass.properties[i++];
            if (groupProperty.typeKind case _PropertyTypeKindToken groupKind) {
              if (groupKind.groupId != tokenKind.groupId) {
                i -= 2;
                break;
              }
              groupProperties.add(groupProperty);
            } else {
              i -= 2;
              break;
            }
          }
          var names = groupProperties.map((p) => p.name).join(', ');
          buffer.write('''
if (Token.lexicallyFirst($names) case var result?) {
  return result;
}''');
          continue;
        }
      }

      switch (property.typeKind) {
        case _PropertyTypeKindToken():
          if (property.isNullable) {
            buffer.writeln(
              'if (${property.name} case var ${property.name}?) {',
            );
            buffer.write('return ${property.name};');
            buffer.writeln('}');
          } else {
            buffer.write('return ${property.name};');
            foundNonNullProperty = true;
            break propertiesLoop;
          }
        case _PropertyTypeKindTokenList():
          throw UnimplementedError();
        case _PropertyTypeKindNode():
          if (property.isNullable) {
            buffer.writeln(
              'if (${property.name} case var ${property.name}?) {',
            );
            buffer.write('return ${property.name}.beginToken;');
            buffer.writeln('}');
          } else {
            buffer.write('return ${property.name}.beginToken;');
            foundNonNullProperty = true;
            break propertiesLoop;
          }
        case _PropertyTypeKindNodeList():
          buffer.write('''
if (${property.name}.beginToken case var result?) {
  return result;
}''');
        case _PropertyTypeKindOther():
        // nothing
      }
    }

    if (!foundNonNullProperty) {
      buffer.writeln("throw StateError('Expected at least one non-null');");
    }

    buffer.write('}');
  }

  void _generateChildContainingRange(
    _ImplClass implClass,
    StringBuffer buffer,
  ) {
    if (implClass.doNotGenerateLookupNames.contains('_childContainingRange')) {
      return;
    }

    buffer.write('''
\n  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
''');

    if (implClass.isAnnotatedNodeSubclass) {
      buffer.write(r'''
if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
  return result;
}''');
    }

    for (var property in implClass.properties) {
      switch (property.typeKind) {
        case _PropertyTypeKindToken():
        case _PropertyTypeKindTokenList():
          break; // ignored
        case _PropertyTypeKindNode():
          var propertyName = property.name;
          if (property.isNullable) {
            buffer.write('''
if ($propertyName case var $propertyName?) {
  if ($propertyName._containsOffset(rangeOffset, rangeEnd)) {
    return $propertyName;
  }
}
''');
          } else {
            buffer.write('''
if ($propertyName._containsOffset(rangeOffset, rangeEnd)) {
  return $propertyName;
}
''');
          }
        case _PropertyTypeKindNodeList():
          var propertyName = property.name;
          var invocation = '_elementContainingRange(rangeOffset, rangeEnd)';
          buffer.write('''
if ($propertyName.$invocation case var result?) {
  return result;
}
''');
        case _PropertyTypeKindOther():
        // nothing
      }
    }

    buffer.write('''
  return null;
}
''');
  }

  void _generateChildEntities(_ImplClass implClass, StringBuffer buffer) {
    if (implClass.doNotGenerateLookupNames.contains('_childEntities')) {
      return;
    }

    buffer.write('''
\n@generated
@override
ChildEntities get _childEntities =>''');

    if (implClass.isAnnotatedNodeSubclass) {
      buffer.write('super._childEntities');
    } else {
      buffer.write('ChildEntities()');
    }

    for (var property in implClass.properties) {
      var propertyName = property.name;
      switch (property.typeKind) {
        case _PropertyTypeKindToken():
          buffer.write("\n..addToken('$propertyName', $propertyName)");
        case _PropertyTypeKindTokenList():
          buffer.write("\n..addTokenList('$propertyName', $propertyName)");
        case _PropertyTypeKindNode():
          buffer.write("\n..addNode('$propertyName', $propertyName)");
        case _PropertyTypeKindNodeList():
          buffer.write("\n..addNodeList('$propertyName', $propertyName)");
        case _PropertyTypeKindOther():
        // nothing
      }
    }

    buffer.writeln(';');
  }

  void _generateConstructor(_ImplClass implClass, StringBuffer buffer) {
    if (implClass.doNotGenerateLookupNames.contains('new')) {
      return;
    }

    buffer.write('''
\n@generated
    ${implClass.name}({
    ''');

    if (implClass.isAnnotatedNodeSubclass) {
      buffer.write(r'''
required super.comment,
required super.metadata,''');
    }

    for (var property in implClass.properties) {
      var propertyName = property.name;

      if (property.isSuper) {
        buffer.writeln('required super.$propertyName,');
        continue;
      }

      switch (property.typeKind) {
        case _PropertyTypeKindToken():
        case _PropertyTypeKindTokenList():
        case _PropertyTypeKindOther():
          buffer.writeln('required this.$propertyName,');
        case _PropertyTypeKindNode():
          var typeCode = property.typeCode;
          buffer.writeln('required $typeCode $propertyName,');
        case _PropertyTypeKindNodeList typeKind:
          var typeCode = 'List<${typeKind.elementTypeCode}>';
          buffer.writeln('required $typeCode $propertyName,');
      }
    }

    buffer.write('})');

    var isFirstFieldInitializer = true;
    for (var property in implClass.properties) {
      if (property.isSuper) {
        continue;
      }
      if (property.typeKind is _PropertyTypeKindNode) {
        if (isFirstFieldInitializer) {
          buffer.write(' : ');
        } else {
          buffer.write(',\n');
        }
        isFirstFieldInitializer = false;
        var propertyName = property.name;
        buffer.write('_$propertyName = $propertyName');
      }
    }

    buffer.writeln(' {');

    for (var property in implClass.properties) {
      if (property.isSuper) {
        continue;
      }
      switch (property.typeKind) {
        case _PropertyTypeKindToken():
        case _PropertyTypeKindTokenList():
        case _PropertyTypeKindOther():
          break; // nothing
        case _PropertyTypeKindNode():
          buffer.writeln('_becomeParentOf(${property.name});');
        case _PropertyTypeKindNodeList():
          var name = property.name;
          buffer.writeln('this.$name._initialize(this, $name);');
      }
    }

    buffer.writeln('}');

    // Remove empty block body with empty body.
    var bufferStr = buffer.toString();
    if (bufferStr.endsWith(' {\n}\n')) {
      buffer.clear();
      buffer.write(bufferStr.substring(0, bufferStr.length - 5));
      buffer.writeln(';');
    }
  }

  void _generateEndToken(_ImplClass implClass, StringBuffer buffer) {
    if (implClass.doNotGenerateLookupNames.contains('endToken')) {
      return;
    }

    buffer.write('''\n
@generated
@override
Token get endToken {
''');

    var foundNonNullProperty = false;
    propertiesLoop:
    for (var property in implClass.properties.reversed) {
      switch (property.typeKind) {
        case _PropertyTypeKindToken():
          if (property.isNullable) {
            buffer.writeln(
              'if (${property.name} case var ${property.name}?) {',
            );
            buffer.write('return ${property.name};');
            buffer.writeln('}');
          } else {
            buffer.write('return ${property.name};');
            foundNonNullProperty = true;
            break propertiesLoop;
          }
        case _PropertyTypeKindTokenList():
          var lastIndexStr = '${property.name}.length - 1';
          buffer.write('return ${property.name}[$lastIndexStr];');
          foundNonNullProperty = true;
          break propertiesLoop;
        case _PropertyTypeKindNode():
          if (property.isNullable) {
            buffer.writeln(
              'if (${property.name} case var ${property.name}?) {',
            );
            buffer.write('return ${property.name}.endToken;');
            buffer.writeln('}');
          } else {
            buffer.write('return ${property.name}.endToken;');
            foundNonNullProperty = true;
            break propertiesLoop;
          }
        case _PropertyTypeKindNodeList():
          buffer.write('''
if (${property.name}.endToken case var result?) {
  return result;
}''');
        case _PropertyTypeKindOther():
        // nothing
      }
    }

    if (!foundNonNullProperty) {
      buffer.writeln("throw StateError('Expected at least one non-null');");
    }

    buffer.write('}');
  }

  void _generateFields(_ImplClass implClass, StringBuffer buffer) {
    for (var property in implClass.properties) {
      var propertyName = property.name;

      if (property.isSuper) {
        continue;
      }

      switch (property.typeKind) {
        case _PropertyTypeKindToken kind:
          var maybeOverride = property.withOverride ? '@override' : '';
          var finalKeyword = kind.isWritable ? '' : 'final ';
          buffer.write('''
\n@generated
$maybeOverride
$finalKeyword ${property.typeCode} $propertyName;
''');
        case _PropertyTypeKindTokenList():
          buffer.write('''
\n@generated
@override
final ${property.typeCode} $propertyName;
''');
        case _PropertyTypeKindNode():
          var typeCode = property.typeCode;
          buffer.write('''
\n@generated
$typeCode _$propertyName;
''');
        case _PropertyTypeKindNodeList kind:
          var finalKeyword = kind.isWritable ? '' : 'final ';
          buffer.write('''
\n@generated
@override
$finalKeyword ${property.typeCode} $propertyName = NodeListImpl._();
''');
        case _PropertyTypeKindOther():
          buffer.write('''
\n@generated
@override
final ${property.typeCode} $propertyName;
''');
      }
    }
  }

  void _generateNodeGettersSetters(StringBuffer buffer, _ImplClass implClass) {
    for (var property in implClass.properties) {
      if (property.isSuper) {
        if (property.withOverrideSuperNotNull) {
          buffer.write('''
\n@generated
@override
${property.typeCode} get ${property.name} => super.${property.name}!;
''');
        }
        continue;
      }
      if (property.typeKind is _PropertyTypeKindNode) {
        var propertyName = property.name;
        var maybeOverride = property.withOverride ? '@override' : '';
        buffer.write('''
\n@generated
$maybeOverride
${property.typeCode} get $propertyName => _$propertyName;
    
@generated
set $propertyName(${property.typeCode} $propertyName) {
  _$propertyName = _becomeParentOf($propertyName);
}
''');
      }
    }
  }

  void _generateResolveExpression(_ImplClass implClass, StringBuffer buffer) {
    if (implClass.doNotGenerateLookupNames.contains('resolveExpression')) {
      return;
    }

    if (implClass.interfaceElement.isExpressionOrSubtype) {
      buffer.write('''
\n@generated
@override
void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
  resolver.visit${implClass.interfaceName}(this, contextType: contextType);
}''');
    }
  }

  String _generateSingleClassMembers(_ImplClass implClass) {
    var buffer = StringBuffer();
    _generateFields(implClass, buffer);
    _generateConstructor(implClass, buffer);
    _generateBeginToken(implClass, buffer);
    _generateEndToken(implClass, buffer);
    _generateNodeGettersSetters(buffer, implClass);
    _generateAccept(implClass, buffer);
    _generateChildContainingRange(implClass, buffer);
    _generateChildEntities(implClass, buffer);
    _generateResolveExpression(implClass, buffer);
    _generateVisitChildren(implClass, buffer);
    return buffer.toString();
  }

  void _generateVisitChildren(_ImplClass implClass, StringBuffer buffer) {
    if (implClass.doNotGenerateLookupNames.contains('visitChildren')) {
      return;
    }

    buffer.write('''
\n@generated
@override
void visitChildren(AstVisitor visitor) {''');

    if (implClass.isAnnotatedNodeSubclass) {
      buffer.write('super.visitChildren(visitor);');
    }

    for (var property in implClass.properties) {
      switch (property.typeKind) {
        case _PropertyTypeKindToken():
        case _PropertyTypeKindTokenList():
        case _PropertyTypeKindOther():
          break; // nothing
        case _PropertyTypeKindNode():
          var propertyName = property.name;
          var maybeQuestion = property.isNullable ? '?' : '';
          buffer.write('\n$propertyName$maybeQuestion.accept(visitor);');
        case _PropertyTypeKindNodeList():
          var propertyName = property.name;
          buffer.write('\n$propertyName.accept(visitor);');
      }
    }

    buffer.writeln('\n}');
  }

  String _getAstPath() {
    var analyzerPath = normalize(join(pkg_root.packageRoot, 'analyzer'));
    var analyzerLibPath = normalize(join(analyzerPath, 'lib'));
    var astPath = normalize(
      join(analyzerLibPath, 'src', 'dart', 'ast', 'ast.dart'),
    );
    return astPath;
  }

  Future<ResolvedUnitResult> _getAstResolvedUnit() async {
    var astPath = _getAstPath();
    var collection = AnalysisContextCollection(includedPaths: [astPath]);
    var analysisContext = collection.contextFor(astPath);
    var analysisSession = analysisContext.currentSession;
    var astUnitResult = await analysisSession.getResolvedUnit(astPath);
    return astUnitResult as ResolvedUnitResult;
  }

  void _removeGeneratedMembers(ResolvedUnitResult astUnitResult) {
    var replacements = <_Replacement>[];
    for (var implClass in implClasses) {
      for (var member in implClass.node.members) {
        String memberName;
        switch (member) {
          case ConstructorDeclarationImpl():
            var element = member.declaredFragment!.element;
            memberName = element.lookupName!;
            if (element.metadata.hasDoNotGenerate) {
              implClass.doNotGenerateLookupNames.add(memberName);
              continue;
            }
          case MethodDeclarationImpl():
            var element = member.declaredFragment!.element;
            memberName = element.lookupName!;
            if (element.metadata.hasDoNotGenerate) {
              implClass.doNotGenerateLookupNames.add(memberName);
              continue;
            }
          case FieldDeclarationImpl():
            var field = member.fields.variables.single;
            memberName = field.declaredFragment!.element.lookupName!;
        }
        if (implClass.generatedLookupNames.contains(memberName)) {
          replacements.add(_Replacement(member.offset, member.end, ''));
        }
      }
    }

    replacements.sort((a, b) => b.offset - a.offset);
    for (var replacement in replacements) {
      newCode =
          newCode.substring(0, replacement.offset) +
          replacement.text +
          newCode.substring(replacement.end);
      var oldLength = replacement.end - replacement.offset;
      var deltaOffset = oldLength - replacement.text.length;
      for (var implClass in implClasses.reversed) {
        if (implClass.leftBracketOffset > replacement.offset) {
          implClass.leftBracketOffset -= deltaOffset;
        } else {
          break;
        }
      }
    }
  }

  static Future<String> _formatSortCode(String path, String code) async {
    var server = Server();
    await server.start();
    server.listenToOutput();

    await server.send('analysis.setAnalysisRoots', {
      'included': [path],
      'excluded': [],
    });

    Future<void> updateContent() async {
      await server.send('analysis.updateContent', {
        'files': {
          path: {'type': 'add', 'content': code},
        },
      });
    }

    await updateContent();
    var formatResponse = await server.send('edit.format', {
      'file': path,
      'selectionOffset': 0,
      'selectionLength': code.length,
    });
    var formatResult = EditFormatResult.fromJson(
      ResponseDecoder(null),
      'result',
      formatResponse,
    );
    code = SourceEdit.applySequence(code, formatResult.edits);

    await updateContent();
    var sortResponse = await server.send('edit.sortMembers', {'file': path});
    var sortResult = EditSortMembersResult.fromJson(
      ResponseDecoder(null),
      'result',
      sortResponse,
    );
    code = SourceEdit.applySequence(code, sortResult.edit.edits);

    await server.kill();
    return code;
  }
}

class _ImplClass {
  final ClassDeclarationImpl node;
  final InterfaceElement interfaceElement;
  final List<_Property> properties;
  final Set<String> doNotGenerateLookupNames = {};
  int leftBracketOffset;

  late final Set<String> generatedLookupNames = () {
    var generatedLookupNames = {
      '_childContainingRange',
      '_childEntities',
      'accept',
      'beginToken',
      'endToken',
      'firstTokenAfterCommentAndMetadata',
      'new',
      'resolveExpression',
      'visitChildren',
    };
    for (var property in properties) {
      var propertyName = property.name;
      // We always have a getter.
      generatedLookupNames.add(propertyName);
      // For expressions we also have a field, and a setter.
      if (property.typeKind is _PropertyTypeKindNode) {
        generatedLookupNames.add('_$propertyName');
        generatedLookupNames.add('$propertyName=');
      }
    }
    return generatedLookupNames;
  }();

  _ImplClass({
    required this.node,
    required this.interfaceElement,
    required this.properties,
    required this.leftBracketOffset,
  });

  @deprecated
  bool get hasNotAbstractVisitChildren {
    var element = node.declaredFragment!.element;
    return element.inheritanceManager.getMember(
          element,
          Name(null, 'visitChildren'),
          forSuper: true,
        ) !=
        null;
  }

  String get interfaceName => interfaceElement.name!;

  bool get isAnnotatedNodeSubclass {
    var element = node.declaredFragment!.element;
    return element.allSupertypes.any(
      (type) => type.element.isAnnotatedNodeExactly,
    );
  }

  bool get isNamedCompilationUnitMemberSubclass {
    var element = node.declaredFragment!.element;
    return element.allSupertypes.any(
      (type) => type.element.isNamedCompilationUnitMemberNodeExactly,
    );
  }

  String get name {
    return node.name.lexeme;
  }
}

class _Property {
  final String name;
  final InterfaceType type;
  final _PropertyTypeKind typeKind;
  final bool isSuper;
  final bool withOverride;
  final bool withOverrideSuperNotNull;

  _Property({
    required this.name,
    required this.type,
    required this.typeKind,
    required this.isSuper,
    required this.withOverride,
    required this.withOverrideSuperNotNull,
  });

  bool get isNullable {
    return type.nullabilitySuffix == NullabilitySuffix.question;
  }

  String get typeCode {
    var nullSuffix = isNullable ? '?' : '';
    switch (typeKind) {
      case _PropertyTypeKindToken():
        return 'Token$nullSuffix';
      case _PropertyTypeKindTokenList():
        return 'List<Token>$nullSuffix';
      case _PropertyTypeKindNodeList typeKind:
        var elementTypeCode = typeKind.elementTypeCode;
        return 'NodeListImpl<$elementTypeCode>$nullSuffix';
      case _PropertyTypeKindOther():
        return type.asCode;
      default:
        return '${type.element.name!}Impl$nullSuffix';
    }
  }
}

sealed class _PropertyTypeKind {
  static _PropertyTypeKind fromType(DartType type) {
    if (type.isToken) {
      return _PropertyTypeKindToken();
    }
    if (type.isTokenListExactly) {
      return _PropertyTypeKindTokenList();
    }
    if (type.isNodeOrSubtype) {
      return _PropertyTypeKindNode();
    }
    if (type.isNodeListExactly) {
      type as InterfaceType;
      var elementType = type.typeArguments.single;
      return _PropertyTypeKindNodeList(
        elementType: elementType as InterfaceType,
      );
    }
    return _PropertyTypeKindOther();
  }
}

class _PropertyTypeKindNode extends _PropertyTypeKind {}

class _PropertyTypeKindNodeList extends _PropertyTypeKind {
  final InterfaceType elementType;
  bool isWritable = false;

  _PropertyTypeKindNodeList({required this.elementType});

  String get elementTypeCode {
    return '${elementType.element.name!}Impl';
  }
}

class _PropertyTypeKindOther extends _PropertyTypeKind {}

class _PropertyTypeKindToken extends _PropertyTypeKind {
  bool isWritable = false;
  int? groupId;
}

class _PropertyTypeKindTokenList extends _PropertyTypeKind {}

class _Replacement {
  final int offset;
  final int end;
  final String text;

  _Replacement(this.offset, this.end, this.text);
}

extension _DartTypeExtension on DartType {
  String get asCode {
    var nullSuffix = nullabilitySuffix == NullabilitySuffix.question ? '?' : '';
    switch (this) {
      case DynamicType():
        return 'dynamic';
      case InterfaceType self:
        var typeArguments = self.typeArguments;
        if (typeArguments.isEmpty) {
          return '${self.element.name!}$nullSuffix';
        } else {
          var typeArgumentsStr = typeArguments.map((t) => t.asCode).join(', ');
          return '${self.element.name}<$typeArgumentsStr>$nullSuffix';
        }
      case TypeParameterType self:
        return '${self.element.name!}$nullSuffix';
      case VoidType():
        return 'void';
      default:
        throw UnimplementedError('($runtimeType) $this');
    }
  }

  bool get isNodeListExactly {
    if (this case InterfaceType self) {
      return self.isNodeListExactly;
    }
    return false;
  }

  bool get isNodeOrSubtype {
    if (this case InterfaceType self) {
      return self.isNodeOrSubtype;
    }
    return false;
  }

  bool get isToken {
    if (this case InterfaceType self) {
      return self.isToken;
    }
    return false;
  }

  bool get isTokenListExactly {
    if (this case InterfaceType self) {
      return self.isTokenListExactly;
    }
    return false;
  }
}

extension _ElementAnnotationExtension on ElementAnnotation {
  bool get isDoNotGenerate {
    if (element case ConstructorElement constructorElement) {
      var interfaceElement = constructorElement.enclosingElement;
      return interfaceElement.isDoNotGenerateExactly;
    }
    return false;
  }
}

extension _InterfaceElementExtension on InterfaceElement {
  static final uriAst = Uri.parse('package:analyzer/src/dart/ast/ast.dart');
  static final uriToken = Uri.parse(
    'package:_fe_analyzer_shared/src/scanner/token.dart',
  );

  bool get isAnnotatedNodeExactly {
    return library.uri == uriAst && name == 'AnnotatedNode';
  }

  bool get isDoNotGenerateExactly {
    return library.uri == uriAst && name == 'DoNotGenerate';
  }

  bool get isExpressionExactly {
    return library.uri == uriAst && name == 'Expression';
  }

  bool get isExpressionOrSubtype {
    return isExpressionExactly ||
        allSupertypes.any((t) => t.isExpressionExactly);
  }

  bool get isListExactly {
    return library.uri == Uri.parse('dart:core') && name == 'List';
  }

  bool get isNamedCompilationUnitMemberNodeExactly {
    return library.uri == uriAst && name == 'NamedCompilationUnitMember';
  }

  bool get isNodeExactly {
    return library.uri == uriAst && name == 'AstNode';
  }

  bool get isNodeListExactly {
    return library.uri == uriAst && name == 'NodeList';
  }

  bool get isTokenExactly {
    return library.uri == uriToken && name == 'Token';
  }
}

extension _InterfaceTypeExtension on InterfaceType {
  bool get isExpressionExactly {
    return element.isExpressionExactly;
  }

  bool get isNodeExactly {
    return element.isNodeExactly;
  }

  bool get isNodeListExactly {
    return element.isNodeListExactly;
  }

  bool get isNodeOrSubtype {
    return isNodeExactly || allSupertypes.any((t) => t.isNodeExactly);
  }

  bool get isToken {
    return element.isTokenExactly;
  }

  bool get isTokenListExactly {
    return element.isListExactly &&
        typeArguments.length == 1 &&
        typeArguments.single.isToken;
  }
}

extension _MetadataExtension on Metadata {
  bool get hasDoNotGenerate {
    return annotations.any((annotation) => annotation.isDoNotGenerate);
  }
}
