Checklist to ensure that we have integration test coverage of all analysis
server calls.

This file is validated by `coverage_test.dart`.

TODO(devoncarew): We should track analysis server notifications here as well.

## server domain
- [x] server.getVersion
- [x] server.shutdown
- [x] server.setSubscriptions

## analysis domain
- [x] analysis.getErrors
- [x] analysis.getHover
- [ ] analysis.getReachableSources
- [ ] analysis.getLibraryDependencies
- [x] analysis.getNavigation (failing - see #28799)
- [x] analysis.reanalyze
- [x] analysis.setAnalysisRoots
- [ ] analysis.setGeneralSubscriptions
- [ ] analysis.setPriorityFiles
- [x] analysis.setSubscriptions
- [x] analysis.updateContent
- [x] analysis.updateOptions (failing - see #28800)

## completion domain
- [x] completion.getSuggestions

## search domain
- [ ] search.findElementReferences
- [ ] search.findMemberDeclarations
- [ ] search.findMemberReferences
- [ ] search.findTopLevelDeclarations
- [x] search.getTypeHierarchy

## edit domain
- [x] edit.format
- [ ] edit.getAssists
- [ ] edit.getAvailableRefactorings
- [ ] edit.getFixes
- [ ] edit.getRefactoring
- [x] edit.sortMembers
- [x] edit.organizeDirectives

## execution domain
- [x] execution.createContext
- [x] execution.deleteContext
- [x] execution.mapUri
- [x] execution.setSubscriptions (failing - see #28806)

## diagnostic domain
- [x] diagnostic.getDiagnostics
