// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(johnniwinther): Make this a separate library.
part of dart2js.kernel.element_map;

class KernelAnnotationProcessor implements AnnotationProcessor {
  final KernelToElementMapForImpactImpl elementMap;
  final NativeBasicDataBuilder _nativeBasicDataBuilder;

  KernelAnnotationProcessor(this.elementMap, this._nativeBasicDataBuilder);

  void extractNativeAnnotations(LibraryEntity library) {
    ElementEnvironment elementEnvironment = elementMap.elementEnvironment;
    CommonElements commonElements = elementMap.commonElements;

    elementEnvironment.forEachClass(library, (ClassEntity cls) {
      String annotationName;
      for (ConstantValue value in elementEnvironment.getClassMetadata(cls)) {
        String name = readAnnotationName(
            cls, value, commonElements.nativeAnnotationClass);
        if (annotationName == null) {
          annotationName = name;
        } else if (name != null) {
          failedAt(cls, 'Too many name annotations.');
        }
      }
      if (annotationName != null) {
        _nativeBasicDataBuilder.setNativeClassTagInfo(cls, annotationName);
      }
    });
  }

  String getJsInteropName(
      Spannable spannable, Iterable<ConstantValue> metadata) {
    CommonElements commonElements = elementMap.commonElements;
    String annotationName;
    for (ConstantValue value in metadata) {
      String name = readAnnotationName(
          spannable, value, commonElements.jsAnnotationClass,
          defaultValue: '');
      if (annotationName == null) {
        annotationName = name;
      } else if (name != null) {
        // TODO(johnniwinther): This should be an error, not a crash.
        failedAt(spannable, 'Too many name annotations.');
      }
    }
    return annotationName;
  }

  void checkFunctionParameters(FunctionEntity function) {
    if (function.parameterStructure.namedParameters.isNotEmpty) {
      elementMap.reporter.reportErrorMessage(
          function,
          MessageKind.JS_INTEROP_METHOD_WITH_NAMED_ARGUMENTS,
          {'method': function.name});
    }
  }

  void extractJsInteropAnnotations(LibraryEntity library) {
    DiagnosticReporter reporter = elementMap.reporter;
    ElementEnvironment elementEnvironment = elementMap.elementEnvironment;
    CommonElements commonElements = elementMap.commonElements;

    String libraryName = getJsInteropName(
        library, elementEnvironment.getLibraryMetadata(library));
    bool isJsLibrary = libraryName != null;

    elementEnvironment.forEachLibraryMember(library, (MemberEntity member) {
      if (member.isField) return;
      String memberName = getJsInteropName(
          library, elementEnvironment.getMemberMetadata(member));
      if (memberName != null) {
        _nativeBasicDataBuilder.markAsJsInteropMember(member, memberName);
        checkFunctionParameters(member);
      }
    });

    elementEnvironment.forEachClass(library, (ClassEntity cls) {
      Iterable<ConstantValue> metadata =
          elementEnvironment.getClassMetadata(cls);
      String className = getJsInteropName(cls, metadata);
      if (className != null) {
        bool isAnonymous = false;
        for (ConstantValue value in metadata) {
          if (isAnnotation(cls, value, commonElements.jsAnonymousClass)) {
            isAnonymous = true;
            break;
          }
        }
        // TODO(johnniwinther): Report an error if the class is anonymous but
        // has a non-empty name.
        _nativeBasicDataBuilder.markAsJsInteropClass(cls,
            name: className, isAnonymous: isAnonymous);
        // TODO(johnniwinther): When fasta supports library metadata, report
        // and error if [isJsLibrary] is false.
        // For now, assume the library is a js-interop library.
        isJsLibrary = true;

        elementEnvironment.forEachLocalClassMember(cls, (MemberEntity member) {
          if (member.isField) return;
          FunctionEntity function = member;

          String memberName = getJsInteropName(
              library, elementEnvironment.getMemberMetadata(function));
          if (memberName != null) {
            _nativeBasicDataBuilder.markAsJsInteropMember(function, memberName);
          }

          if (!function.isExternal &&
              !function.isAbstract &&
              !function.isConstructor &&
              !function.isStatic) {
            reporter.reportErrorMessage(
                function,
                MessageKind.JS_INTEROP_CLASS_NON_EXTERNAL_MEMBER,
                {'cls': cls.name, 'member': member.name});
          }

          checkFunctionParameters(function);
        });
        elementEnvironment.forEachConstructor(cls,
            (ConstructorEntity constructor) {
          String memberName = getJsInteropName(
              library, elementEnvironment.getMemberMetadata(constructor));
          if (memberName != null) {
            _nativeBasicDataBuilder.markAsJsInteropMember(
                constructor, memberName);
          }

          if (constructor.isFactoryConstructor && isAnonymous) {
            if (constructor.parameterStructure.positionalParameters > 0) {
              reporter.reportErrorMessage(
                  constructor,
                  MessageKind
                      .JS_OBJECT_LITERAL_CONSTRUCTOR_WITH_POSITIONAL_ARGUMENTS,
                  {'cls': cls.name});
            }
          } else {
            checkFunctionParameters(constructor);
          }
        });
      }
    });

    if (isJsLibrary) {
      // TODO(johnniwinther): Remove this when fasta supports library metadata.
      // For now, assume the empty name.
      libraryName ??= '';
      _nativeBasicDataBuilder.markAsJsInteropLibrary(library,
          name: libraryName);
    }
  }

  @override
  void processJsInteropAnnotations(
      NativeBasicData nativeBasicData, NativeDataBuilder nativeDataBuilder) {
    DiagnosticReporter reporter = elementMap.reporter;
    ElementEnvironment elementEnvironment = elementMap.elementEnvironment;
    CommonElements commonElements = elementMap.commonElements;

    for (LibraryEntity library in elementEnvironment.libraries) {
      // Error checking for class inheritance must happen after the first pass
      // through all the classes because it is possible to declare a subclass
      // before a superclass that has not yet had "markJsInteropClass" called on
      // it.
      elementEnvironment.forEachClass(library, (ClassEntity cls) {
        Iterable<ConstantValue> metadata =
            elementEnvironment.getClassMetadata(cls);
        String className = getJsInteropName(cls, metadata);
        if (className != null) {
          bool implementsJsJavaScriptObjectClass = false;
          elementEnvironment.forEachSupertype(cls, (InterfaceType supertype) {
            if (supertype.element == commonElements.jsJavaScriptObjectClass) {
              implementsJsJavaScriptObjectClass = true;
            }
          });
          if (!implementsJsJavaScriptObjectClass) {
            reporter.reportErrorMessage(
                cls, MessageKind.JS_INTEROP_CLASS_CANNOT_EXTEND_DART_CLASS, {
              'cls': cls.name,
              'superclass': elementEnvironment.getSuperClass(cls).name
            });
          }
        }
      });
    }
  }
}
