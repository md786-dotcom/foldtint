# Security Policy

This document tells you how to report a security problem in foldtint.

## Supported versions

We fix security problems in the latest release on npm and in the `main` branch.

| Version | Supported |
| ------- | --------- |
| 1.0.x   | Yes       |
| Older   | No        |

## What is a security problem

Report these problems:

- A way to run code outside foldtint without user action
- A way to change folders outside `~/Desktop`
- A way to read or write files outside the Desktop scope
- A way to bypass the folder lock check
- A way to make the watcher use high memory for a long time through normal Desktop use
- A problem in the npm install script that runs unexpected code

Do not report these items as security problems:

- A bug that only changes tag color on a folder you already locked
- A limit listed in the README (for example, top-level Desktop folders only)
- A request for a new feature

## How to report

Do not open a public issue for a security problem. Public issues can expose the problem before a fix is ready.

Use GitHub private vulnerability reporting:

https://github.com/md786-dotcom/foldtint/security/advisories/new

If you cannot use that page, send a private message to the repository owner through GitHub.

## What to include

Include these items in your report:

- A short description of the problem
- Steps to reproduce the problem
- Your macOS version
- Your foldtint version (`foldtint --help` shows the version)
- The effect of the problem (for example, path escape or unexpected file write)

Do not include large attachments in the first message. We may ask for more data later.

## Response

We try to respond within 7 days.

We try to send a fix or a mitigation plan within 90 days.

We will tell you when we publish a fix. We may credit you in the release notes if you want credit.

## Disclosure

Do not disclose the problem in public until we publish a fix, unless we agree to an earlier date.

We follow coordinated disclosure. We work with you to understand the problem and to test the fix.

## Security updates

Install updates through npm:

```
npm update -g foldtint
```

After an update, run `foldtint scan` if the watcher is off. You do not need `scan` when the watcher is on.
