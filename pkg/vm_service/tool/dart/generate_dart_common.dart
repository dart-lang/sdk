// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library generate_vm_service_dart;

import 'package:markdown/markdown.dart';

import '../common/generate_common.dart';
import '../common/parser.dart';
import '../common/src_gen_common.dart';
import 'src_gen_dart.dart';

export 'src_gen_dart.dart' show DartGenerator;

String? _coerceRefType(String? typeName) {
  if (typeName == 'Object') typeName = 'Obj';
  if (typeName == '@Object') typeName = 'ObjRef';
  if (typeName == 'Null') typeName = 'NullVal';
  if (typeName == '@Null') typeName = 'NullValRef';
  if (typeName == 'Function') typeName = 'Func';
  if (typeName == '@Function') typeName = 'FuncRef';

  if (typeName!.startsWith('@')) typeName = '${typeName.substring(1)}Ref';

  if (typeName == 'string') typeName = 'String';
  if (typeName == 'map') typeName = 'Map';

  return typeName;
}

String typeRefListToString(List<TypeRef> types) =>
    'const [${types.map((e) => "'${e.name!}'").join(',')}]';

final registerServiceImpl = '''
_serviceExtensionRegistry.registerExtension(params!['service'], this);
response =  Success();''';

final streamListenCaseImpl = '''
var id = params!['streamId'];
if (_streamSubscriptions.containsKey(id)) {
  throw RPCError.withDetails(
    'streamListen', 103, 'Stream already subscribed',
    details: "The stream '\$id' is already subscribed",
  );
}

var stream = id == 'Service'
    ? _serviceExtensionRegistry.onExtensionEvent
    : _serviceImplementation.onEvent(id);
_streamSubscriptions[id] = stream.listen((e) {
  _responseSink.add({
    'jsonrpc': '2.0',
    'method': 'streamNotify',
    'params': {
      'streamId': id,
      'event': e.toJson(),
    },
  });
});
response = Success();''';

final streamCancelCaseImpl = '''
var id = params!['streamId'];
var existing = _streamSubscriptions.remove(id);
if (existing == null) {
  throw RPCError.withDetails(
    'streamCancel', 104, 'Stream not subscribed',
    details: "The stream '\$id' is not subscribed",
  );
}
await existing.cancel();
response = Success();''';

abstract class Member {
  String? get name;

  String? get docs => null;

  void generate(DartGenerator gen);

  bool get hasDocs => docs != null;

  @override
  String toString() => name!;
}

abstract class Api with ApiParseUtil {
  String? serviceVersion;
  List<Method> methods = [];
  List<Enum> enums = [];
  List<Type?> types = [];
  List<StreamCategory> streamCategories = [];

  void parse(List<Node> nodes) {
    serviceVersion = ApiParseUtil.parseVersionString(nodes);

    // Look for h3 nodes
    // the pre following it is the definition
    // the optional p following that is the documentation

    String? h3Name;

    for (int i = 0; i < nodes.length; i++) {
      Node node = nodes[i];

      if (isPre(node) && h3Name != null) {
        String definition = textForCode(node);
        String? docs = '';

        while (i + 1 < nodes.length &&
                (isPara(nodes[i + 1]) || isBlockquote(nodes[i + 1])) ||
            isList(nodes[i + 1])) {
          Element p = nodes[++i] as Element;
          String str = TextOutputVisitor.printText(p);
          if (!str.contains('|') &&
              !str.contains('``') &&
              !str.startsWith('- ')) {
            str = collapseWhitespace(str);
          }
          docs = '$docs\n\n$str';
        }

        docs = docs!.trim();
        if (docs.isEmpty) docs = null;

        _parse(h3Name, definition, docs);
      } else if (isH3(node)) {
        h3Name = textForElement(node);
      } else if (isHeader(node)) {
        h3Name = null;
      }
    }

    for (Type? type in types) {
      type!.calculateFieldOverrides();
    }

    Method streamListenMethod =
        methods.singleWhere((method) => method.name == 'streamListen');
    _parseStreamListenDocs(streamListenMethod.docs!);
  }

  void _parse(String name, String definition, [String? docs]) {
    name = replaceHTMLEntities(name.trim());
    definition = replaceHTMLEntities(definition.trim());
    if (docs != null) docs = replaceHTMLEntities(docs.trim());

    if (definition.startsWith('class ')) {
      types.add(Type(this, this, name, definition, docs));
    } else if (name.substring(0, 1).toLowerCase() == name.substring(0, 1)) {
      methods.add(Method(this, name, definition, docs));
    } else if (definition.startsWith('enum ')) {
      enums.add(Enum(name, definition, docs));
    } else {
      throw 'unexpected entity: $name, $definition';
    }
  }

  void _parseStreamListenDocs(String docs) {
    Iterator<String> lines = docs.split('\n').map((l) => l.trim()).iterator;
    bool inStreamDef = false;

    while (lines.moveNext()) {
      final String line = lines.current;

      if (line.startsWith('streamId |')) {
        inStreamDef = true;
        lines.moveNext();
      } else if (inStreamDef) {
        if (line.isEmpty) {
          inStreamDef = false;
        } else {
          streamCategories.add(StreamCategory(line));
        }
      }
    }
  }

  static String printNode(Node n) {
    if (n is Text) {
      return n.text;
    } else if (n is Element) {
      if (n.tag != 'h3') return n.tag;
      return '${n.tag}:[${n.children!.map((c) => printNode(c)).join(', ')}]';
    } else {
      return '$n';
    }
  }

