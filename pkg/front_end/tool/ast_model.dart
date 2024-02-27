// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_prototype/front_end.dart';
import 'package:front_end/src/api_unstable/ddc.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart';
import 'package:front_end/src/kernel_generator_impl.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/src/printer.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';
import 'package:vm/modular/target/vm.dart';

final Uri astLibraryUri = Uri.parse('package:kernel/ast.dart');
final Uri canonicalNameLibraryUri =
    Uri.parse('package:kernel/canonical_name.dart');
Uri computePackageConfig(Uri repoDir) =>
    repoDir.resolve('.dart_tool/package_config.json');

/// Map from names of node classes that declares nominal entities that are _not_
/// referenced through a [Reference] to their identifying name, if any.
///
/// For these classes, [_fieldRuleMap] must defined whether fields of these
/// types should be consider declarations or references to the declarations.
///
/// If the identifying name is non-null, this is used to determine the
/// nominality. For instance the name of a variable declaration is taking as
/// defining its identity.
const Map<String, String?> _declarativeClassesNames = const {
  'VariableDeclaration': 'name',
  'TypeParameter': 'name',
  'StructuralParameter': 'name',
  'LabeledStatement': null,
  'SwitchCase': null,
};

/// Names of non-node, non-enum classes that should be treated as atomic
/// values.
const Set<String> _utilityClassesAsValues = const {
  'Version',
};

/// Names of subclasses of [Node] that do _not_ have a `visitX` method.
const Set<String> _classesWithoutVisitMethods = const {
  'InvocationExpression',
  'InstanceInvocationExpression',
  'NamedNode',
  'PrimitiveConstant',
};

/// Names of inner [Node] classes that are used as interfaces for (generally)
/// interchangeable classes.
///
/// For instance, when [Expression] is used as the field type, any subtype of
/// [Expression] can be used to populate the field.
const Set<String> _interchangeableClasses = const {
  'Member',
  'Statement',
  'Expression',
  'Constant',
  'DartType',
  'Initializer',
  'Pattern',
};

/// Names of subclasses of [NamedNode] that do _not_ have a `visitXReference`
/// method.
const Set<String> _classesWithoutVisitReference = const {
  'NamedNode',
  'Library',
  'PrimitiveConstant',
};

