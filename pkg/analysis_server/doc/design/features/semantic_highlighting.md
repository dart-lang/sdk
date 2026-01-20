# Semantic highlighting

    LSP:    [textDocument/semanticTokens/*][] requests
    Legacy: `analysis.highlights` notification

Semantic highlighting makes it easier for the user to understand the code by
making certain syntactic and semantic aspects of the code more visible. The
client typically uses this information to apply text color or other highlighting
to the code being shown in the editor.

The design of the feature is largely dictated by the protocol, but there are
some areas where we have some flexibility. This document will cover those areas.

## Syntactic highlighting

Syntactic highlighting covers highlighting that is based purely on the syntax of
the language. For example, the highlighting of string literals or comments is
part of syntactic highlighting.

### Handling keywords

There is one question related to syntactic highlighting: the handling of
keywords. Dart has three categories of identifiers with special semantics, and
we needed to decide whether to explicitly represent these three categories of
identifiers or whether to ignore the distinctions. It could be argued that
ignoring the distinction would violate the principle of [language fidelity][].
It could also be argued that making the distinction might be confusing for the
user.

In the end, we decided that the better interpretation of the language spec is
that there are two important categories: identifiers that are functioning as a
keyword and identifiers that are not. As a result, we treat all of these as
keywords whenever they serve the function of a keyword, and treat them as
identifiers when they don't.

## Semantic highlighting

Semantic highlighting covers highlighting that is dependent on knowing the
semantics of the code. For example, highlighting static members of a class
differently than instance members requires knowing which member is being
referenced and whether it's a static member.

[language fidelity]: ../design/principles/language_fidelity.md
[textDocument/semanticTokens/*]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_semanticTokens
