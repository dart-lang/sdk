---
name: closing-obsolete-issues
description: Find obsolete, stale, or not reproducible analysis-server issues in the dart-lang/sdk repository.
---

# Closing Obsolete Issues

Use this skill to find old, outdated issues in the `dart-lang/sdk` repository that have been fixed, are stale, obsolete, or not reproducible.

## Instructions

1. **Identify Target Issues**:
   - Use the GitHub CLI (`gh`) to search for the oldest open issues.
   - Use the label `area-devexp` to identify analysis server issues.
   - Also use label `type-bug` and any other label that the user gives you.
   - **Exclude Labeled Issues**: Exclude issues already labeled `verified-by-an-agent` or `closed-by-agent` by adding `-label:verified-by-an-agent -label:closed-by-agent` to the search query.
   - Sort by creation date (`created-asc`) or last update (`updated-asc`) to find the most likely candidates for being outdated.
   - Fetch at least 50 candidates.
   - Example command (with label): `gh issue list --repo dart-lang/sdk --search "label:area-devexp is:open label:type-bug -label:verified-by-an-agent sort:created-asc" --limit 50 | cat`
   - Example command (without label): `gh issue list --repo dart-lang/sdk --search "label:area-devexp is:open -label:verified-by-an-agent sort:created-asc" --limit 50 | cat`
   - **Efficiency Filter**: Before investigating, read `references/investigated_issues.txt` (create it if it does not exist). Filter out and skip any candidate issue numbers that are already listed in this file.

2. **Investigate Status**:
   - **Pre-Qualification Guardrails**: Before evaluating any candidate against obsolete rationales, check the issue metadata. **Abort evaluation and keep the issue open** if any of the following are true:
     1. *Recent Activity*: The issue has any comment or status change from a user within the last 365 days.
     2. *Priority/Milestone*: The issue carries a high-priority label (e.g., `P0`, `P1`, `critical`) or is assigned to an active milestone.
     3. *Corporate Interest*: The issue has active engagement or reproduction steps provided by a Dart/Flutter team member within the last 2 years.
   - For candidates that pass pre-qualification, analyze their description and comments.
   - Use the bundled script `scripts/fetch_issue_details.sh <number>` to get a comprehensive view of the issue and its comments.
   - Compare the issue's request or reported bug and subsequent comments with the current state of the codebase.
   - Refer to the data-driven checks in `references/rationale_templates.md` to verify if a rationale applies.
   - **Safety Rule**: Do not assume a bug is fixed or obsolete just because the code has changed or the issue has not been updated for a long time. Verify if the specific bug behavior is still possible. Valid bugs or feature requests should not be closed as stale just because they are old or have no activity. Inactivity alone does not invalidate a feature request or bug report.

3. **Draft and Review Comments (CRITICAL MANDATE)**:
   - **For Candidates for Closure**: For issues identified as candidates for closure, draft a detailed comment for each explaining *why* it can be closed. Consult `references/rationale_templates.md` for wording inspiration. Each comment MUST end with: "If there is more work to do here, please let us know by filing a new issue with up to date information. Thanks!"
   - **For Still-Valid Issues**: If you determine that a bug is still valid (reproducible on `HEAD`):
     - Draft a comment confirming that the bug remains reproducible at `HEAD` on the latest SDK.
     - Construct a minimal, self-contained Dart reproduction code example or a formal Dart unit test case (following existing testing patterns in the `test/` directory) demonstrating the issue.
     - Include this reproduction or unit test in your drafted comment to assist developers in fixing the bug.
     - **Footer Restriction**: Do NOT end comments on still-valid issues with the closure footer (about filing a new issue), as this issue is remaining open.
   - **Required Output Format**: For each evaluated issue, generate your assessment in this structured JSON format so that a coordinator agent or human supervisor can easily parse, validate, and approve your findings:
     ```json
     {
       "issue_number": 12345,
       "issue_url": "https://github.com/dart-lang/sdk/issues/12345",
       "eligible_for_close": true,
       "matched_rationale_id": 1,
       "confidence_score": 0.95,
       "verification_finding": "Verified that standard LSP protocol capabilities natively handle the requested server configuration.",
       "proposed_comment": "[Full proposed comment including the mandatory footer]"
     }
     ```
   - **User Approval Required**: You MUST present both (a) the candidates for closure with their drafted comments, and (b) the still-valid issues with their drafted confirmation comments and reproductions, to the user and obtain explicit approval BEFORE running any command that comments on or closes an issue. You can present the JSON findings format directly to the user for review.

4. **Iterate on Skill Knowledge (Learning Loop)**:
   - If you discover a new, distinct category of closing rationale that is not covered in `references/rationale_templates.md`, **update the reference file** to include it.

5. **Execute and Summarize**:
   - **For Approved Closure Candidates**: Use `gh issue close` with the `-c` flag to post the comment and close the issue. Apply the `closed-by-agent` label to the issue.
   - **For Approved Still-Valid Issues**: Use `gh issue comment <number> -b "<comment>"` to post the confirmation comment containing the minimal reproduction / test case. Apply the `verified-by-an-agent` label to the issue using `gh issue edit <number> --add-label "verified-by-an-agent"`.
   - **Update Tracking File**: Append any investigated issue numbers that were determined to be STILL VALID (and thus left open) to `references/investigated_issues.txt`, one issue number per line. Do NOT track closed issues, as they are already filtered out by `is:open`.
   - Provide the user with a clean bulleted list of closed issues and updated/commented valid issues.

## Tips

- Use available file and content search tools (such as `grep`, `ripgrep`, or environment-specific
search tools) to check the current codebase for references to the issue or relevant code.
- Look for related Gerrit CLs that might have fixed the issue but didn't close it automatically.
- **Pro Tip**: Use the `read_gerrit_cl` skill ([SKILL.md](../../../../../.agents/skills/read_gerrit_cl/SKILL.md)) to inspect the patchset diffs and comments of open or merged Gerrit CLs.
- **Always prioritize active verification on HEAD**: Regardless of how old an issue is or what version it specifies, always attempt to research and reproduce the reported issue against the current `HEAD` of the codebase before proposing closure. Never assume a bug is obsolete or fixed based solely on the passage of time or version discrepancies. If you cannot reproduce it, provide clear details of your reproduction attempt on the current codebase.