  void generate(DartGenerator gen);

  bool isEnumName(String? typeName) =>
      enums.any((Enum e) => e.name == typeName);

  Type? getType(String? name) =>
      types.firstWhere((t) => t!.name == name, orElse: () => null);
}

class StreamCategory {
  String? _name;
  List<String>? _events;

  StreamCategory(String line) {
    // Debug | PauseStart, PauseExit, ...
    _name = line.split('|')[0].trim();

    line = line.split('|')[1];
    _events = line.split(',').map((w) => w.trim()).toList();
  }

  String? get name => _name;

  List<String>? get events => _events;

  void generate(DartGenerator gen) {
    gen.writeln();
    gen.writeln('// ${events!.join(', ')}');
    gen.writeln(
        "Stream<Event> get on${name}Event => _getEventController('$name').stream;");
  }

  @override
  String toString() => '$name: $events';
}

class Method extends Member {
  final Api api;

  @override
  final String name;
  @override
  final String? docs;

  late MemberType returnType = MemberType(api);
  bool get deprecated => deprecationMessage != null;
  String? deprecationMessage;
  List<MethodArg> args = [];

  Method(this.api, this.name, String definition, [this.docs]) {
    _parse(Tokenizer(definition).tokenize());
  }

  bool get hasArgs => args.isNotEmpty;

  bool get hasOptionalArgs => args.any((MethodArg arg) => arg.optional);

  @override
  void generate(DartGenerator gen) {
    generateDefinition(gen);
    if (!hasArgs) {
      gen.writeStatement("=> _call('$name');");
    } else if (hasOptionalArgs) {
      gen.writeStatement("=> _call('$name', {");
      gen.write(args
          .where((MethodArg a) => !a.optional)
          .map((arg) => "'${arg.name}': ${arg.name},")
          .join());

      args.where((MethodArg a) => a.optional).forEach((MethodArg arg) {
        String? valueRef = arg.name;
        // Special case for `getAllocationProfile`. We do not want to add these
        // params if they are false.
        if (name == 'getAllocationProfile') {
          gen.writeln('if (${arg.name} != null && ${arg.name})');
        } else {
          gen.writeln('if (${arg.name} != null)');
        }
        gen.writeln("'${arg.name}': $valueRef,");
      });

      gen.writeln('});');
    } else {
      gen.write("=> _call('$name', {");
      gen.write(args.map((MethodArg arg) {
        return "'${arg.name}': ${arg.name}";
      }).join(', '));
      gen.writeStatement('});');
    }
  }

  /// Writes the method definition without the body.
  ///
  /// Does not write an opening or closing bracket, or a trailing semicolon.
  void generateDefinition(DartGenerator gen) {
    gen.writeln();
    if (docs != null) {
      String methodDocs = docs!;
      if (returnType.isMultipleReturns) {
        methodDocs += '\n\nThe return value can be one of '
            '${joinLast(returnType.types.map((t) => '[$t]'), ', ', ' or ')}.';
        methodDocs = methodDocs.trim();
      }
      if (returnType.canReturnSentinel) {
        methodDocs +=
            '\n\nThis method will throw a [SentinelException] in the case a [Sentinel] is returned.';
        methodDocs = methodDocs.trim();
      }
      if (methodDocs.isNotEmpty) gen.writeDocs(methodDocs);
    }
    if (deprecated) {
      gen.writeln("@Deprecated('$deprecationMessage')");
    }
    gen.write('Future<${returnType.name}> $name(');
    bool startedOptional = false;
    gen.write(args.map((MethodArg arg) {
      String typeName;
      if (api.isEnumName(arg.type.name)) {
        if (arg.type.isArray) {
          typeName = typeName = '/*${arg.type}*/ List<String>';
        } else {
          typeName = '/*${arg.type}*/ String';
        }
      } else {
        typeName = arg.type.ref;
      }
      final nullable = arg.optional ? '?' : '';
      if (arg.optional && !startedOptional) {
        startedOptional = true;
        return '{$typeName$nullable ${arg.name}';
      } else {
        return '$typeName$nullable ${arg.name}';
      }
    }).join(', '));
    if (args.length >= 4) gen.write(',');
    if (startedOptional) gen.write('}');
    gen.write(') ');
  }

  void _parse(Token? token) => MethodParser(token).parseInto(this);
}

class MemberType extends Member {
  final Api api;
  List<TypeRef> types = [];

  MemberType(this.api);

  void parse(Parser parser, {bool isReturnType = false}) {
    // foo|bar[]|baz
    // (@Instance|Sentinel)[]
    bool loop = true;
    bool nullable = false;
    this.isReturnType = isReturnType;

    final unionTypes = <String>[];
    while (loop) {
      if (parser.consume('(')) {
        while (parser.peek()!.text != ')') {
          if (parser.consume('Null')) {
            nullable = true;
          } else {
            // @Instance | Sentinel
            final token = parser.advance()!;
            if (token.isName) {
              unionTypes.add(_coerceRefType(token.text)!);
            }
          }
        }
        parser.consume(')');
        TypeRef ref;
        if (unionTypes.length == 1) {
          ref = TypeRef(unionTypes.first)..nullable = nullable;
        } else {
          ref = TypeRef('dynamic');
        }
        while (parser.consume('[')) {
          parser.expect(']');
          ref.arrayDepth++;
        }
        types.add(ref);
      } else {
        Token t = parser.expectName();
        TypeRef ref = TypeRef(_coerceRefType(t.text));
        while (parser.consume('[')) {
          parser.expect(']');
          ref.arrayDepth++;
        }
        if (isReturnType && ref.name == 'Sentinel') {
          canReturnSentinel = true;
        } else {
          types.add(ref);
        }
      }

      loop = parser.consume('|');
    }
  }

