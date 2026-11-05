# Neovim (nvim-flutter/flutter-tools)

**Version**: Neovim 0.12.4, nvim-flutter/flutter-tools 7d1acfd
**Date**: 2026-07-16

```js
{
	"general": {
		"positionEncodings": [
			"utf-8",
			"utf-16",
			"utf-32"
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
			"disabledSupport": true,
			"dynamicRegistration": true,
			"honorsChangeAnnotations": true,
			"isPreferredSupport": true,
			"resolveSupport": {
				"properties": [
					"edit",
					"command"
				]
			}
		},
		"codeLens": {
			"dynamicRegistration": false,
			"resolveSupport": {
				"properties": [
					"command"
				]
			}
		},
		"colorProvider": {
			"dynamicRegistration": true
		},
		"completion": {
			"completionItem": {
				"commitCharactersSupport": false,
				"deprecatedSupport": true,
				"documentationFormat": [
					"markdown",
					"plaintext"
				],
				"insertReplaceSupport": true,
				"labelDetailsSupport": true,
				"preselectSupport": false,
				"resolveSupport": {
					"properties": [
						"documentation",
						"detail",
						"additionalTextEdits"
					]
				},
				"snippetSupport": true,
				"tagSupport": {
					"valueSet": [
						1
					]
				}
			},
			"completionItemKind": {
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
					25
				]
			},
			"completionList": {
				"itemDefaults": [
					"editRange",
					"insertTextFormat",
					"insertTextMode",
					"data"
				]
			},
			"contextSupport": true,
			"dynamicRegistration": false
		},
		"declaration": {
			"linkSupport": true
		},
		"definition": {
			"dynamicRegistration": true,
			"linkSupport": true
		},
		"diagnostic": {
			"dataSupport": true,
			"dynamicRegistration": true,
			"relatedDocumentSupport": true,
			"relatedInformation": true,
			"tagSupport": {
				"valueSet": [
					1,
					2
				]
			}
		},
		"documentColor": {
			"dynamicRegistration": true
		},
		"documentHighlight": {
			"dynamicRegistration": false
		},
		"documentLink": {
			"dynamicRegistration": false,
			"tooltipSupport": false
		},
		"documentSymbol": {
			"dynamicRegistration": false,
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
			},
			"tagSupport": {
				"valueSet": [
					1
				]
			}
		},
		"foldingRange": {
			"dynamicRegistration": false,
			"foldingRange": {
				"collapsedText": true
			},
			"foldingRangeKind": {
				"valueSet": [
					"comment",
					"imports",
					"region"
				]
			},
			"lineFoldingOnly": true
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
			"linkSupport": true
		},
		"inlayHint": {
			"dynamicRegistration": true,
			"resolveSupport": {
				"properties": [
					"textEdits",
					"tooltip",
					"location",
					"command"
				]
			}
		},
		"inlineCompletion": {
			"dynamicRegistration": false
		},
		"linkedEditingRange": {
			"dynamicRegistration": false
		},
		"onTypeFormatting": {
			"dynamicRegistration": false
		},
		"publishDiagnostics": {
			"dataSupport": true,
			"relatedInformation": true,
			"tagSupport": {
				"valueSet": [
					1,
					2
				]
			}
		},
		"rangeFormatting": {
			"dynamicRegistration": true,
			"rangesSupport": true
		},
		"references": {
			"dynamicRegistration": false
		},
		"rename": {
			"dynamicRegistration": true,
			"honorsChangeAnnotations": true,
			"prepareSupport": true
		},
		"selectionRange": {
			"dynamicRegistration": false
		},
		"semanticTokens": {
			"augmentsSyntaxTokens": true,
			"dynamicRegistration": false,
			"formats": [
				"relative"
			],
			"multilineTokenSupport": true,
			"overlappingTokenSupport": true,
			"requests": {
				"full": {
					"delta": true
				},
				"range": true
			},
			"serverCancelSupport": false,
			"tokenModifiers": [
				"declaration",
				"definition",
				"readonly",
				"static",
				"deprecated",
				"abstract",
				"async",
				"modification",
				"documentation",
				"defaultLibrary"
			],
			"tokenTypes": [
				"namespace",
				"type",
				"class",
				"enum",
				"interface",
				"struct",
				"typeParameter",
				"parameter",
				"variable",
				"property",
				"enumMember",
				"event",
				"function",
				"method",
				"macro",
				"keyword",
				"modifier",
				"comment",
				"string",
				"number",
				"regexp",
				"operator",
				"decorator"
			]
		},
		"signatureHelp": {
			"dynamicRegistration": false,
			"signatureInformation": {
				"activeParameterSupport": true,
				"documentationFormat": [
					"markdown",
					"plaintext"
				],
				"noActiveParameterSupport": true,
				"parameterInformation": {
					"labelOffsetSupport": true
				}
			}
		},
		"synchronization": {
			"didSave": true,
			"dynamicRegistration": false,
			"willSave": true,
			"willSaveWaitUntil": true
		},
		"typeDefinition": {
			"linkSupport": true
		}
	},
	"window": {
		"showDocument": {
			"support": true
		},
		"showMessage": {
			"messageActionItem": {
				"additionalPropertiesSupport": true
			}
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
			"refreshSupport": true
		},
		"didChangeConfiguration": {
			"dynamicRegistration": false
		},
		"didChangeWatchedFiles": {
			"dynamicRegistration": false,
			"relativePatternSupport": true
		},
		"fileOperations": {
			"didCreate": false,
			"didDelete": false,
			"didRename": false,
			"dynamicRegistration": false,
			"willCreate": false,
			"willDelete": false,
			"willRename": false
		},
		"inlayHint": {
			"refreshSupport": true
		},
		"semanticTokens": {
			"refreshSupport": true
		},
		"symbol": {
			"dynamicRegistration": false,
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
			"changeAnnotationSupport": {
				"groupsOnLabel": true
			},
			"documentChanges": true,
			"normalizesLineEndings": true,
			"resourceOperations": [
				"rename",
				"create",
				"delete"
			]
		},
		"workspaceFolders": true
	}
}
```