/// Map of [FieldRule]s. These consist of a map for each class name, with
/// `null` used for "any class". For each class, a map from field names to
/// [FieldRule] define exceptions to how a field should be treated.
///
/// If a field name maps to `null`, the field is not included in the [AstModel].
const Map<String?, Map<String, FieldRule?>> _fieldRuleMap = {
  null: {
    'hashCode': null,
    'parent': null,
  },
  'Component': {
    'root': null,
    '_mainMethodName': FieldRule(name: 'mainMethodName'),
    '_mode': FieldRule(name: 'mode'),
  },
  'Library': {
    '_languageVersion': FieldRule(name: 'languageVersion'),
    '_libraryId': null,
    '_classes': FieldRule(name: 'classes'),
    '_typedefs': FieldRule(name: 'typedefs'),
    '_extensions': FieldRule(name: 'extensions'),
    '_extensionTypeDeclarations': FieldRule(name: 'extensionTypeDeclarations'),
    '_fields': FieldRule(name: 'fields'),
    '_procedures': FieldRule(name: 'procedures'),
  },
  'Class': {
    'typeParameters': FieldRule(isDeclaration: true),
    '_constructorsView': null,
    '_constructorsInternal': FieldRule(name: 'constructors'),
    '_fieldsView': null,
    '_fieldsInternal': FieldRule(name: 'fields'),
    '_proceduresView': null,
    '_proceduresInternal': FieldRule(name: 'procedures'),
    '_onClause': null,
    'lazyBuilder': null,
    'dirty': null,
  },
  'Extension': {
    'typeParameters': FieldRule(isDeclaration: true),
  },
  'ExtensionTypeDeclaration': {
    'typeParameters': FieldRule(isDeclaration: true),
    '_procedures': FieldRule(name: 'procedures'),
  },
  'Field': {
    'reference': FieldRule(name: 'fieldReference'),
  },
  'TypeParameter': {
    '_variance': FieldRule(name: 'variance'),
  },
  'StructuralParameter': {
    '_variance': FieldRule(name: 'variance'),
  },
  'FunctionNode': {
    '_body': FieldRule(name: 'body'),
    'typeParameters': FieldRule(isDeclaration: true),
    'positionalParameters': FieldRule(isDeclaration: true),
    'namedParameters': FieldRule(isDeclaration: true),
  },
  'Typedef': {
    'typeParameters': FieldRule(isDeclaration: true),
  },
  'TypedefTearOff': {
    'typeParameters': FieldRule(isDeclaration: true),
  },
  'TypedefTearOffConstant': {
    'parameters': FieldRule(isDeclaration: true),
  },
  'LocalInitializer': {
    'variable': FieldRule(isDeclaration: true),
  },
  'Let': {
    'variable': FieldRule(isDeclaration: true),
  },
  'VariableGet': {
    'variable': FieldRule(isDeclaration: false),
  },
  'VariableSet': {
    'variable': FieldRule(isDeclaration: false),
  },
  'LocalFunctionInvocation': {
    'variable': FieldRule(isDeclaration: false),
  },
  'BreakStatement': {
    'target': FieldRule(isDeclaration: false),
  },
  'ForStatement': {
    'variables': FieldRule(isDeclaration: true),
  },
  'ForInStatement': {
    'variable': FieldRule(isDeclaration: true),
  },
  'SwitchStatement': {
    'cases': FieldRule(isDeclaration: true),
  },
  'ContinueSwitchStatement': {
    'target': FieldRule(isDeclaration: false),
  },
  'Catch': {
    'exception': FieldRule(isDeclaration: true),
    'stackTrace': FieldRule(isDeclaration: true),
  },
  'FunctionDeclaration': {
    'variable': FieldRule(isDeclaration: true),
  },
  'FunctionType': {
    'typeParameters': FieldRule(isDeclaration: true),
  },
  'TypeParameterType': {
    'parameter': FieldRule(isDeclaration: false),
  },
  'StructuralParameterType': {
    'parameter': FieldRule(isDeclaration: false),
  },
  'VariableDeclaration': {
    '_name': FieldRule(name: 'name'),
  },
  'AssignedVariablePattern': {
    'variable': FieldRule(isDeclaration: false),
  },
  'InvalidPattern': {
    'declaredVariables': FieldRule(isDeclaration: true),
  },
  'OrPattern': {
    'orPatternJointVariables': FieldRule(isDeclaration: false),
  },
  'VariablePattern': {
    'variable': FieldRule(isDeclaration: true),
  },
  'PatternSwitchCase': {
    'jointVariables': FieldRule(isDeclaration: true),
  },
  'PatternSwitchStatement': {
    'cases': FieldRule(isDeclaration: true),
  },
};

/// Data that determines exceptions to how fields are used.
class FieldRule {
  /// If non-null, the field should be accessed by this name.
  ///
  /// This is for instance used for private fields accessed through a public
  /// getter.
  final String? name;

  /// For fields contain ast class of kind `AstClassKind.declarative`, this
  /// value defines whether the field should be treated as a declaration or
  /// a reference to the declaration.
  final bool? isDeclaration;

  const FieldRule({this.name, this.isDeclaration});
}

/// Return the [FieldRule] to use for the [field] in [AstClass].
FieldRule? getFieldRule(AstClass astClass, Field field) {
  String name = field.name.text;
  Map<String?, FieldRule?>? leafClassMap = _fieldRuleMap[astClass.name];
  if (leafClassMap != null && leafClassMap.containsKey(name)) {
    return leafClassMap[name];
  }
  Map<String?, FieldRule?>? enclosingClassMap =
      _fieldRuleMap[field.enclosingClass!.name];
  if (enclosingClassMap != null && enclosingClassMap.containsKey(name)) {
    return enclosingClassMap[name];
  }
  Map<String?, FieldRule?>? defaultClassMap = _fieldRuleMap[null];
  if (defaultClassMap != null && defaultClassMap.containsKey(name)) {
    return defaultClassMap[name];
  }
  return new FieldRule(name: name);
}

