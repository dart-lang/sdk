// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/workspace/blaze.dart';
import 'package:path/path.dart' show relative;

import 'schema.dart' as schema;

/// Given some [ConstructorElement], this method returns '<class-name>' as the
/// name of the constructor, unless the constructor is a named constructor in
/// which '<class-name>.<constructor-name>' is returned.
String _computeConstructorElementName(ConstructorElement element) {
  var name = element.enclosingElement2.name;
  var constructorName = element.name;
  if (constructorName.isNotEmpty) {
    name = '$name.$constructorName';
  }
  return name;
}

String? _getNodeKind(Element e) {
  if (e is FieldElement && e.isEnumConstant) {
    // FieldElement is a kind of VariableElement, so this test case must be
    // before the e is VariableElement check.
    return schema.CONSTANT_KIND;
  } else if (e is VariableElement || e is PrefixElement) {
    return schema.VARIABLE_KIND;
  } else if (e is ExecutableElement) {
    return schema.FUNCTION_KIND;
  } else if (e is InterfaceElement || e is TypeParameterElement) {
    // TODO(jwren): this should be using absvar instead, see
    // https://kythe.io/docs/schema/#absvar
    return schema.RECORD_KIND;
  }
  return null;
}

String _getPath(ResourceProvider provider, Element? e,
    {String? sdkRootPath, String? corpus}) {
  // TODO(jwren) This method simply serves to provide the WORKSPACE relative
  // path for sources in Elements, it needs to be written in a more robust way.
  // TODO(jwren) figure out what source generates a e != null, but
  // e.source == null to ensure that it is not a bug somewhere in the stack.
  var source = e?.source;
  if (source == null) {
    // null sometimes when the element is used to generate the node type
    // "dynamic"
    return '';
  }
  if (sdkRootPath != null) {
    final uri = source.uri;
    if (uri.isScheme('dart')) {
      final pathSegments = uri.pathSegments;
      if (pathSegments.length == 1) {
        final libraryName = pathSegments.single;
        return '$sdkRootPath/lib/$libraryName/$libraryName.dart';
      } else {
        return '$sdkRootPath/lib/${uri.path}';
      }
    }
    return relative(source.fullName, from: '/$corpus/');
  }

  var path = source.fullName;
  var blazeWorkspace = BlazeWorkspace.find(provider, path);
  if (blazeWorkspace != null) {
    return provider.pathContext.relative(path, from: blazeWorkspace.root);
  }
  if (path.lastIndexOf('CORPUS_NAME') != -1) {
    return path.substring(path.lastIndexOf('CORPUS_NAME') + 12);
  }

  return path;
}

/// If a non-null element is passed, the [_SignatureElementVisitor] is used to
/// generate and return a [String] signature, otherwise [schema.DYNAMIC_KIND] is
/// returned.
String _getSignature(
    ResourceProvider provider, Element? element, String nodeKind, String corpus,
    {String? sdkRootPath}) {
  assert(nodeKind != schema.ANCHOR_KIND); // Call _getAnchorSignature instead
  if (element == null) {
    return schema.DYNAMIC_KIND;
  }
  if (element is CompilationUnitElement) {
    return _getPath(provider, element,
        sdkRootPath: sdkRootPath, corpus: corpus);
  }
  return '$nodeKind:${element.accept(_SignatureElementVisitor.instance)}';
}

/// A helper class for getting the Kythe uri's for elements for querying
/// Kythe from Cider.
class CiderKytheHelper {
  final String sdkRootPath;
  final String corpus;
  final ResourceProvider resourceProvider;

  CiderKytheHelper(this.resourceProvider, this.corpus, this.sdkRootPath);

  /// Returns a URI that can be used to query Kythe.
  String toKytheUri(Element e) {
    var nodeKind = _getNodeKind(e) ?? schema.RECORD_KIND;
    var vname = _vNameFromElement(e, nodeKind);
    return 'kythe://$corpus?lang=dart?path=${vname.path}#${vname.signature}';
  }

  /// Given some [Element] and Kythe node kind, this method generates and
  /// returns the [_KytheVName].
  _KytheVName _vNameFromElement(Element? e, String nodeKind) {
    assert(nodeKind != schema.FILE_KIND);
    // general case
    return _KytheVName(
      path: _getPath(resourceProvider, e,
          sdkRootPath: sdkRootPath, corpus: corpus),
      signature: _getSignature(resourceProvider, e, nodeKind, corpus,
          sdkRootPath: sdkRootPath),
    );
  }
}

class _KytheVName {
  final String path;
  final String signature;

  _KytheVName({
    required this.path,
    required this.signature,
  });
}

/// This visitor class should be used by [_getSignature].
///
/// This visitor is an [GeneralizingElementVisitor] which builds up a [String]
/// signature for a given [Element], uniqueness is guaranteed within the
/// enclosing file.
class _SignatureElementVisitor
    extends GeneralizingElementVisitor<StringBuffer> {
  static _SignatureElementVisitor instance = _SignatureElementVisitor();

  @override
  StringBuffer visitCompilationUnitElement(CompilationUnitElement element) {
    return StringBuffer();
  }

  @override
  StringBuffer visitElement(Element element) {
    assert(element is! MultiplyInheritedExecutableElement);
    var enclosingElt = element.enclosingElement2!;
    var buffer = enclosingElt.accept(this)!;
    if (buffer.isNotEmpty) {
      buffer.write('#');
    }
    if (element is MethodElement &&
        element.name == '-' &&
        element.parameters.length == 1) {
      buffer.write('unary-');
    } else if (element is ConstructorElement) {
      buffer.write(_computeConstructorElementName(element));
    } else {
      buffer.write(element.name);
    }
    if (enclosingElt is ExecutableElement) {
      buffer
        ..write('@')
        ..write(element.nameOffset - enclosingElt.nameOffset);
    }
    return buffer;
  }

  @override
  StringBuffer visitLibraryElement(LibraryElement element) {
    return StringBuffer('library:${element.displayName}');
  }

  @override
  StringBuffer visitTypeParameterElement(TypeParameterElement element) {
    // It is legal to have a named constructor with the same name as a type
    // parameter.  So we distinguish them by using '.' between the class (or
    // typedef) name and the type parameter name.
    return element.enclosingElement2!.accept(this)!
      ..write('.')
      ..write(element.name);
  }
}
