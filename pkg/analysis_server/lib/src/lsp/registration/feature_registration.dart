// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/client_configuration.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handler_call_hierarchy.dart';
import 'package:analysis_server/src/lsp/handlers/handler_change_workspace_folders.dart';
import 'package:analysis_server/src/lsp/handlers/handler_code_actions.dart';
import 'package:analysis_server/src/lsp/handlers/handler_completion.dart';
import 'package:analysis_server/src/lsp/handlers/handler_definition.dart';
import 'package:analysis_server/src/lsp/handlers/handler_document_color.dart';
import 'package:analysis_server/src/lsp/handlers/handler_document_highlights.dart';
import 'package:analysis_server/src/lsp/handlers/handler_document_symbols.dart';
import 'package:analysis_server/src/lsp/handlers/handler_execute_command.dart';
import 'package:analysis_server/src/lsp/handlers/handler_folding.dart';
import 'package:analysis_server/src/lsp/handlers/handler_format_on_type.dart';
import 'package:analysis_server/src/lsp/handlers/handler_format_range.dart';
import 'package:analysis_server/src/lsp/handlers/handler_formatting.dart';
import 'package:analysis_server/src/lsp/handlers/handler_hover.dart';
import 'package:analysis_server/src/lsp/handlers/handler_implementation.dart';
import 'package:analysis_server/src/lsp/handlers/handler_inlay_hint.dart';
import 'package:analysis_server/src/lsp/handlers/handler_references.dart';
import 'package:analysis_server/src/lsp/handlers/handler_rename.dart';
import 'package:analysis_server/src/lsp/handlers/handler_selection_range.dart';
import 'package:analysis_server/src/lsp/handlers/handler_semantic_tokens.dart';
import 'package:analysis_server/src/lsp/handlers/handler_signature_help.dart';
import 'package:analysis_server/src/lsp/handlers/handler_text_document_changes.dart';
import 'package:analysis_server/src/lsp/handlers/handler_type_definition.dart';
import 'package:analysis_server/src/lsp/handlers/handler_type_hierarchy.dart';
import 'package:analysis_server/src/lsp/handlers/handler_will_rename_files.dart';
import 'package:analysis_server/src/lsp/handlers/handler_workspace_configuration.dart';
import 'package:analysis_server/src/lsp/handlers/handler_workspace_symbols.dart';
import 'package:analysis_server/src/lsp/server_capabilities_computer.dart';

typedef LspDynamicRegistration = (Method, ToJsonable?);

/// Provides static/dynamic registration info for an LSP feature.
abstract class FeatureRegistration {
  final RegistrationContext _context;

  FeatureRegistration(this._context);

  /// The capabilities of the client.
  LspClientCapabilities get clientCapabilities => _context.clientCapabilities;

  /// The configuration provided by the client.
  LspClientConfiguration get clientConfiguration =>
      _context.clientConfiguration;

  /// A helper to see which features the client supports dynamic registrations
  /// for. This information is derived from the [ClientCapabilities].
  ClientDynamicRegistrations get clientDynamic => _context.clientDynamic;

  /// Gets all dynamic registrations for this feature.
  ///
  /// These registrations should only be used if [supportsDynamic] returns true.
  List<LspDynamicRegistration> get dynamicRegistrations;

  /// Types of documents that are fully supported by the server.
  ///
  /// File types like pubspec.yaml, analysis_options.yaml and fix_data files are
  /// not included here as their support is very limited and do not provide
  /// functionality in most handlers.
  List<TextDocumentFilterWithScheme> get fullySupportedTypes {
    return {
      dartFiles,
      ...pluginTypes,
    }.toList();
  }

  /// Types of documents that loaded plugins are interetsed in.
  List<TextDocumentFilterWithScheme> get pluginTypes => _context.pluginTypes;

  /// Whether both the client, and this feature, support dynamic registration.
  bool get supportsDynamic;
}

/// A helper to provide access to all feature registrations.
class LspFeatures {
  final CallHierarchyRegistrations callHierarchy;
  final ChangeWorkspaceFoldersRegistrations changeNotifications;
  final CodeActionRegistrations codeActions;
  final CompletionRegistrations completion;
  final DefinitionRegistrations definition;
  final DocumentColorRegistrations colors;
  final DocumentHighlightsRegistrations documentHighlight;
  final DocumentSymbolsRegistrations documentSymbol;
  final ExecuteCommandRegistrations executeCommand;
  final FoldingRegistrations foldingRange;
  final FormatOnTypeRegistrations formatOnType;
  final FormatRangeRegistrations formatRange;
  final FormattingRegistrations format;
  final HoverRegistrations hover;
  final ImplementationRegistrations implementation;
  final InlayHintRegistrations inlayHint;
  final ReferencesRegistrations references;
  final RenameRegistrations rename;
  final SelectionRangeRegistrations selectionRange;
  final SemanticTokensRegistrations semanticTokens;
  final SignatureHelpRegistrations signatureHelp;
  final TextDocumentRegistrations textDocumentSync;
  final TypeDefinitionRegistrations typeDefinition;
  final TypeHierarchyRegistrations typeHierarchy;
  final WillRenameFilesRegistrations willRename;
  final WorkspaceDidChangeConfigurationRegistrations
      workspaceDidChangeConfiguration;
  final WorkspaceSymbolRegistrations workspaceSymbol;

