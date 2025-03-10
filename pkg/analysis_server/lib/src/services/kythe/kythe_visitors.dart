// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: analyzer_use_new_elements

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer/src/workspace/blaze.dart';
import 'package:path/path.dart' show relative;

import 'schema.dart' as schema;

/// Returns the name of the [constructor].
///
/// This is either '<class-name>' or '<class-name>.<constructor-name>',
/// depending on whether the constructor is a named constructor.
String _computeConstructorElementName(ConstructorElement2 constructor) {
  var name = constructor.enclosingElement2.name3!;
  var constructorName = constructor.name3;
  if (constructorName != null && constructorName != 'new') {
    name = '$name.$constructorName';
  }
  return name;
}

String? _getNodeKind(Element2 e) {
  if (e is FieldElement2 && e.isEnumConstant) {
    // FieldElement is a kind of VariableElement, so this test case must be
    // before the e is VariableElement check.
    return schema.CONSTANT_KIND;
  } else if (e is VariableElement2 || e is PrefixElement2) {
    return schema.VARIABLE_KIND;
  } else if (e is ExecutableElement2) {
    return schema.FUNCTION_KIND;
  } else if (e is InterfaceElement2 || e is TypeParameterElement2) {
    // TODO(jwren): this should be using absvar instead, see
    // https://kythe.io/docs/schema/#absvar
    return schema.RECORD_KIND;
  }
  return null;
}

String _getPath(
  ResourceProvider provider,
  Element2? e, {
  String? sdkRootPath,
  String? corpus,
}) {
  // TODO(jwren): This method simply serves to provide the WORKSPACE relative
  // path for sources in Elements, it needs to be written in a more robust way.
  // TODO(jwren): figure out what source generates a e != null, but
  // e.source == null to ensure that it is not a bug somewhere in the stack.
  var source = e?.firstFragment.libraryFragment!.source;
  if (source == null) {
    // null sometimes when the element is used to generate the node type
    // "dynamic"
    return '';
  }
  if (sdkRootPath != null) {
    var uri = source.uri;
    if (uri.isScheme('dart')) {
      var pathSegments = uri.pathSegments;
      if (pathSegments.length == 1) {
        var libraryName = pathSegments.single;
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
  ResourceProvider provider,
  Element2? element,
  String nodeKind,
  String corpus, {
  String? sdkRootPath,
}) {
  assert(nodeKind != schema.ANCHOR_KIND); // Call _getAnchorSignature instead
  if (element == null) {
    return schema.DYNAMIC_KIND;
  }
  if (element is LibraryElement2) {
    return _getPath(
      provider,
      element,
      sdkRootPath: sdkRootPath,
      corpus: corpus,
    );
  }
  var builder = _SignatureBuilder.instance;
  return '$nodeKind:${builder.signatureFor(element)}';
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
    return toKytheUri2(e.asElement2!);
  }

  /// Returns a URI that can be used to query Kythe.
  String toKytheUri2(Element2 e) {
    var nodeKind = _getNodeKind(e) ?? schema.RECORD_KIND;
    var vname = _vNameFromElement(e, nodeKind);
    return 'kythe://$corpus?lang=dart?path=${vname.path}#${vname.signature}';
  }

  /// Returns the Kythe name for the [element].
  _KytheVName _vNameFromElement(Element2? e, String nodeKind) {
    assert(nodeKind != schema.FILE_KIND);
    // general case
    return _KytheVName(
      path: _getPath(
        resourceProvider,
        e,
        sdkRootPath: sdkRootPath,
        corpus: corpus,
      ),
      signature: _getSignature(
        resourceProvider,
        e,
        nodeKind,
        corpus,
        sdkRootPath: sdkRootPath,
      ),
    );
  }
}

class _KytheVName {
  final String path;
  final String signature;

  _KytheVName({required this.path, required this.signature});
}

/// An objects that builds up a string signature for an element.
///
/// Uniqueness is guaranteed within the enclosing file.
class _SignatureBuilder {
  static _SignatureBuilder instance = _SignatureBuilder();

  StringBuffer signatureFor(Element2 element) {
    var buffer = StringBuffer();
    _appendSignatureTo(buffer, element);
    return buffer;
  }

  void _appendSignatureTo(StringBuffer buffer, Element2 element) {
    if (element is LibraryElement2) {
      buffer.write('library:${element.displayName}');
    } else if (element is TypeParameterElement2) {
      // It is legal to have a named constructor with the same name as a type
      // parameter.  So we distinguish them by using '.' between the class (or
      // typedef) name and the type parameter name.
      _appendSignatureTo(buffer, element.enclosingElement2!);
      buffer
        ..write('.')
        ..write(element.name3!);
    } else {
      var enclosingElt = element.enclosingElement2!;
      _appendSignatureTo(buffer, enclosingElt);
      if (buffer.isNotEmpty) {
        buffer.write('#');
      }
      if (element is MethodElement2 &&
          element.name3 == '-' &&
          element.formalParameters.length == 1) {
        buffer.write('unary-');
      } else if (element is ConstructorElement2) {
        buffer.write(_computeConstructorElementName(element));
      } else {
        buffer.write(element.name3);
      }
      if (enclosingElt is ExecutableElement2) {
        buffer
          ..write('@')
          ..write(
            element.firstFragment.nameOffset2! -
                enclosingElt.firstFragment.nameOffset2!,
          );
      }
    }
  }
}
