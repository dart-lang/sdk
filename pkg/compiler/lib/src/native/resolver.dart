// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/scanner.dart' show StringToken, Token;
import 'package:front_end/src/fasta/scanner.dart' as Tokens show EOF_TOKEN;
import 'package:front_end/src/scanner/token.dart' show BeginToken;

import '../common.dart';
import '../common_elements.dart' show CommonElements, ElementEnvironment;
import '../common/backend_api.dart';
import '../common/resolution.dart';
import '../compiler.dart' show Compiler;
import '../constants/values.dart';
import '../elements/elements.dart'
    show
        ClassElement,
        Element,
        FieldElement,
        MemberElement,
        MetadataAnnotation,
        MethodElement;
import '../elements/entities.dart';
import '../elements/modelx.dart' show FunctionElementX, MetadataAnnotationX;
import '../elements/resolution_types.dart' show ResolutionDartType;
import '../js_backend/js_backend.dart';
import '../js_backend/native_data.dart';
import '../patch_parser.dart';
import '../tree/tree.dart';
import 'behavior.dart';

/// Interface for computing native members.
abstract class NativeMemberResolver {
  /// Computes whether [element] is native or JsInterop and, if so, registers
  /// its [NativeBehavior]s to [registry].
  void resolveNativeMember(MemberEntity element, [NativeRegistry registry]);
}

/// Interface for computing native members and [NativeBehavior]s in member code
/// based on the AST.
abstract class NativeDataResolver implements NativeMemberResolver {
  /// Returns `true` if [element] is a JsInterop member.
  bool isJsInteropMember(MemberElement element);

  /// Computes the [NativeBehavior] for a `JS` call, which can be an
  /// instantiation point for types.
  ///
  /// For example, the following code instantiates and returns native classes
  /// that are `_DOMWindowImpl` or a subtype.
  ///
  ///    JS('_DOMWindowImpl', 'window')
  ///
  NativeBehavior resolveJsCall(Send node, ForeignResolver resolver);

  /// Computes the [NativeBehavior] for a `JS_EMBEDDED_GLOBAL` call, which can
  /// be an instantiation point for types.
  ///
  /// For example, the following code instantiates and returns a String class
  ///
  ///     JS_EMBEDDED_GLOBAL('String', 'foo')
  ///
  NativeBehavior resolveJsEmbeddedGlobalCall(
      Send node, ForeignResolver resolver);

  /// Computes the [NativeBehavior] for a `JS_BUILTIN` call, which can be an
  /// instantiation point for types.
  ///
  /// For example, the following code instantiates and returns a String class
  ///
  ///     JS_BUILTIN('String', 'int2string', 0)
  ///
  NativeBehavior resolveJsBuiltinCall(Send node, ForeignResolver resolver);
}

abstract class NativeMemberResolverBase implements NativeMemberResolver {
  static final RegExp _identifier = new RegExp(r'^[a-zA-Z_$][a-zA-Z0-9_$]*$');

  ElementEnvironment get elementEnvironment;
  CommonElements get commonElements;
  NativeBasicData get nativeBasicData;
  NativeDataBuilder get nativeDataBuilder;

  bool isJsInteropMember(covariant MemberEntity element);
  bool isNativeMethod(covariant FunctionEntity element);

  NativeBehavior computeNativeMethodBehavior(covariant FunctionEntity function,
      {bool isJsInterop});
  NativeBehavior computeNativeFieldLoadBehavior(covariant FieldEntity field,
      {bool isJsInterop});
  NativeBehavior computeNativeFieldStoreBehavior(covariant FieldEntity field);

