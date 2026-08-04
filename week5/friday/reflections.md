# KijaniKiosk CI/CD Pipeline - Reflections

## Challenges and Considerations

The CI/CD pipeline and version control systems might experience instability when there are too many developers working simultaneously. This is because multiple developers incorporating changes from various version control systems can create conflicts and bottlenecks in the pipeline. The risk of merge conflicts, build failures, and deployment errors increases as the team size grows.

## Recommended Governance

It is recommended to have at least one or two dedicated individuals whose sole purpose is monitoring the CI/CD pipelines across all projects and services. These individuals would be responsible for:

- Ensuring workflows are maintained and not disrupted
- Troubleshooting pipeline failures quickly
- Managing access controls and permissions
- Monitoring build and deployment health
- Coordinating between development teams

Without dedicated oversight, minor issues can escalate into major disruptions that affect the entire development team.

## Security Considerations

Teams should avoid running online Jenkins scripts or copying pipeline code from untrusted sources without proper technical knowledge. This practice can expose the organization to various security vulnerabilities, including:

- Malicious code injection in the pipeline
- Supply chain attacks through untrusted plugins
- Credential theft from exposed variables
- Data breaches through insecure pipeline configurations

All Jenkins scripts and pipeline code should be reviewed, tested, and validated before being integrated into the CI/CD workflow. Pipeline code should be treated with the same security scrutiny as application code.

## Summary

A successful CI/CD implementation requires not just technical setup but also proper governance and security awareness. The pipeline is only as reliable as the team maintaining it and the security practices they follow.
