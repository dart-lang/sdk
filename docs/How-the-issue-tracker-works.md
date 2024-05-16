> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

The Dart SDK repo contains a large number of tools and libraries maintained by a
variety of sub-teams. Having them all in one repo makes it easier to land sweeping
changes across those components, but it comes at the expense of a big, unwieldy
issue tracker. To tame that chaos, we use the labels and policies explained here.

## Assignment

Like many modern software teams, Dart uses a pull model to assign tasks to
people. Most issues are assigned to a team (using the area labels below), but
not proactively assigned to an individual. When a person begins active work on
an issue, they assign the issue to themselves.

If you see an issue with a person assigned to it, it's usually in-progress. This
isn't always the case. Sometimes an issue is assigned to someone because we know
they will be the one to fix it, but they haven't started yet. When work gets
paused (sometimes for a long time) the assignee might not unassign themselves.

## Labels

Labels help us narrow down issues to the subsets each team or person cares
about. They let us count related issues to compare areas or see trends over
time. And they help the larger community understand what we're working on and
the state of their bugs.

For consistency, label names are `kebab-case`: lowercase words separated
by hyphens. Since we have a lot of labels, most of them are categorized. The
first word in the label name usually indicates the category. The labels and
categories are:

### Area ("area-")

These are the main labels that people on the Dart team care about. Each area
label defines a subteam (sometimes just one person) that owns issues and is
responsible for resolving them or passing them to another area.

Every issue must have a single area label. We've found that when labels have no
area, or multiple areas, it's not clear who is responsible for it, and it falls
through the cracks. If a single issue needs work from multiple teams, then it's
split into two or more issues, each one assigned to a single area.

The "[area-meta][]" area is special. A meta-issue groups a set of other issues
together to coordinate work across multiple teams. The issue usually describes
the overall plan at a high level and then links to the specific issues related
to it. Since no one team is responsible for "area-meta", an issue with that
label should also be assigned to a single person that is responsible for
tracking the status of the individual linked issues and closing the meta-issue
when everything is complete.

### Browser

For issues on our web products, this tracks which browser is affected by the
issue. We don't always apply this diligently, so the absence of this could mean
either "all browsers" or "we haven't investigated which browsers are affected".
Likewise, the *presence* of this doesn't necessarily mean other browsers are in
the clear.

### Customer ("customer-")

If an issue seriously affects a key partner, this tracks who they are. This
helps us prioritize the issue and makes sure we keep them in the loop on it.

We also use this to track Dart subteams that are affected by an issue owned
by another area. For example, if someone files a bug that the VM is failing to
display a certain static error, it would likely have "[area-cfe][]" (because the
front end team handles static errors) and "[customer-vm][]" because that's where
the error isn't being surfaced.

### OS ("os-")

Similar to browser, this tracks which operating systems an issue manifests on.
Again, we aren't super diligent about this. The presence of this label indicates
that we know it *does* have a problem on that OS, but may still possibly affect
others.

### Priority

Priority labels indicate the team's urgency around resolving the issue. They
roughly mean:

*   **[P0][]**: "World is on fire." Issues like multiple products
    unusable, a security issue exposing personal information, or a dramatic
    performance regression. As many team members as needed should drop
    everything to fix this.

*   **[P1][]**: "Something's broken." A single project is unusable or has
    many test failures. It should be fixed before resuming normal work.

*   **[P2][]**: "Business as usual." These are normal issues and feature
    requests that we can work into our schedule without any particular urgency.

*   **[P3][]**: "If you get a chance." Cosmetic or minor bugs with no
    urgency and low visibility. Polish or nice-to-haves.

Almost every issue should have exactly one of these labels.

### Closed ("closed-")

As the name implies, these labels are applied to closed issues, and indicate why
it was closed. In a perfect world, every issue filed would uniquely identify a
real, important problem and every closed issue would be fixed.

Alas, sometimes issues are duplicates of others, are too confusing, or we simply
don't have the time to do anything about it. We take every issue seriously, but
we also have to maximize the value we provide in the limited time we have, which
requires some trade-offs.

If an issue is closed without a closed label, that implies it is fixed. There
should usually be a link to the commit that fixes the issue or a comment
explaining it. Otherwise, it should have one of the resolution labels applied,
and often a comment explaining why that resolution was chosen.

The reasons are:

*   **[closed-as-intended][]**: This is one of the most contentious reasons to
    close an issue. This label means the current behavior is what we want, even
    though it's clearly not what the person who filed the issue wants.

    When possible, the person closing the bug should write a comment explaining
    why the current behavior is preferred. Often, there are constraints or
    interactions with other systems that prevent us from supporting the
    requested behavior. Sometimes it's simply making a trade-off between users
    who want different things.