  @override
  String get name {
    if (types.isEmpty) return '';
    if (types.length == 1) return types.first.ref;
    if (isReturnType) return 'Response';
    return 'dynamic';
  }

  bool isReturnType = false;
  bool canReturnSentinel = false;

  bool get isMultipleReturns => types.length > 1;

  bool get areAllTypesSimple => types.every((type) => type.isSimple);

  List<String> get subsetOfTypesThatAreSimple =>
      types.fold(<String>[], (List<String> accumulator, TypeRef typeRef) {
        if (typeRef.isSimple) {
          accumulator.add(typeRef.ref);
        }
        return accumulator;
      });

  bool get isSimple => types.length == 1 && types.first.isSimple;

  bool get isEnum => types.length == 1 && api.isEnumName(types.first.name);

  bool get isArray => types.length == 1 && types.first.isArray;

  @override
  void generate(DartGenerator gen) => gen.write(name);
}

class TypeRef {
  String? name;
  int arrayDepth = 0;
  bool nullable = false;
  List<TypeRef>? genericTypes;

  TypeRef(this.name);

  String get ref {
    if (arrayDepth == 2) {
      return 'List<List<$name${nullable ? "?" : ""}>>';
    } else if (arrayDepth == 1) {
      return 'List<$name${nullable ? "?" : ""}>';
    } else if (genericTypes != null) {
      return '$name<${genericTypes!.join(', ')}>';
    } else {
      return name!.startsWith('_') ? name!.substring(1) : name!;
    }
  }

  String get listCreationRef {
    assert(arrayDepth == 1);

    if (isListTypeSimple) {
      return 'List<$name${nullable ? "?" : ""}>';
    } else {
      return 'List<String>';
    }
  }

  String? get listTypeArg => arrayDepth == 2
      ? 'List<$name${nullable ? "?" : ""}>'
      : '$name${nullable ? "?" : ""}';

  bool get isArray => arrayDepth > 0;

  bool get isSimple =>
      arrayDepth == 0 &&
      (name == 'int' ||
          name == 'num' ||
          name == 'String' ||
          name == 'bool' ||
          name == 'double' ||
          name == 'ByteData');

  bool get isListTypeSimple =>
      arrayDepth == 1 &&
      (name == 'int' ||
          name == 'num' ||
          name == 'String' ||
          name == 'bool' ||
          name == 'double' ||
          name == 'ByteData');

  @override
  String toString() => ref;
}

class MethodArg extends Member {
  final Method parent;
  TypeRef type;
  @override
  String? name;
  bool optional = false;

  MethodArg(this.parent, this.type, this.name);

  @override
  void generate(DartGenerator gen) {
    gen.write('${type.ref} $name');
  }

  @override
  String toString() => '$type $name';
}

class Type extends Member {
  final Api api;
  final Api parent;
  String? rawName;
  @override
  String? name;
  String? superName;
  @override
  final String? docs;
  List<TypeField> fields = [];

  Type(this.api, this.parent, String categoryName, String definition,
      [this.docs]) {
    _parse(Tokenizer(definition).tokenize());
  }

  Type._(this.api, this.parent, this.rawName, this.name, this.superName,
      this.docs);

  factory Type.merge(Type t1, Type t2) {
    final Api parent = t1.parent;
    final String? rawName = t1.rawName;
    final String? name = t1.name;
    final String? superName = t1.superName;
    final String docs = [t1.docs, t2.docs].where((e) => e != null).join('\n');
    final Map<String?, TypeField> map = <String?, TypeField>{};
    for (TypeField f in t2.fields.reversed) {
      map[f.name] = f;
    }
    // The official service.md is the default
    for (TypeField f in t1.fields.reversed) {
      map[f.name] = f;
    }

    final fields = map.values.toList().reversed.toList();

    return Type._(t1.api, parent, rawName, name, superName, docs)
      ..fields = fields;
  }

  bool get isResponse {
    if (superName == null) return false;
    if (name == 'Response' || superName == 'Response') return true;
    return parent.getType(superName)!.isResponse;
  }

  bool get isRef => name!.endsWith('Ref');

  bool get supportsIdentity {
    if (fields.any((f) => f.name == 'id')) return true;
    return superName == null ? false : getSuper()!.supportsIdentity;
  }

  Type? getSuper() => superName == null ? null : api.getType(superName);

  List<TypeField> getAllFields() {
    if (superName == null) return fields;

    List<TypeField> all = [];
    all.insertAll(0, fields);

    Type? s = getSuper();
    while (s != null) {
      all.insertAll(0, s.fields);
      s = s.getSuper();
    }

    return all;
  }

  bool get skip => name == 'ExtensionData';

