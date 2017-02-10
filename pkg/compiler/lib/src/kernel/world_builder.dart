// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../common/backend_api.dart';
import '../common/names.dart';
import '../compile_time_constants.dart';
import '../constants/constant_system.dart';
import '../constants/constructors.dart';
import '../constants/evaluation.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../core_types.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js_backend/backend_helpers.dart';
import '../js_backend/constant_system_javascript.dart';
import '../native/native.dart' as native;
import 'element_adapter.dart';
import 'elements.dart';

/// World builder used for creating elements and types corresponding to Kernel
/// IR nodes.
// TODO(johnniwinther): Implement [ResolutionWorldBuilder].
class KernelWorldBuilder extends KernelElementAdapterMixin {
  CommonElements _commonElements;
  native.BehaviorBuilder _nativeBehaviorBuilder;
  final DiagnosticReporter reporter;
  ElementEnvironment _elementEnvironment;
  DartTypeConverter _typeConverter;

  /// Library environment. Used for fast lookup.
  KEnv _env;

  /// List of library environments by `KLibrary.libraryIndex`. This is used for
  /// fast lookup into library classes and members.
  List<KLibraryEnv> _libraryEnvs = <KLibraryEnv>[];

  /// List of class environments by `KClass.classIndex`. This is used for
  /// fast lookup into class members.
  List<KClassEnv> _classEnvs = <KClassEnv>[];

  Map<ir.Library, KLibrary> _libraryMap = <ir.Library, KLibrary>{};
  Map<ir.Class, KClass> _classMap = <ir.Class, KClass>{};
  Map<ir.TypeParameter, KTypeVariable> _typeVariableMap =
      <ir.TypeParameter, KTypeVariable>{};

  Map<ir.Member, KConstructor> _constructorMap = <ir.Member, KConstructor>{};
  // TODO(johnniwinther): Change this to a list of 'KConstructorData' class
  // holding the [ConstantConstructor] if we need more data for constructors.
  List<ir.Member> _constructorList = <ir.Member>[];
  Map<KConstructor, ConstantConstructor> _constructorConstantMap =
      <KConstructor, ConstantConstructor>{};

  Map<ir.Procedure, KFunction> _methodMap = <ir.Procedure, KFunction>{};
  Map<ir.Field, KField> _fieldMap = <ir.Field, KField>{};
  Map<ir.TreeNode, KLocalFunction> _localFunctionMap =
      <ir.TreeNode, KLocalFunction>{};

  KernelWorldBuilder(this.reporter, ir.Program program)
      : _env = new KEnv(program) {
    _elementEnvironment = new KernelElementEnvironment(this);
    _commonElements = new KernelCommonElements(_elementEnvironment);
    BackendHelpers helpers =
        new BackendHelpers(_elementEnvironment, null, _commonElements);
    ConstantEnvironment constants = new KernelConstantEnvironment(this);
    _nativeBehaviorBuilder =
        new KernelBehaviorBuilder(_commonElements, helpers, constants);
    _typeConverter = new DartTypeConverter(this);
  }

  CommonElements get commonElements => _commonElements;

  ElementEnvironment get elementEnvironment => _elementEnvironment;

  native.BehaviorBuilder get nativeBehaviorBuilder => _nativeBehaviorBuilder;

  LibraryEntity lookupLibrary(Uri uri) {
    KLibraryEnv libraryEnv = _env.lookupLibrary(uri);
    return _getLibrary(libraryEnv.library, libraryEnv);
  }

  KLibrary _getLibrary(ir.Library node, [KLibraryEnv libraryEnv]) {
    return _libraryMap.putIfAbsent(node, () {
      _libraryEnvs.add(libraryEnv ?? _env.lookupLibrary(node.importUri));
      String name = node.name;
      if (name == null) {
        // Use the file name as script name.
        String path = node.importUri.path;
        name = path.substring(path.lastIndexOf('/') + 1);
      }
      return new KLibrary(_libraryMap.length, name);
    });
  }

  MemberEntity lookupLibraryMember(KLibrary library, String name,
      {bool setter: false}) {
    KLibraryEnv libraryEnv = _libraryEnvs[library.libraryIndex];
    ir.Member member = libraryEnv.lookupMember(name, setter: setter);
    return member != null ? getMember(member) : null;
  }

