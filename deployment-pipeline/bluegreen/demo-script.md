# KijaniKiosk Deployment Pipeline - Demo Script for Nia

**[Stage Direction: Nia is at the boardroom table. The Jenkins dashboard is visible on the screen. Two terminal windows are open side by side.]**

**Nia:** Good morning everyone. Today I want to show you how our deployment pipeline works. This is the system that will handle every payment request from our customers.

**[Stage Direction: Nia points to the Jenkins dashboard showing the pipeline.]**

**Nia:** What you see here is our automated deployment system. When a developer finishes writing code and pushes it to our repository, this system automatically builds, tests, and deploys it.

**[Stage Direction: Nia runs the pipeline. The screen shows the progress bars.]**

**Nia:** The system first checks the code quality, then it runs a security audit, and finally it tests the application. If any of these steps fail, the deployment stops immediately.

**[Stage Direction: Nia switches traffic from blue to green. The health check shows v1.4.0.]**

**Nia:** Now we are switching from our current version to the new version. Notice there is no downtime. The system handles this seamlessly.

**[Stage Direction: Nia opens two terminals. One terminal runs the monitor that watches the health of the system. The other terminal is where she will introduce the fault.]**

**Nia:** In this first terminal, the monitor is watching the health of the new version. In the second terminal, I will simulate a problem.

**[Stage Direction: Nia introduces a fault by stopping the green service in the second terminal. The monitor in the first terminal detects the failure immediately.]**

**Nia:** Something has gone wrong. The new version is not responding. Watch what happens in the first terminal.

**[Stage Direction: The monitor detects the fault and automatically triggers the rollback. The screen shows the system reverting to the previous version.]**

**Nia:** The monitor has detected the problem and is rolling back to the previous version. This happens without any human intervention. No one clicked a button. The system made the decision on its own.

**[Stage Direction: The rollback completes. The health check shows v1.3.0 is now active again.]**

**Nia:** The rollback completed in 42 seconds. That is faster than any person could have responded. The system is now back to serving the stable version.

**Nia:** This means we can deploy new features with confidence. If something goes wrong, the system fixes itself. Our customers never experience downtime.