*   **[closed-cannot-reproduce][]**: It's hard to verify that a fix is the right
    one without being able to see the underlying problem first. Sometimes this
    happens because the bug got fixed before anyone looked at the issue. Other
    times, the problem is still there but the investigator failed to get it to
    manifest. This resolution means they weren't able to make the issue happen
    and they believe it's likely to not be a problem any more.

    If an issue you filed is closed with this but it is still valid, consider
    adding a comment with more detailed reproduction steps so the issue can be
    re-opened.

*   **[closed-duplicate][]**: There is already another issue that tracks
    this change. When an issue is closed with this label, it should also have a
    comment that links to the other issue it is a duplicate of.

    Determining if two issues are duplicates often relies on
    understanding internal architecture and implementation details. Sometimes
    two issues look like the same problem but need to get solved in different
    ways. Other times, two seemingly-different issues have the same underlying
    cause.

    Because we use issues to track units of work, we treat issues as duplicates
    if they will be solved by a single change. This means that when we close one
    issue, we are not discarding the information in the issue or the important
    discussion it might have. That's still there and easy to find since the open
    issue links to it. It simply means we think there is only one task to
    perform that will address both issues, so there is no need to keep both
    open.

    In general, when deduplicating issues, we tend to keep the older one open
    unless the newer one is clearly more useful.

*   **[closed-invalid][]**: Sometimes, despite everyone's best intentions, we
    can't figure out what an issue description is trying to convey. Users
    sometimes file issues on our repo for completely unrelated products.
    Mistakes happen. This label means we couldn't make heads or tails of the
    issue.

    Most of the time, we try to avoid this and instead use "[needs-info][]" to
    get clarification from the person who filed the issue.

*   **[closed-obsolete][]**: The issue has been around for a long time with no
    activity. No one has worked on a solution and people don't seem to be
    clamoring for one either. The problem may have been fixed without someone
    realizing there was an issue. Sometimes stuff that was important turns out
    not to be later when needs change.

    In that case, there's little value keeping a zombie issue around and it will
    get closed. It's always OK to re-open the issue or file a new one of it
    turns out the problem is still relevant. This label is often applied
    manually by people when closing bugs, but also by the bot according to our
    expiration policy below.

*   **[closed-not-planned][]**: Possibly the saddest label. This is for issues
    where the request is valid but isn't expected to happen. Sometimes this is
    because other higher-priority enhancements would directly conflict with it.
    Often, it's simply a matter of not having enough time to get to it.

    When an issue is closed as not planned, that doesn't mean it will *never*
    happen. Priorities and capacity changes over time and it's entirely possible
    that it will come to the fore in the future. But in the meantime, we think
    it more clearly communicates the team's current priorities to close the
    issue instead of letting it linger even though we have no intent to
    allocate time to it.

### Type ("type-")

An issue's type categorizes the kind of problem entailed, or the nature of the
work required to solve it. There are a handful:

*   **[type-bug][]**: Issues with this label describe problems where the current
    behavior of the system is wrong and is not intended to act this way. It
    could be as severe as a crash or a more subtle misbehavior, but it should be
    obviously wrong in a way that almost no user wants.

*   **[type-code-health][]**: This tracks internal changes to our tools and
    workflows to make them cleaner, simpler, or more maintainable in ways that
    aren't user visible.

*   **[type-documentation][]**: A request to add or improve documentation. Since
    most of the high level docs like the pages on [dartlang.org][] are managed
    in other repositories, this ends up not being particularly common and is
    mostly API-level doc comments.

*   **[type-enhancement][]**: Every request for a concrete change to a tool that
    isn't a bug is an enhancement. These are new features, refinements to
    existing features, or other changes where the current behavior was intended
    but may no longer be desired or sufficient. Most issues around changing code
    get this label.

*   **[type-performance][]**: These are issues where the observed behavior is
    correct but the efficiency leaves something to be desired. "Performance"
    varies across a number of axes: execution time, memory usage, startup time,
    etc.

*   **[type-security][]**: The scariest kind of issue. These are problems
    related to user privacy or the ability of a malicious actor to take over a
    system.

*   **[type-task][]**: Tasks track work that needs to be done but where the
    result isn't a change to code or documentation. This is things like moving
    data around, publishing packages, tweaking servers or other infrastructure,
    etc.

Any given issue should have exactly one of these. If not, it's probably still
waiting to be triaged.

### Area-specific labels

Subteams often have their own labels that are only meaningful for a certain
product or system. Those labels start with the name of the team's area. For
example, "analyzer-", "vm-", etc. Area-specific labels are owned by the
respective team and it's up to that team to manage how the labels are used, what
they mean, and when they can be removed.

### Other labels

There are a few other miscellaneous labels you might run into:

*   **[blocked][]**: This marks an issue where the team is unable to make
    progress on it because of some external constraint or other team. There
    should be a comment explaining what it's blocked on. When possible, it will
    link directly to another issue that is blocking this one.

*   **[cla: yes][]**, **[cla: no][]**: Before we can accept a change from a
    non-Google contributor, they must sign our [contributor license
    agreement][cla]. We have a bot that requests that they do that and tracks
    whether they have using these labels.