  ClassEntity lookupClass(KLibrary library, String name) {
    KLibraryEnv libraryEnv = _libraryEnvs[library.libraryIndex];
    KClassEnv classEnv = libraryEnv.lookupClass(name);
    if (classEnv != null) {
      return _getClass(classEnv.cls, classEnv);
    }
    return null;
  }

  MemberEntity lookupClassMember(KClass cls, String name,
      {bool setter: false}) {
    KClassEnv classEnv = _classEnvs[cls.classIndex];
    ir.Member member = classEnv.lookupMember(name, setter: setter);
    return member != null ? getMember(member) : null;
  }

  ConstructorEntity lookupConstructor(KClass cls, String name) {
    KClassEnv classEnv = _classEnvs[cls.classIndex];
    ir.Member member = classEnv.lookupConstructor(name);
    return member != null ? getConstructor(member) : null;
  }

  KClass _getClass(ir.Class node, [KClassEnv classEnv]) {
    return _classMap.putIfAbsent(node, () {
      if (classEnv == null) {
        KLibrary library = _getLibrary(node.enclosingLibrary);
        classEnv = _libraryEnvs[library.libraryIndex].lookupClass(node.name);
      }
      _classEnvs.add(classEnv);
      return new KClass(_classMap.length, node.name);
    });
  }

  KTypeVariable _getTypeVariable(ir.TypeParameter node) {
    return _typeVariableMap.putIfAbsent(node, () {
      if (node.parent is ir.Class) {
        ir.Class cls = node.parent;
        int index = cls.typeParameters.indexOf(node);
        return new KTypeVariable(_getClass(cls), node.name, index);
      }
      if (node.parent is ir.FunctionNode) {
        ir.FunctionNode func = node.parent;
        int index = func.typeParameters.indexOf(node);
        if (func.parent is ir.Constructor) {
          ir.Constructor constructor = func.parent;
          ir.Class cls = constructor.enclosingClass;
          return _getTypeVariable(cls.typeParameters[index]);
        }
        if (func.parent is ir.Procedure) {
          ir.Procedure procedure = func.parent;
          if (procedure.kind == ir.ProcedureKind.Factory) {
            ir.Class cls = procedure.enclosingClass;
            return _getTypeVariable(cls.typeParameters[index]);
          } else {
            return new KTypeVariable(_getMethod(procedure), node.name, index);
          }
        }
      }
      throw new UnsupportedError('Unsupported type parameter type node $node.');
    });
  }

  KConstructor _getConstructor(ir.Member node) {
    return _constructorMap.putIfAbsent(node, () {
      int constructorIndex = _constructorList.length;
      KConstructor constructor;
      if (node is ir.Constructor) {
        constructor = new KGenerativeConstructor(constructorIndex,
            _getClass(node.enclosingClass), getName(node.name));
      } else {
        constructor = new KFactoryConstructor(constructorIndex,
            _getClass(node.enclosingClass), getName(node.name));
      }
      _constructorList.add(node);
      return constructor;
    });
  }

  KFunction _getMethod(ir.Procedure node) {
    return _methodMap.putIfAbsent(node, () {
      KClass enclosingClass =
          node.enclosingClass != null ? _getClass(node.enclosingClass) : null;
      Name name = getName(node.name);
      bool isStatic = node.isStatic;
      switch (node.kind) {
        case ir.ProcedureKind.Factory:
          throw new UnsupportedError("Cannot create method from factory.");
        case ir.ProcedureKind.Getter:
          return new KGetter(enclosingClass, name, isStatic: isStatic);
        case ir.ProcedureKind.Method:
        case ir.ProcedureKind.Operator:
          return new KMethod(enclosingClass, name, isStatic: isStatic);
        case ir.ProcedureKind.Setter:
          return new KSetter(enclosingClass, getName(node.name).setter,
              isStatic: isStatic);
      }
    });
  }

  KField _getField(ir.Field node) {
    return _fieldMap.putIfAbsent(node, () {
      KClass enclosingClass =
          node.enclosingClass != null ? _getClass(node.enclosingClass) : null;
      Name name = getName(node.name);
      bool isStatic = node.isStatic;
      return new KField(enclosingClass, name,
          isStatic: isStatic, isAssignable: node.isMutable);
    });
  }