  LspFeatures(RegistrationContext context)
      : callHierarchy = CallHierarchyRegistrations(context),
        changeNotifications = ChangeWorkspaceFoldersRegistrations(context),
        codeActions = CodeActionRegistrations(context),
        colors = DocumentColorRegistrations(context),
        completion = CompletionRegistrations(context),
        definition = DefinitionRegistrations(context),
        format = FormattingRegistrations(context),
        documentHighlight = DocumentHighlightsRegistrations(context),
        formatOnType = FormatOnTypeRegistrations(context),
        formatRange = FormatRangeRegistrations(context),
        documentSymbol = DocumentSymbolsRegistrations(context),
        executeCommand = ExecuteCommandRegistrations(context),
        foldingRange = FoldingRegistrations(context),
        hover = HoverRegistrations(context),
        implementation = ImplementationRegistrations(context),
        inlayHint = InlayHintRegistrations(context),
        references = ReferencesRegistrations(context),
        rename = RenameRegistrations(context),
        selectionRange = SelectionRangeRegistrations(context),
        semanticTokens = SemanticTokensRegistrations(context),
        signatureHelp = SignatureHelpRegistrations(context),
        textDocumentSync = TextDocumentRegistrations(context),
        typeDefinition = TypeDefinitionRegistrations(context),
        typeHierarchy = TypeHierarchyRegistrations(context),
        willRename = WillRenameFilesRegistrations(context),
        workspaceDidChangeConfiguration =
            WorkspaceDidChangeConfigurationRegistrations(context),
        workspaceSymbol = WorkspaceSymbolRegistrations(context);

  List<FeatureRegistration> get allFeatures => [
        callHierarchy,
        changeNotifications,
        codeActions,
        completion,
        definition,
        colors,
        documentHighlight,
        documentSymbol,
        executeCommand,
        foldingRange,
        formatOnType,
        formatRange,
        format,
        hover,
        implementation,
        inlayHint,
        references,
        rename,
        selectionRange,
        semanticTokens,
        signatureHelp,
        textDocumentSync,
        typeDefinition,
        typeHierarchy,
        willRename,
        workspaceDidChangeConfiguration,
        workspaceSymbol,
      ];
}

class RegistrationContext {
  /// A helper to see which features the client supports dynamic registrations
  /// for. This information is derived from the [ClientCapabilities].
  final ClientDynamicRegistrations clientDynamic;

  /// Types of documents that loaded plugins are interetsed in.
  final List<TextDocumentFilterWithScheme> pluginTypes;

  /// The capabilities of the client.
  final LspClientCapabilities clientCapabilities;

  /// The configuration provided by the client.
  final LspClientConfiguration clientConfiguration;

  RegistrationContext({
    required this.clientCapabilities,
    required this.clientConfiguration,
    required this.pluginTypes,
  }) : clientDynamic = ClientDynamicRegistrations(clientCapabilities.raw);
}

/// A helper mixin to simplify feature registrations that only provide a single
/// dynamic registration.
mixin SingleDynamicRegistration on FeatureRegistration {
  @override
  List<LspDynamicRegistration> get dynamicRegistrations {
    return [(registrationMethod, options)];
  }

  /// The options to use for static registration if it is to be used.
  ToJsonable? get options;

  /// The [Method] used for dynamic registration.
  Method get registrationMethod;
}

/// A helper that adds support for static registration of a feature.
mixin StaticRegistration<T> on FeatureRegistration {
  /// The raw options used for static registration. This should be accessed via
  /// [staticRegistration] to ensure it's only used when a) static registration
  /// is supported/enabled and b) dynamic registration is not supported.
  T get staticOptions;

  /// Only return static registration options if we support static and do not
  /// support dynamic registration.
  ///
  /// Some features will override [supportsStatic] to check options, so we must
  /// check [supportsDynamic] explicitly too.
  T? get staticRegistration =>
      supportsStatic && !supportsDynamic ? staticOptions : null;

  /// Whether this feature supports static registration.
  ///
  /// This is usually `true`, but may be overridden by client settings.
  bool get supportsStatic => true;
}
