Checklist to ensure that we have integration test coverage of all analysis
server calls. This file is validated by `coverage_test.dart`.

## analysis domain
- [x] analysis.getErrors
- [x] analysis.getHover
- [x] analysis.getImportedElements
- [x] analysis.getLibraryDependencies (failing - see #29310)
- [x] analysis.getNavigation (failing - see #28799)
- [x] analysis.getReachableSources (failing - see #29311)
- [ ] analysis.getSignature
- [x] analysis.reanalyze
- [x] analysis.setAnalysisRoots
- [x] analysis.setGeneralSubscriptions
- [x] analysis.setPriorityFiles
- [x] analysis.setSubscriptions
- [x] analysis.updateContent
- [x] analysis.updateOptions (failing - see #28800) (deprecated)
- [ ] analysis.analyzedFiles
- [ ] analysis.closingLabels
- [ ] analysis.errors
- [ ] analysis.flushResults
- [ ] analysis.folding
- [x] analysis.highlights
- [ ] analysis.implemented
- [ ] analysis.invalidate
- [x] analysis.navigation
- [x] analysis.occurrences
- [x] analysis.outline
- [x] analysis.overrides

## completion domain
- [ ] completion.availableSuggestions
- [ ] completion.existingImports
- [ ] completion.getSuggestionDetails
- [x] completion.getSuggestions
- [x] completion.listTokenDetails
- [ ] completion.registerLibraryPaths
- [ ] completion.results
- [ ] completion.setSubscriptions

## diagnostic domain
- [x] diagnostic.getDiagnostics
- [x] diagnostic.getServerPort

## edit domain
- [x] edit.bulkFixes
- [x] edit.dartfix
- [x] edit.format
- [x] edit.getAssists
- [x] edit.getAvailableRefactorings
- [x] edit.getDartfixInfo
- [x] edit.getFixes
- [x] edit.getPostfixCompletion
- [x] edit.getRefactoring
- [x] edit.getStatementCompletion
- [x] edit.importElements
- [x] edit.isPostfixCompletionApplicable
- [x] edit.listPostfixCompletionTemplates
- [x] edit.sortMembers
- [x] edit.organizeDirectives

## execution domain
- [x] execution.createContext
- [x] execution.deleteContext
- [ ] execution.getSuggestions
- [x] execution.mapUri
- [x] execution.setSubscriptions
- [ ] execution.launchData

## search domain
- [x] search.findElementReferences
- [x] search.findMemberDeclarations
- [x] search.findMemberReferences
- [x] search.findTopLevelDeclarations
- [ ] search.getElementDeclarations
- [x] search.getTypeHierarchy
- [ ] search.results

## server domain
- [x] server.getVersion
- [x] server.shutdown
- [x] server.setSubscriptions
- [ ] server.connected
- [ ] server.error
- [ ] server.log
- [x] server.status

## analytics domain
- [x] analytics.isEnabled
- [x] analytics.enable
- [x] analytics.sendEvent
- [x] analytics.sendTiming

## kythe domain
- [x] kythe.getKytheEntries

## flutter domain
- [ ] flutter.getChangeAddForDesignTimeConstructor
- [ ] flutter.setSubscriptions
- [ ] flutter.outline
- [ ] flutter.getWidgetDescription
- [ ] flutter.setWidgetPropertyValue