  KLocalFunction _getLocal(ir.TreeNode node) {
    return _localFunctionMap.putIfAbsent(node, () {
      MemberEntity memberContext;
      Entity executableContext;
      ir.TreeNode parent = node.parent;
      while (parent != null) {
        if (parent is ir.Member) {
          executableContext = memberContext = getMember(parent);
          break;
        }
        if (parent is ir.FunctionDeclaration ||
            parent is ir.FunctionExpression) {
          KLocalFunction localFunction = _getLocal(parent);
          executableContext = localFunction;
          memberContext = localFunction.memberContext;
          break;
        }
        parent = parent.parent;
      }
      String name;
      if (node is ir.FunctionDeclaration) {
        name = node.variable.name;
      }
      return new KLocalFunction(name, memberContext, executableContext);
    });
  }

  @override
  DartType getDartType(ir.DartType type) => _typeConverter.convert(type);

  @override
  InterfaceType createInterfaceType(
      ir.Class cls, List<ir.DartType> typeArguments) {
    return new InterfaceType(getClass(cls), getDartTypes(typeArguments));
  }

  @override
  InterfaceType getInterfaceType(ir.InterfaceType type) =>
      _typeConverter.convert(type);

  @override
  List<DartType> getDartTypes(List<ir.DartType> types) {
    // TODO(johnniwinther): Add the type argument to the list literal when we
    // no longer use resolution types.
    List<DartType> list = /*<DartType>*/ [];
    types.forEach((ir.DartType type) {
      list.add(getDartType(type));
    });
    return list;
  }

  InterfaceType _getThisType(KClass cls) {
    KClassEnv env = _classEnvs[cls.classIndex];
    ir.Class node = env.cls;
    // TODO(johnniwinther): Add the type argument to the list literal when we
    // no longer use resolution types.
    return new InterfaceType(
        cls,
        new List/*<DartType>*/ .generate(node.typeParameters.length,
            (int index) {
          return new TypeVariableType(
              _getTypeVariable(node.typeParameters[index]));
        }));
  }

  InterfaceType _getRawType(KClass cls) {
    KClassEnv env = _classEnvs[cls.classIndex];
    ir.Class node = env.cls;
    // TODO(johnniwinther): Add the type argument to the list literal when we
    // no longer use resolution types.
    return new InterfaceType(
        cls,
        new List/*<DartType>*/ .filled(
            node.typeParameters.length, const DynamicType()));
  }

  @override
  FunctionType getFunctionType(ir.FunctionNode node) {
    DartType returnType = getDartType(node.returnType);
    List<DartType> parameterTypes = /*<DartType>*/ [];
    List<DartType> optionalParameterTypes = /*<DartType>*/ [];
    for (ir.VariableDeclaration variable in node.positionalParameters) {
      if (parameterTypes.length == node.requiredParameterCount) {
        optionalParameterTypes.add(getDartType(variable.type));
      } else {
        parameterTypes.add(getDartType(variable.type));
      }
    }
    List<String> namedParameters = <String>[];
    List<DartType> namedParameterTypes = /*<DartType>*/ [];
    List<ir.VariableDeclaration> sortedNamedParameters =
        node.namedParameters.toList()..sort((a, b) => a.name.compareTo(b.name));
    for (ir.VariableDeclaration variable in sortedNamedParameters) {
      namedParameters.add(variable.name);
      namedParameterTypes.add(getDartType(variable.type));
    }
    return new FunctionType(returnType, parameterTypes, optionalParameterTypes,
        namedParameters, namedParameterTypes);
  }

  LibraryEntity getLibrary(ir.Library node) => _getLibrary(node);

  @override
  Local getLocalFunction(ir.TreeNode node) => _getLocal(node);

  @override
  ClassEntity getClass(ir.Class node) => _getClass(node);

  @override
  FieldEntity getField(ir.Field node) => _getField(node);

  TypeVariableEntity getTypeVariable(ir.TypeParameter node) =>
      _getTypeVariable(node);

  @override
  FunctionEntity getMethod(ir.Procedure node) => _getMethod(node);

  @override
  MemberEntity getMember(ir.Member node) {
    if (node is ir.Field) {
      return _getField(node);
    } else if (node is ir.Constructor) {
      return _getConstructor(node);
    } else if (node is ir.Procedure) {
      if (node.kind == ir.ProcedureKind.Factory) {
        return _getConstructor(node);
      } else {
        return _getMethod(node);
      }
    }
    throw new UnsupportedError("Unexpected member: $node");
  }

  @override
  FunctionEntity getConstructor(ir.Member node) => _getConstructor(node);