  @override
  void resolveNativeMember(MemberEntity element, [NativeRegistry registry]) {
    bool isJsInterop = isJsInteropMember(element);
    if (element.isFunction ||
        element.isConstructor ||
        element.isGetter ||
        element.isSetter) {
      FunctionEntity method = element;
      bool isNative = _processMethodAnnotations(method);
      if (isNative || isJsInterop) {
        NativeBehavior behavior =
            computeNativeMethodBehavior(method, isJsInterop: isJsInterop);
        nativeDataBuilder.setNativeMethodBehavior(method, behavior);
        registry?.registerNativeData(behavior);
      }
    } else if (element.isField) {
      FieldEntity field = element;
      bool isNative = _processFieldAnnotations(field);
      if (isNative || isJsInterop) {
        NativeBehavior fieldLoadBehavior =
            computeNativeFieldLoadBehavior(field, isJsInterop: isJsInterop);
        NativeBehavior fieldStoreBehavior =
            computeNativeFieldStoreBehavior(field);
        nativeDataBuilder.setNativeFieldLoadBehavior(field, fieldLoadBehavior);
        nativeDataBuilder.setNativeFieldStoreBehavior(
            field, fieldStoreBehavior);

        // TODO(sra): Process fields for storing separately.
        // We have to handle both loading and storing to the field because we
        // only get one look at each member and there might be a load or store
        // we have not seen yet.
        registry?.registerNativeData(fieldLoadBehavior);
        registry?.registerNativeData(fieldStoreBehavior);
      }
    }
  }

  /// Process the potentially native [field]. Adds information from metadata
  /// attributes. Returns `true` of [method] is native.
  bool _processFieldAnnotations(covariant FieldEntity element) {
    if (element.isInstanceMember &&
        nativeBasicData.isNativeClass(element.enclosingClass)) {
      // Exclude non-instance (static) fields - they are not really native and
      // are compiled as isolate globals.  Access of a property of a constructor
      // function or a non-method property in the prototype chain, must be coded
      // using a JS-call.
      _setNativeName(element);
      return true;
    }
    return false;
  }

  /// Process the potentially native [method]. Adds information from metadata
  /// attributes. Returns `true` of [method] is native.
  bool _processMethodAnnotations(covariant FunctionEntity method) {
    if (isNativeMethod(method)) {
      if (method.isStatic) {
        _setNativeNameForStaticMethod(method);
      } else {
        _setNativeName(method);
      }
      return true;
    }
    return false;
  }

  /// Sets the native name of [element], either from an annotation, or
  /// defaulting to the Dart name.
  void _setNativeName(MemberEntity element) {
    String name = _findJsNameFromAnnotation(element);
    if (name == null) name = element.name;
    nativeDataBuilder.setNativeMemberName(element, name);
  }

  /// Sets the native name of the static native method [element], using the
  /// following rules:
  /// 1. If [element] has a @JSName annotation that is an identifier, qualify
  ///    that identifier to the @Native name of the enclosing class
  /// 2. If [element] has a @JSName annotation that is not an identifier,
  ///    use the declared @JSName as the expression
  /// 3. If [element] does not have a @JSName annotation, qualify the name of
  ///    the method with the @Native name of the enclosing class.
  void _setNativeNameForStaticMethod(FunctionEntity element) {
    String name = _findJsNameFromAnnotation(element);
    if (name == null) name = element.name;
    if (_isIdentifier(name)) {
      List<String> nativeNames =
          nativeBasicData.getNativeTagsOfClass(element.enclosingClass);
      if (nativeNames.length != 1) {
        throw new SpannableAssertionFailure(
            element,
            'Unable to determine a native name for the enclosing class, '
            'options: $nativeNames');
      }
      nativeDataBuilder.setNativeMemberName(element, '${nativeNames[0]}.$name');
    } else {
      nativeDataBuilder.setNativeMemberName(element, name);
    }
  }

  bool _isIdentifier(String s) => _identifier.hasMatch(s);

