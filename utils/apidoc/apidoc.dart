// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This generates the reference documentation for the core libraries that come
 * with dart. It is built on top of dartdoc, which is a general-purpose library
 * for generating docs from any Dart code. This library extends that to include
 * additional information and styling specific to our standard library.
 *
 * Usage:
 *
 *     $ dart apidoc.dart [--out=<output directory>]
 */
library apidoc;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'html_diff.dart';

// TODO(rnystrom): Use "package:" URL (#4968).
import '../../sdk/lib/_internal/compiler/implementation/mirrors/source_mirrors.dart';
import '../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors_util.dart';
import '../../sdk/lib/_internal/compiler/implementation/filenames.dart';
import '../../sdk/lib/_internal/dartdoc/lib/dartdoc.dart';
import '../../sdk/lib/_internal/libraries.dart';
import 'package:path/path.dart' as path;

HtmlDiff _diff;

void main(List<String> args) {
  int mode = MODE_STATIC;
  String outputDir = 'docs';
  bool generateAppCache = false;

  List<String> excludedLibraries = <String>[];

  // For libraries that have names matching the package name,
  // such as library unittest in package unittest, we just give
  // the package name with a --include-lib argument, such as:
  // --include-lib=unittest. These arguments are collected in
  // includedLibraries.
  List<String> includedLibraries = <String>[];

  // For libraries that lie within packages but have a different name,
  // such as the matcher library in package unittest, we can use
  // --extra-lib with a full relative path under pkg, such as
  // --extra-lib=unittest/lib/matcher.dart. These arguments are
  // collected in extraLibraries.
  List<String> extraLibraries = <String>[];

  String packageRoot;
  String version;

  // Parse the command-line arguments.
  for (int i = 0; i < args.length; i++) {
    final arg = args[i];

    switch (arg) {
      case '--mode=static':
        mode = MODE_STATIC;
        break;

      case '--mode=live-nav':
        mode = MODE_LIVE_NAV;
        break;

      case '--generate-app-cache=true':
        generateAppCache = true;
        break;

      default:
        if (arg.startsWith('--exclude-lib=')) {
          excludedLibraries.add(arg.substring('--exclude-lib='.length));
        } else if (arg.startsWith('--include-lib=')) {
          includedLibraries.add(arg.substring('--include-lib='.length));
        } else if (arg.startsWith('--extra-lib=')) {
          extraLibraries.add(arg.substring('--extra-lib='.length));
        } else if (arg.startsWith('--out=')) {
          outputDir = arg.substring('--out='.length);
        } else if (arg.startsWith('--package-root=')) {
          packageRoot = arg.substring('--package-root='.length);
        } else if (arg.startsWith('--version=')) {
          version = arg.substring('--version='.length);
        } else {
          print('Unknown option: $arg');
          return;
        }
        break;
    }
  }

  final libPath = path.join(scriptDir, '..', '..', 'sdk/');

  cleanOutputDirectory(outputDir);

  print('Copying static files...');
  // The basic dartdoc-provided static content.
  final copiedStatic = copyDirectory(
      path.join(scriptDir,
          '..', '..', 'sdk', 'lib', '_internal', 'dartdoc', 'static'),
      outputDir);

  // The apidoc-specific static content.
  final copiedApiDocStatic = copyDirectory(
      path.join(scriptDir, 'static'),
      outputDir);

  print('Parsing MDN data...');
  final mdnFile = new File(path.join(scriptDir, 'mdn', 'database.json'));
  final mdn = JSON.decode(mdnFile.readAsStringSync());

  print('Cross-referencing dart:html...');
  // TODO(amouravski): move HtmlDiff inside of the future chain below to re-use
  // the MirrorSystem already analyzed.
  _diff = new HtmlDiff(printWarnings:false);
  Future htmlDiff = _diff.run(currentDirectory.resolveUri(path.toUri(libPath)));

  // TODO(johnniwinther): Libraries for the compilation seem to be more like
  // URIs. Perhaps Path should have a toURI() method.
  // Add all of the core libraries.
  final apidocLibraries = <Uri>[];
  LIBRARIES.forEach((String name, LibraryInfo info) {
    if (info.documented) {
      apidocLibraries.add(Uri.parse('dart:$name'));
    }
  });

  // TODO(amouravski): This code is really wonky.
  var lister = new Directory(path.join(scriptDir, '..', '..', 'pkg')).list();
  lister.listen((entity) {
    if (entity is Directory) {
      var libName = path.basename(entity.path);
      var libPath = path.join(entity.path, 'lib', '${libName}.dart');

      // Ignore some libraries.
      if (excludedLibraries.contains(libName)) {
        return;
      }

      // Ignore hidden directories (like .svn) as well as pkg.xcodeproj.
      if (libName.startsWith('.') || libName.endsWith('.xcodeproj')) {
        return;
      }

      if (new File(libPath).existsSync()) {
        apidocLibraries.add(path.toUri(libPath));
        includedLibraries.add(libName);
      } else {
        print('Warning: could not find package at ${entity.path}');
      }
    }
  }, onDone: () {
    // Add any --extra libraries that had full pkg paths.
    // TODO(gram): if the handling of --include-lib libraries in the
    // listen() block above is cleaned up, then this will need to be
    // too, as it is a special case of the above.
    for (var lib in extraLibraries) {
      var libPath = '../../$lib';
      if (new File(libPath).existsSync()) {
        apidocLibraries.add(path.toUri(libPath));
        var libName = path.basename(libPath).replaceAll('.dart', '');
        includedLibraries.add(libName);
      }
    }

    final apidoc = new Apidoc(mdn, outputDir, mode, generateAppCache,
                              excludedLibraries, version);
    apidoc.dartdocPath =
        path.join(scriptDir, '..', '..', 'sdk', 'lib', '_internal', 'dartdoc');
    // Select the libraries to include in the produced documentation:
    apidoc.includeApi = true;
    apidoc.includedLibraries = includedLibraries;

    // TODO(amouravski): make apidoc use roughly the same flow as bin/dartdoc.
    Future.wait([copiedStatic, copiedApiDocStatic, htmlDiff])
      .then((_) => apidoc.documentLibraries(apidocLibraries, libPath,
            packageRoot))
      .then((_) => compileScript(mode, outputDir, libPath, apidoc.tmpPath))
      .then((_) => print(apidoc.status))
      .catchError((e, trace) {
        print('Error: generation failed: ${e}');
        if (trace != null) print("StackTrace: $trace");
        apidoc.cleanup();
        exit(1);
      })
      .whenComplete(() => apidoc.cleanup());
  });
}

