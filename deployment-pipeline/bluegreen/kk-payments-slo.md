# KijaniKiosk Payments Service - SLI and SLO Document

## Overview

The Kijani API system was built with one main goal: keeping the service running smoothly for our customers. The team designed it to automatically switch between versions of the application without any downtime. If something goes wrong with a new version, the system detects the problem and switches back to the previous working version within 90 seconds. This happens automatically, so customers never notice any interruption.

The system has two key components that work together. First, the Service Level Indicators measure how well the system is performing. Second, the Service Level Objectives set the targets we aim to meet. This document explains both of these components in plain language.

## Service Level Indicators

### Indicator 1: System Availability

The team measures how often the system is available to handle requests. We do this by checking the health endpoint every few seconds. Over a 30-day period, we count how many checks were successful versus how many failed. This gives us a percentage that tells us how reliable the system is. The more successful checks, the better the availability.

### Indicator 2: Response Time

The team also measures how quickly the system responds to requests. When a customer makes a request, we track the time it takes for the system to answer. We look at the response times over a 30-day period and focus on the 95th percentile. This means we ignore the fastest and slowest responses and look at what most customers experience. The system is designed to respond quickly under normal conditions.

### Indicator 3: Payment Error Rate

The third measurement focuses on payment failures. We track every payment request that results in an error. Over a 30-day period, we calculate the percentage of payments that fail. A low error rate means customers can complete their transactions without issues. This is the most important metric for a payments service because it directly affects revenue and customer trust.

## Service Level Objectives

| SLI | SLO Target | Measurement Window |
|-----|------------|---------------------|
| Availability | 99.9% | 30 days |
| Latency (95th percentile) | Under 300ms | 30 days |
| Payment Error Rate | Under 1% | 30 days |

The team chose these targets based on industry standards for financial services. The 99.9% availability target means the system can have about 43 minutes of downtime per month. The 300ms response time target ensures customers are not waiting too long. The 1% error rate target means we expect 99 out of 100 payments to succeed.

## Rollback Thresholds

| SLI | SLO Target | Short-Window Threshold | Action |
|-----|------------|------------------------|--------|
| Availability | 99.9% | Below 99% in 5 minutes | Trigger automated rollback |
| Latency | Under 300ms | Exceeds 500ms for 2 consecutive checks | Trigger automated rollback |
| Payment Error Rate | Under 1% | Exceeds 2% in 2 minutes | Trigger automated rollback |

The team set these thresholds to be more aggressive than the long-term targets. This means we catch problems early, before they become serious issues. For example, if availability drops below 99% for five minutes, the system rolls back immediately. The short window ensures we do not wait too long before taking action.

## What We Do Not Track

The team made a conscious decision not to track disk usage as a Service Level Objective. The system is designed to prioritize performance over storage. We accept that the application may use more disk space if it means better performance for our customers. Disk space is cheap compared to the cost of slow service or failed payments.

The team also does not track network infrastructure as a Service Level Objective. We assume the network and servers are performing optimally. This allows the team to focus on application-level performance rather than underlying infrastructure concerns. If network issues occur, they are handled separately by the infrastructure team.
