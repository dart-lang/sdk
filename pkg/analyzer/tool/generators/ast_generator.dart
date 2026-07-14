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
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:collection/collection.dart';
import 'package:path/path.dart';

Future<void> main() async {
  var generator = AstNodeImplGenerator();
  var code = await generator.generate();
  io.File(generator.astPath).writeAsStringSync(code);
}

const _astVersionPolicy = _AstVersionPolicy.v2MigrationSdk;

class AstNodeImplGenerator {
  late String newCode;
  late ClassElement parameterKindClass;
  late ClassElement currentClassElement;
  List<_ImplClass> implClasses = [];

  String get astPath {
    var analyzerPath = normalize(join(pkg_root.packageRoot, 'analyzer'));
    var analyzerLibPath = normalize(join(analyzerPath, 'lib'));
    return normalize(join(analyzerLibPath, 'src', 'dart', 'ast', 'ast.dart'));
  }

  Future<String> generate() async {
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

    newCode = await _formatSortCode(astPath, newCode);
    return newCode;
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

    var api = _AstNodeApi.values.byName(
      generateObject.getField('api')!.variable!.name!,
    );

    currentClassElement = classElement;
    var interfaceElement = classElement.interfaces.last.element;

    var inheritanceManager = classElement.inheritanceManager;
    GetterElement lookupInterfaceGetter(String propertyName) {
      var member = inheritanceManager.getMember(
        interfaceElement,
        Name(null, propertyName),
      );
      if (member case GetterElement getter) {
        return getter;
      }
      throw StateError(
        '${interfaceElement.name}.$propertyName: expected a public getter, '
        'but found ${member.runtimeType}.',
      );
    }

    var properties = entities
        .map((entity) {
          var propertyName = entity.getField('name')!.toStringValue()!;
          var v1Name = entity.getField('v1Name')!.toStringValue();
          var v1Projection = _V1ProjectionKind.values.byName(
            entity.getField('v1Projection')!.variable!.name!,
          );
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
          var isInValueExpressionSlot = entity
              .getField('isInValueExpressionSlot')!
              .toBoolValue()!;

          type ??= lookupInterfaceGetter(propertyName).returnType;
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
            v1Name: v1Name,
            v1Projection: v1Projection,
            isSuper: isSuper,
            isInValueExpressionSlot: isInValueExpressionSlot,
            withOverride: withOverride,
            withOverrideSuperNotNull: superNullAssertOverride,
            type: type,
            typeKind: kind,
          );
        })
        .nonNulls
        .toList();

    for (var property in properties) {
      if (property.v1Name case var v1Name?) {
        if (!_astVersionPolicy.hasV1Projection) {
          throw StateError(
            '${interfaceElement.name}.${property.name}: v1Name is only '
            'supported during an active V2 migration.',
          );
        }
        _astVersionPolicy.validateV2Api(
          getter: lookupInterfaceGetter(property.name),
          interfaceName: interfaceElement.name!,
          v2Name: property.name,
        );
        _astVersionPolicy.validateV1Api(
          getter: lookupInterfaceGetter(v1Name),
          interfaceName: interfaceElement.name!,
          v1Name: v1Name,
          v2Name: property.name,
        );
      }
    }

    var nodeBody = nodeImpl.body as BlockClassBodyImpl;
    return _ImplClass(
      node: nodeImpl,
      api: api,
      interfaceElement: interfaceElement,
      properties: properties,
      leftBracketOffset: nodeBody.leftBracket.offset,
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
    if (implClass.doNotGenerateLookupNames.contains('accept')) {
      return;
    }
    if (!implClass.api.hasV1View) {
      buffer.write('''\n
  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) {
    throw StateError('${implClass.interfaceName} is not in the V1 AST view.');
  }
    ''');
      return;
    }
    buffer.write('''\n
  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
    visitor.visit${implClass.interfaceName}(this);
    ''');
  }

