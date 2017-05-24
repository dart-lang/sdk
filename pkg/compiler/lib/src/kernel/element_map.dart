// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../common/names.dart';
import '../constants/constructors.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../common_elements.dart';
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/operators.dart';
import '../elements/types.dart';
import '../js_backend/backend.dart' show JavaScriptBackend;
import '../native/native.dart' as native;
import '../universe/call_structure.dart';
import '../universe/selector.dart';
import 'kernel_debug.dart';

/// Interface that translates between Kernel IR nodes and entities.
abstract class KernelToElementMap {
  /// Access to the commonly used elements and types.
  CommonElements get commonElements;

  /// [ElementEnvironment] for library, class and member lookup.
  ElementEnvironment get elementEnvironment;

  /// Returns the [DartType] corresponding to [type].
  DartType getDartType(ir.DartType type);

  /// Returns the list of [DartType]s corresponding to [types].
  List<DartType> getDartTypes(List<ir.DartType> types);

  /// Returns the [InterfaceType] corresponding to [type].
  InterfaceType getInterfaceType(ir.InterfaceType type);

  /// Return the [InterfaceType] corresponding to the [cls] with the given
  /// [typeArguments].
  InterfaceType createInterfaceType(
      ir.Class cls, List<ir.DartType> typeArguments);

  /// Returns the [CallStructure] corresponding to the [arguments].
  CallStructure getCallStructure(ir.Arguments arguments);

  /// Returns the [Selector] corresponding to the invocation or getter/setter
  /// access of [node].
  Selector getSelector(ir.Expression node);

  /// Returns the [ConstructorEntity] corresponding to the generative or factory
  /// constructor [node].
  ConstructorEntity getConstructor(ir.Member node);

  /// Returns the [ConstructorEntity] corresponding to a super initializer in
  /// [constructor].
  ///
  /// The IR resolves super initializers to a [target] up in the type hierarchy.
  /// Most of the time, the result of this function will be the entity
  /// corresponding to that target. In the presence of unnamed mixins, this
  /// function returns an entity for an intermediate synthetic constructor that
  /// kernel doesn't explicitly represent.
  ///
  /// For example:
  ///     class M {}
  ///     class C extends Object with M {}
  ///
  /// Kernel will say that C()'s super initializer resolves to Object(), but
  /// this function will return an entity representing the unnamed mixin
  /// application "Object+M"'s constructor.
  ConstructorEntity getSuperConstructor(
      ir.Constructor constructor, ir.Member target);

  /// Returns the [MemberEntity] corresponding to the member [node].
  MemberEntity getMember(ir.Member node);

  /// Returns the [FunctionEntity] corresponding to the procedure [node].
  FunctionEntity getMethod(ir.Procedure node);

  /// Returns the super [MemberEntity] for a super invocation, get or set of
  /// [name] from the member [context].
  ///
  /// The IR doesn't always resolve super accesses to the corresponding
  /// [target]. If not, the target is computed using [name] and [setter] from
  /// the enclosing class of [context].
  MemberEntity getSuperMember(ir.Member context, ir.Name name, ir.Member target,
      {bool setter: false});

  /// Returns the [FieldEntity] corresponding to the field [node].
  FieldEntity getField(ir.Field node);

  /// Returns the [ClassEntity] corresponding to the class [node].
  ClassEntity getClass(ir.Class node);

  /// Returns the [Local] corresponding to the [node]. The node must be either
  /// a [ir.FunctionDeclaration] or [ir.FunctionExpression].
  Local getLocalFunction(ir.TreeNode node);

  /// Returns the [LibraryEntity] corresponding to the library [node].
  LibraryEntity getLibrary(ir.Library node);

  /// Returns the [Name] corresponding to [name].
  Name getName(ir.Name name);

  /// Returns `true` is [node] has a `@Native(...)` annotation.
  bool isNativeClass(ir.Class node);

  /// Return `true` if [node] is the `dart:_foreign_helper` library.
  bool isForeignLibrary(ir.Library node);

  /// Computes the native behavior for reading the native [field].
  native.NativeBehavior getNativeBehaviorForFieldLoad(ir.Field field,
      {bool isJsInterop});

