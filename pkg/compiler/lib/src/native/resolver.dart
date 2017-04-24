// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/scanner.dart'
    show BeginGroupToken, StringToken, Token;
import 'package:front_end/src/fasta/scanner.dart' as Tokens show EOF_TOKEN;

import '../common.dart';
import '../common_elements.dart' show CommonElements;
import '../common/backend_api.dart';
import '../common/resolution.dart';
import '../compiler.dart' show Compiler;
import '../constants/values.dart';
import '../elements/elements.dart'
    show
        ClassElement,
        Element,
        FieldElement,
        LibraryElement,
        MemberElement,
        MetadataAnnotation,
        MethodElement;
import '../elements/entities.dart';
import '../elements/modelx.dart' show FunctionElementX, MetadataAnnotationX;
import '../elements/resolution_types.dart' show ResolutionDartType;
import '../js_backend/js_backend.dart';
import '../js_backend/native_data.dart';
import '../kernel/element_map.dart' show KernelAnnotationProcessor;
import '../patch_parser.dart';
import '../tree/tree.dart';
import 'behavior.dart';

/// Class that performs the mechanics to investigate annotations in the code.
abstract class AnnotationProcessor {
  factory AnnotationProcessor(Compiler compiler) =>
      compiler.options.loadFromDill
          // TODO(johnniwinther): Pass the [KernelWorldBuilder] to
          // [KernelAnnotationProcessor].
          ? new KernelAnnotationProcessor(null)
          : new _ElementAnnotationProcessor(compiler);

  void extractNativeAnnotations(
      LibraryEntity library, NativeBasicDataBuilder nativeBasicDataBuilder);

  void extractJsInteropAnnotations(
      LibraryEntity library, NativeBasicDataBuilder nativeBasicDataBuilder);
}

/// Original logic for annotation processing, which involves in some cases
/// triggering pre-parsing and validation of the annotations.
class _ElementAnnotationProcessor implements AnnotationProcessor {
  Compiler _compiler;

  _ElementAnnotationProcessor(this._compiler);

  /// Check whether [cls] has a `@Native(...)` annotation, and if so, set its
  /// native name from the annotation.
  void extractNativeAnnotations(
      LibraryElement library, NativeBasicDataBuilder nativeBasicDataBuilder) {
    library.forEachLocalMember((Element element) {
      if (element.isClass) {
        EagerAnnotationHandler.checkAnnotation(_compiler, element,
            new NativeAnnotationHandler(nativeBasicDataBuilder));
      }
    });
  }

  void extractJsInteropAnnotations(
      LibraryElement library, NativeBasicDataBuilder nativeBasicDataBuilder) {
    bool checkJsInteropAnnotation(Element element) {
      return EagerAnnotationHandler.checkAnnotation(
          _compiler, element, const JsInteropAnnotationHandler());
    }

    if (checkJsInteropAnnotation(library)) {
      nativeBasicDataBuilder.markAsJsInteropLibrary(library);
    }
    library.forEachLocalMember((Element element) {
      if (element.isClass) {
        ClassElement cls = element;
        if (checkJsInteropAnnotation(element)) {
          nativeBasicDataBuilder.markAsJsInteropClass(cls);
        }
      }
    });
  }
}

/// Interface for computing native members and [NativeBehavior]s in member code
/// based on the AST.
abstract class NativeDataResolver {
  /// Returns `true` if [element] is a JsInterop member.
  bool isJsInteropMember(MemberElement element);

  /// Computes whether [element] is native or JsInterop and, if so, registers
  /// its [NativeBehavior]s to [registry].
  void resolveNativeMember(MemberElement element, NativeRegistry registry);

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

class NativeDataResolverImpl implements NativeDataResolver {
  static final RegExp _identifier = new RegExp(r'^[a-zA-Z_$][a-zA-Z0-9_$]*$');

  final Compiler _compiler;

  NativeDataResolverImpl(this._compiler);

  JavaScriptBackend get _backend => _compiler.backend;
  DiagnosticReporter get _reporter => _compiler.reporter;
  NativeBasicData get _nativeBasicData => _backend.nativeBasicData;
  NativeDataBuilder get _nativeDataBuilder => _backend.nativeDataBuilder;

  @override
  bool isJsInteropMember(MemberElement element) {
    // TODO(johnniwinther): Avoid computing this twice for external function;
    // once from JavaScriptBackendTarget.resolveExternalFunction and once
    // through JavaScriptBackendTarget.resolveNativeMember.
    bool isJsInterop =
        checkJsInteropMemberAnnotations(_compiler, element, _nativeDataBuilder);
    // TODO(johnniwinther): Avoid this duplication of logic from
    // NativeData.isJsInterop.
    if (!isJsInterop && element is MethodElement && element.isExternal) {
      if (element.enclosingClass != null) {
        isJsInterop = _nativeBasicData.isJsInteropClass(element.enclosingClass);
      } else {
        isJsInterop = _nativeBasicData.isJsInteropLibrary(element.library);
      }
    }
    return isJsInterop;
  }