  void _generateAccept2(_ImplClass implClass, StringBuffer buffer) {
    if (implClass.doNotGenerateLookupNames.contains('accept2')) {
      return;
    }
    if (!implClass.api.hasV2View) {
      buffer.write('''\n
  @generated
  @experimental
  @override
  E? accept2<E>(AstVisitor2<E> visitor) {
    throw StateError('${implClass.interfaceName} is not in the V2 AST view.');
  }
    ''');
      return;
    }
    buffer.write('''\n
  @generated
  @experimental
  @override
  E? accept2<E>(AstVisitor2<E> visitor) =>
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

  void _generateAstNodeApi(_ImplClass implClass, StringBuffer buffer) {
    if (implClass.api == _AstNodeApi.shared) {
      return;
    }
    buffer.write('''
\n@generated
@override
AstNodeApi get _astNodeApi => AstNodeApi.${implClass.api.name};
''');
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
          buffer.write('return ${property.name}.first;');
          foundNonNullProperty = true;
          break propertiesLoop;
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
    if (implClass.api.hasV1View) {
      _generateChildContainingRangeCode(
        implClass,
        buffer,
        methodName: '_childContainingRange',
        propertyNameFor: (property) => property.v1ViewName,
      );
    } else {
      buffer.write('''
\n@generated
@override
AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
  throw StateError('${implClass.interfaceName} is not in the V1 AST view.');
}
''');
    }
  }

  void _generateChildContainingRange2(
    _ImplClass implClass,
    StringBuffer buffer,
  ) {
    if (implClass.doNotGenerateLookupNames.contains('_childContainingRange2')) {
      return;
    }
    if (implClass.api.hasV2View) {
      _generateChildContainingRangeCode(
        implClass,
        buffer,
        methodName: '_childContainingRange2',
        propertyNameFor: (property) => property.name,
      );
    } else {
      buffer.write('''
\n@generated
@override
AstNodeImpl? _childContainingRange2(int rangeOffset, int rangeEnd) {
  throw StateError('${implClass.interfaceName} is not in the V2 AST view.');
}
''');
    }
  }

  void _generateChildContainingRangeCode(
    _ImplClass implClass,
    StringBuffer buffer, {
    required String methodName,
    required String Function(_Property property) propertyNameFor,
  }) {
    buffer.write('''
\n  @generated
  @override
  AstNodeImpl? $methodName(int rangeOffset, int rangeEnd) {
''');

    if (implClass.isAnnotatedNodeSubclass) {
      buffer.write('''
if (super.$methodName(rangeOffset, rangeEnd) case var result?) {
  return result;
}''');
    }

    for (var property in implClass.properties) {
      switch (property.typeKind) {
        case _PropertyTypeKindToken():
        case _PropertyTypeKindTokenList():
          break; // ignored
        case _PropertyTypeKindNode():
          var propertyName = propertyNameFor(property);
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
          var propertyName = propertyNameFor(property);
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
    if (!implClass.api.hasV1View) {
      _generateThrowingChildEntities(
        implClass,
        buffer,
        methodName: '_childEntities',
        viewName: 'V1',
      );
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
      var propertyName = property.v1ViewName;
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

  void _generateChildEntities2(_ImplClass implClass, StringBuffer buffer) {
    if (implClass.doNotGenerateLookupNames.contains('_childEntities2')) {
      return;
    }
    if (!implClass.api.hasV2View) {
      _generateThrowingChildEntities(
        implClass,
        buffer,
        methodName: '_childEntities2',
        viewName: 'V2',
      );
      return;
    }

    buffer.write('''
\n@generated
@override
ChildEntities get _childEntities2 =>''');

    if (implClass.isAnnotatedNodeSubclass) {
      buffer.write('super._childEntities2');
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

    var becomeParentMethod = implClass.api.becomeParentMethod;
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
          buffer.writeln('$becomeParentMethod(${property.name});');
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
      var propertyName = property.name;
      if (implClass.doNotGenerateLookupNames.contains(propertyName)) {
        continue;
      }

      switch (property.typeKind) {
        case _PropertyTypeKindToken():
          if (property.isNullable) {
            buffer.writeln('if ($propertyName case var $propertyName?) {');
            buffer.write('return $propertyName;');
            buffer.writeln('}');
          } else {
            buffer.write('return $propertyName;');
            foundNonNullProperty = true;
            break propertiesLoop;
          }
        case _PropertyTypeKindTokenList():
          var lastIndexStr = '$propertyName.length - 1';
          buffer.write('return $propertyName[$lastIndexStr];');
          foundNonNullProperty = true;
          break propertiesLoop;
        case _PropertyTypeKindNode():
          if (property.isNullable) {
            buffer.writeln('if ($propertyName case var $propertyName?) {');
            buffer.write('return $propertyName.endToken;');
            buffer.writeln('}');
          } else {
            buffer.write('return $propertyName.endToken;');
            foundNonNullProperty = true;
            break propertiesLoop;
          }
        case _PropertyTypeKindNodeList():
          buffer.write('''
if ($propertyName.endToken case var result?) {
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

      if (implClass.doNotGenerateLookupNames.contains(propertyName)) {
        continue;
      }

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
          var maybeOverride = property.withOverride ? '@override' : '';
          buffer.write('''
\n@generated
$maybeOverride
final ${property.typeCode} $propertyName;
''');
        case _PropertyTypeKindNode():
          var typeCode = property.typeCode;
          buffer.write('''
\n@generated
$typeCode _$propertyName;
''');
        case _PropertyTypeKindNodeList kind:
          var maybeOverride = property.withOverride ? '@override' : '';
          var finalKeyword = kind.isWritable ? '' : 'final ';
          var v2ApiAnnotations = property.v2MigrationAnnotations;
          buffer.write('''
\n@generated
$v2ApiAnnotations
$maybeOverride
$finalKeyword ${property.typeCode} $propertyName = NodeListImpl._();
''');
          if (property.v1Name case var v1Name?) {
            if (!implClass.doNotGenerateLookupNames.contains(v1Name)) {
              var v1ApiAnnotations = property.v1MigrationAnnotations;
              buffer.write('''
\n@generated
$v1ApiAnnotations
@override
late final ${property.typeCode} $v1Name = _V1ProjectedNodeListImpl(
  $propertyName,
  ${property.v1ProjectionMethod},
);
''');
            }
          }
        case _PropertyTypeKindOther():
          var maybeOverride = property.withOverride ? '@override' : '';
          buffer.write('''
\n@generated
$maybeOverride
final ${property.typeCode} $propertyName;
''');
      }
    }
  }