  /// Computes the native behavior for writing to the native [field].
  native.NativeBehavior getNativeBehaviorForFieldStore(ir.Field field);

  /// Computes the native behavior for calling [procedure].
  native.NativeBehavior getNativeBehaviorForMethod(ir.Procedure procedure,
      {bool isJsInterop});

  /// Computes the [native.NativeBehavior] for a call to the [JS] function.
  native.NativeBehavior getNativeBehaviorForJsCall(ir.StaticInvocation node);

  /// Computes the [native.NativeBehavior] for a call to the [JS_BUILTIN]
  /// function.
  native.NativeBehavior getNativeBehaviorForJsBuiltinCall(
      ir.StaticInvocation node);

  /// Computes the [native.NativeBehavior] for a call to the
  /// [JS_EMBEDDED_GLOBAL] function.
  native.NativeBehavior getNativeBehaviorForJsEmbeddedGlobalCall(
      ir.StaticInvocation node);

  /// Compute the kind of foreign helper function called by [node], if any.
  ForeignKind getForeignKind(ir.StaticInvocation node);

  /// Computes the [InterfaceType] referenced by a call to the
  /// [JS_INTERCEPTOR_CONSTANT] function, if any.
  InterfaceType getInterfaceTypeForJsInterceptorCall(ir.StaticInvocation node);

  /// Computes the [ConstantValue] for the constant [expression].
  ConstantValue getConstantValue(ir.Expression expression);

  /// Returns the `noSuchMethod` [FunctionEntity] call from a
  /// `super.noSuchMethod` invocation within [cls].
  FunctionEntity getSuperNoSuchMethod(ClassEntity cls);
}

/// Kinds of foreign functions.
enum ForeignKind {
  JS,
  JS_BUILTIN,
  JS_EMBEDDED_GLOBAL,
  JS_INTERCEPTOR_CONSTANT,
  NONE,
}

abstract class KernelToElementMapMixin implements KernelToElementMap {
  DiagnosticReporter get reporter;
  FunctionType getFunctionType(ir.FunctionNode node);
  native.BehaviorBuilder get nativeBehaviorBuilder;
  ConstantValue computeConstantValue(ConstantExpression constant);

  @override
  Name getName(ir.Name name) {
    return new Name(
        name.name, name.isPrivate ? getLibrary(name.library) : null);
  }

  @override
  CallStructure getCallStructure(ir.Arguments arguments) {
    int argumentCount = arguments.positional.length + arguments.named.length;
    List<String> namedArguments = arguments.named.map((e) => e.name).toList();
    return new CallStructure(argumentCount, namedArguments);
  }

  @override
  Selector getSelector(ir.Expression node) {
    // TODO(efortuna): This is screaming for a common interface between
    // PropertyGet and SuperPropertyGet (and same for *Get). Talk to kernel
    // folks.
    if (node is ir.PropertyGet) {
      return getGetterSelector(node.name);
    }
    if (node is ir.SuperPropertyGet) {
      return getGetterSelector(node.name);
    }
    if (node is ir.PropertySet) {
      return getSetterSelector(node.name);
    }
    if (node is ir.SuperPropertySet) {
      return getSetterSelector(node.name);
    }
    if (node is ir.InvocationExpression) {
      return getInvocationSelector(node);
    }
    throw new SpannableAssertionFailure(
        CURRENT_ELEMENT_SPANNABLE,
        "Can only get the selector for a property get or an invocation: "
        "${node}");
  }

  Selector getInvocationSelector(ir.InvocationExpression invocation) {
    Name name = getName(invocation.name);
    SelectorKind kind;
    if (Selector.isOperatorName(name.text)) {
      if (name == Names.INDEX_NAME || name == Names.INDEX_SET_NAME) {
        kind = SelectorKind.INDEX;
      } else {
        kind = SelectorKind.OPERATOR;
      }
    } else {
      kind = SelectorKind.CALL;
    }

    CallStructure callStructure = getCallStructure(invocation.arguments);
    return new Selector(kind, name, callStructure);
  }

  Selector getGetterSelector(ir.Name irName) {
    Name name = new Name(
        irName.name, irName.isPrivate ? getLibrary(irName.library) : null);
    return new Selector.getter(name);
  }