  void resolveNativeMember(MemberElement element, NativeRegistry registry) {
    bool isJsInterop = isJsInteropMember(element);
    if (element.isFunction ||
        element.isConstructor ||
        element.isGetter ||
        element.isSetter) {
      MethodElement method = element;
      bool isNative = _processMethodAnnotations(method);
      if (isNative || isJsInterop) {
        NativeBehavior behavior = NativeBehavior
            .ofMethodElement(method, _compiler, isJsInterop: isJsInterop);
        _nativeDataBuilder.setNativeMethodBehavior(method, behavior);
        registry.registerNativeData(behavior);
      }
    } else if (element.isField) {
      FieldElement field = element;
      bool isNative = _processFieldAnnotations(field);
      if (isNative || isJsInterop) {
        NativeBehavior fieldLoadBehavior = NativeBehavior
            .ofFieldElementLoad(field, _compiler, isJsInterop: isJsInterop);
        NativeBehavior fieldStoreBehavior =
            NativeBehavior.ofFieldElementStore(field, _compiler);
        _nativeDataBuilder.setNativeFieldLoadBehavior(field, fieldLoadBehavior);
        _nativeDataBuilder.setNativeFieldStoreBehavior(
            field, fieldStoreBehavior);

        // TODO(sra): Process fields for storing separately.
        // We have to handle both loading and storing to the field because we
        // only get one look at each member and there might be a load or store
        // we have not seen yet.
        registry.registerNativeData(fieldLoadBehavior);
        registry.registerNativeData(fieldStoreBehavior);
      }
    }
  }