  void _generateIsInValueExpressionSlot(
    _ImplClass implClass,
    StringBuffer buffer,
  ) {
    if (implClass.doNotGenerateLookupNames.contains(
      'isInValueExpressionSlot',
    )) {
      return;
    }

    var valueNodeOrListProperties = implClass.nodeOrListProperties
        .where((property) => property.isInValueExpressionSlot)
        .toList();

    var nonValueNodeOrListProperties = implClass.nodeOrListProperties
        .where((property) => !property.isInValueExpressionSlot)
        .toList();

    if (valueNodeOrListProperties.isEmpty) {
      buffer.write('''
\n@generated
@override
bool isInValueExpressionSlot(AstNode child) {
  assert(identical(child.parent2, this));
  return false;
}
''');
      return;
    }

    if (nonValueNodeOrListProperties.isEmpty) {
      buffer.write('''
\n@generated
@override
bool isInValueExpressionSlot(AstNode child) {
  assert(identical(child.parent2, this));
  return true;
}
''');
      return;
    }

    buffer.write('''
\n@generated
@override
bool isInValueExpressionSlot(AstNode child) {
  assert(identical(child.parent2, this));
''');

    String returnValue;
    if (valueNodeOrListProperties.any(
      (property) => property.typeKind is _PropertyTypeKindNodeList,
    )) {
      returnValue = nonValueNodeOrListProperties
          .map((property) {
            var propertyName = property.name;
            switch (property.typeKind) {
              case _PropertyTypeKindNode():
                return '!identical($propertyName, child)';
              case _PropertyTypeKindNodeList():
                throw StateError('Cannot have both value and non-value lists.');
              default:
                throw StateError('Unexpected: $propertyName');
            }
          })
          .join(' && ');
    } else {
      returnValue = valueNodeOrListProperties
          .map((property) {
            var propertyName = property.name;
            switch (property.typeKind) {
              case _PropertyTypeKindNode():
                return 'identical($propertyName, child)';
              default:
                throw StateError('Unexpected: $propertyName');
            }
          })
          .join(' || ');
    }
    buffer.write('return $returnValue;\n}');
  }

