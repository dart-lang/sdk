// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/doc_comment.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:collection/collection.dart';
import 'package:yaml/yaml.dart';

/// Computes [DocumentLink]s for lint names in an 'analysis_options.yaml'.
class AnalysisOptionLinkComputer {
  static const _lintsUrl = 'https://dart.dev/tools/linter-rules/';
  final String pubHostedUrl;

  AnalysisOptionLinkComputer(this.pubHostedUrl);

  List<DocumentLink> findLinks(String content) {
    YamlNode node;
    try {
      node = loadYamlNode(content);
    } catch (exception) {
      return [];
    }

    if (node is! YamlMap) return [];

    var allRules = <YamlNode>[
      if (node.nodes['linter'] case YamlMap dependencies)
        ...switch (dependencies.nodes['rules']) {
          YamlMap(:var nodes) => nodes.keys.cast<YamlNode>(),
          YamlList rules => rules.nodes,
          _ => const <YamlNode>[],
        },
    ];

    var links = <DocumentLink>[];
    for (var rule in allRules) {
      var packageLink = _computeLink(rule);

      if (packageLink != null) {
        var offset = rule.span.start.offset;
        var length = rule.span.length;
        links.add(DocumentLink(offset, length, packageLink));
      }
    }

    var allPlugins = <YamlNode>[
      if (node.nodes['analyzer'] case YamlMap analyzer)
        if (analyzer.nodes['plugins'] case YamlNode plugins)
          ...switch (plugins) {
            YamlMap(:var nodes) => nodes.keys.cast<YamlNode>(),
            YamlList plugins => plugins.nodes,
            _ => const <YamlNode>[],
          },
    ];

    for (final plugin in allPlugins) {
      var pluginLink = _computePluginLink(plugin);

      if (pluginLink != null) {
        var offset = plugin.span.start.offset;
        var length = plugin.span.length;
        links.add(DocumentLink(offset, length, pluginLink));
      }
    }

    links.sort((a, b) => a.offset.compareTo(b.offset));

    return links;
  }

  /// Computes a link for the rule named [rule].
  Uri? _computeLink(YamlNode rule) {
    if (rule is! YamlScalar) return null;
    var name = rule.value;
    if (name is! String) return null;
    name = name.toLowerCase();

    var lint = Registry.ruleRegistry.rules.firstWhereOrNull(
      (rule) => rule.name.toLowerCase() == name,
    );
    if (lint == null) {
      return null;
    }

    return Uri.tryParse(_lintsUrl + name);
  }

  /// Computes a link for the plugin named [plugin].
  Uri? _computePluginLink(YamlNode plugin) {
    if (plugin is! YamlScalar) return null;
    var name = plugin.value;
    if (name is! String || name.isEmpty) return null;

    var separator = pubHostedUrl.endsWith('/') ? '' : '/';

    return Uri.parse('$pubHostedUrl${separator}packages/$name');
  }
}

/// A visitor to locate links to other documents in a file.
///
/// Such paths include "See example/a/b.dart" in documentation comments.
class DartDocumentLinkVisitor extends RecursiveAstVisitor<void> {
  final ParsedUnitResult unit;
  final String filePath;
  final ResourceProvider resourceProvider;
  final _documentLinks = <DocumentLink>[];

  /// The directory that contains `examples/api`, `null` if not found.
  late final Folder? folderWithExamplesApi = () {
    var file = resourceProvider.getFile(filePath);
    for (var parent in file.parent.withAncestors) {
      var apiFolder = parent
          .getChildAssumingFolder('examples')
          .getChildAssumingFolder('api');
      if (apiFolder.exists) {
        return parent;
      }
    }
    return null;
  }();

  DartDocumentLinkVisitor(this.resourceProvider, this.unit)
    : filePath = unit.path;

  List<DocumentLink> findLinks(AstNode node) {
    _documentLinks.clear();
    node.accept(this);
    return _documentLinks;
  }

  @override
  void visitComment(Comment node) {
    super.visitComment(node);

    var content = unit.content;

    var toolDirectives = node.docDirectives
        .where((directive) => directive.type == DocDirectiveType.tool)
        .whereType<BlockDocDirective>();
    for (var toolDirective in toolDirectives) {
      var contentsStart = toolDirective.openingTag.end;
      var contentsEnd = toolDirective.closingTag?.offset;

      // Skip unclosed tags.
      if (contentsEnd == null) {
        continue;
      }

      var strValue = content.substring(contentsStart, contentsEnd);
      if (strValue.isEmpty) {
        continue;
      }

      var seeCodeIn = '** See code in ';
      var startIndex = strValue.indexOf('${seeCodeIn}examples/api/');
      if (startIndex != -1) {
        final folderWithExamplesApi = this.folderWithExamplesApi;
        if (folderWithExamplesApi == null) {
          // Examples directory doesn't exist.
          return;
        }
        startIndex += seeCodeIn.length;
        var endIndex = strValue.indexOf('.dart') + 5;
        var pathSnippet = strValue.substring(startIndex, endIndex);
        // Split on '/' because that's what the comment syntax uses, but
        // re-join it using the resource provider to get the right separator
        // for the platform.
        var examplePath = resourceProvider.pathContext.joinAll([
          folderWithExamplesApi.path,
          ...pathSnippet.split('/'),
        ]);
        var offset = contentsStart + startIndex;
        var length = endIndex - startIndex;
        _documentLinks.add(DocumentLink(offset, length, Uri.file(examplePath)));
      }
    }
  }
}

