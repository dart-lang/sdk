# Introduction

The purpose of this page is to give you an overview of what an analyzer plugin
is and what it can do.

## What is a plugin?

An analyzer plugin is a piece of code that communicates with the analysis server
to provide additional analysis support. The additional support is often specific
to a package or set of packages. For example, there is a plugin that provides
analysis specific to the Angular framework. Plugins are not required to be
specific to a package, but if the additional analysis is general enough, we
would urge you to consider contributing it back to the Dart project so that
everyone can more easily benefit from your work.

Plugins are written in Dart. They are executed by the analysis server by running
them in the same VM as the analysis server, but each plugin is run in a separate
isolate. The analysis server communicates with the plugins using a wire protocol
that is specified in the [plugin API][pluginapi] document. This API is similar
to the API used by the analysis server to communicate with clients.

The API consists of three kinds of communication. When the analysis server needs
information from the plugin, or needs to pass information to the plugin, it
sends a *request*. The plugin is required to answer every request with a
*response*. If the request was a request for information, then the response will
contain the requested information. Otherwise, the response is merely an
acknowledgement that the request was received. In addition, the plugin can send
a *notification* to the server to provide information to the server.

## What can plugins do?

The scope of what a plugin can do is defined by the [plugin API][pluginapi], but
it's useful to start with a high level overview.

### Lifecycle management

The API includes support for managing the lifecycle of a plugin. There is no
guarantee about when plugins will be started or stopped relative to either the
server or to each other.

When a plugin is first started, the analysis server will send a
`plugin.versionCheck` request to the plugin to verify that the plugin is using
the same version of the API as the server and therefore can communicate with the
server. This exchange also serves to communicate some other information between
the two participants.

When the server is asked to shut down, it will send a `plugin.shutdown` request
to the plugin to shut it down. This gives the plugin an opportunity to release
system resources or perform any other necessary actions. If a plugin encounters
an error that causes it to need to shut down, it should send a `plugin.error`
notification to the server to indicate that it is doing so.

### Managing analysis

The API includes support for managing which files are analyzed. There is no
requirement for when a plugin should perform the analysis, but to optimize the
user experience plugins should provide information to the server as quickly as
possible.

The analysis server sends an `analysis.setContextRoots` request to plugins to
tell them which files to analyze. Each `ContextRoot` indicates the root
directory containing the files to be analyzed (included) and any files and
directories within the root that should *not* be analyzed (excluded). Plugins
can read and use excluded files in the process of analyzing included files, but
should not report results for excluded files.

In order to improve the user experience, the analysis server will send an
`analysis.setPriorityFiles` request to specify which files should take priority
over other files. These are typically the files that are open and visible in the
client.

The analysis server will send an `analysis.handleWatchEvents` request to the
plugin when one or more files (within a context root) have been modified. The
plugin is expected to re-analyze those files in order to update the results for
those files.

The analysis server will send an `analysis.updateContent` request when the user
has edited a file but the edited content has not yet been written to disk. This
allows the plugin to provide analysis results as the user is typing.

### Requesting Analysis Results

In order to accommodate the workflow of clients, there are two ways for the
server to request analysis results from a plugin.

First, the server can send a request to request specific results for a specific
file. This is typically used for client-side functionality that the user has to
explicitly request and that clients will not retain long term. For example,
there is a request to get code completion suggestions. These requests are
discussed below.

For functionality that is always available, or for results that can change
without the client being aware that new data should be requested, there is a
subscription model. The server will send an `analysis.setSubscriptions` request
to the plugin. This request tells the plugin which results should be sent to the
server when the results become available. The plugin does not send any results
in the response to the request, but instead is expected to send a notification
to the server when the results have been computed. The notifications that can be
requested are also discussed below.

If the server has explicitly requested results, either by a request or by a
subscription, the plugin should provide those results even if the file is an
excluded file. This exception to the general rule does *not* apply to the
implicit subscription for diagnostics.

Plugins should *not* send analysis results that duplicate the information
computed by the analysis server itself. The expectation is for plugins to
extend this information, not replicate it.

### Diagnostics

Plugins can generate diagnostics to make users aware of problems in the code
that they have written. Diagnostics are typically displayed in the editor region
and might also be displayed in a separate diagnostics view or as decorations on
a directory structure view.

Plugins are expected to send any diagnostics that they generate for any of the
analyzed files (files that are included in a context root and not excluded).
Essentially, there is an implicit subscription for errors for all (non-excluded)
files. The plugin should send the errors in an `analysis.errors` notification.

### Semantic highlighting

Highlight information is used to color the content of the editor view.

If the server has subscribed for highlighting information in some set of files,
then the plugin should send the information in an `analysis.highlights`
notification whenever the information needs to be updated.

### Navigation

Navigation information is used by clients to allow users to navigate to the
location at which an identifier is defined.

Navigation information can be requested both by an `analysis.getNavigation`
request and by a subscription. If the server has subscribed for navigation
information in some set of files, the the plugin should send the information in
an `analysis.navigation` notification whenever the information needs to be
updated.

There is a tutorial explaining how to implement [navigation][navigation].

### Mark occurrences

Occurrences information is used by clients to highlight (or mark) all uses
within a given file of a single identifier when the user selects one use of that
identifier.

If the server has subscribed for occurrences information in some set of files,
then the plugin should send the information in an `analysis.occurrences`
notification whenever the information needs to be updated.

### Outline

Outline information is typically used by clients to provide a tree indicating
the nesting structure of declarations within the code.

If the server has subscribed for outline information in some set of files, then
the plugin should send the information in an `analysis.outline` notification
whenever the information needs to be updated.

### Folding

Folding information is used to allow users to collapse regions of text.

If the server has subscribed for folding information in some set of files, then
the plugin should send the information in an `analysis.folding` notification
whenever the information needs to be updated.

### Code completion

Code completion suggestions are used to provide possible completions at some
point in the text.

When the client request completion suggestions, the server will send a
`completion.getSuggestions` request. The plugin should only send suggestions
that would not also be returned by the server.

There is a tutorial explaining how to implement [code completion][completion].

### Fixes and assists

Fixes and assists are a set of edits that users can choose to have applied to
the code. They differ from a refactoring in that they cannot request additional
information from the user. For example, a rename refactoring needs to know the
new name, which requires prompting the user, and hence could not be implemented
as either a fix or an assist.

Fixes are associated with specific diagnostics, and hence should only be
generated if the diagnostics with which they are associated have been generated.
For example, if a diagnostic has been produced to indicate that a required
semicolon is missing, a fix might be generated to insert a semicolon.

The analysis server will request fixes by sending an `edit.getFixes` request.

Plugins should provide fixes for as many of the diagnostics they generate as
possible, but only when those fixes provide value to the user. (For example, a
fix to insert a semicolon is arguably harder to use than simply typing the
semicolon would be, and therefore is of questionable value.)

There is a tutorial explaining how to implement [fixes][fixes].

Assists are generally context-specific and hence should only be generated if the
cursor is in the right context. For example, if there is an assist to convert an
expression-style function body (one introduced by `=>`) into a block-style
function body, it should only be generated if the cursor is within an
expression-style function body.

The analysis server will request assists by sending an `edit.getAssists`
request.

There is a tutorial explaining how to implement [assists][assists].

[assists]: assists.md
[completion]: completion.md
[fixes]: fixes.md
[navigation]: navigation.md
[pluginapi]: https://htmlpreview.github.io/?https://github.com/dart-lang/sdk/blob/master/pkg/analyzer_plugin/doc/api.html
