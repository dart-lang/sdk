// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:js_runtime/shared/embedded_names.dart';
import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../common.dart';
import '../common/names.dart';
import '../constants/constructors.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../common_elements.dart';
import '../elements/entities.dart';
import '../elements/jumps.dart';
import '../elements/names.dart';
import '../elements/operators.dart';
import '../elements/types.dart';
import '../js/js.dart' as js;
import '../js_backend/backend.dart' show JavaScriptBackend;
import '../js_backend/namer.dart';
import '../js_emitter/code_emitter_task.dart';
import '../native/native.dart' as native;
import '../types/types.dart';
import '../universe/call_structure.dart';
import '../universe/selector.dart';
import '../world.dart';
import 'kernel_debug.dart';

/// Interface that translates between Kernel IR nodes and entities.
abstract class KernelToElementMap {
  /// Access to the commonly used elements and types.
  CommonElements get commonElements;

  /// [ElementEnvironment] for library, class and member lookup.
  ElementEnvironment get elementEnvironment;

  /// Returns the [DartType] corresponding to [type].
  DartType getDartType(ir.DartType type);

  /// Returns the [FunctionType] of the [node].
  FunctionType getFunctionType(ir.FunctionNode node);

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

  /// Returns the kernel IR node that defines the [member].
  ir.Node getMemberNode(covariant MemberEntity member);

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

  /// Returns the [js.Name] for the `JsGetName` [constant] value.
  js.Name getNameForJsGetName(ConstantValue constant, Namer namer);

  /// Returns the [js.Template] for the `JsBuiltin` [constant] value.
  js.Template getJsBuiltinTemplate(
      ConstantValue constant, CodeEmitterTask emitter);

  /// Computes the [InterfaceType] referenced by a call to the
  /// [JS_INTERCEPTOR_CONSTANT] function, if any.
  InterfaceType getInterfaceTypeForJsInterceptorCall(ir.StaticInvocation node);

  /// Computes the [ConstantValue] for the constant [expression].
  ConstantValue getConstantValue(ir.Expression expression,
      {bool requireConstant: true, bool implicitNull: false});

  /// Return the [ConstantValue] the initial value of [field] or `null` if
  /// the initializer is not a constant expression.
  ConstantValue getFieldConstantValue(ir.Field field);

  /// Returns the `noSuchMethod` [FunctionEntity] call from a
  /// `super.noSuchMethod` invocation within [cls].
  FunctionEntity getSuperNoSuchMethod(ClassEntity cls);

  /// Returns a [Spannable] for a message pointing to the IR [node] in the
  /// context of [member].
  Spannable getSpannable(MemberEntity member, ir.Node node);
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
  native.BehaviorBuilder get nativeBehaviorBuilder;
  ConstantValue computeConstantValue(ConstantExpression constant,
      {bool requireConstant: true});

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

  ConstantValue getConstantValue(ir.Expression node,
      {bool requireConstant: true, bool implicitNull: false}) {
    ConstantExpression constant;
    if (node == null) {
      if (!implicitNull) {
        throw new SpannableAssertionFailure(
            CURRENT_ELEMENT_SPANNABLE, 'No expression for constant.');
      }
      constant = new NullConstantExpression();
    } else {
      constant =
          new Constantifier(this, requireConstant: requireConstant).visit(node);
    }
    if (constant == null) {
      if (requireConstant) {
        throw new UnsupportedError(
            'No constant for ${DebugPrinter.prettyPrint(node)}');
      }
      return null;
    }
    return computeConstantValue(constant, requireConstant: requireConstant);
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
    assert(function != null,
        failedAt(cls, "No super noSuchMethod found for class $cls."));
    return function;
  }

  js.Name getNameForJsGetName(ConstantValue constant, Namer namer) {
    int index = _extractEnumIndexFromConstantValue(
        constant, commonElements.jsGetNameEnum);
    if (index == null) return null;
    return namer.getNameForJsGetName(
        CURRENT_ELEMENT_SPANNABLE, JsGetName.values[index]);
  }