  Selector getSetterSelector(ir.Name irName) {
    Name name = new Name(
        irName.name, irName.isPrivate ? getLibrary(irName.library) : null);
    return new Selector.setter(name);
  }

  ConstantValue getConstantValue(ir.Expression node) {
    ConstantExpression constant = new Constantifier(this).visit(node);
    if (constant == null) {
      throw new UnsupportedError(
          'No constant for ${DebugPrinter.prettyPrint(node)}');
    }
    return computeConstantValue(constant);
  }

  /// Converts [annotations] into a list of [ConstantValue]s.
  List<ConstantValue> getMetadata(List<ir.Expression> annotations) {
    if (annotations.isEmpty) return const <ConstantValue>[];
    List<ConstantValue> metadata = <ConstantValue>[];
    annotations.forEach((ir.Expression node) {
      metadata.add(getConstantValue(node));
    });
    return metadata;
  }

  /// Returns `true` is [node] has a `@Native(...)` annotation.
  // TODO(johnniwinther): Cache this for later use.
  bool isNativeClass(ir.Class node) {
    for (ir.Expression annotation in node.annotations) {
      if (annotation is ir.ConstructorInvocation) {
        FunctionEntity target = getConstructor(annotation.target);
        if (target.enclosingClass == commonElements.nativeAnnotationClass) {
          return true;
        }
      }
    }
    return false;
  }

  /// Compute the kind of foreign helper function called by [node], if any.
  ForeignKind getForeignKind(ir.StaticInvocation node) {
    if (isForeignLibrary(node.target.enclosingLibrary)) {
      switch (node.target.name.name) {
        case JavaScriptBackend.JS:
          return ForeignKind.JS;
        case JavaScriptBackend.JS_BUILTIN:
          return ForeignKind.JS_BUILTIN;
        case JavaScriptBackend.JS_EMBEDDED_GLOBAL:
          return ForeignKind.JS_EMBEDDED_GLOBAL;
        case JavaScriptBackend.JS_INTERCEPTOR_CONSTANT:
          return ForeignKind.JS_INTERCEPTOR_CONSTANT;
      }
    }
    return ForeignKind.NONE;
  }

  /// Return `true` if [node] is the `dart:_foreign_helper` library.
  bool isForeignLibrary(ir.Library node) {
    return node.importUri == Uris.dart__foreign_helper;
  }

  /// Looks up [typeName] for use in the spec-string of a `JS` called.
  // TODO(johnniwinther): Use this in [native.NativeBehavior] instead of calling
  // the `ForeignResolver`.
  // TODO(johnniwinther): Cache the result to avoid redundant lookups?
  native.TypeLookup typeLookup({bool resolveAsRaw: true}) {
    DartType lookup(String typeName, {bool required}) {
      DartType findIn(Uri uri) {
        LibraryEntity library = elementEnvironment.lookupLibrary(uri);
        if (library != null) {
          ClassEntity cls = elementEnvironment.lookupClass(library, typeName);
          if (cls != null) {
            // TODO(johnniwinther): Align semantics.
            return resolveAsRaw
                ? elementEnvironment.getRawType(cls)
                : elementEnvironment.getThisType(cls);
          }
        }
        return null;
      }

      // TODO(johnniwinther): Narrow the set of lookups base on the depending
      // library.
      DartType type = findIn(Uris.dart_core);
      type ??= findIn(Uris.dart__js_helper);
      type ??= findIn(Uris.dart__interceptors);
      type ??= findIn(Uris.dart__isolate_helper);
      type ??= findIn(Uris.dart__native_typed_data);
      type ??= findIn(Uris.dart_collection);
      type ??= findIn(Uris.dart_math);
      type ??= findIn(Uris.dart_html);
      type ??= findIn(Uris.dart_html_common);
      type ??= findIn(Uris.dart_svg);
      type ??= findIn(Uris.dart_web_audio);
      type ??= findIn(Uris.dart_web_gl);
      type ??= findIn(Uris.dart_web_sql);
      type ??= findIn(Uris.dart_indexed_db);
      type ??= findIn(Uris.dart_typed_data);
      if (type == null && required) {
        reporter.reportErrorMessage(CURRENT_ELEMENT_SPANNABLE,
            MessageKind.GENERIC, {'text': "Type '$typeName' not found."});
      }
      return type;
    }

    return lookup;
  }

