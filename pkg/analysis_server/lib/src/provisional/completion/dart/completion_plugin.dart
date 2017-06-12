// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/completion.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/arglist_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/combinator_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/field_formal_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/imported_reference_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/inherited_reference_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/keyword_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/label_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/library_member_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/library_prefix_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/local_constructor_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/local_library_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/local_reference_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/named_constructor_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/static_member_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/type_member_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/uri_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/variable_name_contributor.dart';
import 'package:plugin/plugin.dart';

/**
 * The shared dart completion plugin instance.
 */
final DartCompletionPlugin dartCompletionPlugin = new DartCompletionPlugin();

class DartCompletionPlugin implements Plugin {
  /**
   * The simple identifier of the extension point that allows plugins to
   * register Dart specific completion contributor factories.
   * Use [DART_COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID]
   * when registering contributors.
   */
  static const String CONTRIBUTOR_EXTENSION_POINT = 'contributor';

  /**
   * The unique identifier of this plugin.
   */
  static const String UNIQUE_IDENTIFIER = 'dart.completion';

  /**
   * The extension point that allows plugins to register Dart specific
   * completion contributor factories.
   */
  ExtensionPoint<DartCompletionContributorFactory> _contributorExtensionPoint;

  /**
   * Return a list containing all of the Dart specific completion contributors.
   */
  Iterable<DartCompletionContributor> get contributors =>
      _contributorExtensionPoint.extensions.map(
          (Object factory) => (factory as DartCompletionContributorFactory)());

  @override
  String get uniqueIdentifier => UNIQUE_IDENTIFIER;

  @override
  void registerExtensionPoints(RegisterExtensionPoint registerExtensionPoint) {
    _contributorExtensionPoint =
        new ExtensionPoint<DartCompletionContributorFactory>(
            this, CONTRIBUTOR_EXTENSION_POINT, null);
    registerExtensionPoint(_contributorExtensionPoint);
  }

  @override
  void registerExtensions(RegisterExtension registerExtension) {
    //
    // Register DartCompletionManager as a CompletionContributor
    // which delegates to all the DartCompletionContributors
    //
    registerExtension(COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID,
        () => new DartCompletionManager());
    //
    // Register the default DartCompletionContributors
    //
    registerExtension(DART_COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID,
        () => new ArgListContributor());
    registerExtension(DART_COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID,
        () => new CombinatorContributor());
    registerExtension(DART_COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID,
        () => new FieldFormalContributor());
    registerExtension(DART_COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID,
        () => new ImportedReferenceContributor());
    registerExtension(DART_COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID,
        () => new InheritedReferenceContributor());
    registerExtension(DART_COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID,
        () => new KeywordContributor());
    registerExtension(DART_COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID,
        () => new LabelContributor());
    registerExtension(DART_COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID,
        () => new LibraryMemberContributor());
    registerExtension(DART_COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID,
        () => new LibraryPrefixContributor());
    registerExtension(DART_COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID,
        () => new LocalConstructorContributor());
    registerExtension(DART_COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID,
        () => new LocalLibraryContributor());
    registerExtension(DART_COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID,
        () => new LocalReferenceContributor());
    registerExtension(DART_COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID,
        () => new NamedConstructorContributor());
    // Revisit this contributor and these tests
    // once DartChangeBuilder API has solidified.
    // registerExtension(DART_COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID,
    //     () => new OverrideContributor());
    registerExtension(DART_COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID,
        () => new StaticMemberContributor());
    registerExtension(DART_COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID,
        () => new TypeMemberContributor());
    registerExtension(DART_COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID,
        () => new UriContributor());
    registerExtension(DART_COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID,
        () => new VariableNameContributor());
  }
}
