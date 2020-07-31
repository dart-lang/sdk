// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(johnniwinther): Make this a separate library.
part of dart2js.kernel.element_map;

class KernelAnnotationProcessor implements AnnotationProcessor {
  final KernelToElementMapImpl elementMap;
  final NativeBasicDataBuilder _nativeBasicDataBuilder;
  final IrAnnotationData annotationData;

  KernelAnnotationProcessor(
      this.elementMap, this._nativeBasicDataBuilder, this.annotationData)
      : assert(annotationData != null);

  @override
  void extractNativeAnnotations(LibraryEntity library) {
    KElementEnvironment elementEnvironment = elementMap.elementEnvironment;

    elementEnvironment.forEachClass(library, (ClassEntity cls) {
      ir.Class node = elementMap.getClassNode(cls);
      String annotationName = annotationData.getNativeClassName(node);
      if (annotationName != null) {
        _nativeBasicDataBuilder.setNativeClassTagInfo(cls, annotationName);
      }
    });
  }

  String getJsInteropName(
      Spannable spannable, Iterable<ConstantValue> metadata) {
    KCommonElements commonElements = elementMap.commonElements;
    String annotationName;
    for (ConstantValue value in metadata) {
      String name = readAnnotationName(commonElements.dartTypes, spannable,
              value, commonElements.jsAnnotationClass1, defaultValue: '') ??
          readAnnotationName(commonElements.dartTypes, spannable, value,
              commonElements.jsAnnotationClass2,
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

  @override
  void extractJsInteropAnnotations(LibraryEntity library) {
    DiagnosticReporter reporter = elementMap.reporter;
    KElementEnvironment elementEnvironment = elementMap.elementEnvironment;
    KCommonElements commonElements = elementMap.commonElements;

    ir.Library libraryNode = elementMap.getLibraryNode(library);
    String libraryName = annotationData.getJsInteropLibraryName(libraryNode);
    final bool isExplicitlylyJsLibrary = libraryName != null;
    bool isJsLibrary = isExplicitlylyJsLibrary;

    elementEnvironment.forEachLibraryMember(library, (MemberEntity member) {
      ir.Member memberNode = elementMap.getMemberNode(member);
      String memberName = annotationData.getJsInteropMemberName(memberNode);
      if (member.isField) {
        if (memberName != null) {
          // TODO(34174): Disallow js-interop fields.
          /*reporter.reportErrorMessage(
              member, MessageKind.JS_INTEROP_FIELD_NOT_SUPPORTED);*/
        }
      } else {
        FunctionEntity function = member;
        if (function.isExternal && isExplicitlylyJsLibrary) {
          // External members of explicit js-interop library are implicitly
          // js-interop members.
          memberName ??= function.name;
        }
        if (memberName != null) {
          if (!function.isExternal) {
            // TODO(johnniwinther): Disallow non-external js-interop members.
            /*reporter.reportErrorMessage(
                function, MessageKind.JS_INTEROP_NON_EXTERNAL_MEMBER);*/
          } else {
            _nativeBasicDataBuilder.markAsJsInteropMember(function, memberName);
            checkFunctionParameters(function);
            // TODO(johnniwinther): It is unclear whether library can be
            // implicitly js-interop. For now we allow it.
            isJsLibrary = true;
          }
        } else if (function.isExternal &&
            !commonElements.isExternalAllowed(function)) {
          reporter.reportErrorMessage(
              function, MessageKind.NON_NATIVE_EXTERNAL);
        }
      }
    });

    elementEnvironment.forEachClass(library, (ClassEntity cls) {
      ir.Class classNode = elementMap.getClassNode(cls);
      String className = annotationData.getJsInteropClassName(classNode);
      if (className != null) {
        bool isAnonymous = annotationData.isAnonymousJsInteropClass(classNode);
        // TODO(johnniwinther): Report an error if the class is anonymous but
        // has a non-empty name.
        _nativeBasicDataBuilder.markAsJsInteropClass(cls,
            name: className, isAnonymous: isAnonymous);
        // TODO(johnniwinther): It is unclear whether library can be implicitly
        // js-interop. For now we allow it.
        isJsLibrary = true;

        elementEnvironment.forEachLocalClassMember(cls, (MemberEntity member) {
          if (member.isField) {
            // TODO(34174): Disallow js-interop fields.
            /*reporter.reportErrorMessage(
                member, MessageKind.IMPLICIT_JS_INTEROP_FIELD_NOT_SUPPORTED);*/
          } else {
            FunctionEntity function = member;
            ir.Member memberNode = elementMap.getMemberNode(member);
            String memberName =
                annotationData.getJsInteropMemberName(memberNode);
            if (function.isExternal) {
              memberName ??= function.name;
            }
            if (memberName != null) {
              // TODO(johnniwinther): The documentation states that explicit
              // member name annotations are not allowed on instance members.
              _nativeBasicDataBuilder.markAsJsInteropMember(
                  function, memberName);
            }

            if (!function.isExternal &&
                !function.isAbstract &&
                !function.isStatic) {
              reporter.reportErrorMessage(
                  function,
                  MessageKind.JS_INTEROP_CLASS_NON_EXTERNAL_MEMBER,
                  {'cls': cls.name, 'member': member.name});
            }

            checkFunctionParameters(function);
          }
        });
        elementEnvironment.forEachConstructor(cls,
            (ConstructorEntity constructor) {
          String memberName = getJsInteropName(
              library, elementEnvironment.getMemberMetadata(constructor));
          if (constructor.isExternal) {
            // TODO(johnniwinther): It should probably be an error to have a
            // no-name constructor without a @JS() annotation.
            memberName ??= constructor.name;
          }
          if (memberName != null) {
            // TODO(johnniwinther): The documentation states that explicit
            // member name annotations are not allowed on instance members.
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
      } else {
        elementEnvironment.forEachLocalClassMember(cls, (MemberEntity member) {
          String memberName = getJsInteropName(
              library, elementEnvironment.getMemberMetadata(member));
          if (memberName != null) {
            reporter.reportErrorMessage(
                member, MessageKind.JS_INTEROP_MEMBER_IN_NON_JS_INTEROP_CLASS);
          } else if (member is FunctionEntity) {
            if (member.isExternal &&
                !commonElements.isExternalAllowed(member)) {
              reporter.reportErrorMessage(
                  member, MessageKind.NON_NATIVE_EXTERNAL);
            }
          }
        });
        elementEnvironment.forEachConstructor(cls,
            (ConstructorEntity constructor) {
          String memberName = getJsInteropName(
              library, elementEnvironment.getMemberMetadata(constructor));
          if (memberName != null) {
            reporter.reportErrorMessage(constructor,
                MessageKind.JS_INTEROP_MEMBER_IN_NON_JS_INTEROP_CLASS);
          } else {
            if (constructor.isExternal &&
                !commonElements.isExternalAllowed(constructor)) {
              reporter.reportErrorMessage(
                  constructor, MessageKind.NON_NATIVE_EXTERNAL);
            }
          }
        });
      }
    });

    if (isJsLibrary) {
      // TODO(johnniwinther): It is unclear whether library can be implicitly
      // js-interop. For now we allow it and assume the empty name.
      libraryName ??= '';
      _nativeBasicDataBuilder.markAsJsInteropLibrary(library,
          name: libraryName);
    }
  }

  @override
  void processJsInteropAnnotations(
      NativeBasicData nativeBasicData, NativeDataBuilder nativeDataBuilder) {
    DiagnosticReporter reporter = elementMap.reporter;
    KElementEnvironment elementEnvironment = elementMap.elementEnvironment;
    KCommonElements commonElements = elementMap.commonElements;

    for (LibraryEntity library in elementEnvironment.libraries) {
      // Error checking for class inheritance must happen after the first pass
      // through all the classes because it is possible to declare a subclass
      // before a superclass that has not yet had "markJsInteropClass" called on
      // it.
      elementEnvironment.forEachClass(library, (ClassEntity cls) {
        ir.Class classNode = elementMap.getClassNode(cls);
        String className = annotationData.getJsInteropClassName(classNode);
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