  String _getStringArgument(ir.StaticInvocation node, int index) {
    return node.arguments.positional[index].accept(new Stringifier());
  }

  /// Computes the [native.NativeBehavior] for a call to the [JS] function.
  // TODO(johnniwinther): Cache this for later use.
  native.NativeBehavior getNativeBehaviorForJsCall(ir.StaticInvocation node) {
    if (node.arguments.positional.length < 2 ||
        node.arguments.named.isNotEmpty) {
      reporter.reportErrorMessage(
          CURRENT_ELEMENT_SPANNABLE, MessageKind.WRONG_ARGUMENT_FOR_JS);
      return new native.NativeBehavior();
    }
    String specString = _getStringArgument(node, 0);
    if (specString == null) {
      reporter.reportErrorMessage(
          CURRENT_ELEMENT_SPANNABLE, MessageKind.WRONG_ARGUMENT_FOR_JS_FIRST);
      return new native.NativeBehavior();
    }

    String codeString = _getStringArgument(node, 1);
    if (codeString == null) {
      reporter.reportErrorMessage(
          CURRENT_ELEMENT_SPANNABLE, MessageKind.WRONG_ARGUMENT_FOR_JS_SECOND);
      return new native.NativeBehavior();
    }

    return native.NativeBehavior.ofJsCall(
        specString,
        codeString,
        typeLookup(resolveAsRaw: true),
        CURRENT_ELEMENT_SPANNABLE,
        reporter,
        commonElements);
  }

  /// Computes the [native.NativeBehavior] for a call to the [JS_BUILTIN]
  /// function.
  // TODO(johnniwinther): Cache this for later use.
  native.NativeBehavior getNativeBehaviorForJsBuiltinCall(
      ir.StaticInvocation node) {
    if (node.arguments.positional.length < 1) {
      reporter.internalError(
          CURRENT_ELEMENT_SPANNABLE, "JS builtin expression has no type.");
      return new native.NativeBehavior();
    }
    if (node.arguments.positional.length < 2) {
      reporter.internalError(
          CURRENT_ELEMENT_SPANNABLE, "JS builtin is missing name.");
      return new native.NativeBehavior();
    }
    String specString = _getStringArgument(node, 0);
    if (specString == null) {
      reporter.internalError(
          CURRENT_ELEMENT_SPANNABLE, "Unexpected first argument.");
      return new native.NativeBehavior();
    }
    return native.NativeBehavior.ofJsBuiltinCall(
        specString,
        typeLookup(resolveAsRaw: true),
        CURRENT_ELEMENT_SPANNABLE,
        reporter,
        commonElements);
  }

  /// Computes the [native.NativeBehavior] for a call to the
  /// [JS_EMBEDDED_GLOBAL] function.
  // TODO(johnniwinther): Cache this for later use.
  native.NativeBehavior getNativeBehaviorForJsEmbeddedGlobalCall(
      ir.StaticInvocation node) {
    if (node.arguments.positional.length < 1) {
      reporter.internalError(CURRENT_ELEMENT_SPANNABLE,
          "JS embedded global expression has no type.");
      return new native.NativeBehavior();
    }
    if (node.arguments.positional.length < 2) {
      reporter.internalError(
          CURRENT_ELEMENT_SPANNABLE, "JS embedded global is missing name.");
      return new native.NativeBehavior();
    }
    if (node.arguments.positional.length > 2 ||
        node.arguments.named.isNotEmpty) {
      reporter.internalError(CURRENT_ELEMENT_SPANNABLE,
          "JS embedded global has more than 2 arguments.");
      return new native.NativeBehavior();
    }
    String specString = _getStringArgument(node, 0);
    if (specString == null) {
      reporter.internalError(
          CURRENT_ELEMENT_SPANNABLE, "Unexpected first argument.");
      return new native.NativeBehavior();
    }
    return native.NativeBehavior.ofJsEmbeddedGlobalCall(
        specString,
        typeLookup(resolveAsRaw: true),
        CURRENT_ELEMENT_SPANNABLE,
        reporter,
        commonElements);
  }

