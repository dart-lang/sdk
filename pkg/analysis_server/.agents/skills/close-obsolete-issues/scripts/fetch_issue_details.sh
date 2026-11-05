#!/bin/bash

# A script to fetch and format comprehensive issue details for investigation.
# Usage: ./fetch_issue_details.sh <issue_number>

ISSUE_NUMBER=$1

if [ -z "$ISSUE_NUMBER" ]; then
  echo "Usage: $0 <issue_number>"
  exit 1
fi

echo "--- INVESTIGATION FOR ISSUE #$ISSUE_NUMBER ---"
# Fetching all comments to ensure full context is captured.
gh issue view "$ISSUE_NUMBER" --repo dart-lang/sdk --json number,title,author,createdAt,labels,body,comments -t '
Title: {{.title}}
Author: {{if .author}}{{.author.login}}{{else}}ghost{{end}}
Created: {{.createdAt}}
Labels: {{range .labels}}{{.name}}, {{end}}

Description:
{{.body}}

--- ALL COMMENTS ---
{{range .comments}}
{{if .author}}{{.author.login}}{{else}}ghost{{end}} ({{.createdAt}}):
{{.body}}
------------------------------------------------------------
{{end}}
'