  js.Template getJsBuiltinTemplate(
      ConstantValue constant, CodeEmitterTask emitter) {
    int index = _extractEnumIndexFromConstantValue(
        constant, commonElements.jsBuiltinEnum);
    if (index == null) return null;
    return emitter.builtinTemplateFor(JsBuiltin.values[index]);
  }

  int _extractEnumIndexFromConstantValue(
      ConstantValue constant, ClassEntity classElement) {
    if (constant is ConstructedConstantValue) {
      if (constant.type.element == classElement) {
        assert(constant.fields.length == 1 || constant.fields.length == 2);
        ConstantValue indexConstant = constant.fields.values.first;
        if (indexConstant is IntConstantValue) {
          return indexConstant.primitiveValue;
        }
      }
    }
    return null;
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
    if (requireConstant) {
      throw new UnimplementedError(
          'Unimplemented constant expression $node (${node.runtimeType})');
    }
    return null;
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
    List<ConstantExpression> expressions = _computeArguments(arguments);
    if (expressions == null) return null;
    return new ConstructedConstantExpression(
        elementAdapter.createInterfaceType(
            target.enclosingClass, arguments.types),
        elementAdapter.getConstructor(target),
        elementAdapter.getCallStructure(arguments),
        expressions);
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
    } else if (node.variable.isConst) {
      return visit(node.variable.initializer);
    }
    return defaultExpression(node);
  }

  @override
  ConstantExpression visitStaticGet(ir.StaticGet node) {
    ir.Member target = node.target;
    if (target is ir.Field && target.isConst) {
      return new FieldConstantExpression(elementAdapter.getField(node.target));
    } else if (node.target is ir.Procedure) {
      FunctionEntity function = elementAdapter.getMethod(node.target);
      DartType type = elementAdapter.getFunctionType(node.target.function);
      return new FunctionConstantExpression(function, type);
    }
    return defaultExpression(node);
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
    List<ConstantExpression> expressions = _computeList(node.expressions);
    if (expressions == null) return null;
    return new ConcatenateConstantExpression(expressions);
  }

  @override
  ConstantExpression visitMapLiteral(ir.MapLiteral node) {
    if (!node.isConst) {
      return defaultExpression(node);
    }
    DartType keyType = elementAdapter.getDartType(node.keyType);
    DartType valueType = elementAdapter.getDartType(node.valueType);
    List<ConstantExpression> keys = <ConstantExpression>[];
    List<ConstantExpression> values = <ConstantExpression>[];
    for (ir.MapEntry entry in node.entries) {
      ConstantExpression key = visit(entry.key);
      if (key == null) return null;
      keys.add(key);
      ConstantExpression value = visit(entry.value);
      if (value == null) return null;
      values.add(value);
    }
    return new MapConstantExpression(
        _commonElements.mapType(keyType, valueType), keys, values);
  }

  @override
  ConstantExpression visitListLiteral(ir.ListLiteral node) {
    if (!node.isConst) {
      return defaultExpression(node);
    }
    DartType elementType = elementAdapter.getDartType(node.typeArgument);
    List<ConstantExpression> values = <ConstantExpression>[];
    for (ir.Expression expression in node.expressions) {
      ConstantExpression value = visit(expression);
      if (value == null) return null;
      values.add(value);
    }
    return new ListConstantExpression(
        _commonElements.listType(elementType), values);
  }

  @override
  ConstantExpression visitTypeLiteral(ir.TypeLiteral node) {
    DartType type = elementAdapter.getDartType(node.type);
    String name;
    if (type.isDynamic) {
      name = 'dynamic';
    } else if (type is InterfaceType) {
      name = type.element.name;
    } else if (type.isFunctionType || type.isTypedef) {
      // TODO(johnniwinther): Compute a name for the type literal? It is only
      // used in error messages in the old SSA builder.
      name = '?';
    } else {
      return defaultExpression(node);
    }
    return new TypeConstantExpression(type, name);
  }

  @override
  ConstantExpression visitNot(ir.Not node) {
    ConstantExpression expression = visit(node.operand);
    if (expression == null) return null;
    return new UnaryConstantExpression(UnaryOperator.NOT, expression);
  }

  @override
  ConstantExpression visitConditionalExpression(ir.ConditionalExpression node) {
    ConstantExpression condition = visit(node.condition);
    if (condition == null) return null;
    ConstantExpression trueExp = visit(node.then);
    if (trueExp == null) return null;
    ConstantExpression falseExp = visit(node.otherwise);
    if (falseExp == null) return null;
    return new ConditionalConstantExpression(condition, trueExp, falseExp);
  }

  @override
  ConstantExpression visitPropertyGet(ir.PropertyGet node) {
    if (node.name.name != 'length') {
      throw new UnimplementedError(
          'Unexpected constant expression $node (${node.runtimeType})');
    }
    ConstantExpression receiver = visit(node.receiver);
    if (receiver == null) return null;
    return new StringLengthConstantExpression(receiver);
  }

  @override
  ConstantExpression visitMethodInvocation(ir.MethodInvocation node) {
    // Method invocations are generally not constant expressions but unary
    // and binary expressions are encoded as method invocations in kernel.
    if (node.arguments.named.isNotEmpty) {
      return defaultExpression(node);
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
        if (expression == null) return null;
        return new UnaryConstantExpression(operator, expression);
      }
    }
    if (node.arguments.positional.length == 1) {
      BinaryOperator operator = BinaryOperator.parse(node.name.name);
      if (operator != null) {
        ConstantExpression left = visit(node.receiver);
        if (left == null) return null;
        ConstantExpression right = visit(node.arguments.positional.single);
        if (right == null) return null;
        return new BinaryConstantExpression(left, operator, right);
      }
    }
    return defaultExpression(node);
  }

  @override
  ConstantExpression visitStaticInvocation(ir.StaticInvocation node) {
    MemberEntity member = elementAdapter.getMember(node.target);
    if (member == _commonElements.identicalFunction) {
      if (node.arguments.positional.length == 2 &&
          node.arguments.named.isEmpty) {
        ConstantExpression left = visit(node.arguments.positional[0]);
        if (left == null) return null;
        ConstantExpression right = visit(node.arguments.positional[1]);
        if (right == null) return null;
        return new IdenticalConstantExpression(left, right);
      }
    } else if (member.name == 'fromEnvironment' &&
        node.arguments.positional.length == 1) {
      ConstantExpression name = visit(node.arguments.positional.single);
      if (name == null) return null;
      ConstantExpression defaultValue;
      if (node.arguments.named.length == 1) {
        if (node.arguments.named.single.name != 'defaultValue') {
          return defaultExpression(node);
        }
        defaultValue = visit(node.arguments.named.single.value);
        if (defaultValue == null) return null;
      }
      if (member.enclosingClass == _commonElements.boolClass) {
        return new BoolFromEnvironmentConstantExpression(name, defaultValue);
      } else if (member.enclosingClass == _commonElements.intClass) {
        return new IntFromEnvironmentConstantExpression(name, defaultValue);
      } else if (member.enclosingClass == _commonElements.stringClass) {
        return new StringFromEnvironmentConstantExpression(name, defaultValue);
      }
    }
    return defaultExpression(node);
  }

  @override
  ConstantExpression visitLogicalExpression(ir.LogicalExpression node) {
    BinaryOperator operator = BinaryOperator.parse(node.operator);
    if (operator != null) {
      ConstantExpression left = visit(node.left);
      if (left == null) return null;
      ConstantExpression right = visit(node.right);
      if (right == null) return null;
      return new BinaryConstantExpression(left, operator, right);
    }
    return defaultExpression(node);
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
            if (left == null) return null;
            ConstantExpression right = visit(body.then);
            if (right == null) return null;
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
    return defaultExpression(node);
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
    for (ir.VariableDeclaration parameter
        in node.function.positionalParameters) {
      if (parameterIndex >= node.function.requiredParameterCount) {
        ConstantExpression defaultValue;
        if (parameter.initializer != null) {
          defaultValue = parameter.initializer.accept(this);
        } else {
          defaultValue = new NullConstantExpression();
        }
        if (defaultValue == null) return null;
        defaultValues[parameterIndex] = defaultValue;
      }
      parameterIndex++;
    }
    for (ir.VariableDeclaration parameter in node.function.namedParameters) {
      ConstantExpression defaultValue = parameter.initializer.accept(this);
      if (defaultValue == null) return null;
      defaultValues[parameter.name] = defaultValue;
    }

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

/// Interface for type inference results for kernel IR nodes.
abstract class KernelToTypeInferenceMap {
  /// Returns the inferred return type of [function].
  TypeMask getReturnTypeOf(FunctionEntity function);

  /// Returns the inferred receiver type of the dynamic [invocation].
  TypeMask typeOfInvocation(
      ir.MethodInvocation invocation, ClosedWorld closedWorld);

  /// Returns the inferred receiver type of the dynamic [read].
  TypeMask typeOfGet(ir.PropertyGet read);

  /// Returns the inferred receiver type of the dynamic [write].
  TypeMask typeOfSet(ir.PropertySet write, ClosedWorld closedWorld);

  /// Returns the inferred type of [listLiteral].
  TypeMask typeOfListLiteral(covariant MemberEntity owner,
      ir.ListLiteral listLiteral, ClosedWorld closedWorld);

  /// Returns the inferred type of iterator in [forInStatement].
  TypeMask typeOfIterator(ir.ForInStatement forInStatement);

  /// Returns the inferred type of `current` in [forInStatement].
  TypeMask typeOfIteratorCurrent(ir.ForInStatement forInStatement);

  /// Returns the inferred type of `moveNext` in [forInStatement].
  TypeMask typeOfIteratorMoveNext(ir.ForInStatement forInStatement);

  /// Returns `true` if [forInStatement] is inferred to be a JavaScript
  /// indexable iterator.
  bool isJsIndexableIterator(
      ir.ForInStatement forInStatement, ClosedWorld closedWorld);

  /// Returns `true` if [mask] is inferred to have a JavaScript `length`
  /// property.
  bool isFixedLength(TypeMask mask, ClosedWorld closedWorld);

  /// Returns the inferred index type of [forInStatement].
  TypeMask inferredIndexType(ir.ForInStatement forInStatement);

  /// Returns the inferred type of [member].
  TypeMask getInferredTypeOf(MemberEntity member);

  /// Returns the inferred type of the [parameter].
  TypeMask getInferredTypeOfParameter(Local parameter);

  /// Returns the inferred type of a dynamic [selector] access on a receiver of
  /// type [mask].
  TypeMask selectorTypeOf(Selector selector, TypeMask mask);

  /// Returns the returned type annotation in the [nativeBehavior].
  TypeMask typeFromNativeBehavior(
      native.NativeBehavior nativeBehavior, ClosedWorld closedWorld);
}

/// Map from kernel IR nodes to local entities.
abstract class KernelToLocalsMap {
  /// The member currently being built.
  MemberEntity get currentMember;

  // TODO(johnniwinther): Make these return the [KernelToLocalsMap] to use from
  // now on.
  /// Call to notify that [member] is currently being inlined.
  void enterInlinedMember(covariant MemberEntity member);

  /// Call to notify that [member] is no longer being inlined.
  void leaveInlinedMember(covariant MemberEntity member);

  /// Returns the [Local] for [node].
  Local getLocal(ir.VariableDeclaration node);

  /// Returns the [JumpTarget] for the branch in [node].
  // TODO(johnniwinther): Split this by kind of [node]?
  JumpTarget getJumpTarget(ir.TreeNode node, {bool isContinueTarget: false});

  /// Returns the [LoopClosureRepresentationInfo] for the loop [node] in
  /// [closureClassMaps].
  LoopClosureRepresentationInfo getClosureRepresentationInfoForLoop(
      ClosureDataLookup closureLookup, ir.TreeNode node);
}

/// Comparator for the canonical order or named arguments.
// TODO(johnniwinther): Remove this when named parameters are sorted in dill.
int namedOrdering(ir.VariableDeclaration a, ir.VariableDeclaration b) {
  return a.name.compareTo(b.name);
}
