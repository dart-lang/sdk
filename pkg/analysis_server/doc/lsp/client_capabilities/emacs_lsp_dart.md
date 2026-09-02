# Emacs (lsp-mode with lsp-dart)

**Version**: lsp-mode 20260716.755, lsp-dart 20260507.1741
**Date**: 2026-07-16

```js
{
	"experimental": {
		"snippetTextEdit": null
	},
	"general": {
		"positionEncodings": [
			"utf-32",
			"utf-8",
			"utf-16"
		]
	},
	"textDocument": {
		"callHierarchy": {
			"dynamicRegistration": false
		},
		"codeAction": {
			"codeActionLiteralSupport": {
				"codeActionKind": {
					"valueSet": [
						"",
						"quickfix",
						"refactor",
						"refactor.extract",
						"refactor.inline",
						"refactor.rewrite",
						"source",
						"source.organizeImports"
					]
				}
			},
			"dataSupport": true,
			"dynamicRegistration": true,
			"isPreferredSupport": true,
			"resolveSupport": {
				"properties": [
					"edit",
					"command"
				]
			}
		},
		"completion": {
			"completionItem": {
				"deprecatedSupport": true,
				"documentationFormat": [
					"markdown",
					"plaintext"
				],
				"insertReplaceSupport": true,
				"insertTextModeSupport": {
					"valueSet": [
						1,
						2
					]
				},
				"labelDetailsSupport": true,
				"resolveAdditionalTextEditsSupport": true,
				"resolveSupport": {
					"properties": [
						"documentation",
						"detail",
						"additionalTextEdits",
						"command"
					]
				},
				"snippetSupport": false
			},
			"contextSupport": true,
			"dynamicRegistration": true
		},
		"declaration": {
			"dynamicRegistration": true,
			"linkSupport": true
		},
		"definition": {
			"dynamicRegistration": true,
			"linkSupport": true
		},
		"diagnostic": {
			"dynamicRegistration": false,
			"relatedDocumentSupport": false
		},
		"documentLink": {
			"dynamicRegistration": true,
			"tooltipSupport": true
		},
		"documentSymbol": {
			"hierarchicalDocumentSymbolSupport": true,
			"symbolKind": {
				"valueSet": [
					1,
					2,
					3,
					4,
					5,
					6,
					7,
					8,
					9,
					10,
					11,
					12,
					13,
					14,
					15,
					16,
					17,
					18,
					19,
					20,
					21,
					22,
					23,
					24,
					25,
					26
				]
			}
		},
		"foldingRange": {
			"dynamicRegistration": true
		},
		"formatting": {
			"dynamicRegistration": true
		},
		"hover": {
			"contentFormat": [
				"markdown",
				"plaintext"
			],
			"dynamicRegistration": true
		},
		"implementation": {
			"dynamicRegistration": true,
			"linkSupport": true
		},
		"inlineCompletion": null,
		"linkedEditingRange": {
			"dynamicRegistration": true
		},
		"onTypeFormatting": {
			"dynamicRegistration": true
		},
		"publishDiagnostics": {
			"relatedInformation": true,
			"tagSupport": {
				"valueSet": [
					1,
					2
				]
			},
			"versionSupport": true
		},
		"rangeFormatting": {
			"dynamicRegistration": true
		},
		"references": {
			"dynamicRegistration": true
		},
		"rename": {
			"dynamicRegistration": true,
			"prepareSupport": true
		},
		"selectionRange": {
			"dynamicRegistration": true
		},
		"signatureHelp": {
			"dynamicRegistration": true,
			"signatureInformation": {
				"activeParameterSupport": true,
				"parameterInformation": {
					"labelOffsetSupport": true
				}
			}
		},
		"synchronization": {
			"didSave": true,
			"willSave": true,
			"willSaveWaitUntil": true
		},
		"typeDefinition": {
			"dynamicRegistration": true,
			"linkSupport": true
		},
		"typeHierarchy": {
			"dynamicRegistration": true
		}
	},
	"window": {
		"showDocument": {
			"support": true
		},
		"workDoneProgress": true
	},
	"workspace": {
		"applyEdit": true,
		"codeLens": {
			"refreshSupport": true
		},
		"configuration": true,
		"diagnostics": {
			"refreshSupport": false
		},
		"didChangeWatchedFiles": {
			"dynamicRegistration": true
		},
		"executeCommand": {
			"dynamicRegistration": false
		},
		"fileOperations": {
			"didCreate": false,
			"didDelete": false,
			"didRename": true,
			"willCreate": false,
			"willDelete": false,
			"willRename": true
		},
		"symbol": {
			"symbolKind": {
				"valueSet": [
					1,
					2,
					3,
					4,
					5,
					6,
					7,
					8,
					9,
					10,
					11,
					12,
					13,
					14,
					15,
					16,
					17,
					18,
					19,
					20,
					21,
					22,
					23,
					24,
					25,
					26
				]
			}
		},
		"workspaceEdit": {
			"documentChanges": true,
			"resourceOperations": [
				"create",
				"rename",
				"delete"
			]
		},
		"workspaceFolders": true
	}
}
```