  ConstantConstructor _getConstructorConstant(KConstructor constructor) {
    return _constructorConstantMap.putIfAbsent(constructor, () {
      ir.Member node = _constructorList[constructor.constructorIndex];
      if (node is ir.Constructor && node.isConst) {
        return new Constantifier(this).computeConstantConstructor(node);
      }
      throw new SpannableAssertionFailure(constructor,
          "Unexpected constructor $constructor in KernelWorldBuilder._getConstructorConstant");
    });
  }
}

/// Environment for fast lookup of program libraries.
class KEnv {
  final ir.Program program;

  Map<Uri, KLibraryEnv> _libraryMap;

  KEnv(this.program);

  /// Return the [KLibraryEnv] for the library with the canonical [uri].
  KLibraryEnv lookupLibrary(Uri uri) {
    if (_libraryMap == null) {
      _libraryMap = <Uri, KLibraryEnv>{};
      for (ir.Library library in program.libraries) {
        _libraryMap[library.importUri] = new KLibraryEnv(library);
      }
    }
    return _libraryMap[uri];
  }
}

/// Environment for fast lookup of library classes and members.
// TODO(johnniwinther): Add member lookup.
class KLibraryEnv {
  final ir.Library library;

  Map<String, KClassEnv> _classMap;
  Map<String, ir.Member> _memberMap;

  KLibraryEnv(this.library);

  /// Return the [KClassEnv] for the class [name] in [library].
  KClassEnv lookupClass(String name) {
    if (_classMap == null) {
      _classMap = <String, KClassEnv>{};
      for (ir.Class cls in library.classes) {
        _classMap[cls.name] = new KClassEnv(cls);
      }
    }
    return _classMap[name];
  }

  /// Return the [ir.Member] for the member [name] in [library].
  ir.Member lookupMember(String name, {bool setter: false}) {
    if (_memberMap == null) {
      _memberMap = <String, ir.Member>{};
      for (ir.Member member in library.members) {
        // TODO(johnniwinther): Support setter vs. getter.
        _memberMap[member.name.name] = member;
      }
    }
    return _memberMap[name];
  }
}

/// Environment for fast lookup of class members.
// TODO(johnniwinther): Add member lookup.
class KClassEnv {
  final ir.Class cls;

  Map<String, ir.Member> _constructorMap;
  Map<String, ir.Member> _memberMap;

  KClassEnv(this.cls);

  void _ensureMaps() {
    if (_memberMap == null) {
      _memberMap = <String, ir.Member>{};
      _constructorMap = <String, ir.Member>{};
      for (ir.Member member in cls.members) {
        if (member is ir.Procedure && member.kind == ir.ProcedureKind.Factory) {
          _constructorMap[member.name.name] = member;
        } else {
          // TODO(johnniwinther): Support setter vs. getter.
          _memberMap[member.name.name] = member;
        }
      }
      for (ir.Member member in cls.constructors) {
        _constructorMap[member.name.name] = member;
      }
    }
  }

  /// Return the [ir.Member] for the member [name] in [library].
  ir.Member lookupMember(String name, {bool setter: false}) {
    _ensureMaps();
    return _memberMap[name];
  }

  /// Return the [ir.Member] for the member [name] in [library].
  ir.Member lookupConstructor(String name, {bool setter: false}) {
    _ensureMaps();
    return _constructorMap[name];
  }
}

class KernelElementEnvironment implements ElementEnvironment {
  final KernelWorldBuilder worldBuilder;

  KernelElementEnvironment(this.worldBuilder);

  @override
  InterfaceType getThisType(ClassEntity cls) {
    return worldBuilder._getThisType(cls);
  }

  @override
  InterfaceType getRawType(ClassEntity cls) {
    return worldBuilder._getRawType(cls);
  }

  @override
  InterfaceType createInterfaceType(
      ClassEntity cls, List<DartType> typeArguments) {
    return new InterfaceType(cls, typeArguments);
  }

  @override
  ConstructorEntity lookupConstructor(ClassEntity cls, String name,
      {bool required: false}) {
    ConstructorEntity constructor = worldBuilder.lookupConstructor(cls, name);
    if (constructor == null && required) {
      throw new SpannableAssertionFailure(CURRENT_ELEMENT_SPANNABLE,
          "The constructor $name was not found in class '${cls.name}'.");
    }
    return constructor;
  }

  @override
  MemberEntity lookupClassMember(ClassEntity cls, String name,
      {bool setter: false, bool required: false}) {
    MemberEntity member =
        worldBuilder.lookupClassMember(cls, name, setter: setter);
    if (member == null && required) {
      throw new SpannableAssertionFailure(CURRENT_ELEMENT_SPANNABLE,
          "The member '$name' was not found in ${cls.name}.");
    }
    return member;
  }

