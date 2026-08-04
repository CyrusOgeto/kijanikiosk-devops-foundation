# Post-Incident Review: Staging Unavailability During Board Walkthrough

## Section 1: Incident Summary

During an investor demonstration on a recent walkthrough, the KijaniKiosk staging environment became unavailable for 48 seconds. The team was showing the pipeline to the board when the environment stopped responding. The incident was resolved by manually reverting the environment switch, and the demonstration continued after a brief interruption. The board understood the issue and appreciated that the team had a rollback mechanism in place.

## Section 2: Timeline

The walkthrough began with the team showing the pipeline running against staging. A team member triggered the pipeline to demonstrate a deployment. The pipeline targeted the wrong environment due to a configuration gap, causing the staging environment to be modified unexpectedly. The staging environment became unresponsive and the board noticed the error. The team identified the issue and manually triggered the rollback script. The rollback completed and staging became available again. The total duration of the incident was 48 seconds.

## Section 3: Root Cause

The pipeline was triggered against staging but the environment variable that controls the deployment target was set to production. This happened because the pipeline used a single environment variable that was shared between environments.

Reasons for environment failure

The wrong environment was targeted because both environments use the same variables
The pipeline configuration does not differentiate between staging and production

Environment variables were hardcoded

The pipeline did not use separate configuration files for separate environments


## Section 4: Contributing Factors

The following conditions made the root cause possible:

1. The pipeline configuration did not validate the target environment before running.
2. The environment variables were defined globally rather than per environment.
3. There was no confirmation step before deploying to production.
4. The team was demonstrating the pipeline live, which increased pressure to move quickly.

## Section 5: What Went Well

The rollback script was tested and worked correctly. When the error was identified, the team was able to revert the environment in under 60 seconds. This proved that the rollback mechanism is reliable when triggered correctly. The board also appreciated seeing how quickly the team responded to the issue.

## Section 6: Action Items

| Action Item | Owner | Target Timeframe |
|-------------|-------|------------------|
| Split environment variables into separate configuration files for staging and production | Engineering Lead | 1 week |
| Add a confirmation step before any deployment to production | DevOps Engineer | 3 days |
| Implement automatic environment validation in the pipeline | DevOps Engineer | 1 week |
| Add a pre-flight check that verifies the target environment before running any deployment | Engineering Lead | 1 week |
| Document the environment configuration process for the team | DevOps Engineer | 2 weeks |