  @override
  void generate(DartGenerator gen) {
    gen.writeln();
    if (docs != null) gen.writeDocs(docs!);
    gen.write('class $name ');
    Type? superType;
    if (superName != null) {
      superType = parent.getType(superName);
      gen.write('extends $superName ');
    }
    if (parent.getType('${name}Ref') != null) {
      gen.write('implements ${name}Ref ');
    }
    gen.writeln('{');
    gen.writeln('static $name? parse(Map<String, dynamic>? json) => '
        'json == null ? null : $name._fromJson(json);');
    gen.writeln();

    if (name == 'Response' || name == 'TimelineEvent') {
      gen.writeln('Map<String, dynamic>? json;');
    }
    if (name == 'Script') {
      gen.writeln('final _tokenToLine = <int, int>{};');
      gen.writeln('final _tokenToColumn = <int, int>{};');
    }

    // fields
    for (var field in fields) {
      field.generate(gen);
    }
    gen.writeln();

    // ctors

    bool hasRequiredParentFields = superType != null &&
        (superType.name == 'ObjRef' || superType.name == 'Obj');
    // Default
    gen.write('$name(');
    if (fields.isNotEmpty || hasRequiredParentFields) {
      gen.write('{');
      fields.where((field) => !field.optional).forEach((field) {
        final fromParent = (name == 'Instance' && field.name == 'classRef');
        field.generateNamedParameter(gen, fromParent: fromParent);
      });
      if (hasRequiredParentFields) {
        superType.fields.where((field) => !field.optional).forEach(
            (field) => field.generateNamedParameter(gen, fromParent: true));
      }
      fields
          .where((field) => field.optional)
          .forEach((field) => field.generateNamedParameter(gen));
      gen.write('}');
    }
    gen.write(')');
    if (hasRequiredParentFields) {
      gen.write(' : super(');
      superType.fields.where((field) => !field.optional).forEach((field) {
        String? name = field.generatableName;
        gen.writeln('$name: $name,');
      });
      if (name == 'Instance') {
        gen.writeln('classRef: classRef,');
      }
      gen.write(')');
    } else if (name!.contains('NullVal')) {
      gen.writeln(' : super(');
      gen.writeln("id: 'instance/null',");
      gen.writeln('identityHashCode: 0,');
      gen.writeln('kind: InstanceKind.kNull,');
      gen.writeln("classRef: ClassRef(id: 'class/null',");
      gen.writeln("library: LibraryRef(id: '', name: 'dart:core',");
      gen.writeln("uri: 'dart:core',),");
      gen.writeln("name: 'Null',),");
      gen.writeln(')');
    }

    gen.writeln(';');

    // Build from JSON.
    gen.writeln();
    String superCall = superName == null ? '' : ': super._fromJson(json) ';
    if (name == 'Response' || name == 'TimelineEvent') {
      gen.write('$name._fromJson(this.json)');
    } else {
      gen.write('$name._fromJson(Map<String, dynamic> json) $superCall');
    }

    if (fields.isEmpty) {
      gen.writeln(';');
    } else {
      gen.writeln('{');
    }

    for (var field in fields) {
      if (field.type.isSimple || field.type.isEnum) {
        // Special case `AllocationProfile`.
        if (name == 'AllocationProfile' && field.type.name == 'int') {
          gen.write(
              "${field.generatableName} = json['${field.name}'] is String ? "
              "int.parse(json['${field.name}']) : json['${field.name}']");
        } else {
          gen.write("${field.generatableName} = json['${field.name}']");
        }
        final defaultValue = field.defaultValue;
        if (defaultValue != null) {
          gen.write(' ?? $defaultValue');
        }
        gen.writeln(';');
        // } else if (field.type.isEnum) {
        //   // Parse the enum.
        //   String enumTypeName = field.type.types.first.name;
        //   gen.writeln(
        //     "${field.generatableName} = _parse${enumTypeName}[json['${field.name}']];");
      } else if (name == 'Event' && field.name == 'extensionData') {
        // Special case `Event.extensionData`.
        gen.writeln(
            "extensionData = ExtensionData.parse(json['extensionData']);");
      } else if (name == 'Instance' && field.name == 'associations') {
        // Special case `Instance.associations`.
        gen.writeln("associations = json['associations'] == null "
            '? null : List<MapAssociation>.from('
            "_createSpecificObject(json['associations'], MapAssociation.parse));");
      } else if (name == 'Instance' && field.name == 'classRef') {
        // This is populated by `Obj`
      } else if (name == '_CpuProfile' && field.name == 'codes') {
        // Special case `_CpuProfile.codes`.
        gen.writeln('codes = List<CodeRegion>.from('
            "_createSpecificObject(json['codes']!, CodeRegion.parse));");
      } else if (name == '_CpuProfile' && field.name == 'functions') {
        // Special case `_CpuProfile.functions`.
        gen.writeln('functions = List<ProfileFunction>.from('
            "_createSpecificObject(json['functions']!, ProfileFunction.parse));");
      } else if (name == 'SourceReport' && field.name == 'ranges') {
        // Special case `SourceReport.ranges`.
        gen.writeln('ranges = List<SourceReportRange>.from('
            "_createSpecificObject(json['ranges']!, SourceReportRange.parse));");
      } else if (name == 'SourceReportRange' && field.name == 'coverage') {
        // Special case `SourceReportRange.coverage`.
        gen.writeln('coverage = _createSpecificObject('
            "json['coverage'], SourceReportCoverage.parse);");
      } else if (name == 'Library' && field.name == 'dependencies') {
        // Special case `Library.dependencies`.
        gen.writeln('dependencies = List<LibraryDependency>.from('
            "_createSpecificObject(json['dependencies']!, "
            'LibraryDependency.parse));');
      } else if (name == 'Script' && field.name == 'tokenPosTable') {
        // Special case `Script.tokenPosTable`.
        gen.write('tokenPosTable = ');
        if (field.optional) {
          gen.write("json['tokenPosTable'] == null ? null : ");
        }
        gen.writeln("List<List<int>>.from(json['tokenPosTable']!.map"
            '((dynamic list) => List<int>.from(list)));');
        gen.writeln('_parseTokenPosTable();');
      } else if (field.type.isArray) {
        TypeRef fieldType = field.type.types.first;
        String typesList = typeRefListToString(field.type.types);
        String ref = "json['${field.name}']";
        if (field.optional) {
          if (fieldType.isListTypeSimple) {
            gen.writeln('${field.generatableName} = $ref == null ? null : '
                'List<${fieldType.listTypeArg}>.from($ref);');
          } else {
            gen.writeln('${field.generatableName} = $ref == null ? null : '
                'List<${fieldType.listTypeArg}>.from(createServiceObject($ref, $typesList)! as List);');
          }
        } else {
          if (fieldType.isListTypeSimple) {
            // Special case `ClassHeapStats`. Pre 3.18, responses included keys
            // `new` and `old`. Post 3.18, these will be null.
            if (name == 'ClassHeapStats') {
              gen.writeln('${field.generatableName} = $ref == null ? null : '
                  'List<${fieldType.listTypeArg}>.from($ref);');
            } else {
              gen.writeln('${field.generatableName} = '
                  'List<${fieldType.listTypeArg}>.from($ref);');
            }
          } else {
            // Special case `InstanceSet`. Pre 3.20, instances were sent in a
            // field named 'samples' instead of 'instances'.
            if (name == 'InstanceSet') {
              gen.writeln('${field.generatableName} = '
                  "List<${fieldType.listTypeArg}>.from(createServiceObject(($ref ?? json['samples']!) as List, $typesList)! as List);");
            } else {
              gen.writeln('${field.generatableName} = '
                  'List<${fieldType.listTypeArg}>.from(createServiceObject($ref, $typesList) as List? ?? []);');
            }
          }
        }
      } else {
        String typesList = typeRefListToString(field.type.types);
        String nullable = field.type.name != 'dynamic' ? '?' : '';
        gen.writeln(
          '${field.generatableName} = '
          "createServiceObject(json['${field.name}'], "
          '$typesList) as ${field.type.name}$nullable;',
        );
      }
    }
    if (fields.isNotEmpty) {
      gen.writeln('}');
    }
    gen.writeln();

    if (name == 'Script') {
      generateScriptTypeMethods(gen);
    }

    // toJson support, the base Response type is not supported
    if (name == 'Response') {
      gen.writeln("String get type => 'Response';");
      gen.writeln();
      gen.writeln('''
Map<String, dynamic> toJson() {
  final localJson = json;
  final result = localJson == null ? <String, dynamic>{} : Map<String, dynamic>.of(localJson);
  result['type'] = type;
  return result;
}''');
    } else if (name == 'TimelineEvent') {
      // TimelineEvent doesn't have any declared properties as the response is
      // fairly dynamic. Return the json directly.
      gen.writeln('''
          Map<String, dynamic> toJson() {
            final localJson = json;
            final result = localJson == null ? <String, dynamic>{} : Map<String, dynamic>.of(localJson);
            result['type'] = 'TimelineEvent';
            return result;
          }
      ''');
    } else {
      if (isResponse) {
        gen.writeln('@override');
        gen.writeln("String get type => '$rawName';");
        gen.writeln();
      }

      if (isResponse) {
        gen.writeln('@override');
      }
      gen.writeln('Map<String, dynamic> toJson() {');
      if (superName == null || superName == 'Response') {
        // The base Response type doesn't have a toJson
        gen.writeln('final json = <String, dynamic>{};');
      } else {
        gen.writeln('final json = super.toJson();');
      }

      // Only Response objects have a `type` field, as defined by protocol.
      if (isResponse) {
        // Overwrites "type" from the super class if we had one.
        gen.writeln("json['type'] = type;");
      }

      var requiredFields = fields.where((f) => !f.optional);
      if (requiredFields.isNotEmpty) {
        gen.writeln('json.addAll({');
        for (var field in requiredFields) {
          gen.write("'${field.name}': ");
          generateSerializedFieldAccess(field, gen);
          gen.writeln(',');
        }
        gen.writeln('});');
      }

      var optionalFields = fields.where((f) => f.optional);
      for (var field in optionalFields) {
        gen.write("_setIfNotNull(json, '${field.name}', ");
        generateSerializedFieldAccess(field, gen);
        gen.writeln(');');
      }
      gen.writeln('return json;');
      gen.writeln('}');
      gen.writeln();
    }

    // equals and hashCode
    if (supportsIdentity) {
      gen.writeln('@override');
      gen.writeStatement('int get hashCode => id.hashCode;');
      gen.writeln();

      gen.writeln('@override');
      gen.writeStatement(
          'bool operator ==(Object other) => other is $name && id == other.id;');
      gen.writeln();
    }

    // toString()
    Iterable<TypeField> toStringFields =
        getAllFields().where((f) => !f.optional);
    const maxFieldsShownInToString = 8;
    gen.writeln('@override');
    if (toStringFields.length <= maxFieldsShownInToString) {
      String properties = toStringFields
          .map((TypeField f) => '${f.generatableName}: \$${f.generatableName}')
          .join(', ');
      if (properties.length > 60) {
        int index = properties.indexOf(', ', 55);
        if (index != -1) {
          properties =
              "${properties.substring(0, index + 2)}' //\n'${properties.substring(index + 2)}";
        }
        gen.writeln("String toString() => '[$name ' //\n'$properties]';");
      } else {
        final formattedProperties = (properties.isEmpty) ? '' : ' $properties';
        gen.writeln("String toString() => '[$name$formattedProperties]';");
      }
    } else {
      gen.writeln("String toString() => '[$name]';");
    }

    gen.writeln('}');
  }