  @override
  MemberEntity lookupLibraryMember(LibraryEntity library, String name,
      {bool setter: false, bool required: false}) {
    MemberEntity member =
        worldBuilder.lookupLibraryMember(library, name, setter: setter);
    if (member == null && required) {
      throw new SpannableAssertionFailure(CURRENT_ELEMENT_SPANNABLE,
          "The member '${name}' was not found in library '${library.name}'.");
    }
    return member;
  }

  @override
  ClassEntity lookupClass(LibraryEntity library, String name,
      {bool required: false}) {
    ClassEntity cls = worldBuilder.lookupClass(library, name);
    if (cls == null && required) {
      throw new SpannableAssertionFailure(CURRENT_ELEMENT_SPANNABLE,
          "The class '$name'  was not found in library '${library.name}'.");
    }
    return cls;
  }

  @override
  LibraryEntity lookupLibrary(Uri uri, {bool required: false}) {
    LibraryEntity library = worldBuilder.lookupLibrary(uri);
    if (library == null && required) {
      throw new SpannableAssertionFailure(
          CURRENT_ELEMENT_SPANNABLE, "The library '$uri' was not found.");
    }
    return library;
  }
}

/// [CommonElements] implementation based on [KernelWorldBuilder].
class KernelCommonElements extends CommonElementsMixin {
  final ElementEnvironment environment;

  KernelCommonElements(this.environment);

  @override
  LibraryEntity get coreLibrary {
    return environment.lookupLibrary(Uris.dart_core, required: true);
  }

  @override
  DynamicType get dynamicType => const DynamicType();

  @override
  ClassEntity get nativeAnnotationClass {
    throw new UnimplementedError('KernelCommonElements.nativeAnnotationClass');
  }

  @override
  ClassEntity get patchAnnotationClass {
    throw new UnimplementedError('KernelCommonElements.patchAnnotationClass');
  }

  @override
  LibraryEntity get typedDataLibrary {
    throw new UnimplementedError('KernelCommonElements.typedDataLibrary');
  }

  @override
  LibraryEntity get mirrorsLibrary {
    throw new UnimplementedError('KernelCommonElements.mirrorsLibrary');
  }

  @override
  LibraryEntity get asyncLibrary {
    throw new UnimplementedError('KernelCommonElements.asyncLibrary');
  }
}

/// Visitor that converts kernel dart types into [DartType].
class DartTypeConverter extends ir.DartTypeVisitor<DartType> {
  final KernelWorldBuilder elementAdapter;
  bool topLevel = true;

  DartTypeConverter(this.elementAdapter);

  DartType convert(ir.DartType type) {
    topLevel = true;
    return type.accept(this);
  }

  /// Visit a inner type.
  DartType visitType(ir.DartType type) {
    topLevel = false;
    return type.accept(this);
  }

  List<DartType> visitTypes(List<ir.DartType> types) {
    topLevel = false;
    return new List.generate(
        types.length, (int index) => types[index].accept(this));
  }

  @override
  DartType visitTypeParameterType(ir.TypeParameterType node) {
    return new TypeVariableType(elementAdapter.getTypeVariable(node.parameter));
  }

  @override
  DartType visitFunctionType(ir.FunctionType node) {
    return new FunctionType(
        visitType(node.returnType),
        visitTypes(node.positionalParameters
            .take(node.requiredParameterCount)
            .toList()),
        visitTypes(node.positionalParameters
            .skip(node.requiredParameterCount)
            .toList()),
        node.namedParameters.map((n) => n.name).toList(),
        node.namedParameters.map((n) => visitType(n.type)).toList());
  }

  @override
  DartType visitInterfaceType(ir.InterfaceType node) {
    ClassEntity cls = elementAdapter.getClass(node.classNode);
    return new InterfaceType(cls, visitTypes(node.typeArguments));
  }

  @override
  DartType visitVoidType(ir.VoidType node) {
    return const VoidType();
  }

  @override
  DartType visitDynamicType(ir.DynamicType node) {
    return const DynamicType();
  }

  @override
  DartType visitInvalidType(ir.InvalidType node) {
    if (topLevel) {
      throw new UnimplementedError(
          "Outermost invalid types not currently supported");
    }
    // Nested invalid types are treated as `dynamic`.
    return const DynamicType();
  }
}