  /// Process the potentially native [field]. Adds information from metadata
  /// attributes. Returns `true` of [method] is native.
  bool _processFieldAnnotations(Element element) {
    if (_compiler.serialization.isDeserialized(element)) {
      return false;
    }
    if (element.isInstanceMember &&
        _backend.nativeBasicData.isNativeClass(element.enclosingClass)) {
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
  bool _processMethodAnnotations(Element method) {
    if (_compiler.serialization.isDeserialized(method)) {
      return false;
    }
    if (_isNativeMethod(method)) {
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
  void _setNativeName(MemberElement element) {
    String name = _findJsNameFromAnnotation(element);
    if (name == null) name = element.name;
    _nativeDataBuilder.setNativeMemberName(element, name);
  }

  /// Sets the native name of the static native method [element], using the
  /// following rules:
  /// 1. If [element] has a @JSName annotation that is an identifier, qualify
  ///    that identifier to the @Native name of the enclosing class
  /// 2. If [element] has a @JSName annotation that is not an identifier,
  ///    use the declared @JSName as the expression
  /// 3. If [element] does not have a @JSName annotation, qualify the name of
  ///    the method with the @Native name of the enclosing class.
  void _setNativeNameForStaticMethod(MethodElement element) {
    String name = _findJsNameFromAnnotation(element);
    if (name == null) name = element.name;
    if (_isIdentifier(name)) {
      List<String> nativeNames =
          _nativeBasicData.getNativeTagsOfClass(element.enclosingClass);
      if (nativeNames.length != 1) {
        _reporter.internalError(
            element,
            'Unable to determine a native name for the enclosing class, '
            'options: $nativeNames');
      }
      _nativeDataBuilder.setNativeMemberName(
          element, '${nativeNames[0]}.$name');
    } else {
      _nativeDataBuilder.setNativeMemberName(element, name);
    }
  }

  bool _isIdentifier(String s) => _identifier.hasMatch(s);

  bool _isNativeMethod(FunctionElementX element) {
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

  /// Returns the JSName annotation string or `null` if no JSName annotation is
  /// present.
  String _findJsNameFromAnnotation(Element element) {
    String jsName = null;
    for (MetadataAnnotation annotation in element.implementation.metadata) {
      annotation.ensureResolved(_compiler.resolution);
      ConstantValue value =
          _compiler.constants.getConstantValue(annotation.constant);
      String name = readAnnotationName(
          annotation, value, _compiler.commonElements.annotationJSNameClass);
      if (jsName == null) {
        jsName = name;
      } else if (name != null) {
        throw new SpannableAssertionFailure(
            annotation, 'Too many JSName annotations: ${annotation}');
      }
    }
    return jsName;
  }

  @override
  NativeBehavior resolveJsCall(Send node, ForeignResolver resolver) {
    return NativeBehavior.ofJsCallSend(node, _reporter,
        _compiler.parsingContext, _compiler.commonElements, resolver);
  }

  @override
  NativeBehavior resolveJsEmbeddedGlobalCall(
      Send node, ForeignResolver resolver) {
    return NativeBehavior.ofJsEmbeddedGlobalCallSend(
        node, _reporter, _compiler.commonElements, resolver);
  }

  @override
  NativeBehavior resolveJsBuiltinCall(Send node, ForeignResolver resolver) {
    return NativeBehavior.ofJsBuiltinCallSend(
        node, _reporter, _compiler.commonElements, resolver);
  }
}

/// Check whether [cls] has a `@Native(...)` annotation, and if so, set its
/// native name from the annotation.
checkNativeAnnotation(Compiler compiler, ClassElement cls,
    NativeBasicDataBuilder nativeBasicDataBuilder) {
  EagerAnnotationHandler.checkAnnotation(
      compiler, cls, new NativeAnnotationHandler(nativeBasicDataBuilder));
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
        constant.getType(compiler.commonElements);
    if (annotationType.element !=
        compiler.commonElements.nativeAnnotationClass) {
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
    ResolutionDartType type = constant.getType(compiler.commonElements);
    if (type.element != compiler.commonElements.jsAnnotationClass) {
      compiler.reporter
          .internalError(annotation, 'Invalid @JS(...) annotation.');
    }
  }

  bool get defaultResult => false;
}

/// Interface for computing all native classes in a set of libraries.
abstract class NativeClassResolver {
  Iterable<ClassEntity> computeNativeClasses(Iterable<LibraryEntity> libraries);
}

class NativeClassResolverImpl implements NativeClassResolver {
  final DiagnosticReporter _reporter;
  final Resolution _resolution;
  final CommonElements _commonElements;
  final NativeBasicData _nativeBasicData;

  Map<String, ClassElement> _tagOwner = new Map<String, ClassElement>();

  NativeClassResolverImpl(this._resolution, this._reporter,
      this._commonElements, this._nativeBasicData);

  Iterable<ClassElement> computeNativeClasses(
      Iterable<LibraryElement> libraries) {
    Set<ClassElement> nativeClasses = new Set<ClassElement>();
    libraries.forEach((l) => _processNativeClassesInLibrary(l, nativeClasses));
    if (_commonElements.isolateHelperLibrary != null) {
      _processNativeClassesInLibrary(
          _commonElements.isolateHelperLibrary, nativeClasses);
    }
    _processSubclassesOfNativeClasses(libraries, nativeClasses);
    return nativeClasses;
  }

  void _processNativeClassesInLibrary(
      LibraryElement library, Set<ClassElement> nativeClasses) {
    // Use implementation to ensure the inclusion of injected members.
    library.implementation.forEachLocalMember((Element element) {
      if (element.isClass) {
        ClassElement cls = element;
        if (_nativeBasicData.isNativeClass(cls)) {
          _processNativeClass(element, nativeClasses);
        }
      }
    });
  }

  void _processNativeClass(
      ClassElement classElement, Set<ClassElement> nativeClasses) {
    nativeClasses.add(classElement);
    // Resolve class to ensure the class has valid inheritance info.
    classElement.ensureResolved(_resolution);
    // Js Interop interfaces do not have tags.
    if (_nativeBasicData.isJsInteropClass(classElement)) return;
    // Since we map from dispatch tags to classes, a dispatch tag must be used
    // on only one native class.
    for (String tag in _nativeBasicData.getNativeTagsOfClass(classElement)) {
      ClassElement owner = _tagOwner[tag];
      if (owner != null) {
        if (owner != classElement) {
          _reporter.internalError(
              classElement, "Tag '$tag' already in use by '${owner.name}'");
        }
      } else {
        _tagOwner[tag] = classElement;
      }
    }
  }

  void _processSubclassesOfNativeClasses(
      Iterable<LibraryElement> libraries, Set<ClassElement> nativeClasses) {
    Set<ClassElement> nativeClassesAndSubclasses = new Set<ClassElement>();
    // Collect potential subclasses, e.g.
    //
    //     class B extends foo.A {}
    //
    // String "A" has a potential subclass B.

    var potentialExtends = new Map<String, Set<ClassElement>>();

    libraries.forEach((library) {
      library.implementation.forEachLocalMember((element) {
        if (element.isClass) {
          String extendsName = _findExtendsNameOfClass(element);
          if (extendsName != null) {
            Set<ClassElement> potentialSubclasses = potentialExtends
                .putIfAbsent(extendsName, () => new Set<ClassElement>());
            potentialSubclasses.add(element);
          }
        }
      });
    });

    // Resolve all the native classes and any classes that might extend them in
    // [potentialExtends], and then check that the properly resolved class is in
    // fact a subclass of a native class.

    ClassElement nativeSuperclassOf(ClassElement classElement) {
      if (_nativeBasicData.isNativeClass(classElement)) return classElement;
      if (classElement.superclass == null) return null;
      return nativeSuperclassOf(classElement.superclass);
    }

    void walkPotentialSubclasses(ClassElement element) {
      if (nativeClassesAndSubclasses.contains(element)) return;
      element.ensureResolved(_resolution);
      ClassElement nativeSuperclass = nativeSuperclassOf(element);
      if (nativeSuperclass != null) {
        nativeClassesAndSubclasses.add(element);
        Set<ClassElement> potentialSubclasses = potentialExtends[element.name];
        if (potentialSubclasses != null) {
          potentialSubclasses.forEach(walkPotentialSubclasses);
        }
      }
    }

    nativeClasses.forEach(walkPotentialSubclasses);
    nativeClasses.addAll(nativeClassesAndSubclasses);
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
      BeginGroupToken beginGroupToken = token;
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
      if (!token.isIdentifier()) return null;
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
        if (!token.isIdentifier()) return null;
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
  return specStringConstant.toDartString().slowToString();
}
