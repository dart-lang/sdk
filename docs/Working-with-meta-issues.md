> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

When doing a large task that involves multiple people or changes to the codebase, it helps to have a single issue that tracks the overall state of the task. This is called a "meta-issue". It describes the overall goal and links to more specific issues for individual pieces of work.

If a meta-issue involves work across multiple areas, it should have the "[area-meta][]" label. It should also be assigned to a person who is responsible for coordinating the work across teams and keeping the meta-issue updated. If all of the tasks are within a single area, the meta-issue should instead be labeled with that area. In that case, it doesn't need an assignee, though having one doesn't hurt.

Like other specific issues, it should have a type label that describes the type of the overall change: [type-bug], [type-enhancement], etc.

[area-meta]: https://github.com/dart-lang/sdk/labels/area-meta
[type-bug]: https://github.com/dart-lang/sdk/labels/type-bug
[type-enhancement]: https://github.com/dart-lang/sdk/labels/type-enhancement

The meta-issue's body text should give a high-level overview of the change followed by a task list for all the sub-issues. Each entry should have a very brief description and a link to the sub-issue. A task list can be created using the following Markdown:

```markdown
- [ ] item
- [ ] item
- [x] checked item
```

Once a sub-issue is completed, its entry should be checked. If applicable, the first release to contain the fix should be mentioned as well.

Occasionally new sub-issues come up. For example, a bug might be found in the solution to a previously-completed sub-issue. To add these to the meta-issue, a triager should both add a comment linking to the new sub-issue *and* add it to the task list. Adding a comment notifies interested parties of a new blocking issue, and updating the task list ensures that the original post continues to provide an up-to-date view of everything required for the meta-issue.

When all of the sub-issues are closed and the owner of the meta-issue decides the overall task is complete, they should close the meta-issue.

See [this issue](https://github.com/dart-lang/sdk/issues/23454) for a good example of a meta-issue.