class Apidoc extends Dartdoc {
  /** Big ball of JSON containing the scraped MDN documentation. */
  final Map mdn;


  // A set of type names (TypeMirror.simpleName values) to ignore while
  // looking up information from MDN data.  TODO(eub, jacobr): fix up the MDN
  // import scripts so they run correctly and generate data that doesn't have
  // any entries that need to be ignored.
  static Set<String> _mdnTypeNamesToSkip = null;

  /**
   * The URL to the page on MDN that content was pulled from for the current
   * type being documented. Will be `null` if the type doesn't use any MDN
   * content.
   */
  String mdnUrl = null;

  Apidoc(this.mdn, String outputDir, int mode, bool generateAppCache,
      [List<String> excludedLibraries, String version]) {
    if (excludedLibraries != null) this.excludedLibraries = excludedLibraries;
    this.version = version;
    this.outputDir = outputDir;
    this.mode = mode;
    this.generateAppCache = generateAppCache;

    // Skip bad entries in the checked-in mdn/database.json:
    //  * UnknownElement has a top-level Gecko DOM page in German.
    if (_mdnTypeNamesToSkip == null)
      _mdnTypeNamesToSkip = new Set.from(['UnknownElement']);

    mainTitle = 'Dart API Reference';
    mainUrl = 'http://dartlang.org';

    final note    = 'http://code.google.com/policies.html#restrictions';
    final cca     = 'http://creativecommons.org/licenses/by/3.0/';
    final bsd     = 'http://code.google.com/google_bsd_license.html';
    final tos     = 'http://www.dartlang.org/tos.html';
    final privacy = 'http://www.google.com/intl/en/privacy/privacy-policy.html';

    footerText =
        '''
        <p>Except as otherwise <a href="$note">noted</a>, the content of this
        page is licensed under the <a href="$cca">Creative Commons Attribution
        3.0 License</a>, and code samples are licensed under the
        <a href="$bsd">BSD License</a>.</p>
        <p><a href="$tos">Terms of Service</a> |
        <a href="$privacy">Privacy Policy</a></p>
        ''';

    searchEngineId = '011220921317074318178:i4mscbaxtru';
    searchResultsUrl = 'http://www.dartlang.org/search.html';
  }

