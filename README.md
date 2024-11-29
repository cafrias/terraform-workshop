# Terraform Workshop

In this codebase, I solve the assignment for a Terraform Workshop.

Rubrics:

> Provision an AWS Lambda function that gets triggered from an API Gateway

## TODO

Required:
- [ ] Provision the API Gateway
- [ ] Create lambda code
- [ ] Provision lambda 

### Nice-to-have

I'd like to expand the experiment to a Lambda function that registers an email in a DynamoDB database from the request
then sends an email with the offers stored also in DynamoDB.

It will use:
- Lambda Layers, to store the dependencies required by the lambda function
- DynamoDB to store emails and offers in two different tables
- SES to send the emails when a new registration happens

Special Scenarios:
- If the email already exists, don't store again, just send email.
