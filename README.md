# Zeus
AWS Auditing &amp; Hardening Tool v1.0

Zeus is a powerful script for AWS EC2 / S3 best hardening practices. It checks security settings according to the profiles the user creates and changes them to recommended settings based on the CIS AWS Benchmark source at request of the user.

Currently, it only includes the Logging mechanism (v1.0).

- Ensure CloudTrail is enabled in all regions 
- Ensure CloudTrail log file validation is enabled 
- Ensure the S3 bucket CloudTrail logs to is not publicly accessible
- Ensure CloudTrail trails are integrated with CloudWatch Logs 
- Ensure AWS Config is enabled in all regions
- Ensure S3 bucket access logging is enabled on the CloudTrail S3 bucket
- Ensure CloudTrail logs are encrypted at rest using KMS CMKs
- Ensure rotation for customer created CMKs is enabled

# Requirements

Script has been written in bash using AWS-CLI and it works in Linux/UNIX and OSX.

Make sure that the AWS-CLI tool is installed on the system and profile is configured (aws configure).


![alt text](https://i.hizliresim.com/kWEVmr.jpg)

![alt text](https://i.hizliresim.com/r2EPn1.jpg)
