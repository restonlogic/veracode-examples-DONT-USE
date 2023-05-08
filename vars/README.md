### Overview

Files exposed as variables in Jenkins Groovy pipelines. To have access to these files/functions, the following line
must exist at the top of the pipeline code.

```groovy
@Library(['global-jenkins-library@main']) _
```

### Files

| Filename                 | Description                                                             |
| ------------------------ | ----------------------------------------------------------------------- |
| `notifications.groovy`   | Functions containing reusable pipeline steps for sending emails.        |
| `genericsteps.groovy`    | Functions containing reusable pipeline steps for declarative pipelines. |
| `git.groovy`             | Functions containing reusable pipeline steps for git/github operations. |
| `pipelinejob.groovy`     | Functions containing commonly used Jenkins pipeline steps.              |
| `scans.groovy`           | Functions containing commonly used Jenkins pipeline steps.              |
| `secrets.groovy`         | Functions containing commonly used Jenkins pipeline steps.              |

### Resources

1. [Jenkins Sharing Pipeline Code](https://jenkins.io/blog/2017/10/02/pipeline-templates-with-shared-libraries/)
2. [Docker Network=Host](https://github.com/moby/moby/issues/25537#issuecomment-607376533)