  /// Returns the JSName annotation string or `null` if no JSName annotation is
  /// present.
  String _findJsNameFromAnnotation(MemberEntity element) {
    String jsName = null;
    for (ConstantValue value in elementEnvironment.getMemberMetadata(element)) {
      String name = readAnnotationName(
          element, value, commonElements.annotationJSNameClass);
      if (jsName == null) {
        jsName = name;
      } else if (name != null) {
        throw new SpannableAssertionFailure(
            element, 'Too many JSName annotations: ${value.toDartText()}');
      }
    }
    return jsName;
  }
}

class NativeDataResolverImpl extends NativeMemberResolverBase
    implements NativeDataResolver {
  final Compiler _compiler;

  NativeDataResolverImpl(this._compiler);

  JavaScriptBackend get _backend => _compiler.backend;
  DiagnosticReporter get _reporter => _compiler.reporter;
  ElementEnvironment get elementEnvironment =>
      _compiler.resolution.elementEnvironment;
  CommonElements get commonElements => _compiler.resolution.commonElements;
  NativeBasicData get nativeBasicData =>
      _compiler.frontendStrategy.nativeBasicData;
  NativeDataBuilder get nativeDataBuilder => _backend.nativeDataBuilder;

  @override
  bool isJsInteropMember(MemberElement element) {
    // TODO(johnniwinther): Avoid computing this twice for external function;
    // once from JavaScriptBackendTarget.resolveExternalFunction and once
    // through JavaScriptBackendTarget.resolveNativeMember.
    bool isJsInterop =
        checkJsInteropMemberAnnotations(_compiler, element, nativeDataBuilder);
    // TODO(johnniwinther): Avoid this duplication of logic from
    // NativeData.isJsInterop.
    if (!isJsInterop && element is MethodElement && element.isExternal) {
      if (element.enclosingClass != null) {
        isJsInterop = nativeBasicData.isJsInteropClass(element.enclosingClass);
      } else {
        isJsInterop = nativeBasicData.isJsInteropLibrary(element.library);
      }
    }
    return isJsInterop;
  }

  @override
  NativeBehavior computeNativeMethodBehavior(MethodElement function,
      {bool isJsInterop}) {
    return NativeBehavior.ofMethodElement(function, _compiler,
        isJsInterop: isJsInterop);
  }

  @override
  NativeBehavior computeNativeFieldLoadBehavior(FieldElement field,
      {bool isJsInterop}) {
    return NativeBehavior.ofFieldElementLoad(field, _compiler,
        isJsInterop: isJsInterop);
  }

  @override
  NativeBehavior computeNativeFieldStoreBehavior(FieldElement field) {
    return NativeBehavior.ofFieldElementStore(field, _compiler);
  }

  @override
  bool isNativeMethod(FunctionElementX element) {
    if (!_backend.canLibraryUseNative(element.library)) return false;
    // Native method?
    return _reporter.withCurrentElement(element, () {
      Node node = element.parseNode(_compiler.resolution.parsingContext);
      if (node is! FunctionExpression) return false;
      FunctionExpression functionExpression = node;
      node = functionExpression.body;
      Token token = node.getBeginToken();
      if (identical(token.stringValue, 'native')) return true;
      return false;
    });
  }

  @override
  bool _processMethodAnnotations(MethodElement method) {
    if (_compiler.serialization.isDeserialized(method)) {
      return false;
    }
    return super._processMethodAnnotations(method);
  }

  @override
  bool _processFieldAnnotations(FieldElement element) {
    if (_compiler.serialization.isDeserialized(element)) {
      return false;
    }
    return super._processFieldAnnotations(element);
  }

  @override
  NativeBehavior resolveJsCall(Send node, ForeignResolver resolver) {
    return NativeBehavior.ofJsCallSend(
        node, _reporter, _compiler.parsingContext, commonElements, resolver);
  }

  @override
  NativeBehavior resolveJsEmbeddedGlobalCall(
      Send node, ForeignResolver resolver) {
    return NativeBehavior.ofJsEmbeddedGlobalCallSend(
        node, _reporter, commonElements, resolver);
  }

  @override
  NativeBehavior resolveJsBuiltinCall(Send node, ForeignResolver resolver) {
    return NativeBehavior.ofJsBuiltinCallSend(
        node, _reporter, commonElements, resolver);
  }
}

