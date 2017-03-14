Checklist to ensure that we have integration test coverage of all analysis
server calls.

This file is validated by `coverage_test.dart`.

TODO(devoncarew): We should track analysis server notifications here as well.

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

## diagnostic domain
- [x] diagnostic.getDiagnostics
- [x] diagnostic.getServerPort

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
- [x] execution.setSubscriptions

## search domain
- [x] search.findElementReferences
- [x] search.findMemberDeclarations
- [x] search.findMemberReferences
- [x] search.findTopLevelDeclarations
- [x] search.getTypeHierarchy

## server domain
- [x] server.getVersion
- [x] server.shutdown
- [x] server.setSubscriptions