  void writeHeadContents(String title) {
    super.writeHeadContents(title);

    // Include the apidoc-specific CSS.
    // TODO(rnystrom): Use our CSS pre-processor to combine these.
    writeln(
        '''
        <link rel="stylesheet" type="text/css"
            href="${relativePath('apidoc-styles.css')}" />
        ''');

    // Add the analytics code.
    writeln(
        '''
        <script type="text/javascript">
          var _gaq = _gaq || [];
          _gaq.push(["_setAccount", "UA-26406144-9"]);
          _gaq.push(["_trackPageview"]);

          (function() {
            var ga = document.createElement("script");
            ga.type = "text/javascript"; ga.async = true;
            ga.src = ("https:" == document.location.protocol ?
              "https://ssl" : "http://www") + ".google-analytics.com/ga.js";
            var s = document.getElementsByTagName("script")[0];
            s.parentNode.insertBefore(ga, s);
          })();
        </script>
        ''');
  }

  void docIndexLibrary(LibraryMirror library) {
    // TODO(rnystrom): Hackish. The IO libraries reference this but we don't
    // want it in the docs.
    if (displayName(library) == 'dart:nativewrappers') return;
    super.docIndexLibrary(library);
  }

  void docLibraryNavigationJson(LibraryMirror library, List libraryList) {
    // TODO(rnystrom): Hackish. The IO libraries reference this but we don't
    // want it in the docs.
    if (displayName(library) == 'dart:nativewrappers') return;
    super.docLibraryNavigationJson(library, libraryList);
  }

  void docLibrary(LibraryMirror library) {
    // TODO(rnystrom): Hackish. The IO libraries reference this but we don't
    // want it in the docs.
    if (displayName(library) == 'dart:nativewrappers') return;
    super.docLibrary(library);
  }

  DocComment getLibraryComment(LibraryMirror library) {
    return super.getLibraryComment(library);
  }

  DocComment getTypeComment(TypeMirror type) {
    return _mergeDocs(
        includeMdnTypeComment(type), super.getTypeComment(type));
  }

  DocComment getMemberComment(DeclarationMirror member) {
    return _mergeDocs(
        includeMdnMemberComment(member), super.getMemberComment(member));
  }

  DocComment _mergeDocs(MdnComment mdnComment,
                            DocComment fileComment) {
    // Otherwise, prefer comment from the (possibly generated) Dart file.
    if (fileComment != null) return fileComment;

    // Finally, fallback on MDN if available.
    if (mdnComment != null) {
      mdnUrl = mdnComment.mdnUrl;
      return mdnComment;
    }

    // We got nothing!
    return null;
  }

  void docType(TypeMirror type) {
    // Track whether we've inserted MDN content into this page.
    mdnUrl = null;

    super.docType(type);
  }

  void writeTypeFooter() {
    if (mdnUrl != null) {
      final MOZ = 'http://www.mozilla.org/';
      final MDN = 'https://developer.mozilla.org';
      final CCA = 'http://creativecommons.org/licenses/by-sa/2.5/';
      final CONTRIB = 'https://developer.mozilla.org/Project:en/How_to_Help';
      writeln(
          '''
          <p class="mdn-attribution">
          <a href="$MDN">
            <img src="${relativePath('mdn-logo-tiny.png')}" class="mdn-logo" />
          </a>
          This page includes <a href="$mdnUrl">content</a> from the
          <a href="$MOZ">Mozilla Foundation</a> that is graciously
          <a href="$MDN/Project:Copyrights">licensed</a> under a
          <a href="$CCA">Creative Commons: Attribution-Sharealike license</a>.
          Mozilla has no other association with Dart or dartlang.org. We
          encourage you to improve the web by
          <a href="$CONTRIB">contributing</a> to
          <a href="$MDN">The Mozilla Developer Network</a>.
          </p>
          ''');
    }
  }