/// Annotation handler for pre-resolution detection of `@Native(...)`
/// annotations.
class NativeAnnotationHandler extends EagerAnnotationHandler<String> {
  final NativeBasicDataBuilder _nativeBasicDataBuilder;

  NativeAnnotationHandler(this._nativeBasicDataBuilder);

  String getNativeAnnotation(MetadataAnnotationX annotation) {
    if (annotation.beginToken != null &&
        annotation.beginToken.next.lexeme == 'Native') {
      // Skipping '@', 'Native', and '('.
      Token argument = annotation.beginToken.next.next.next;
      if (argument is StringToken) {
        return argument.lexeme;
      }
    }
    return null;
  }

  String apply(
      Compiler compiler, Element element, MetadataAnnotation annotation) {
    if (element.isClass) {
      ClassElement cls = element;
      String native = getNativeAnnotation(annotation);
      if (native != null) {
        String tagText = native.substring(1, native.length - 1);
        _nativeBasicDataBuilder.setNativeClassTagInfo(cls, tagText);
        return native;
      }
    }
    return null;
  }

  void validate(Compiler compiler, Element element,
      MetadataAnnotation annotation, ConstantValue constant) {
    ResolutionDartType annotationType =
        constant.getType(compiler.resolution.commonElements);
    if (annotationType.element !=
        compiler.resolution.commonElements.nativeAnnotationClass) {
      DiagnosticReporter reporter = compiler.reporter;
      reporter.internalError(annotation, 'Invalid @Native(...) annotation.');
    }
  }
}

bool checkJsInteropMemberAnnotations(Compiler compiler, MemberElement element,
    NativeDataBuilder nativeDataBuilder) {
  bool isJsInterop = EagerAnnotationHandler.checkAnnotation(
      compiler, element, const JsInteropAnnotationHandler());
  if (isJsInterop) {
    nativeDataBuilder.markAsJsInteropMember(element);
  }
  return isJsInterop;
}

/// Annotation handler for pre-resolution detection of `@JS(...)`
/// annotations.
class JsInteropAnnotationHandler implements EagerAnnotationHandler<bool> {
  const JsInteropAnnotationHandler();

  bool hasJsNameAnnotation(MetadataAnnotationX annotation) =>
      annotation.beginToken != null &&
      annotation.beginToken.next.lexeme == 'JS';

  bool apply(
      Compiler compiler, Element element, MetadataAnnotation annotation) {
    return hasJsNameAnnotation(annotation);
  }

  @override
  void validate(Compiler compiler, Element element,
      MetadataAnnotation annotation, ConstantValue constant) {
    ResolutionDartType type =
        constant.getType(compiler.resolution.commonElements);
    if (type.element != compiler.resolution.commonElements.jsAnnotationClass) {
      compiler.reporter
          .internalError(annotation, 'Invalid @JS(...) annotation.');
    }
  }

  bool get defaultResult => false;
}

/// Determines all native classes in a set of libraries.
abstract class NativeClassFinder {
  /// Returns the set of all native classes declared in [libraries].
  Iterable<ClassEntity> computeNativeClasses(Iterable<LibraryEntity> libraries);
}

class BaseNativeClassFinder implements NativeClassFinder {
  final ElementEnvironment _elementEnvironment;
  final CommonElements _commonElements;
  final NativeBasicData _nativeBasicData;

  Map<String, ClassEntity> _tagOwner = new Map<String, ClassEntity>();

  BaseNativeClassFinder(
      this._elementEnvironment, this._commonElements, this._nativeBasicData);

