job("single-seed-job") {
    description("Freestyle Job that builds a single other job")
    parameters {
        stringParam("repository", "", "Repository containing the Job DSL script")
        stringParam("branch", "", "Repo branch containing the Job DSL script")
        stringParam("job_dsl_path", "", "Location of Job DSL script")
    }
    scm {
        git {
            branch("\$branch")
            remote {
                credentials("git-creds")
                url("\${primary-repo}")
            }
        }
    }
    steps {
        dsl {
            external("\${job_dsl_path}")
        }
    }
}