/// Categorization of classes declared in 'package:kernel/ast.dart'.
enum AstClassKind {
  /// The root [Node] class.
  root,

  /// An abstract node class that is a superclass of a public class.
  ///
  /// For instance [Statement] and [Expression].
  inner,

  /// A concrete node class. These are the classes for which we have `visitX`
  /// methods.
  ///
  /// For instance [Procedure] and [VariableGet].
  public,

  /// An abstract node class that is a subclass of sealed class. These classes
  /// are used to extend the AST and therefore have no known concrete
  /// subclasses.
  ///
  /// For instance [AuxiliaryExpression] and [AuxiliaryType].
  auxiliary,

  /// A concrete node class that serves only as an implementation of public
  /// node class.
  ///
  /// For instance [PrivateName] and [PublicName] that implements the public
  /// node [Name].
  implementation,

  /// A node class that serves as an interface.
  ///
  /// For instance `FileUriNode`.
  interface,

  /// A named node class that declares a nominal entity that is used with a
  /// reference.
  named,

  /// A node class that declares a nominal entity but used without reference.
  ///
  /// For instance [VariableDeclaration] which introduces a new entity when it
  /// occurs in a [Block] but is used as a reference when it occurs in a
  /// [VariableGet].
  declarative,

  /// A none-node class that should be treated as a composite structure.
  ///
  /// For instance [ConstantMapEntry] which is a tuple of a [Constant] key and
  /// a [Constant] value.
  utilityAsStructure,

  /// A none-node class that should be treated as an atomic value.
  ///
  /// For instance enum classes.
  utilityAsValue,
}

class AstClass {
  final Class node;
  AstClassKind? _kind;
  final String? declarativeName;
  final bool isInterchangeable;

  AstClass? superclass;
  List<AstClass> interfaces = [];
  List<AstClass> subclasses = [];
  List<AstClass> subtypes = [];

  Map<String, AstField> fields = {};

  AstClass(this.node,
      {this.superclass,
      AstClassKind? kind,
      this.declarativeName,
      required this.isInterchangeable})
      : _kind = kind {
    if (superclass != null) {
      superclass!.subclasses.add(this);
    }
  }

  String get name => node.name;

  AstClassKind get kind {
    if (_kind == null) {
      if (node.isAbstract) {
        if (node.name.startsWith("Auxiliary")) {
          // TODO(johnniwinther): Is there a better way to determine this?
          _kind = AstClassKind.auxiliary;
        } else if (subclasses.isNotEmpty) {
          if (subclasses.every(
              (element) => element.kind == AstClassKind.implementation)) {
            _kind = AstClassKind.public;
          } else {
            _kind = AstClassKind.inner;
          }
        } else {
          _kind = AstClassKind.interface;
        }
      } else {
        if (node.name.startsWith('_')) {
          _kind = AstClassKind.implementation;
        } else {
          _kind = AstClassKind.public;
        }
      }
    }
    return _kind!;
  }

  /// Returns `true` if this class has a `visitX` method.
  ///
  /// This is only valid for subclass of [Node].
  bool get hasVisitMethod {
    switch (kind) {
      case AstClassKind.public:
      case AstClassKind.named:
      case AstClassKind.declarative:
      case AstClassKind.auxiliary:
        return !_classesWithoutVisitMethods.contains(name);
      case AstClassKind.root:
      case AstClassKind.inner:
      case AstClassKind.implementation:
      case AstClassKind.interface:
      case AstClassKind.utilityAsStructure:
      case AstClassKind.utilityAsValue:
        return false;
    }
  }

  /// Returns `true` if this class has a `visitXReference` method.
  ///
  /// This is only valid for subclass of [NamedNode] or [Constant].
  bool get hasVisitReferenceMethod {
    switch (kind) {
      case AstClassKind.public:
      case AstClassKind.named:
      case AstClassKind.declarative:
      case AstClassKind.auxiliary:
        return !_classesWithoutVisitReference.contains(name);
      case AstClassKind.root:
      case AstClassKind.inner:
      case AstClassKind.implementation:
      case AstClassKind.interface:
      case AstClassKind.utilityAsStructure:
      case AstClassKind.utilityAsValue:
        return false;
    }
  }