  // Special methods for Script objects.
  void generateScriptTypeMethods(DartGenerator gen) {
    gen.writeDocs('''This function maps a token position to a line number.
The VM considers the first line to be line 1.''');
    gen.writeln(
        'int? getLineNumberFromTokenPos(int tokenPos) => _tokenToLine[tokenPos];');
    gen.writeln();
    gen.writeDocs('''This function maps a token position to a column number.
The VM considers the first column to be column 1.''');
    gen.writeln(
        'int? getColumnNumberFromTokenPos(int tokenPos) => _tokenToColumn[tokenPos];');
    gen.writeln();
    gen.writeln('''
void _parseTokenPosTable() {
  final tokenPositionTable = tokenPosTable;
  if (tokenPositionTable == null) {
    return;
  }
  final lineSet = <int>{};
  for (List line in tokenPositionTable) {
    // Each entry begins with a line number...
    int lineNumber = line[0];
    lineSet.add(lineNumber);
    for (var pos = 1; pos < line.length; pos += 2) {
      // ...and is followed by (token offset, col number) pairs.
      final int tokenOffset = line[pos];
      final int colNumber = line[pos + 1];
      _tokenToLine[tokenOffset] = lineNumber;
      _tokenToColumn[tokenOffset] = colNumber;
    }
  }
}''');
  }

