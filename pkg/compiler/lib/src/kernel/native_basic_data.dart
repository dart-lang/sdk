// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../common/elements.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../ir/annotations.dart';
import '../js_backend/native_data.dart';
import '../native/resolver.dart';

import 'element_map.dart';

class KernelAnnotationProcessor {
  final KernelToElementMap elementMap;
  final NativeBasicDataBuilder _nativeBasicDataBuilder;
  final IrAnnotationData annotationData;

  KernelAnnotationProcessor(
      this.elementMap, this._nativeBasicDataBuilder, this.annotationData);

  void extractNativeAnnotations(LibraryEntity library) {
    KElementEnvironment elementEnvironment = elementMap.elementEnvironment;

    elementEnvironment.forEachClass(library, (ClassEntity cls) {
      ir.Class node = elementMap.getClassNode(cls);
      String? annotationName = annotationData.getNativeClassName(node);
      if (annotationName != null) {
        _nativeBasicDataBuilder.setNativeClassTagInfo(cls, annotationName);
      }
    });
  }

  String? getJsInteropName(
      Spannable spannable, Iterable<ConstantValue> metadata) {
    KCommonElements commonElements = elementMap.commonElements;
    String? annotationName;
    for (ConstantValue value in metadata) {
      String? name;
      List<ClassEntity?> jsAnnotationClasses = [
        commonElements.jsAnnotationClass1,
        commonElements.jsAnnotationClass2,
        commonElements.jsAnnotationClass3
      ];
      for (ClassEntity? jsAnnotationClass in jsAnnotationClasses) {
        if (jsAnnotationClass != null) {
          name = readAnnotationName(
              commonElements.dartTypes, spannable, value, jsAnnotationClass,
              defaultValue: '');
          if (name != null) break;
        }
      }
      if (annotationName == null) {
        annotationName = name;
      } else if (name != null) {
        // TODO(johnniwinther): This should be an error, not a crash.
        failedAt(spannable, 'Too many name annotations.');
      }
    }
    return annotationName;
  }

  void extractJsInteropAnnotations(LibraryEntity library) {
    // Unused reporter, add back in if uncommenting report lines down below.
    // DiagnosticReporter reporter = elementMap.reporter;
    KElementEnvironment elementEnvironment = elementMap.elementEnvironment;

    ir.Library libraryNode = elementMap.getLibraryNode(library);
    String? libraryName = annotationData.getJsInteropLibraryName(libraryNode);
    final bool isExplicitlyJsLibrary = libraryName != null;
    bool isJsLibrary = isExplicitlyJsLibrary;

    elementEnvironment.forEachLibraryMember(library, (MemberEntity member) {
      ir.Member memberNode = elementMap.getMemberNode(member);
      String? memberName = annotationData.getJsInteropMemberName(memberNode);
      if (member is FieldEntity) {
        if (memberName != null) {
          // TODO(34174): Disallow js-interop fields.
          /*reporter.reportErrorMessage(
              member, MessageKind.JS_INTEROP_FIELD_NOT_SUPPORTED);*/
        }
      } else {
        FunctionEntity function = member as FunctionEntity;
        if (function.isExternal && isExplicitlyJsLibrary) {
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
            _nativeBasicDataBuilder.markAsJsInteropMember(function, memberName,
                isJsInteropObjectLiteral:
                    annotationData.isJsInteropObjectLiteral(memberNode));
            // TODO(johnniwinther): It is unclear whether library can be
            // implicitly js-interop. For now we allow it.
            isJsLibrary = true;
          }
        }
      }
    });

    elementEnvironment.forEachClass(library, (ClassEntity cls) {
      ir.Class classNode = elementMap.getClassNode(cls);
      String? className = annotationData.getJsInteropClassName(classNode);
      if (className != null) {
        bool isAnonymous = annotationData.isAnonymousJsInteropClass(classNode);
        bool isStaticInterop = annotationData.isStaticInteropClass(classNode);
        // TODO(johnniwinther): Report an error if the class is anonymous but
        // has a non-empty name.
        _nativeBasicDataBuilder.markAsJsInteropClass(cls,
            name: className,
            isAnonymous: isAnonymous,
            isStaticInterop: isStaticInterop);
        // TODO(johnniwinther): It is unclear whether library can be implicitly
        // js-interop. For now we allow it.
        isJsLibrary = true;

        elementEnvironment.forEachLocalClassMember(cls, (MemberEntity member) {
          if (member is FieldEntity) {
            // TODO(34174): Disallow js-interop fields.
            /*reporter.reportErrorMessage(
                member, MessageKind.IMPLICIT_JS_INTEROP_FIELD_NOT_SUPPORTED);*/
          } else {
            FunctionEntity function = member as FunctionEntity;
            ir.Member memberNode = elementMap.getMemberNode(member);
            // Members that are not annotated and not external will result in
            // null here. For example, the default constructor which is not
            // user-specified.
            String? memberName =
                annotationData.getJsInteropMemberName(memberNode);
            if (function.isExternal) {
              memberName ??= function.name;
            }
            if (memberName != null) {
              // TODO(johnniwinther): The documentation states that explicit
              // member name annotations are not allowed on instance members.
              _nativeBasicDataBuilder.markAsJsInteropMember(
                  function, memberName,
                  isJsInteropObjectLiteral: false);
            }
          }
        });
        elementEnvironment.forEachConstructor(cls,
            (ConstructorEntity constructor) {
          String? memberName = getJsInteropName(
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
                constructor, memberName,
                isJsInteropObjectLiteral: false);
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
}