  /// Computes the [InterfaceType] referenced by a call to the
  /// [JS_INTERCEPTOR_CONSTANT] function, if any.
  InterfaceType getInterfaceTypeForJsInterceptorCall(ir.StaticInvocation node) {
    if (node.arguments.positional.length != 1 ||
        node.arguments.named.isNotEmpty) {
      reporter.reportErrorMessage(CURRENT_ELEMENT_SPANNABLE,
          MessageKind.WRONG_ARGUMENT_FOR_JS_INTERCEPTOR_CONSTANT);
    }
    ir.Node argument = node.arguments.positional.first;
    if (argument is ir.TypeLiteral && argument.type is ir.InterfaceType) {
      return getInterfaceType(argument.type);
    }
    return null;
  }

  /// Computes the native behavior for reading the native [field].
  // TODO(johnniwinther): Cache this for later use.
  native.NativeBehavior getNativeBehaviorForFieldLoad(ir.Field field,
      {bool isJsInterop}) {
    DartType type = getDartType(field.type);
    List<ConstantValue> metadata = getMetadata(field.annotations);
    return nativeBehaviorBuilder.buildFieldLoadBehavior(
        type, metadata, typeLookup(resolveAsRaw: false),
        isJsInterop: isJsInterop);
  }

  /// Computes the native behavior for writing to the native [field].
  // TODO(johnniwinther): Cache this for later use.
  native.NativeBehavior getNativeBehaviorForFieldStore(ir.Field field) {
    DartType type = getDartType(field.type);
    return nativeBehaviorBuilder.buildFieldStoreBehavior(type);
  }

  /// Computes the native behavior for calling [procedure].
  // TODO(johnniwinther): Cache this for later use.
  native.NativeBehavior getNativeBehaviorForMethod(ir.Procedure procedure,
      {bool isJsInterop}) {
    DartType type = getFunctionType(procedure.function);
    List<ConstantValue> metadata = getMetadata(procedure.annotations);
    return nativeBehaviorBuilder.buildMethodBehavior(
        type, metadata, typeLookup(resolveAsRaw: false),
        isJsInterop: isJsInterop);
  }

  @override
  FunctionEntity getSuperNoSuchMethod(ClassEntity cls) {
    while (cls != null) {
      cls = elementEnvironment.getSuperClass(cls);
      MemberEntity member =
          elementEnvironment.lookupClassMember(cls, Identifiers.noSuchMethod_);
      if (member != null) {
        if (member.isFunction) {
          FunctionEntity function = member;
          if (function.parameterStructure.positionalParameters >= 1) {
            return function;
          }
        }
        // If [member] is not a valid `noSuchMethod` the target is
        // `Object.superNoSuchMethod`.
        break;
      }
    }
    FunctionEntity function = elementEnvironment.lookupClassMember(
        commonElements.objectClass, Identifiers.noSuchMethod_);
    assert(invariant(cls, function != null,
        message: "No super noSuchMethod found for class $cls."));
    return function;
  }
}

/// Visitor that converts string literals and concatenations of string literals
/// into the string value.
class Stringifier extends ir.ExpressionVisitor<String> {
  @override
  String visitStringLiteral(ir.StringLiteral node) => node.value;

  @override
  String visitStringConcatenation(ir.StringConcatenation node) {
    StringBuffer sb = new StringBuffer();
    for (ir.Expression expression in node.expressions) {
      String value = expression.accept(this);
      if (value == null) return null;
      sb.write(value);
    }
    return sb.toString();
  }
}

/// Visitor that converts a kernel constant expression into a
/// [ConstantExpression].
class Constantifier extends ir.ExpressionVisitor<ConstantExpression> {
  final bool requireConstant;
  final KernelToElementMapMixin elementAdapter;

  Constantifier(this.elementAdapter, {this.requireConstant: true});

  CommonElements get _commonElements => elementAdapter.commonElements;

  ConstantExpression visit(ir.Expression node) {
    ConstantExpression constant = node.accept(this);
    if (constant == null && requireConstant) {
      throw new UnsupportedError(
          "No constant computed for $node (${node.runtimeType})");
    }
    return constant;
  }