  MdnComment lookupMdnComment(Mirror mirror) {
    if (mirror is TypeMirror) {
      return includeMdnTypeComment(mirror);
    } else if (mirror is MethodMirror || mirror is VariableMirror) {
      return includeMdnMemberComment(mirror);
    } else {
      return null;
    }
  }

  /**
   * Gets the MDN-scraped docs for [type], or `null` if this type isn't
   * scraped from MDN.
   */
  MdnComment includeMdnTypeComment(TypeMirror type) {
    if (_mdnTypeNamesToSkip.contains(type.simpleName)) {
      return null;
    }

    var typeString = '';
    if (HTML_LIBRARY_URIS.contains(getLibrary(type).uri)) {
      // If it's an HTML type, try to map it to a base DOM type so we can find
      // the MDN docs.
      final domTypes = _diff.htmlTypesToDom[type.qualifiedName];

      // Couldn't find a DOM type.
      if ((domTypes == null) || (domTypes.length != 1)) return null;

      // Use the corresponding DOM type when searching MDN.
      // TODO(rnystrom): Shame there isn't a simpler way to get the one item
      // out of a singleton Set.
      // TODO(floitsch): switch to domTypes.first, once that's implemented.
      var iter = domTypes.iterator;
      iter.moveNext();
      typeString = iter.current;
    } else {
      // Not a DOM type.
      return null;
    }

    final mdnType = mdn[typeString];
    if (mdnType == null) return null;
    if (mdnType['skipped'] != null) return null;
    if (mdnType['summary'] == null) return null;
    if (mdnType['summary'].trim().isEmpty) return null;

    // Remember which MDN page we're using so we can attribute it.
    return new MdnComment(mdnType['summary'], mdnType['srcUrl']);
  }

  /**
   * Gets the MDN-scraped docs for [member], or `null` if this type isn't
   * scraped from MDN.
   */
  MdnComment includeMdnMemberComment(DeclarationMirror member) {
    var library = getLibrary(member);
    var memberString = '';
    if (HTML_LIBRARY_URIS.contains(library.uri)) {
      // If it's an HTML type, try to map it to a DOM type name so we can find
      // the MDN docs.
      final domMembers = _diff.htmlToDom[member.qualifiedName];

      // Couldn't find a DOM type.
      if ((domMembers == null) || (domMembers.length != 1)) return null;

      // Use the corresponding DOM member when searching MDN.
      // TODO(rnystrom): Shame there isn't a simpler way to get the one item
      // out of a singleton Set.
      // TODO(floitsch): switch to domTypes.first, once that's implemented.
      var iter = domMembers.iterator;
      iter.moveNext();
      memberString = iter.current;
    } else {
      // Not a DOM type.
      return null;
    }

    // Ignore top-level functions.
    if (member.isTopLevel) return null;

    var mdnMember = null;
    var mdnType =  null;
    var pieces = memberString.split('.');
    if (pieces.length == 2) {
      mdnType = mdn[pieces[0]];
      if (mdnType == null) return null;
      var nameToFind = pieces[1];
      for (final candidateMember in mdnType['members']) {
        if (candidateMember['name'] == nameToFind) {
          mdnMember = candidateMember;
          break;
        }
      }
    }

    if (mdnMember == null) return null;
    if (mdnMember['help'] == null) return null;
    if (mdnMember['help'].trim().isEmpty) return null;

    // Remember which MDN page we're using so we can attribute it.
    return new MdnComment(mdnMember['help'], mdnType['srcUrl']);
  }

  /**
   * Returns a link to [member], relative to a type page that may be in a
   * different library than [member].
   */
  String _linkMember(DeclarationMirror member) {
    final typeName = member.owner.simpleName;
    var memberName = '$typeName.${member.simpleName}';
    if (member is MethodMirror && member.isConstructor) {
      final separator = member.constructorName == '' ? '' : '.';
      memberName = 'new $typeName$separator${member.constructorName}';
    }

    return a(memberUrl(member), memberName);
  }
}

