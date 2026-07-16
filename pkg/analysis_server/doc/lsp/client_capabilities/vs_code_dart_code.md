# VS Code (Dart-Code extension)

This LSP client is an NPM package bundled with Dart-Code and therefore updated/versioned along with Dart-Code.

**Version**: Dart-Code 3.139.20260702
**Date**: 2026-07-15

```js
{
	"experimental": {
		"supportsWindowShowMessageRequest": true,
		"commands": [
			"dart.goToLocation"
		],
		"interactiveResolve": {
			"inputTypes": [
				"bool",
				"file",
				"enum",
				"lazyEnum",
				"number",
				"string"
			]
		},
		"dartCodeAction": {
			"commandParameterSupport": {
				"supportedKinds": [
					"saveUri"
				]
			}
		},
		"snippetTextEdit": true
	},
	"general": {
		"markdown": {
			"allowedTags": [
				"ul",
				"li",
				"p",
				"code",
				"blockquote",
				"ol",
				"h1",
				"h2",
				"h3",
				"h4",
				"h5",
				"h6",
				"hr",
				"em",
				"pre",
				"table",
				"thead",
				"tbody",
				"tr",
				"th",
				"td",
				"div",
				"del",
				"a",
				"strong",
				"br",
				"img",
				"span"
			],
			"parser": "marked",
			"version": "1.1.0"
		},
		"positionEncodings": [
			"utf-16"
		],
		"regularExpressions": {
			"engine": "ECMAScript",
			"version": "ES2020"
		},
		"staleRequestSupport": {
			"cancel": true,
			"retryOnContentModified": [
				"textDocument/semanticTokens/full",
				"textDocument/semanticTokens/range",
				"textDocument/semanticTokens/full/delta"
			]
		}
	},
	"notebookDocument": {
		"synchronization": {
			"dynamicRegistration": true,
			"executionSummarySupport": true
		}
	},
	"textDocument": {
		"callHierarchy": {
			"dynamicRegistration": true
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
						"refactor.move",
						"refactor.rewrite",
						"source",
						"source.organizeImports",
						"notebook"
					]
				}
			},
			"dataSupport": true,
			"disabledSupport": true,
			"documentationSupport": true,
			"dynamicRegistration": true,
			"honorsChangeAnnotations": true,
			"isPreferredSupport": true,
			"resolveSupport": {
				"properties": [
					"edit",
					"command"
				]
			},
			"tagSupport": {
				"valueSet": [
					1
				]
			}
		},
		"codeLens": {
			"dynamicRegistration": true,
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
				"commitCharactersSupport": true,
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
				"preselectSupport": true,
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
				"applyKindSupport": true,
				"itemDefaults": [
					"commitCharacters",
					"editRange",
					"insertTextFormat",
					"insertTextMode",
					"data"
				]
			},
			"contextSupport": true,
			"dynamicRegistration": true,
			"insertTextMode": 2
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
			"codeDescriptionSupport": true,
			"dataSupport": true,
			"dynamicRegistration": true,
			"markupMessageSupport": false,
			"relatedDocumentSupport": false,
			"relatedInformation": true,
			"tagSupport": {
				"valueSet": [
					1,
					2
				]
			}
		},
		"documentHighlight": {
			"dynamicRegistration": true
		},
		"documentLink": {
			"dynamicRegistration": true,
			"tooltipSupport": true
		},
		"documentSymbol": {
			"dynamicRegistration": true,
			"hierarchicalDocumentSymbolSupport": true,
			"labelSupport": true,
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
		"filters": {
			"relativePatternSupport": true
		},
		"foldingRange": {
			"dynamicRegistration": true,
			"foldingRange": {
				"collapsedText": false
			},
			"foldingRangeKind": {
				"valueSet": [
					"comment",
					"imports",
					"region"
				]
			},
			"lineFoldingOnly": true,
			"rangeLimit": 5000
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
		"inlayHint": {
			"dynamicRegistration": true,
			"resolveSupport": {
				"properties": [
					"tooltip",
					"textEdits",
					"label.tooltip",
					"label.location",
					"label.command"
				]
			}
		},
		"inlineValue": {
			"dynamicRegistration": true
		},
		"linkedEditingRange": {
			"dynamicRegistration": true
		},
		"onTypeFormatting": {
			"dynamicRegistration": true
		},
		"publishDiagnostics": {
			"codeDescriptionSupport": true,
			"dataSupport": true,
			"relatedInformation": true,
			"tagSupport": {
				"valueSet": [
					1,
					2
				]
			},
			"versionSupport": false
		},
		"rangeFormatting": {
			"dynamicRegistration": true,
			"rangesSupport": true
		},
		"references": {
			"dynamicRegistration": true
		},
		"rename": {
			"dynamicRegistration": true,
			"honorsChangeAnnotations": true,
			"prepareSupport": true,
			"prepareSupportDefaultBehavior": 1
		},
		"selectionRange": {
			"dynamicRegistration": true
		},
		"semanticTokens": {
			"augmentsSyntaxTokens": true,
			"dynamicRegistration": true,
			"formats": [
				"relative"
			],
			"multilineTokenSupport": false,
			"overlappingTokenSupport": false,
			"requests": {
				"full": {
					"delta": true
				},
				"range": true
			},
			"serverCancelSupport": true,
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
				"comment",
				"string",
				"number",
				"regexp",
				"operator",
				"decorator",
				"label"
			]
		},
		"signatureHelp": {
			"contextSupport": true,
			"dynamicRegistration": true,
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
			"dynamicRegistration": true,
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
			"dynamicRegistration": true
		},
		"didChangeWatchedFiles": {
			"dynamicRegistration": true,
			"relativePatternSupport": true
		},
		"executeCommand": {
			"dynamicRegistration": true
		},
		"fileOperations": {
			"didCreate": true,
			"didDelete": true,
			"didRename": true,
			"dynamicRegistration": true,
			"willCreate": true,
			"willDelete": true,
			"willRename": true
		},
		"foldingRange": {
			"refreshSupport": true
		},
		"inlayHint": {
			"refreshSupport": true
		},
		"inlineValue": {
			"refreshSupport": true
		},
		"semanticTokens": {
			"refreshSupport": true
		},
		"symbol": {
			"dynamicRegistration": true,
			"resolveSupport": {
				"properties": [
					"location.range"
				]
			},
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
		"workspaceEdit": {
			"changeAnnotationSupport": {
				"groupsOnLabel": true
			},
			"documentChanges": true,
			"failureHandling": "textOnlyTransactional",
			"metadataSupport": true,
			"normalizesLineEndings": true,
			"resourceOperations": [
				"create",
				"rename",
				"delete"
			],
			"snippetEditSupport": true
		},
		"workspaceFolders": true
	}
}
```