  // Writes the code to retrieve the serialized value of a field.
  void generateSerializedFieldAccess(TypeField field, DartGenerator gen) {
    if (field.type.isSimple ||
        field.type.isEnum ||
        field.type.areAllTypesSimple) {
      gen.write('${field.generatableName}');
      final defaultValue = field.defaultValue;
      if (defaultValue != null) {
        gen.write(' ?? $defaultValue');
      }
    } else if (name == 'Event' && field.name == 'extensionData') {
      // Special case `Event.extensionData`.
      gen.writeln('extensionData?.data');
    } else if (field.type.isArray) {
      gen.write('${field.generatableName}?.map((f) => f');
      // Special case `tokenPosTable` which is a List<List<int>>.
      if (field.name == 'tokenPosTable') {
        gen.write('.toList()');
      } else if (!field.type.types.first.isListTypeSimple) {
        gen.write('.toJson()');
      }
      gen.write(').toList()');
    } else {
      final subsetOfTypesThatAreSimple = field.type.subsetOfTypesThatAreSimple;
      if (subsetOfTypesThatAreSimple.isNotEmpty) {
        for (int i = 0; i < subsetOfTypesThatAreSimple.length; i++) {
          if (i >= 1) {
            gen.write(' || ');
          }
          gen.write(
              '${field.generatableName} is ${subsetOfTypesThatAreSimple[i]}');
        }
        gen.write(' ? ${field.generatableName} : ');
      }
      gen.write('${field.generatableName}?.toJson()');
    }
  }

  void generateAssert(DartGenerator gen) {
    gen.writeln('vms.$name assert$name(vms.$name obj) {');
    gen.writeln('assertNotNull(obj);');
    for (TypeField field in getAllFields()) {
      if (!field.optional) {
        MemberType type = field.type;
        if (type.isArray) {
          TypeRef arrayType = type.types.first;
          if (arrayType.arrayDepth == 1) {
            String assertMethodName =
                'assertListOf${arrayType.name!.substring(0, 1).toUpperCase()}${arrayType.name!.substring(1)}';
            gen.writeln('$assertMethodName(obj.${field.generatableName}!);');
          } else {
            gen.writeln(
                '// assert obj.${field.generatableName} is ${type.name}');
          }
        } else if (type.isMultipleReturns) {
          bool first = true;
          for (TypeRef typeRef in type.types) {
            if (!first) gen.write('} else ');
            first = false;
            gen.writeln(
                'if (obj.${field.generatableName} is vms.${typeRef.name}) {');
            String assertMethodName =
                'assert${typeRef.name!.substring(0, 1).toUpperCase()}${typeRef.name!.substring(1)}';
            gen.writeln('$assertMethodName(obj.${field.generatableName}!);');
          }
          gen.writeln('} else {');
          gen.writeln(
              'throw "Unexpected value: \${obj.${field.generatableName}}";');
          gen.writeln('}');
        } else {
          String assertMethodName =
              'assert${type.name.substring(0, 1).toUpperCase()}${type.name.substring(1)}';
          gen.writeln('$assertMethodName(obj.${field.generatableName}!);');
        }
      }
    }
    gen.writeln('return obj;');
    gen.writeln('}');
    gen.writeln('');
  }

  void generateListAssert(DartGenerator gen) {
    gen.writeln('List<vms.$name> '
        'assertListOf$name(List<vms.$name> list) {');
    gen.writeln('for (vms.$name elem in list) {');
    gen.writeln('assert$name(elem);');
    gen.writeln('}');
    gen.writeln('return list;');
    gen.writeln('}');
    gen.writeln('');
  }

  void _parse(Token? token) => TypeParser(token).parseInto(this);

  void calculateFieldOverrides() {
    for (TypeField field in fields.toList()) {
      if (superName == null) continue;

      if (getSuper()!.hasField(field.name)) {
        field.setOverrides();
      }
    }
  }

  bool hasField(String? name) {
    if (fields.any((field) => field.name == name)) return true;
    return getSuper()?.hasField(name) ?? false;
  }
}

