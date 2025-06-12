# Event Announcement System

A fully serverless, event-driven web application that enables users to submit event announcements via a simple web form. The submitted events are stored in an S3 bucket and broadcast to all subscribed users using Amazon SNS. All backend logic is handled by AWS Lambda functions triggered via API Gateway.

---

## Features

- **Event Submission Form**: Users can submit events with title, description, and date.
- **Email Subscription**: Users can subscribe to receive future event notifications.
- **Real-time Notifications**: Subscribed users receive an email when a new event is added.
- **S3 Static Website Hosting**: Frontend is hosted directly on AWS S3.
- **Serverless Architecture**: No dedicated servers; powered by Lambda, API Gateway, SNS, and S3.
- **IAM Roles & Permissions**: Securely manages access to AWS services.

---

## 🛠 Tech Stack

 **Frontend:** HTML, CSS, JavaScriptAdd commentMore actions
- **Backend:** AWS Lambda (Python)
- **API Gateway:** REST API (Lambda Proxy Integration)
- **Storage:** Amazon S3 (event data in JSON)
- **Notifications:** Amazon SNS (email/SMS subscribers)
- **Infrastructure as Code:** Terraform
- **CI/CD:** GitHub Actions

---

## Architecture Overview

```plaintext
[User]
 │
 ▼
[Static Website] (S3 Bucket Hosting)
 │
 ▼
[API Gateway]
 ├─ /subscribe ─> [AWS Lambda Function] (Subscription Function) ─> SNS (Add Email Subscriber)
 └─ /create-event ─> [AWS Lambda Function]  (Event Registration Function)
                            ├─> Update events.json in S3
                            └─> Trigger SNS (Notify Subscribers)