  Iterable<ClassEntity> computeNativeClasses(
      Iterable<LibraryEntity> libraries) {
    Set<ClassEntity> nativeClasses = new Set<ClassEntity>();
    libraries.forEach((l) => _processNativeClassesInLibrary(l, nativeClasses));
    if (_commonElements.isolateHelperLibrary != null) {
      _processNativeClassesInLibrary(
          _commonElements.isolateHelperLibrary, nativeClasses);
    }
    _processSubclassesOfNativeClasses(libraries, nativeClasses);
    return nativeClasses;
  }

  /// Adds all directly native classes declared in [library] to [nativeClasses].
  void _processNativeClassesInLibrary(
      LibraryEntity library, Set<ClassEntity> nativeClasses) {
    _elementEnvironment.forEachClass(library, (ClassEntity cls) {
      if (_nativeBasicData.isNativeClass(cls)) {
        _processNativeClass(cls, nativeClasses);
      }
    });
  }

  /// Adds [cls] to [nativeClasses] and performs further processing of [cls],
  /// if necessary.
  void _processNativeClass(
      covariant ClassEntity cls, Set<ClassEntity> nativeClasses) {
    nativeClasses.add(cls);
    // Js Interop interfaces do not have tags.
    if (_nativeBasicData.isJsInteropClass(cls)) return;
    // Since we map from dispatch tags to classes, a dispatch tag must be used
    // on only one native class.
    for (String tag in _nativeBasicData.getNativeTagsOfClass(cls)) {
      ClassEntity owner = _tagOwner[tag];
      if (owner != null) {
        if (owner != cls) {
          throw new SpannableAssertionFailure(
              cls, "Tag '$tag' already in use by '${owner.name}'");
        }
      } else {
        _tagOwner[tag] = cls;
      }
    }
  }

  /// Returns the name of the super class of [cls] or `null` of [cls] has
  /// no explicit superclass.
  String _findExtendsNameOfClass(covariant ClassEntity cls) {
    return _elementEnvironment
        .getSuperClass(cls, skipUnnamedMixinApplications: true)
        ?.name;
  }

  /// Adds all subclasses of [nativeClasses] found in [libraries] to
  /// [nativeClasses].
  void _processSubclassesOfNativeClasses(
      Iterable<LibraryEntity> libraries, Set<ClassEntity> nativeClasses) {
    Set<ClassEntity> nativeClassesAndSubclasses = new Set<ClassEntity>();
    // Collect potential subclasses, e.g.
    //
    //     class B extends foo.A {}
    //
    // String "A" has a potential subclass B.

    Map<String, Set<ClassEntity>> potentialExtends =
        <String, Set<ClassEntity>>{};

    libraries.forEach((LibraryEntity library) {
      _elementEnvironment.forEachClass(library, (ClassEntity cls) {
        String extendsName = _findExtendsNameOfClass(cls);
        if (extendsName != null) {
          Set<ClassEntity> potentialSubclasses = potentialExtends.putIfAbsent(
              extendsName, () => new Set<ClassEntity>());
          potentialSubclasses.add(cls);
        }
      });
    });

    // Resolve all the native classes and any classes that might extend them in
    // [potentialExtends], and then check that the properly resolved class is in
    // fact a subclass of a native class.

    ClassEntity nativeSuperclassOf(ClassEntity cls) {
      if (_nativeBasicData.isNativeClass(cls)) return cls;
      ClassEntity superclass = _elementEnvironment.getSuperClass(cls);
      if (superclass == null) return null;
      return nativeSuperclassOf(superclass);
    }

    void walkPotentialSubclasses(ClassEntity element) {
      if (nativeClassesAndSubclasses.contains(element)) return;
      ClassEntity nativeSuperclass = nativeSuperclassOf(element);
      if (nativeSuperclass != null) {
        nativeClassesAndSubclasses.add(element);
        Set<ClassEntity> potentialSubclasses = potentialExtends[element.name];
        if (potentialSubclasses != null) {
          potentialSubclasses.forEach(walkPotentialSubclasses);
        }
      }
    }

    nativeClasses.forEach(walkPotentialSubclasses);
    nativeClasses.addAll(nativeClassesAndSubclasses);
  }
}