class TypeField extends Member {
  static final Map<String, String> _nameRemap = {
    'const': 'isConst',
    'final': 'isFinal',
    'static': 'isStatic',
    'abstract': 'isAbstract',
    'super': 'superClass',
    'class': 'classRef',
    'new': 'new_',
  };

  final Api api;
  final Type parent;
  final String? _docs;
  late MemberType type = MemberType(api);
  @override
  String? name;
  bool optional = false;
  String? _defaultValue;
  bool overrides = false;

  TypeField(this.api, this.parent, this._docs);

  void setOverrides() => overrides = true;

  @override
  String? get docs {
    String str = _docs == null ? '' : _docs!;
    if (type.isMultipleReturns) {
      str += '\n\n[$generatableName] can be one of '
          '${joinLast(type.types.map((t) => '[$t]'), ', ', ' or ')}.';
      str = str.trim();
    }
    return str;
  }

  String? get generatableName {
    return _nameRemap[name] ?? name;
  }

  set defaultValue(String? value) {
    _defaultValue = value;
  }

  String? get defaultValue {
    if (_defaultValue != null) {
      return _defaultValue;
    }
    if (optional) {
      return null;
    }
    // If a default isn't provided and the field is required, generate a sane
    // default initializer to avoid TypeErrors at runtime when running in a
    // null-safe context.
    switch (type.name) {
      case 'int':
      case 'num':
      case 'double':
        return '-1';
      case 'bool':
        return 'false';
      case 'String':
        return "''";
      case 'ByteData':
        return 'ByteData(0)';
    }
    if (type.isEnum) {
      // TODO(bkonyi): Figure out if there's a more correct way to determine a
      // default value for enums.
      return "''";
    }
    return null;
  }

  @override
  void generate(DartGenerator gen) {
    Type? refType = parent.parent.getType('${parent.name}Ref');
    var interfaceOverride = refType?.hasField(name) ?? false;

    if (docs!.isNotEmpty) gen.writeDocs(docs!);
    if (optional) gen.write('@optional ');
    if (overrides || interfaceOverride) gen.write('@override ');
    // Special case where Instance extends Obj, but 'classRef' is not optional
    // for Instance although it is for Obj.
    /*if (parent.name == 'Instance' && generatableName == 'classRef') {
      gen.writeStatement('covariant late final ClassRef classRef;');
    } else if (parent.name!.contains('NullVal') &&
        generatableName == 'valueAsString') {
      gen.writeStatement('covariant late final String valueAsString;');
    } else */
    {
      String? typeName =
          api.isEnumName(type.name) ? '/*${type.name}*/ String' : type.name;
      if (typeName != 'dynamic') {
        typeName = '$typeName?';
      }
      gen.writeStatement('$typeName $generatableName;');
      if (parent.fields.any((field) => field.hasDocs)) gen.writeln();
    }
  }

  void generateNamedParameter(DartGenerator gen, {bool fromParent = false}) {
    if (fromParent) {
      String? typeName =
          api.isEnumName(type.name) ? '/*${type.name}*/ String' : type.name;
      gen.writeStatement('required $typeName $generatableName,');
    } else {
      gen.writeStatement('this.$generatableName,');
    }
  }
}

class Enum extends Member {
  @override
  final String name;
  @override
  final String? docs;

  List<EnumValue> enums = [];

  Enum(this.name, String definition, [this.docs]) {
    _parse(Tokenizer(definition).tokenize());
  }

  Enum._(this.name, this.docs);

  factory Enum.merge(Enum e1, Enum e2) {
    final String name = e1.name;
    final String docs = [e1.docs, e2.docs].where((e) => e != null).join('\n');
    final Map<String?, EnumValue> map = <String?, EnumValue>{};
    for (EnumValue e in e2.enums.reversed) {
      map[e.name] = e;
    }
    // The official service.md is the default
    for (EnumValue e in e1.enums.reversed) {
      map[e.name] = e;
    }

    final enums = map.values.toList().reversed.toList();

    return Enum._(name, docs)..enums = enums;
  }

  String get prefix =>
      name.endsWith('Kind') ? name.substring(0, name.length - 4) : name;

  @override
  void generate(DartGenerator gen) {
    gen.writeln();
    if (docs != null) gen.writeDocs(docs!);
    gen.writeStatement('abstract class $name {');
    gen.writeln();
    for (var e in enums) {
      e.generate(gen);
    }
    gen.writeStatement('}');
  }

  void generateAssert(DartGenerator gen) {
    gen.writeln('String assert$name(String obj) {');
    List<EnumValue> sorted = enums.toList()
      ..sort((EnumValue e1, EnumValue e2) => e1.name!.compareTo(e2.name!));
    for (EnumValue value in sorted) {
      gen.writeln('  if (obj == "${value.name}") return obj;');
    }
    gen.writeln('  throw "invalid $name: \$obj";');
    gen.writeln('}');
    gen.writeln('');
  }

  void _parse(Token? token) => EnumParser(token).parseInto(this);
}

class EnumValue extends Member {
  final Enum parent;
  @override
  final String? name;
  @override
  final String? docs;

  EnumValue(this.parent, this.name, [this.docs]);

  bool get isLast => parent.enums.last == this;

  @override
  void generate(DartGenerator gen) {
    if (docs != null) gen.writeDocs(docs!);
    gen.writeStatement("static const String k$name = '$name';");
  }
}

class TextOutputVisitor implements NodeVisitor {
  static String printText(Node node) {
    TextOutputVisitor visitor = TextOutputVisitor();
    node.accept(visitor);
    return visitor.toString();
  }

