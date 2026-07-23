# KijaniKiosk CI Pipeline

## Overview

I created a Jenkins script that runs on the API server at **http://10.185.172.42:8080**.

The script creates a Docker container that automatically installs all the necessary Node.js and npm packages required for the API to run.

## How the Pipeline Works

The pipeline has several stages that check different aspects of the code:

### 1. Linting Stage
Linting checks the code quality and style. For example, if you write `const x = 5` without a semicolon, it's technically fine in JavaScript, but the linter might suggest using template literals like `hello ${name}` instead of `'hello' + name`. This helps keep the code consistent and easier to read.

### 2. Build Stage
This stage installs all the dependencies and makes sure the code can actually compile and run. If there's a missing file or an import that doesn't exist, like `import { User } from './models/User'` when the file isn't there, the build will fail.

### 3. Test Stage
The tests check if the code actually works as expected. For example, if you have a function called `divide(a, b)` that returns `a / b`, but you don't test what happens when `b` is 0, the tests will catch that edge case.

### 4. Security Audit
This runs a security check on all the dependencies. If you accidentally hardcode a password like `const password = 'admin123'`, the security audit will flag it and alert you.

### 5. Archive Stage
If all the checks pass, the code is packaged into a zip file and stored as an artifact.

### 6. Publish Stage
The final step is to publish the packaged code to a repository where it can be downloaded and deployed.

## Intentional Failure

The pipeline currently includes a test that intentionally fails. This is to demonstrate that the pipeline correctly catches bad code and prevents it from being published. The test checks if `1 + 1` equals `3`, which it doesn't, so the test fails.

## Intentional Failures Tested

To ensure the pipeline behaves correctly under failure conditions, intentional failures were tested at every stage to monitor and simulate the behavior of the server. Each stage was deliberately broken to observe how the pipeline would respond.

### Failure Testing Summary

| Stage | What was tested | Expected Behavior | Result |
|-------|-----------------|-------------------|--------|
| **Lint Stage** | Added invalid syntax | Pipeline stops at Lint stage | Correct behavior observed |
| **Build Stage** | Removed npm install | Build stage fails, remaining stages skip | Correct behavior observed |
| **Test Stage** | Changed addition test to expect 1+1=3 | Test stage fails, Archive and Publish skip | Correct behavior observed |
| **Archive Stage** | Deleted dist directory | Archive fails, Publish skips | Correct behavior observed |
| **Publish Stage** | Used invalid Nexus credentials | Publish fails, Archive still succeeds | Correct behavior observed |

### Why This Matters

Testing failures at every stage proves that:
- The pipeline is resilient and handles errors gracefully
- Each stage properly validates its own requirements
- The correct stages are skipped when dependencies are missing
- The team can trust the pipeline to catch problems at every step
- Production is protected from bad code, even if multiple things go wrong

This comprehensive testing ensures that when something does break, the pipeline will handle it predictably and the team will be notified immediately.

## Why This Matters

This pipeline ensures that every change made to the codebase is automatically checked for:
- Code quality issues
- Missing dependencies
- Logic errors
- Security vulnerabilities

This means that only tested, verified code gets to the deployment stage, which reduces errors and makes the software more reliable.

## Notifications

The Jenkins pipeline can also send notifications to the team if something goes wrong. When code is pushed to production and the pipeline fails, Jenkins can automatically alert:

- **Amina** - The team lead
- **Osei** - The senior developer
- **Cyrus Ogeto Nyamwange** - The DevOps consultant

Jenkins can send these notifications through:
- **Email** - An automated email with the build status and error details
- **Phone/SMS** - A text message alert for critical failures

This ensures that the right people are informed immediately when something breaks, so they can fix it quickly before it affects users.

## Architecture

Jenkins runs on the API server and communicates with GitHub to fetch the latest code. The pipeline runs inside a Docker container, which provides a consistent environment for building and testing the application. Each stage of the pipeline is isolated and runs in its own container, ensuring that dependencies don't conflict with each other.

## What Happens When Something Goes Wrong

When the pipeline fails, here is what happens:

- The pipeline stops immediately and shows a red X in Jenkins
- The stage that failed is highlighted so you know exactly where the problem is
- An email notification is sent to the team with the build details
- The failed code is NOT published or deployed to production
- The developer who pushed the code is notified to fix the issue
- All tests and security checks are rerun on the next code push
- The pipeline only turns green again when all issues are resolved
- A log of all failures is kept for debugging and review purposes

This ensures that broken code never makes it to production and the team is always aware of any issues immediately.

## Future Improvements

The pipeline could be enhanced with additional features such as:
- Automated deployment to staging and production environments
- Integration with Slack or Teams for instant messaging alerts
- Performance testing to ensure the API meets response time requirements
- Code coverage reports to track how much of the codebase is tested
- Parallel testing across different Node.js versions

## Conclusion

This CI pipeline represents a significant step forward in the KijaniKiosk project's development workflow. By automating the build, test, and security processes, the team can deliver higher quality software with greater confidence and speed.
