folder('microservice-pipelines') {
    displayName('microservice-pipelines')
    description('folder containing all the pipelines for each microservice.')
    primaryView('All')
    authorization {
        permissions('andy', [
            'hudson.model.Item.Create',
            'hudson.model.Item.Discover'
        ])
        permission('hudson.model.Item.Discover', 'guest')
    }
}

folder('operation-pipelines') {
    displayName('operation-pipelines')
    description('folder containing all the pipelines for operations.')
    primaryView('All')
    authorization {
        permissions('andy', [
            'hudson.model.Item.Create',
            'hudson.model.Item.Discover'
        ])
        permission('hudson.model.Item.Discover', 'guest')
    }
}