// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../common/names.dart';
import '../constants/constructors.dart';
import '../constants/expressions.dart';
import '../common_elements.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js_backend/backend.dart' show JavaScriptBackend;
import '../native/native.dart' as native;
import '../universe/call_structure.dart';
import '../universe/selector.dart';
import 'kernel_debug.dart';

/// Interface that translates between Kernel IR nodes and entities.
abstract class KernelElementAdapter {
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

  /// Returns the [MemberEntity] corresponding to the member [node].
  MemberEntity getMember(ir.Member node);

  /// Returns the [FunctionEntity] corresponding to the procedure [node].
  FunctionEntity getMethod(ir.Procedure node);

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
  native.NativeBehavior getNativeBehaviorForFieldLoad(ir.Field field);

  /// Computes the native behavior for writing to the native [field].
  native.NativeBehavior getNativeBehaviorForFieldStore(ir.Field field);

  /// Computes the native behavior for calling [procedure].
  native.NativeBehavior getNativeBehaviorForMethod(ir.Procedure procedure);

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
}

/// Kinds of foreign functions.
enum ForeignKind {
  JS,
  JS_BUILTIN,
  JS_EMBEDDED_GLOBAL,
  JS_INTERCEPTOR_CONSTANT,
  NONE,
}

abstract class KernelElementAdapterMixin implements KernelElementAdapter {
  DiagnosticReporter get reporter;
  FunctionType getFunctionType(ir.FunctionNode node);
  native.BehaviorBuilder get nativeBehaviorBuilder;

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
    if (Elements.isOperatorName(invocation.name.name)) {
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

  /// Converts [annotations] into a list of [ConstantExpression]s.
  List<ConstantExpression> getMetadata(List<ir.Expression> annotations) {
    if (annotations.isEmpty) return const <ConstantExpression>[];
    List<ConstantExpression> metadata = <ConstantExpression>[];
    annotations.forEach((ir.Expression node) {
      ConstantExpression constant = new Constantifier(this).visit(node);
      if (constant == null) {
        throw new UnsupportedError(
            'No constant for ${DebugPrinter.prettyPrint(node)}');
      }
      metadata.add(constant);
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
  native.NativeBehavior getNativeBehaviorForFieldLoad(ir.Field field) {
    DartType type = getDartType(field.type);
    List<ConstantExpression> metadata = getMetadata(field.annotations);
    // TODO(johnniwinther): Provide the correct value for [isJsInterop].
    return nativeBehaviorBuilder.buildFieldLoadBehavior(
        type, metadata, typeLookup(resolveAsRaw: false),
        isJsInterop: false);
  }

  /// Computes the native behavior for writing to the native [field].
  // TODO(johnniwinther): Cache this for later use.
  native.NativeBehavior getNativeBehaviorForFieldStore(ir.Field field) {
    DartType type = getDartType(field.type);
    return nativeBehaviorBuilder.buildFieldStoreBehavior(type);
  }

  /// Computes the native behavior for calling [procedure].
  // TODO(johnniwinther): Cache this for later use.
  native.NativeBehavior getNativeBehaviorForMethod(ir.Procedure procedure) {
    DartType type = getFunctionType(procedure.function);
    List<ConstantExpression> metadata = getMetadata(procedure.annotations);
    // TODO(johnniwinther): Provide the correct value for [isJsInterop].
    return nativeBehaviorBuilder.buildMethodBehavior(
        type, metadata, typeLookup(resolveAsRaw: false),
        isJsInterop: false);
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
  final KernelElementAdapter elementAdapter;

  Constantifier(this.elementAdapter, {this.requireConstant: true});

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
    return new FieldConstantExpression(elementAdapter.getField(node.target));
  }

  @override
  ConstantExpression visitStringLiteral(ir.StringLiteral node) {
    return new StringConstantExpression(node.value);
  }

  @override
  ConstantExpression visitStringConcatenation(ir.StringConcatenation node) {
    return new ConcatenateConstantExpression(_computeList(node.expressions));
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