/// [native.BehaviorBuilder] for kernel based elements.
class KernelBehaviorBuilder extends native.BehaviorBuilder {
  final CommonElements commonElements;
  final BackendHelpers helpers;
  final ConstantEnvironment constants;

  KernelBehaviorBuilder(this.commonElements, this.helpers, this.constants);

  @override
  bool get trustJSInteropTypeAnnotations {
    throw new UnimplementedError(
        "KernelNativeBehaviorComputer.trustJSInteropTypeAnnotations");
  }

  @override
  DiagnosticReporter get reporter {
    throw new UnimplementedError("KernelNativeBehaviorComputer.reporter");
  }

  @override
  BackendClasses get backendClasses {
    throw new UnimplementedError("KernelNativeBehaviorComputer.backendClasses");
  }
}

/// Constant environment mapping [ConstantExpression]s to [ConstantValue]s using
/// [_EvaluationEnvironment] for the evaluation.
class KernelConstantEnvironment implements ConstantEnvironment {
  KernelWorldBuilder _worldBuilder;
  Map<ConstantExpression, ConstantValue> _valueMap =
      <ConstantExpression, ConstantValue>{};

  KernelConstantEnvironment(this._worldBuilder);

  @override
  ConstantSystem get constantSystem => const JavaScriptConstantSystem();

  @override
  ConstantValue getConstantValueForVariable(VariableElement element) {
    throw new UnimplementedError(
        "KernelConstantEnvironment.getConstantValueForVariable");
  }

  @override
  ConstantValue getConstantValue(ConstantExpression expression) {
    return _valueMap.putIfAbsent(expression, () {
      return expression.evaluate(
          new _EvaluationEnvironment(_worldBuilder), constantSystem);
    });
  }

  @override
  bool hasConstantValue(ConstantExpression expression) {
    throw new UnimplementedError("KernelConstantEnvironment.hasConstantValue");
  }
}

/// Evaluation environment used for computing [ConstantValue]s for
/// kernel based [ConstantExpression]s.
class _EvaluationEnvironment implements Environment {
  final KernelWorldBuilder _worldBuilder;

  _EvaluationEnvironment(this._worldBuilder);

  @override
  CommonElements get commonElements {
    throw new UnimplementedError("_EvaluationEnvironment.commonElements");
  }

  @override
  BackendClasses get backendClasses {
    throw new UnimplementedError("_EvaluationEnvironment.backendClasses");
  }

  @override
  InterfaceType substByContext(InterfaceType base, InterfaceType target) {
    if (base.typeArguments.isNotEmpty) {
      throw new UnimplementedError("_EvaluationEnvironment.substByContext");
    }
    return base;
  }

  @override
  ConstantConstructor getConstructorConstant(ConstructorEntity constructor) {
    return _worldBuilder._getConstructorConstant(constructor);
  }

  @override
  ConstantExpression getFieldConstant(FieldEntity field) {
    throw new UnimplementedError("_EvaluationEnvironment.getFieldConstant");
  }

  @override
  ConstantExpression getLocalConstant(Local local) {
    throw new UnimplementedError("_EvaluationEnvironment.getLocalConstant");
  }

  @override
  String readFromEnvironment(String name) {
    throw new UnimplementedError("_EvaluationEnvironment.readFromEnvironment");
  }
}

// Interface for testing equivalence of Kernel-based entities.
class WorldDeconstructionForTesting {
  final KernelWorldBuilder builder;

  WorldDeconstructionForTesting(this.builder);

  Uri getLibraryUri(KLibrary library) {
    return builder._libraryEnvs[library.libraryIndex].library.importUri;
  }

  KLibrary getLibraryForClass(KClass cls) {
    KClassEnv env = builder._classEnvs[cls.classIndex];
    return builder.getLibrary(env.cls.enclosingLibrary);
  }

  KLibrary _getLibrary<E>(E member, Map<ir.Member, E> map) {
    ir.Library library;
    map.forEach((ir.Member node, E other) {
      if (library == null && member == other) {
        library = node.enclosingLibrary;
      }
    });
    if (library == null) {
      throw new ArgumentError("No library found for $member");
    }
    return builder._getLibrary(library);
  }

  KLibrary getLibraryForFunction(KFunction function) =>
      _getLibrary(function, builder._methodMap);

  KLibrary getLibraryForField(KField field) =>
      _getLibrary(field, builder._fieldMap);
}