  StringBuffer buf = StringBuffer();
  bool _em = false;
  bool _href = false;
  bool _blockquote = false;

  TextOutputVisitor();

  @override
  bool visitElementBefore(Element element) {
    if (element.tag == 'em' || element.tag == 'code') {
      buf.write('`');
      _em = true;
    } else if (element.tag == 'p') {
      // Nothing to do.
    } else if (element.tag == 'blockquote') {
      buf.write('```\n');
      _blockquote = true;
    } else if (element.tag == 'a') {
      _href = true;
    } else if (element.tag == 'strong') {
      buf.write('**');
    } else if (element.tag == 'ul') {
      // Nothing to do.
    } else if (element.tag == 'li') {
      buf.write('- ');
    } else {
      throw 'unknown node type: ${element.tag}';
    }

    return true;
  }

  @override
  void visitText(Text text) {
    String? t = text.text;
    if (_em) {
      t = _coerceRefType(t);
    } else if (_href) {
      t = '[${_coerceRefType(t)}]';
    }

    if (_blockquote) {
      buf.write('$t\n```');
    } else {
      buf.write(t);
    }
  }

  @override
  void visitElementAfter(Element element) {
    if (element.tag == 'em' || element.tag == 'code') {
      buf.write('`');
      _em = false;
    } else if (element.tag == 'p') {
      buf.write('\n\n');
    } else if (element.tag == 'blockquote') {
      _blockquote = false;
    } else if (element.tag == 'a') {
      _href = false;
    } else if (element.tag == 'strong') {
      buf.write('**');
    } else if (element.tag == 'ul') {
      // Nothing to do.
    } else if (element.tag == 'li') {
      buf.write('\n');
    } else {
      throw 'unknown node type: ${element.tag}';
    }
  }

  @override
  String toString() => buf.toString().trim();
}

// @Instance|@Error|Sentinel evaluate(
//     string isolateId,
//     string targetId [optional],
//     string expression)
class MethodParser extends Parser {
  MethodParser(super.startToken);

  void parseInto(Method method) {
    // method is return type, name, (, args )
    // args is type name, [optional], comma
    if (peek()?.text?.startsWith('@deprecated') ?? false) {
      advance();
      expect('(');
      method.deprecationMessage = consumeString()!;
      expect(')');
    }
    method.returnType.parse(this, isReturnType: true);

    Token t = expectName();
    validate(
        t.text == method.name, 'method name ${method.name} equals ${t.text}');

    expect('(');

    while (peek()!.text != ')') {
      Token type = expectName();
      TypeRef ref = TypeRef(_coerceRefType(type.text));
      if (peek()!.text == '[') {
        while (consume('[')) {
          expect(']');
          ref.arrayDepth++;
        }
      } else if (peek()!.text == '<') {
        // handle generics
        expect('<');
        ref.genericTypes = [];
        while (peek()!.text != '>') {
          Token genericTypeName = expectName();
          ref.genericTypes!.add(TypeRef(_coerceRefType(genericTypeName.text)));
          consume(',');
        }
        expect('>');
      }

      Token name = expectName();
      MethodArg arg = MethodArg(method, ref, name.text);
      if (consume('[')) {
        expect('optional');
        expect(']');
        arg.optional = true;
      }
      method.args.add(arg);
      consume(',');
    }

    expect(')');

    method.args.sort((MethodArg a, MethodArg b) {
      if (!a.optional && b.optional) return -1;
      if (a.optional && !b.optional) return 1;
      return 0;
    });
  }
}

class TypeParser extends Parser {
  TypeParser(super.startToken);

  void parseInto(Type type) {
    // class ClassList extends Response {
    //   // Docs here.
    //   @Class[] classes [optional];
    // }
    expect('class');

    Token t = expectName();
    type.rawName = t.text;
    type.name = _coerceRefType(type.rawName);
    if (consume('extends')) {
      t = expectName();
      type.superName = _coerceRefType(t.text);
    }

    expect('{');

    while (peek()!.text != '}') {
      TypeField field = TypeField(type.api, type, collectComments());
      field.type.parse(this);
      field.name = expectName().text;
      if (consume('[')) {
        expect('optional');
        expect(']');
        field.optional = true;
      }
      type.fields.add(field);
      expect(';');
    }

    // Special case for Event in order to expose binary response for
    // HeapSnapshot events.
    if (type.rawName == 'Event') {
      final comment = 'Binary data associated with the event.\n\n'
          'This is provided for the event kinds:\n  - HeapSnapshot';
      TypeField dataField = TypeField(type.api, type, comment);
      dataField.type.types.add(TypeRef('ByteData'));
      dataField.name = 'data';
      dataField.optional = true;
      type.fields.add(dataField);
    } else if (type.rawName == 'Response') {
      type.fields.removeWhere((field) => field.name == 'type');
    }

    expect('}');
  }
}

class EnumParser extends Parser {
  EnumParser(super.startToken);

  void parseInto(Enum e) {
    // enum ErrorKind { UnhandledException, Foo, Bar }
    // enum name { (comment* name ,)+ }
    expect('enum');

    Token t = expectName();
    validate(t.text == e.name, 'enum name ${e.name} equals ${t.text}');
    expect('{');

    while (!t.eof) {
      if (consume('}')) break;
      String? docs = collectComments();
      t = expectName();
      consume(',');

      e.enums.add(EnumValue(e, t.text, docs));
    }
  }
}