  ConstantExpression defaultExpression(ir.Expression node) {
    throw new UnimplementedError(
        'Unimplemented constant expression $node (${node.runtimeType})');
  }

  List<ConstantExpression> _computeList(List<ir.Expression> expressions) {
    List<ConstantExpression> list = <ConstantExpression>[];
    for (ir.Expression expression in expressions) {
      ConstantExpression constant = visit(expression);
      if (constant == null) return null;
      list.add(constant);
    }
    return list;
  }

  List<ConstantExpression> _computeArguments(ir.Arguments node) {
    List<ConstantExpression> arguments = <ConstantExpression>[];
    for (ir.Expression argument in node.positional) {
      ConstantExpression constant = visit(argument);
      if (constant == null) return null;
      arguments.add(constant);
    }
    for (ir.NamedExpression argument in node.named) {
      ConstantExpression constant = visit(argument.value);
      if (constant == null) return null;
      arguments.add(constant);
    }
    return arguments;
  }

  ConstructedConstantExpression _computeConstructorInvocation(
      ir.Constructor target, ir.Arguments arguments) {
    return new ConstructedConstantExpression(
        elementAdapter.createInterfaceType(
            target.enclosingClass, arguments.types),
        elementAdapter.getConstructor(target),
        elementAdapter.getCallStructure(arguments),
        _computeArguments(arguments));
  }

  @override
  ConstantExpression visitConstructorInvocation(ir.ConstructorInvocation node) {
    return _computeConstructorInvocation(node.target, node.arguments);
  }

  @override
  ConstantExpression visitVariableGet(ir.VariableGet node) {
    if (node.variable.parent is ir.FunctionNode) {
      ir.FunctionNode function = node.variable.parent;
      int index = function.positionalParameters.indexOf(node.variable);
      if (index != -1) {
        return new PositionalArgumentReference(index);
      } else {
        assert(function.namedParameters.contains(node.variable));
        return new NamedArgumentReference(node.variable.name);
      }
    }
    throw new UnimplementedError(
        'Unimplemented constant expression $node (${node.runtimeType})');
  }

  @override
  ConstantExpression visitStaticGet(ir.StaticGet node) {
    if (node.target is ir.Field) {
      return new FieldConstantExpression(elementAdapter.getField(node.target));
    } else if (node.target is ir.Procedure) {
      FunctionEntity function = elementAdapter.getMethod(node.target);
      DartType type = elementAdapter.getFunctionType(node.target.function);
      return new FunctionConstantExpression(function, type);
    }
    throw new UnimplementedError(
        'Unexpected constant expression $node (${node.runtimeType})');
  }

  @override
  ConstantExpression visitNullLiteral(ir.NullLiteral node) {
    return new NullConstantExpression();
  }

  @override
  ConstantExpression visitBoolLiteral(ir.BoolLiteral node) {
    return new BoolConstantExpression(node.value);
  }

  @override
  ConstantExpression visitIntLiteral(ir.IntLiteral node) {
    return new IntConstantExpression(node.value);
  }

  @override
  ConstantExpression visitDoubleLiteral(ir.DoubleLiteral node) {
    return new DoubleConstantExpression(node.value);
  }

  @override
  ConstantExpression visitStringLiteral(ir.StringLiteral node) {
    return new StringConstantExpression(node.value);
  }

  @override
  ConstantExpression visitSymbolLiteral(ir.SymbolLiteral node) {
    return new SymbolConstantExpression(node.value);
  }

  @override
  ConstantExpression visitStringConcatenation(ir.StringConcatenation node) {
    return new ConcatenateConstantExpression(_computeList(node.expressions));
  }

  @override
  ConstantExpression visitMapLiteral(ir.MapLiteral node) {
    if (!node.isConst) {
      throw new UnimplementedError(
          'Unexpected constant expression $node (${node.runtimeType})');
    }
    DartType keyType = elementAdapter.getDartType(node.keyType);
    DartType valueType = elementAdapter.getDartType(node.valueType);
    List<ConstantExpression> keys = <ConstantExpression>[];
    List<ConstantExpression> values = <ConstantExpression>[];
    for (ir.MapEntry entry in node.entries) {
      keys.add(visit(entry.key));
      values.add(visit(entry.value));
    }
    return new MapConstantExpression(
        _commonElements.mapType(keyType, valueType), keys, values);
  }