*   **[contributions-welcome][]**: This marks an issue which has been vetted as
    "legitimate," and which the owning subteam would welcome a contribution
    from an external developer. Resolving an issue marked with this label
    should not be overly difficult, and should not require a great amount of
    code. This label is typically applied to bugs and documentation requests,
    rather than feature requests, due to the lower cost of review and
    maintenance.


*   **[merge-to-dev][]**, **[merge-to-stable][]**: These are used to track
    requests to cherry-pick a change from master to one of the [release
    branches][branches].

*   **[needs-info][]**: Like the name says, this means we need more
    information. This is often because the initial issue description is unclear.
    Other times, it means we have done some work fixing the issue and want
    someone else to validate the solution.

    When someone applies this label, they should also write a comment explaining
    what information or clarification they are looking for. Issues like this
    have a tendency to go stale because we can't make progress on it and the
    original submitter may have moved on. This means that we are likely to close
    an issue with this label if it hasn't had any activity in 60 days. If you
    care about keeping the issue alive, please try to provide the information it
    needs.

[area-cfe]: https://github.com/dart-lang/sdk/labels/area-cfe
[area-meta]: https://github.com/dart-lang/sdk/labels/area-meta
[blocked]: https://github.com/dart-lang/sdk/labels/blocked
[branches]: Branches-and-releases.md
[cla: no]: https://github.com/dart-lang/sdk/labels/cla%3A%20no
[cla: yes]: https://github.com/dart-lang/sdk/labels/cla%3A%20yes
[cla]: https://cla.developers.google.com/about/google-individual
[closed-as-intended]: https://github.com/dart-lang/sdk/labels/closed-as-intended
[closed-cannot-reproduce]: https://github.com/dart-lang/sdk/labels/closed-cannot-reproduce
[closed-duplicate]: https://github.com/dart-lang/sdk/labels/closed-duplicate
[closed-invalid]: https://github.com/dart-lang/sdk/labels/closed-invalid
[closed-not-planned]: https://github.com/dart-lang/sdk/labels/closed-not-planned
[closed-obsolete]: https://github.com/dart-lang/sdk/labels/closed-obsolete
[contributions-welcome]: https://github.com/dart-lang/sdk/labels/contributions-welcome
[customer-vm]: https://github.com/dart-lang/sdk/labels/customer-vm
[dartlang.org]: https://www.dartlang.org
[merge-to-dev]: https://github.com/dart-lang/sdk/labels/merge-to-dev
[merge-to-stable]: https://github.com/dart-lang/sdk/labels/merge-to-stable
[needs-info]: https://github.com/dart-lang/sdk/labels/needs-info
[P0]: https://github.com/dart-lang/sdk/labels/P0
[P1]: https://github.com/dart-lang/sdk/labels/P1
[P2]: https://github.com/dart-lang/sdk/labels/P2
[P3]: https://github.com/dart-lang/sdk/labels/P3
[type-bug]: https://github.com/dart-lang/sdk/labels/type-bug
[type-code-health]: https://github.com/dart-lang/sdk/labels/type-code-health
[type-documentation]: https://github.com/dart-lang/sdk/labels/type-documentation
[type-enhancement]: https://github.com/dart-lang/sdk/labels/type-enhancement
[type-performance]: https://github.com/dart-lang/sdk/labels/type-performance
[type-security]: https://github.com/dart-lang/sdk/labels/type-security
[type-task]: https://github.com/dart-lang/sdk/labels/type-task

## Queries

* [Issues with no area](https://github.com/dart-lang/sdk/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+-label%3Aarea-analyzer-cfe+-label%3Aarea-analyzer+-label%3Aarea-build+-label%3Aarea-dart2js+-label%3Aarea-dev-compiler+-label%3Aarea-documentation+-label%3Aarea-front-end+-label%3Aarea-html+-label%3Aarea-infrastructure+-label%3Aarea-intellij+-label%3Aarea-js-interop+-label%3Aarea-kernel+-label%3Aarea-language+-label%3Aarea-library+-label%3Aarea-meta+-label%3Aarea-observatory+-label%3Aarea-pkg+-label%3Aarea-samples+-label%3Aarea-sdk+-label%3Aarea-spec-parser+-label%3Aarea-specification+-label%3Aarea-test+-label%3Aarea-vm)
* [Issues with no priority](https://github.com/dart-lang/sdk/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+-label%3Ap0-critical+-label%3Ap1-high+-label%3Ap2-medium+-label%3Ap3-low+)
* [Issues with no type](https://github.com/dart-lang/sdk/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+-label%3Atype-bug+-label%3Atype-code-health+-label%3Atype-documentation+-label%3Atype-enhancement+-label%3Atype-performance+-label%3Atype-security+-label%3Atype-task)
* [Meta-issues with no assignee](https://github.com/dart-lang/sdk/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+label%3Aarea-meta+no%3Aassignee)