/// A link to another document or URI found in a source file.
class DocumentLink {
  final Uri targetUri;
  final int offset;
  final int length;

  DocumentLink(this.offset, this.length, this.targetUri);
}

/// Computes [DocumentLink]s for package names in a 'pubspec.yaml'.
class PubspecDocumentLinkComputer {
  final String pubHostedUrl;

  final _gitHubSsshUrlPrefixRegExp = RegExp(r'^git@github\.com:');

  PubspecDocumentLinkComputer(this.pubHostedUrl);

  List<DocumentLink> findLinks(String content) {
    YamlNode node;
    try {
      node = loadYamlNode(content);
    } catch (exception) {
      return [];
    }

    if (node is! YamlMap) return [];

    var allDependencies = [
      if (node.nodes['dependencies'] case YamlMap dependencies)
        ...dependencies.nodes.cast<YamlNode, YamlNode>().entries,
      if (node.nodes['dev_dependencies'] case YamlMap devDependencies)
        ...devDependencies.nodes.cast<YamlNode, YamlNode>().entries,
      if (node.nodes['dependency_overrides'] case YamlMap dependencyOverrides)
        ...dependencyOverrides.nodes.cast<YamlNode, YamlNode>().entries,
    ];

    var links = <DocumentLink>[];
    for (var MapEntry(key: packageName, value: packageSource)
        in allDependencies) {
      var packageLink = _computeLink(packageName, packageSource);

      if (packageLink != null) {
        var offset = packageName.span.start.offset;
        var length = packageName.span.length;
        links.add(DocumentLink(offset, length, packageLink));
      }
    }

    return links;
  }

  /// Attempts to compute a link for a Git URL.
  ///
  /// If the URL is already HTTP/HTTPS it can usually be used as-is. If it's
  /// an SSH git link, attempt to convert it to an HTTPS equivalent:
  ///
  ///   git@github.com:dart-lang/sdk.git -> https://github.com/dart-lang/sdk.git
  Uri? _computeGit(String gitUrl, String packageName) {
    // Perform substitions for SSH URLs that we know can safely be converted to
    // HTTPS.
    gitUrl = gitUrl.replaceFirst(
      _gitHubSsshUrlPrefixRegExp,
      'https://github.com/',
    );

    var uri = Uri.tryParse(gitUrl);
    return uri != null && (uri.isScheme('https') || uri.isScheme('http'))
        ? uri
        : null;
  }

  /// Computes a link in the form [hostedBase]/packages/[packageName]
  /// handling an optional trailing slash from [hostedBase].
  Uri _computeHosted(String hostedBase, String packageName) {
    var separator = hostedBase.endsWith('/') ? '' : '/';
    return Uri.parse('$hostedBase${separator}packages/$packageName');
  }

  /// Computes a link for the package at [packageNameNode] based on the source
  /// defined by [packageSource].
  Uri? _computeLink(YamlNode packageNameNode, YamlNode packageSource) {
    if (packageNameNode is! YamlScalar) return null;
    var name = packageNameNode.value;
    if (name is! String) return null;

    return switch (packageSource) {
      // Standard Pub packages.
      //   foo:
      //   foo: ^123
      YamlScalar() => _computeHosted(pubHostedUrl, name),

      // Hosted
      //
      // foo:
      //   hosted: http://foo/
      YamlMap(nodes: {'hosted': YamlScalar(value: String base)}) =>
        _computeHosted(base, name),

      // Hosted 2
      //
      // foo2:
      //   hosted:
      //     url: http://foo
      YamlMap(
        nodes: {
          'hosted': YamlMap(nodes: {'url': YamlScalar(value: String base)}),
        },
      ) =>
        _computeHosted(base, name),

      // Git 1
      //
      // foo:
      //   git: git@github.com:dart-lang/sdk.git
      YamlMap(nodes: {'git': YamlScalar(value: String url)}) => _computeGit(
        url,
        name,
      ),

      // Git 2
      //
      // foo2:
      //   git:
      //     url: http://foo
      YamlMap(
        nodes: {'git': YamlMap(nodes: {'url': YamlScalar(value: String url)})},
      ) =>
        _computeGit(url, name),

      // Unknown kind (such as path or sdk) that we can't produce a link for.
      _ => null,
    };
  }
}