  @override
  ConstantExpression visitListLiteral(ir.ListLiteral node) {
    if (!node.isConst) {
      throw new UnimplementedError(
          'Unexpected constant expression $node (${node.runtimeType})');
    }
    DartType elementType = elementAdapter.getDartType(node.typeArgument);
    List<ConstantExpression> values = <ConstantExpression>[];
    for (ir.Expression value in node.expressions) {
      values.add(visit(value));
    }
    return new ListConstantExpression(
        _commonElements.listType(elementType), values);
  }

  @override
  ConstantExpression visitConditionalExpression(ir.ConditionalExpression node) {
    ConstantExpression condition = visit(node.condition);
    ConstantExpression trueExp = visit(node.then);
    ConstantExpression falseExp = visit(node.otherwise);
    return new ConditionalConstantExpression(condition, trueExp, falseExp);
  }

  @override
  ConstantExpression visitPropertyGet(ir.PropertyGet node) {
    if (node.name.name != 'length') {
      throw new UnimplementedError(
          'Unexpected constant expression $node (${node.runtimeType})');
    }
    ConstantExpression receiver = visit(node.receiver);
    return new StringLengthConstantExpression(receiver);
  }

  @override
  ConstantExpression visitMethodInvocation(ir.MethodInvocation node) {
    // Method invocations are generally not constant expressions but unary
    // and binary expressions are encoded as method invocations in kernel.
    if (node.arguments.named.isNotEmpty) {
      throw new UnimplementedError(
          'Unexpected constant expression $node (${node.runtimeType})');
    }
    if (node.arguments.positional.length == 0) {
      UnaryOperator operator;
      if (node.name.name == UnaryOperator.NEGATE.selectorName) {
        operator = UnaryOperator.NEGATE;
      } else {
        operator = UnaryOperator.parse(node.name.name);
      }
      if (operator != null) {
        ConstantExpression expression = visit(node.receiver);
        return new UnaryConstantExpression(operator, expression);
      }
    }
    if (node.arguments.positional.length == 1) {
      BinaryOperator operator = BinaryOperator.parse(node.name.name);
      if (operator != null) {
        ConstantExpression left = visit(node.receiver);
        ConstantExpression right = visit(node.arguments.positional.single);
        return new BinaryConstantExpression(left, operator, right);
      }
    }
    throw new UnimplementedError(
        'Unexpected constant expression $node (${node.runtimeType})');
  }

  @override
  ConstantExpression visitStaticInvocation(ir.StaticInvocation node) {
    MemberEntity member = elementAdapter.getMember(node.target);
    if (member == _commonElements.identicalFunction) {
      if (node.arguments.positional.length == 2 &&
          node.arguments.named.isEmpty) {
        ConstantExpression left = visit(node.arguments.positional[0]);
        ConstantExpression right = visit(node.arguments.positional[1]);
        return new IdenticalConstantExpression(left, right);
      }
    } else if (member.name == 'fromEnvironment' &&
        node.arguments.positional.length == 1) {
      ConstantExpression name = visit(node.arguments.positional.single);
      ConstantExpression defaultValue;
      if (node.arguments.named.length == 1) {
        if (node.arguments.named.single.name != 'defaultValue') {
          throw new UnimplementedError(
              'Unexpected constant expression $node (${node.runtimeType})');
        }
        defaultValue = visit(node.arguments.named.single.value);
      }
      if (member.enclosingClass == _commonElements.boolClass) {
        return new BoolFromEnvironmentConstantExpression(name, defaultValue);
      } else if (member.enclosingClass == _commonElements.intClass) {
        return new IntFromEnvironmentConstantExpression(name, defaultValue);
      } else if (member.enclosingClass == _commonElements.stringClass) {
        return new StringFromEnvironmentConstantExpression(name, defaultValue);
      }
    }
    throw new UnimplementedError(
        'Unexpected constant expression $node (${node.runtimeType})');
  }