  String dump([String indent = ""]) {
    StringBuffer sb = new StringBuffer();
    sb.writeln('${indent}${node.name} ($kind)');
    for (AstField field in fields.values) {
      sb.write(field.dump('${indent}    '));
    }
    for (AstClass subclass in subclasses) {
      sb.write(subclass.dump('${indent}  '));
    }
    return sb.toString();
  }

  @override
  String toString() => '${runtimeType}(${name})';
}

/// Categorization of field types.
enum AstFieldKind {
  /// An atomic non-node value.
  ///
  /// For instance an [int] value.
  value,

  /// A [Node] value that is part of the tree.
  ///
  /// For instance an [Expression] value.
  node,

  /// A [Reference] value.
  reference,

  /// A reference to a declarative [Node].
  ///
  /// For instance the reference to [VariableDeclaration] in [VariableGet].
  use,

  /// A list of values.
  list,

  /// A set of values.
  set,

  /// A map of values.
  map,

  /// A non-node composite value.
  ///
  /// For instance a [ConstantMapEntry] that must be treat as a tuple of
  /// a [Constant] key and a [Constant] value.
  utility,
}

/// Structural description of a field type.
class FieldType {
  final DartType type;
  final AstFieldKind kind;

  FieldType(this.type, this.kind);

  @override
  String toString() => 'FieldType($type,$kind)';
}

class ListFieldType extends FieldType {
  final FieldType elementType;

  ListFieldType(DartType type, this.elementType)
      : super(type, AstFieldKind.list);

  @override
  String toString() => 'ListFieldType($type,$elementType)';
}

class SetFieldType extends FieldType {
  final FieldType elementType;

  SetFieldType(DartType type, this.elementType) : super(type, AstFieldKind.set);

  @override
  String toString() => 'SetFieldType($type,$elementType)';
}

class MapFieldType extends FieldType {
  final FieldType keyType;
  final FieldType valueType;

  MapFieldType(DartType type, this.keyType, this.valueType)
      : super(type, AstFieldKind.map);

  @override
  String toString() => 'MapFieldType($type,$keyType,$valueType)';
}

class UtilityFieldType extends FieldType {
  final AstClass astClass;

  UtilityFieldType(DartType type, this.astClass)
      : super(type, AstFieldKind.utility);

  @override
  String toString() => 'UtilityFieldType($type,$astClass)';
}

class AstField {
  final AstClass astClass;
  final Field node;
  final String name;
  final FieldType type;
  final AstField? parentField;

  AstField(this.astClass, this.node, this.name, this.type, this.parentField);

  String dump([String indent = ""]) {
    StringBuffer sb = new StringBuffer();
    sb.writeln('$indent$name $type');
    return sb.toString();
  }

  @override
  String toString() => '${runtimeType}(${name})';
}

class AstModel {
  final AstClass nodeClass;
  final AstClass namedNodeClass;
  final AstClass constantClass;

  AstModel(this.nodeClass, this.namedNodeClass, this.constantClass);

  /// Returns an [Iterable] for all declarative [Node] classes in the AST model.
  Iterable<AstClass> get declarativeClasses {
    return classes.where((cls) => cls.kind == AstClassKind.declarative);
  }

  /// Returns an [Iterable] for all [Node] (sub)classes in the AST model.
  Iterable<AstClass> get classes sync* {
    Iterable<AstClass> visitClass(AstClass cls) sync* {
      yield cls;
      for (AstClass subclass in cls.subclasses) {
        yield* visitClass(subclass);
      }
    }

    yield* visitClass(nodeClass);
  }
}