/// Native class finder that extends [BaseNativeClassFinder] to handle
/// unresolved classes encountered during the native classes computation.
class ResolutionNativeClassFinder extends BaseNativeClassFinder {
  final DiagnosticReporter _reporter;
  final Resolution _resolution;

  ResolutionNativeClassFinder(
      this._resolution,
      this._reporter,
      ElementEnvironment elementEnvironment,
      CommonElements commonElements,
      NativeBasicData nativeBasicData)
      : super(elementEnvironment, commonElements, nativeBasicData);

  void _processNativeClass(
      ClassElement classElement, Set<ClassEntity> nativeClasses) {
    // Resolve class to ensure the class has valid inheritance info.
    classElement.ensureResolved(_resolution);
    super._processNativeClass(classElement, nativeClasses);
  }

  /**
   * Returns the source string of the class named in the extends clause, or
   * `null` if there is no extends clause.
   */
  String _findExtendsNameOfClass(ClassElement classElement) {
    if (classElement.isResolved) {
      ClassElement superClass = classElement.superclass;
      while (superClass != null) {
        if (!superClass.isUnnamedMixinApplication) {
          return superClass.name;
        }
        superClass = superClass.superclass;
      }
      return null;
    }

    //  "class B extends A ... {}"  --> "A"
    //  "class B extends foo.A ... {}"  --> "A"
    //  "class B<T> extends foo.A<T,T> with M1, M2 ... {}"  --> "A"

    // We want to avoid calling classElement.parseNode on every class.  Doing so
    // will slightly increase parse time and size and cause compiler errors and
    // warnings to me emitted in more unused code.

    // An alternative to this code is to extend the API of ClassElement to
    // expose the name of the extended element.

    // Pattern match the above cases in the token stream.
    //  [abstract] class X extends [id.]* id

    Token skipTypeParameters(Token token) {
      BeginToken beginGroupToken = token;
      Token endToken = beginGroupToken.endGroup;
      return endToken.next;
      //for (;;) {
      //  token = token.next;
      //  if (token.stringValue == '>') return token.next;
      //  if (token.stringValue == '<') return skipTypeParameters(token);
      //}
    }

    String scanForExtendsName(Token token) {
      if (token.stringValue == 'abstract') token = token.next;
      if (token.stringValue != 'class') return null;
      token = token.next;
      if (!token.isIdentifier) return null;
      token = token.next;
      //  class F<X extends B<X>> extends ...
      if (token.stringValue == '<') {
        token = skipTypeParameters(token);
      }
      if (token.stringValue != 'extends') return null;
      token = token.next;
      Token id = token;
      while (token.kind != Tokens.EOF_TOKEN) {
        token = token.next;
        if (token.stringValue != '.') break;
        token = token.next;
        if (!token.isIdentifier) return null;
        id = token;
      }
      // Should be at '{', 'with', 'implements', '<' or 'native'.
      return id.lexeme;
    }

    return _reporter.withCurrentElement(classElement, () {
      return scanForExtendsName(classElement.position);
    });
  }
}

/// Extracts the name if [value] is a named annotation based on
/// [annotationClass], otherwise returns `null`.
String readAnnotationName(
    Spannable spannable, ConstantValue value, ClassEntity annotationClass) {
  if (!value.isConstructedObject) return null;
  ConstructedConstantValue constructedObject = value;
  if (constructedObject.type.element != annotationClass) return null;

  Iterable<ConstantValue> fields = constructedObject.fields.values;
  // TODO(sra): Better validation of the constant.
  if (fields.length != 1 || fields.single is! StringConstantValue) {
    throw new SpannableAssertionFailure(
        spannable, 'Annotations needs one string: ${value.toStructuredText()}');
  }
  StringConstantValue specStringConstant = fields.single;
  return specStringConstant.primitiveValue;
}