  @override
  ConstantExpression visitLogicalExpression(ir.LogicalExpression node) {
    BinaryOperator operator = BinaryOperator.parse(node.operator);
    if (operator != null) {
      ConstantExpression left = visit(node.left);
      ConstantExpression right = visit(node.right);
      return new BinaryConstantExpression(left, operator, right);
    }
    throw new UnimplementedError(
        'Unexpected constant expression $node (${node.runtimeType})');
  }

  @override
  ConstantExpression visitLet(ir.Let node) {
    ir.Expression body = node.body;
    if (body is ir.ConditionalExpression) {
      ir.Expression condition = body.condition;
      if (condition is ir.MethodInvocation) {
        ir.Expression receiver = condition.receiver;
        ir.Expression otherwise = body.otherwise;
        if (condition.name.name == BinaryOperator.EQ.name &&
            receiver is ir.VariableGet &&
            condition.arguments.positional.single is ir.NullLiteral &&
            otherwise is ir.VariableGet) {
          if (receiver.variable == node.variable &&
              otherwise.variable == node.variable) {
            // We have <left> ?? <right> encoded as:
            //    let #1 = <left> in #1 == null ? <right> : #1
            ConstantExpression left = visit(node.variable.initializer);
            ConstantExpression right = visit(body.then);
            // TODO(johnniwinther): Remove [IF_NULL] binary constant expression
            // when the resolver is removed; then we no longer need the
            // expressions to be structurally equivalence for equivalence
            // testing.
            return new BinaryConstantExpression(
                left, BinaryOperator.IF_NULL, right);
          }
        }
      }
    }
    throw new UnimplementedError(
        'Unexpected constant expression $node (${node.runtimeType})');
  }

  /// Compute the [ConstantConstructor] corresponding to the const constructor
  /// [node].
  ConstantConstructor computeConstantConstructor(ir.Constructor node) {
    assert(node.isConst);
    ir.Class cls = node.enclosingClass;
    InterfaceType type = elementAdapter.elementEnvironment
        .getThisType(elementAdapter.getClass(cls));

    Map<dynamic, ConstantExpression> defaultValues =
        <dynamic, ConstantExpression>{};
    int parameterIndex = 0;
    node.function.positionalParameters
        .forEach((ir.VariableDeclaration parameter) {
      if (parameterIndex >= node.function.requiredParameterCount) {
        if (parameter.initializer != null) {
          defaultValues[parameterIndex] = parameter.initializer.accept(this);
        } else {
          defaultValues[parameterIndex] = new NullConstantExpression();
        }
      }
      parameterIndex++;
    });
    node.function.namedParameters.forEach((ir.VariableDeclaration parameter) {
      defaultValues[parameter.name] = parameter.initializer.accept(this);
    });

    bool isRedirecting = node.initializers.length == 1 &&
        node.initializers.single is ir.RedirectingInitializer;

    Map<FieldEntity, ConstantExpression> fieldMap =
        <FieldEntity, ConstantExpression>{};

    void registerField(ir.Field field, ConstantExpression constant) {
      fieldMap[elementAdapter.getField(field)] = constant;
    }

    if (!isRedirecting) {
      for (ir.Field field in cls.fields) {
        if (field.isStatic) continue;
        if (field.initializer != null) {
          registerField(field, field.initializer.accept(this));
        }
      }
    }

    ConstructedConstantExpression superConstructorInvocation;
    for (ir.Initializer initializer in node.initializers) {
      if (initializer is ir.FieldInitializer) {
        registerField(initializer.field, initializer.value.accept(this));
      } else if (initializer is ir.SuperInitializer) {
        superConstructorInvocation = _computeConstructorInvocation(
            initializer.target, initializer.arguments);
      } else if (initializer is ir.RedirectingInitializer) {
        superConstructorInvocation = _computeConstructorInvocation(
            initializer.target, initializer.arguments);
      } else {
        throw new UnsupportedError(
            'Unexpected initializer $node (${node.runtimeType})');
      }
    }
    if (isRedirecting) {
      return new RedirectingGenerativeConstantConstructor(
          defaultValues, superConstructorInvocation);
    } else {
      return new GenerativeConstantConstructor(
          type, defaultValues, fieldMap, superConstructorInvocation);
    }
  }
}