/// Computes the [AstModel] from 'package:kernel/ast' using [repoDir] to locate
/// the package config file.
///
/// If [printDump] is `true`, a dump of the model printed to stdout.
Future<AstModel> deriveAstModel(Uri repoDir, {bool printDump = false}) async {
  bool errorsFound = false;
  CompilerOptions options = new CompilerOptions();
  options.sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);
  options.compileSdk = true;
  options.target = new VmTarget(new TargetFlags());
  options.librariesSpecificationUri = repoDir.resolve("sdk/lib/libraries.json");
  options.environmentDefines = const {};
  options.packagesFileUri = computePackageConfig(repoDir);
  options.onDiagnostic = (DiagnosticMessage message) {
    printDiagnosticMessage(message, print);
    if (message.severity == Severity.error) {
      errorsFound = true;
    }
  };

  InternalCompilerResult compilerResult = (await kernelForProgramInternal(
    astLibraryUri,
    options,
    retainDataForTesting: true,
    requireMain: false,
    buildComponent: false,
  )) as InternalCompilerResult;
  if (errorsFound) {
    throw 'Errors found';
  }
  ClassHierarchy classHierarchy = compilerResult.classHierarchy!;
  CoreTypes coreTypes = compilerResult.coreTypes!;
  TypeEnvironment typeEnvironment =
      new TypeEnvironment(coreTypes, classHierarchy);

  Library astLibrary = compilerResult.component!.libraries
      .singleWhere((library) => library.importUri == astLibraryUri);

  void reportError(String message) {
    print(message);
    errorsFound = true;
  }

  Map<String, String?> declarativeClassesNames = {..._declarativeClassesNames};
  Set<String> classesWithoutVisitMethods = _classesWithoutVisitMethods.toSet();
  Set<String> classesWithoutVisitReference =
      _classesWithoutVisitReference.toSet();
  Map<String?, Map<String, FieldRule?>> fieldRuleMap = {..._fieldRuleMap};
  Map<String, FieldRule?> nullFieldRules = {...?fieldRuleMap.remove(null)};
  Set<String> interchangeableClasses = _interchangeableClasses.toSet();
  for (Class cls in astLibrary.classes) {
    declarativeClassesNames.remove(cls.name);
    classesWithoutVisitMethods.remove(cls.name);
    classesWithoutVisitReference.remove(cls.name);
    interchangeableClasses.remove(cls.name);

    Map<String, FieldRule?> fieldRules = {...?fieldRuleMap.remove(cls.name)};
    Set<String> renames = {};
    Class? parent = cls;
    while (parent != null && parent.enclosingLibrary == astLibrary) {
      for (Field field in parent.fields) {
        bool hasFieldRule = fieldRules.containsKey(field.name.text);
        FieldRule? fieldRule = fieldRules.remove(field.name.text);
        if (fieldRule != null) {
          if (fieldRule.name != null) {
            renames.add(fieldRule.name!);
          }
        }
        if (!hasFieldRule) {
          if (!cls.isEnum && !field.isStatic && field.name.isPrivate) {
            reportError(
                'Private field `${field.name.text}` in ${parent.name} must '
                'have a field rule.');
          }
        }
        if (nullFieldRules.containsKey(field.name.text)) {
          FieldRule? nullFieldRule = nullFieldRules.remove(field.name.text);
          if (nullFieldRule != null) {
            reportError('Only `null` is allowed for class `null`.');
          }
        }
      }
      parent = parent.superclass;
    }
    for (Procedure procedure in cls.procedures) {
      renames.remove(procedure.name.text);
    }
    if (renames.isNotEmpty) {
      reportError('Unknown procedure(s) for field redirections in '
          '${cls.name}: ${renames}');
    }
    if (fieldRules.isNotEmpty) {
      reportError(
          'Unknown field(s) for rules in ${cls.name}: ${fieldRules.keys}');
    }
  }
  if (declarativeClassesNames.isNotEmpty) {
    reportError('Unknown declarative classes: ${declarativeClassesNames}');
  }
  if (classesWithoutVisitMethods.isNotEmpty) {
    reportError('Unknown classes without visit methods: '
        '${classesWithoutVisitMethods}');
  }
  if (classesWithoutVisitReference.isNotEmpty) {
    reportError('Unknown classes without visit reference methods: '
        '${classesWithoutVisitReference}');
  }
  if (interchangeableClasses.isNotEmpty) {
    reportError('Unknown interchangeable classes: '
        '${interchangeableClasses}');
  }
  if (fieldRuleMap.isNotEmpty) {
    reportError('Unknown classes with field rules: ${fieldRuleMap.keys}');
  }

  Class classNode = astLibrary.classes.singleWhere((cls) => cls.name == 'Node');
  DartType nullableNodeType =
      classNode.getThisType(coreTypes, Nullability.nullable);

  Class classNamedNode =
      astLibrary.classes.singleWhere((cls) => cls.name == 'NamedNode');

  Class classConstant =
      astLibrary.classes.singleWhere((cls) => cls.name == 'Constant');

  Library canonicalNameLibrary = compilerResult.component!.libraries
      .singleWhere((library) => library.importUri == canonicalNameLibraryUri);

  Class referenceClass = canonicalNameLibrary.classes
      .singleWhere((cls) => cls.name == 'Reference');
  DartType nullableReferenceType =
      referenceClass.getThisType(coreTypes, Nullability.nullable);

  Set<Class> declarativeClasses = {};
  Set<DartType> declarativeTypes = {};
  for (String name in _declarativeClassesNames.keys) {
    Class cls = astLibrary.classes.singleWhere((cls) => cls.name == name);
    declarativeClasses.add(cls);
    declarativeTypes.add(cls.getThisType(coreTypes, Nullability.nullable));
  }

  Map<Class, AstClass> classMap = {};

  /// Computes the [AstClass] corresponding to [node] if [node] is declared in
  /// 'package:kernel/ast.dart'.
  AstClass? computeAstClass(Class? node) {
    if (node == null) return null;
    if (node.enclosingLibrary != astLibrary) return null;

    AstClass? astClass = classMap[node];
    if (astClass == null) {
      bool isInterchangeable = _interchangeableClasses.contains(node.name);
      if (node == classNode) {
        astClass = new AstClass(node,
            kind: AstClassKind.root, isInterchangeable: isInterchangeable);
      } else if (classHierarchy.isSubInterfaceOf(node, classNode)) {
        AstClass? superclass = computeAstClass(node.superclass);
        AstClassKind? kind;
        String? declarativeName;
        if (!node.isAbstract &&
            classHierarchy.isSubInterfaceOf(node, classNamedNode)) {
          kind = AstClassKind.named;
        } else if (declarativeClasses.contains(node)) {
          kind = AstClassKind.declarative;
          declarativeName = _declarativeClassesNames[node.name];
        }
        astClass = new AstClass(node,
            superclass: superclass,
            kind: kind,
            declarativeName: declarativeName,
            isInterchangeable: isInterchangeable);
        for (Supertype supertype in node.implementedTypes) {
          AstClass? astSupertype = computeAstClass(supertype.classNode);
          if (astSupertype != null) {
            astClass.interfaces.add(astSupertype);
            astSupertype.subtypes.add(astClass);
          }
        }
      } else if (node.isEnum || _utilityClassesAsValues.contains(node.name)) {
        astClass = new AstClass(node,
            kind: AstClassKind.utilityAsValue,
            isInterchangeable: isInterchangeable);
      } else {
        AstClass? superclass = computeAstClass(node.superclass);
        astClass = new AstClass(node,
            superclass: superclass,
            kind: AstClassKind.utilityAsStructure,
            isInterchangeable: isInterchangeable);
      }
      classMap[node] = astClass;
    }
    return astClass;
  }

  for (Class cls in astLibrary.classes) {
    computeAstClass(cls);
  }

  Set<AstClass> hasComputedFields = {};

  void computeAstFields(AstClass astClass) {
    if (!hasComputedFields.add(astClass)) return;

    void computeAstField(Field field, Substitution substitution) {
      if (field.isStatic) {
        return;
      }
      FieldRule? rule = getFieldRule(astClass, field);
      if (rule == null) {
        return;
      }
      DartType type = substitution.substituteType(field.type);

      FieldType computeFieldType(DartType type) {
        bool isDeclarativeType = false;
        for (DartType declarativeType in declarativeTypes) {
          if (type is InterfaceType &&
              typeEnvironment.isSubtypeOf(
                  type, declarativeType, SubtypeCheckMode.withNullabilities)) {
            isDeclarativeType = true;
            break;
          }
        }
        if (isDeclarativeType) {
          if (rule.isDeclaration == null) {
            reportError(
                "No field rule for '${field.name}' in ${astClass.name}.\n"
                "The field type contains the declarative type "
                "'${type.toText(defaultAstTextStrategy)}' "
                "and a rule must therefore specify "
                "whether this constitutes declarative or referential use.");
          }
          if (!rule.isDeclaration!) {
            return new FieldType(type, AstFieldKind.use);
          }
        }
        if (type is TypeDeclarationType &&
            typeEnvironment.isSubtypeOf(type, coreTypes.listNullableRawType,
                SubtypeCheckMode.withNullabilities)) {
          DartType elementType = typeEnvironment
              .getTypeArgumentsAsInstanceOf(type, coreTypes.listClass)!
              .single;
          return new ListFieldType(type, computeFieldType(elementType));
        } else if (type is TypeDeclarationType &&
            typeEnvironment.isSubtypeOf(type, coreTypes.setNullableRawType,
                SubtypeCheckMode.withNullabilities)) {
          DartType elementType = typeEnvironment
              .getTypeArgumentsAsInstanceOf(type, coreTypes.setClass)!
              .single;
          return new SetFieldType(type, computeFieldType(elementType));
        } else if (type is TypeDeclarationType &&
            typeEnvironment.isSubtypeOf(type, coreTypes.mapNullableRawType,
                SubtypeCheckMode.withNullabilities)) {
          List<DartType> typeArguments = typeEnvironment
              .getTypeArgumentsAsInstanceOf(type, coreTypes.mapClass)!;
          return new MapFieldType(type, computeFieldType(typeArguments[0]),
              computeFieldType(typeArguments[1]));
        } else if (type is InterfaceType &&
            typeEnvironment.isSubtypeOf(
                type, nullableNodeType, SubtypeCheckMode.withNullabilities)) {
          return new FieldType(type, AstFieldKind.node);
        } else if (type is InterfaceType &&
            typeEnvironment.isSubtypeOf(type, nullableReferenceType,
                SubtypeCheckMode.withNullabilities)) {
          return new FieldType(type, AstFieldKind.reference);
        } else {
          if (type is InterfaceType) {
            AstClass? astClass = classMap[type.classNode];
            if (astClass != null &&
                astClass.kind == AstClassKind.utilityAsStructure) {
              return new UtilityFieldType(type, astClass);
            }
          }
          return new FieldType(type, AstFieldKind.value);
        }
      }

      FieldType? fieldType = computeFieldType(type);
      String name = rule.name ?? field.name.text;
      astClass.fields[name] = new AstField(
          astClass, field, name, fieldType, astClass.superclass?.fields[name]);
    }

    AstClass? parent = astClass;
    Substitution substitution = Substitution.empty;
    while (parent != null) {
      for (Field field in parent.node.fields) {
        computeAstField(field, substitution);
      }
      parent = parent.superclass;
      if (parent != null) {
        substitution = Substitution.fromSupertype(
            classHierarchy.getClassAsInstanceOf(astClass.node, parent.node)!);
      }
    }
  }

  for (AstClass astClass in classMap.values) {
    computeAstFields(astClass);
  }

  AstClass astClassNode = classMap[classNode]!;
  AstClass astClassNamedNode = classMap[classNamedNode]!;
  AstClass astClassConstant = classMap[classConstant]!;

  if (printDump) {
    print(classMap[classNode]!.dump());
    for (AstClass astClass in classMap.values) {
      if (astClass != astClassNode && astClass.superclass == null) {
        print(astClass.dump());
      }
    }
  }
  if (errorsFound) {
    throw 'Errors found';
  }
  return new AstModel(astClassNode, astClassNamedNode, astClassConstant);
}