  void _generateNodeGettersSetters(StringBuffer buffer, _ImplClass implClass) {
    for (var property in implClass.properties) {
      var propertyName = property.name;
      if (implClass.doNotGenerateLookupNames.contains(propertyName)) {
        continue;
      }
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
        var maybeOverride = property.withOverride ? '@override' : '';
        var v2ApiAnnotations = property.v2MigrationAnnotations;
        buffer.write('''
\n@generated
$v2ApiAnnotations
$maybeOverride
${property.typeCode} get $propertyName => _$propertyName;
''');
        var setterAnnotations = property.v2MigrationAnnotations;
        var becomeParentMethod = implClass.api.becomeParentMethod;
        buffer.write('''
\n@generated
$setterAnnotations
set $propertyName(${property.typeCode} $propertyName) {
  _$propertyName = $becomeParentMethod($propertyName);
}
''');
        if (property.v1Name case var v1Name?) {
          if (!implClass.doNotGenerateLookupNames.contains(v1Name)) {
            var projectedValue = property.projectToV1Code(propertyName);
            var v1ApiAnnotations = property.v1MigrationAnnotations;
            buffer.write('''
\n@generated
$v1ApiAnnotations
@override
${property.typeCode} get $v1Name => $projectedValue;
''');
          }
        }
      }
    }
  }

  void _generateRemoveChild(_ImplClass implClass, StringBuffer buffer) {
    if (implClass.doNotGenerateLookupNames.contains('removeChild')) {
      return;
    }

    if (implClass.nodeOrListProperties.isEmpty) {
      return;
    }

    buffer.write('''
\n@generated
@override
void removeChild(AstNodeImpl oldNode) {
''');

    for (var property in implClass.nodeOrListProperties) {
      var propertyName = property.name;
      switch (property.typeKind) {
        case _PropertyTypeKindNode():
          buffer.write('''
if (identical($propertyName, oldNode)) {
''');
          if (!property.isNullable) {
            buffer.write('''
  throw UnsupportedError("Cannot remove required child '$propertyName'.");
}
''');
          } else {
            buffer.write('''
  $propertyName = null;
  return;
}
''');
          }
        case _PropertyTypeKindNodeList():
          buffer.write('''
if ($propertyName.containsChild(oldNode)) {
  throw UnsupportedError(
    "Cannot remove child '$propertyName' because NodeList cannot be resized.",
  );
}
''');
        default:
          throw StateError('Unexpected: $propertyName');
      }
    }

    buffer.write('''
  super.removeChild(oldNode);
}
''');
  }

  void _generateReplaceChild(_ImplClass implClass, StringBuffer buffer) {
    if (implClass.doNotGenerateLookupNames.contains('replaceChild')) {
      return;
    }

    if (implClass.nodeOrListProperties.isEmpty) {
      return;
    }

    buffer.write('''
\n@generated
@override
void replaceChild(AstNodeImpl oldNode, AstNodeImpl newNode) {
''');

    for (var property in implClass.nodeOrListProperties) {
      var propertyName = property.name;
      switch (property.typeKind) {
        case _PropertyTypeKindNode():
          var typeCode = property.typeCode;
          buffer.write('''
if (identical($propertyName, oldNode)) {
  $propertyName = newNode as $typeCode;
  return;
}
''');
        case _PropertyTypeKindNodeList():
          buffer.write('''
if ($propertyName.replaceChild(oldNode, newNode)) {
  return;
}
''');
        default:
          throw StateError('Unexpected: $propertyName');
      }
    }

    buffer.write('''
  super.replaceChild(oldNode, newNode);
}
''');
  }

  void _generateResolveExpression(_ImplClass implClass, StringBuffer buffer) {
    if (implClass.doNotGenerateLookupNames.contains('resolveExpression')) {
      return;
    }
    if (!implClass.api.hasV1View) {
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
    _generateAstNodeApi(implClass, buffer);
    _generateFields(implClass, buffer);
    _generateConstructor(implClass, buffer);
    _generateBeginToken(implClass, buffer);
    _generateEndToken(implClass, buffer);
    _generateNodeGettersSetters(buffer, implClass);
    _generateAccept(implClass, buffer);
    _generateAccept2(implClass, buffer);
    _generateChildContainingRange(implClass, buffer);
    _generateChildContainingRange2(implClass, buffer);
    _generateChildEntities(implClass, buffer);
    _generateChildEntities2(implClass, buffer);
    _generateIsInValueExpressionSlot(implClass, buffer);
    _generateRemoveChild(implClass, buffer);
    _generateReplaceChild(implClass, buffer);
    _generateResolveExpression(implClass, buffer);
    _generateVisitChildren(implClass, buffer);
    _generateVisitChildren2(implClass, buffer);
    _generateVisitChildrenWithHooks(implClass, buffer);
    return buffer.toString();
  }

  void _generateThrowingChildEntities(
    _ImplClass implClass,
    StringBuffer buffer, {
    required String methodName,
    required String viewName,
  }) {
    if (implClass.doNotGenerateLookupNames.contains(methodName)) {
      return;
    }
    buffer.write('''
\n@generated
@override
ChildEntities get $methodName {
  throw StateError('${implClass.interfaceName} is not in the $viewName AST view.');
}
''');
  }

  void _generateThrowingVisitChildren(
    _ImplClass implClass,
    StringBuffer buffer, {
    required String methodName,
    required String visitorType,
    required String viewName,
  }) {
    if (implClass.doNotGenerateLookupNames.contains(methodName)) {
      return;
    }
    var experimental = visitorType == 'AstVisitor2' ? '@experimental\n' : '';
    buffer.write('''
\n@generated
$experimental@override
void $methodName($visitorType visitor) {
  throw StateError('${implClass.interfaceName} is not in the $viewName AST view.');
}
''');
  }

  void _generateVisitChildren(_ImplClass implClass, StringBuffer buffer) {
    if (implClass.doNotGenerateLookupNames.contains('visitChildren')) {
      return;
    }
    if (!implClass.api.hasV1View) {
      _generateThrowingVisitChildren(
        implClass,
        buffer,
        methodName: 'visitChildren',
        visitorType: 'AstVisitor',
        viewName: 'V1',
      );
      return;
    }

    buffer.write('''
\n@generated
@override
void visitChildren(AstVisitor visitor) {''');

    if (implClass.isAnnotatedNodeSubclass) {
      buffer.write('_visitCommentAndAnnotations(visitor);');
    }

    for (var property in implClass.properties) {
      switch (property.typeKind) {
        case _PropertyTypeKindToken():
        case _PropertyTypeKindTokenList():
        case _PropertyTypeKindOther():
          break; // nothing
        case _PropertyTypeKindNode():
          var propertyName = property.v1ViewName;
          var maybeQuestion = property.isNullable ? '?' : '';
          buffer.write('\n$propertyName$maybeQuestion.accept(visitor);');
        case _PropertyTypeKindNodeList():
          var propertyName = property.v1ViewName;
          buffer.write('\n$propertyName.accept(visitor);');
      }
    }

    buffer.writeln('\n}');
  }

  void _generateVisitChildren2(_ImplClass implClass, StringBuffer buffer) {
    if (implClass.doNotGenerateLookupNames.contains('visitChildren2')) {
      return;
    }

    if (!implClass.api.hasV2View) {
      _generateThrowingVisitChildren(
        implClass,
        buffer,
        methodName: 'visitChildren2',
        visitorType: 'AstVisitor2',
        viewName: 'V2',
      );
      return;
    }

    buffer.write('''
\n@generated
@experimental
@override
void visitChildren2(AstVisitor2 visitor) {''');

    if (implClass.isAnnotatedNodeSubclass) {
      buffer.write('_visitCommentAndAnnotations2(visitor);');
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
          buffer.write('\n$propertyName$maybeQuestion.accept2(visitor);');
        case _PropertyTypeKindNodeList():
          var propertyName = property.name;
          buffer.write('\n$propertyName.accept2(visitor);');
      }
    }

    buffer.writeln('\n}');
  }

  void _generateVisitChildrenWithHooks(
    _ImplClass implClass,
    StringBuffer buffer,
  ) {
    if (implClass.doNotGenerateLookupNames.contains('visitChildrenWithHooks')) {
      return;
    }
    if (!implClass.api.hasV2View) {
      return;
    }

    var hookProperties = implClass.properties.where((p) {
      return p.typeKind is _PropertyTypeKindNode ||
          p.typeKind is _PropertyTypeKindNodeList;
    }).toList();

    if (hookProperties.isEmpty) {
      buffer.write('''
\n/// Visits the children of this node.
@generated
@experimental
void visitChildrenWithHooks(AstVisitor2 visitor) {
''');
    } else {
      buffer.write('''
\n/// Visits the children of this node.
///
/// If a specific hook is provided for a child, it is called instead of
/// dispatching the [visitor] to the child. It is the responsibility of the
/// hook to visit the child.
@generated
@experimental
void visitChildrenWithHooks(AstVisitor2 visitor, {
''');
      for (var property in hookProperties) {
        var hookName = 'visit${property.name.capitalize()}';
        var typeCode = property.typeCodeNotNullable;
        buffer.writeln('void Function($typeCode)? $hookName,');
      }
      buffer.write('}) {');
    }

    if (implClass.isAnnotatedNodeSubclass) {
      buffer.write('_visitCommentAndAnnotations2(visitor);');
    }

    for (var property in implClass.properties) {
      var propertyName = property.name;
      var hookName = 'visit${propertyName.capitalize()}';
      switch (property.typeKind) {
        case _PropertyTypeKindToken():
        case _PropertyTypeKindTokenList():
        case _PropertyTypeKindOther():
          break; // nothing
        case _PropertyTypeKindNode():
          if (property.isNullable) {
            buffer.write('''
if ($propertyName case var $propertyName?) {
  if ($hookName != null) {
    $hookName($propertyName);
  } else {
    $propertyName.accept2(visitor);
  }
}''');
          } else {
            buffer.write('''
if ($hookName != null) {
  $hookName($propertyName);
} else {
  $propertyName.accept2(visitor);
}''');
          }
        case _PropertyTypeKindNodeList():
          buffer.write('''
if ($hookName != null) {
  $hookName($propertyName);
} else {
  $propertyName.accept2(visitor);
}''');
      }
    }

    buffer.writeln('\n}');
  }

  Future<ResolvedUnitResult> _getAstResolvedUnit() async {
    var collection = AnalysisContextCollection(includedPaths: [astPath]);
    var analysisContext = collection.contextFor(astPath);
    var analysisSession = analysisContext.currentSession;
    var astUnitResult = await analysisSession.getResolvedUnit(astPath);
    return astUnitResult as ResolvedUnitResult;
  }

  void _removeGeneratedMembers(ResolvedUnitResult astUnitResult) {
    var replacements = <_Replacement>[];
    for (var implClass in implClasses) {
      for (var member in implClass.members) {
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
            var element = field.declaredFragment!.element;
            memberName = element.lookupName!;
            if (element.metadata.hasDoNotGenerate) {
              implClass.doNotGenerateLookupNames.add(memberName);
              continue;
            }
          case PrimaryConstructorBodyImpl():
            throw UnimplementedError();
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

enum _AstNodeApi {
  v1,
  v2,
  shared;

  String get becomeParentMethod {
    return switch (this) {
      v1 => '_becomeParentOf1',
      v2 => '_becomeParentOf2',
      shared => '_becomeParentOf12',
    };
  }

  bool get hasV1View => this != v2;

  bool get hasV2View => this != v1;
}

enum _AstVersionPolicy {
  /// Generates only the canonical, unsuffixed V1 AST API, with no V2 tree view
  /// or V1 compatibility projection.
  v1Only,

  /// Generates the dual tree views used while migrating SDK code: V2 is the
  /// experimental implementation view, and V1 projection APIs are deprecated
  /// so that their remaining SDK uses are reported.
  v2MigrationSdk,

  /// Generates the dual tree views for publication while V2 is experimental;
  /// V1 projection APIs are marked `@ToBeDeprecated` rather than directing
  /// clients to experimental replacements.
  v2MigrationPublishExperimental,

  /// Generates the dual tree views once V2 is stable: V2 is the public
  /// replacement view, and V1 projection APIs are deprecated.
  v2MigrationPublishStable,

  /// Generates the canonical, unsuffixed V1 tree after rebaseline; any
  /// retained V2 APIs are aliases to that tree, not a separate tree view.
  v2AliasesOnly;

  bool get hasV1Projection {
    return switch (this) {
      v1Only => false,
      v2MigrationSdk => true,
      v2MigrationPublishExperimental => true,
      v2MigrationPublishStable => true,
      v2AliasesOnly => false,
    };
  }

  String get _v1ExpectedAnnotationName {
    return switch (this) {
      v1Only => throw StateError('No V1 migration annotations in $this.'),
      v2MigrationSdk => 'Deprecated',
      v2MigrationPublishExperimental => 'ToBeDeprecated',
      v2MigrationPublishStable => 'Deprecated',
      v2AliasesOnly => throw StateError(
        'No V1 migration annotations in $this.',
      ),
    };
  }

  bool get _v2ApiIsExperimental {
    return switch (this) {
      v1Only => false,
      v2MigrationSdk => true,
      v2MigrationPublishExperimental => true,
      v2MigrationPublishStable => false,
      v2AliasesOnly => false,
    };
  }

  String v1AnnotationCode(String v2Name) {
    var message = 'Use $v2Name instead.';
    return switch (this) {
      v1Only => throw StateError('No V1 migration annotations in $this.'),
      v2MigrationSdk => "@Deprecated('$message')",
      v2MigrationPublishExperimental => "@ToBeDeprecated('$message')",
      v2MigrationPublishStable => "@Deprecated('$message')",
      v2AliasesOnly => throw StateError(
        'No V1 migration annotations in $this.',
      ),
    };
  }

  void validateV1Api({
    required GetterElement getter,
    required String interfaceName,
    required String v1Name,
    required String v2Name,
  }) {
    _validateAnnotation(
      getter: getter,
      interfaceName: interfaceName,
      propertyName: v1Name,
      annotationName: _v1ExpectedAnnotationName,
      annotationDisplay: v1AnnotationCode(v2Name),
      expected: true,
    );

    switch (this) {
      case v1Only:
      case v2AliasesOnly:
        throw StateError('No V1 migration annotations in $this.');
      case v2MigrationSdk:
      case v2MigrationPublishStable:
        _validateAnnotation(
          getter: getter,
          interfaceName: interfaceName,
          propertyName: v1Name,
          annotationName: 'ToBeDeprecated',
          annotationDisplay: '@ToBeDeprecated(...)',
          expected: false,
        );
      case v2MigrationPublishExperimental:
        _validateAnnotation(
          getter: getter,
          interfaceName: interfaceName,
          propertyName: v1Name,
          annotationName: 'Deprecated',
          annotationDisplay: '@Deprecated(...)',
          expected: false,
        );
    }
  }

  void validateV2Api({
    required GetterElement getter,
    required String interfaceName,
    required String v2Name,
  }) {
    _validateAnnotation(
      getter: getter,
      interfaceName: interfaceName,
      propertyName: v2Name,
      annotationName: 'experimental',
      annotationDisplay: '@experimental',
      expected: _v2ApiIsExperimental,
    );
  }

  void _validateAnnotation({
    required GetterElement getter,
    required String interfaceName,
    required String propertyName,
    required String annotationName,
    required String annotationDisplay,
    required bool expected,
  }) {
    var hasAnnotation = getter.hasAnnotationNamed(annotationName);
    if (expected && !hasAnnotation) {
      throw StateError(
        '$interfaceName.$propertyName must have $annotationDisplay '
        'for $_astVersionPolicy.',
      );
    }
    if (!expected && hasAnnotation) {
      throw StateError(
        '$interfaceName.$propertyName must not have $annotationDisplay '
        'for $_astVersionPolicy.',
      );
    }
  }
}

class _ImplClass {
  final ClassDeclarationImpl node;
  final _AstNodeApi api;
  final InterfaceElement interfaceElement;
  final List<_Property> properties;
  final Set<String> doNotGenerateLookupNames = {};
  int leftBracketOffset;

  late final List<_Property> nodeOrListProperties = properties
      .where((property) => property.isNodeOrList)
      .toList();

  late final Set<String> generatedLookupNames = () {
    var generatedLookupNames = {
      '_childContainingRange',
      '_childContainingRange2',
      '_childEntities',
      '_childEntities2',
      '_astNodeApi',
      'accept',
      'accept2',
      'beginToken',
      'endToken',
      'firstTokenAfterCommentAndMetadata',
      'new',
      'isInValueExpressionSlot',
      'removeChild',
      'replaceChild',
      'resolveExpression',
      'visitChildren',
      'visitChildren2',
      'visitChildrenWithHooks',
    };
    for (var property in properties) {
      var propertyName = property.name;
      // We always have a getter.
      generatedLookupNames.add(propertyName);
      if (property.v1Name case var v1Name?) {
        generatedLookupNames.add(v1Name);
      }
      // For expressions we also have a field, and a setter.
      if (property.typeKind is _PropertyTypeKindNode) {
        generatedLookupNames.add('_$propertyName');
        generatedLookupNames.add('$propertyName=');
        if (property.v1Name case var v1Name?) {
          generatedLookupNames.add('$v1Name=');
        }
      }
    }
    return generatedLookupNames;
  }();

  _ImplClass({
    required this.node,
    required this.api,
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

  NodeListImpl<ClassMemberImpl> get members {
    return (node.body as BlockClassBodyImpl).members;
  }

  String get name {
    return node.namePart.typeName.lexeme;
  }
}

class _Property {
  final String name;
  final String? v1Name;
  final _V1ProjectionKind v1Projection;
  final InterfaceType type;
  final _PropertyTypeKind typeKind;
  final bool isSuper;
  final bool isInValueExpressionSlot;
  final bool withOverride;
  final bool withOverrideSuperNotNull;

  _Property({
    required this.name,
    required this.v1Name,
    required this.v1Projection,
    required this.type,
    required this.typeKind,
    required this.isSuper,
    required this.isInValueExpressionSlot,
    required this.withOverride,
    required this.withOverrideSuperNotNull,
  }) {
    if (v1Name == null && v1Projection != _V1ProjectionKind.none) {
      throw StateError('$name: v1Projection requires a v1Name.');
    }
    if (v1Name != null && v1Projection == _V1ProjectionKind.none) {
      throw StateError('$name: v1Name requires a non-none v1Projection.');
    }
    if (v1Name != null && !withOverride) {
      throw StateError('$name: v1Name requires withOverride.');
    }
    if (v1Projection != _V1ProjectionKind.none && !isNodeOrList) {
      throw StateError(
        '$name: v1Projection is only supported for node properties '
        'and node-list properties.',
      );
    }
    if (v1Projection != _V1ProjectionKind.none && isSuper) {
      throw StateError(
        '$name: v1Projection is not supported for super properties.',
      );
    }
  }

  bool get isNodeOrList {
    return typeKind is _PropertyTypeKindNode ||
        typeKind is _PropertyTypeKindNodeList;
  }

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

  String get typeCodeNotNullable {
    return typeCode.removeSuffixOrSelf('?');
  }

  String get v1MigrationAnnotations {
    if (v1Name == null) {
      return '';
    }
    return _astVersionPolicy.v1AnnotationCode(name);
  }

  String get v1ProjectionMethod {
    return switch (v1Projection) {
      _V1ProjectionKind.none => throw StateError(
        '$name: Expected a v1 projection.',
      ),
      _V1ProjectionKind.argument => 'V1Projection.toV1Argument',
      _V1ProjectionKind.expression => 'V1Projection.toV1Expression',
    };
  }

  String get v1ViewName => v1Name ?? name;

  String get v2MigrationAnnotations {
    if (v1Name == null || !_astVersionPolicy._v2ApiIsExperimental) {
      return '';
    }
    return '@experimental';
  }

  String projectToV1Code(String expression) {
    return switch (v1Projection) {
      _V1ProjectionKind.none => expression,
      _V1ProjectionKind.argument ||
      _V1ProjectionKind.expression => '$v1ProjectionMethod($expression)',
    };
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

enum _V1ProjectionKind { none, argument, expression }

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

  bool isNamed(String name) {
    switch (element) {
      case ConstructorElement constructorElement:
        if (constructorElement.enclosingElement.name == name) {
          return true;
        }
      case GetterElement getterElement:
        if (getterElement.name == name) {
          return true;
        }
      case var element?:
        if (element.name == name) {
          return true;
        }
      case null:
        break;
    }

    var value = computeConstantValue();
    return value?.type?.element?.name == name;
  }
}

extension _GetterElementExtension on GetterElement {
  bool hasAnnotationNamed(String name) {
    return metadata.annotations.any((annotation) {
      return annotation.isNamed(name);
    });
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
