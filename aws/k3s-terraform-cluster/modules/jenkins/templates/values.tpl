nameOverride:
fullnameOverride:
namespaceOverride:

clusterZone: "cluster.local"

kubernetesURL: "https://kubernetes.default"

credentialsId:

renderHelmLabels: true

controller:
  componentName: "jenkins-controller"
  image:
    registry: "docker.io"
    repository: "jenkins/jenkins"

    tag:

    tagLabel: jdk17
    pullPolicy: "Always"
  imagePullSecretName:

  disableRememberMe: false

  numExecutors: 0

  executorMode: "NORMAL"


  hostNetworking: false

  admin:

    username: "testadmin"
    password:

    userKey: jenkins-admin-user
    passwordKey: jenkins-admin-password

    createSecret: true

    existingSecret: ""
  jenkinsAdminEmail:

  jenkinsHome: "/var/jenkins_home"

  jenkinsRef: "/usr/share/jenkins/ref"

  jenkinsWar: "/usr/share/jenkins/jenkins.war"

  resources:
    requests:
      cpu: "1000m"
      memory: "2048Mi"
    limits:
      cpu: "2000m"
      memory: "4096Mi"

  shareProcessNamespace: false

  javaOpts:
  jenkinsOpts:

  jenkinsUrlProtocol:

  jenkinsUrl: ${jenkins_url}

  jenkinsUriPrefix: "/jenkins"

  usePodSecurityContext: true

  runAsUser: 0

  fsGroup: 0

  securityContextCapabilities: {}

  podSecurityContextOverride: ~

  containerSecurityContext:
    runAsUser: 0
    runAsGroup: 0
    readOnlyRootFilesystem: true
    allowPrivilegeEscalation: false

  serviceType: ClusterIP

  clusterIp:
  servicePort: 80
  targetPort: 8080
  nodePort:

  healthProbes: true

  probes:
    startupProbe:
      failureThreshold: 12
      httpGet:
        path: '{{ default "" .Values.controller.jenkinsUriPrefix }}/login'
        port: http
      periodSeconds: 10
      timeoutSeconds: 5

    livenessProbe:
      failureThreshold: 5
      httpGet:
        path: '{{ default "" .Values.controller.jenkinsUriPrefix }}/login'
        port: http
      periodSeconds: 10
      timeoutSeconds: 5

      initialDelaySeconds:

    readinessProbe:
      failureThreshold: 3
      httpGet:
        path: '{{ default "" .Values.controller.jenkinsUriPrefix }}/login'
        port: http
      periodSeconds: 10
      timeoutSeconds: 5

      initialDelaySeconds:

  podDisruptionBudget:

    enabled: false

    apiVersion: "policy/v1beta1"

    annotations: {}
    labels: {}
    maxUnavailable: "0"

  agentListenerEnabled: true
  agentListenerPort: 50000
  agentListenerHostPort:
  agentListenerNodePort:

  agentListenerExternalTrafficPolicy:
  agentListenerLoadBalancerSourceRanges:
  - 0.0.0.0/0
  disabledAgentProtocols:
    - JNLP-connect
    - JNLP2-connect
  csrf:
    defaultCrumbIssuer:
      enabled: true
      proxyCompatability: true

  agentListenerServiceType: "ClusterIP"

  agentListenerServiceAnnotations: {}

  agentListenerLoadBalancerIP:

  legacyRemotingSecurityEnabled: false


  loadBalancerSourceRanges:
  - 0.0.0.0/0

  loadBalancerIP:

  jmxPort:

  extraPorts: []

  installPlugins:
    - kubernetes:4203.v1dd44f5b_1cf9
    - workflow-aggregator:596.v8c21c963d92d
    - git:5.2.1
    - configuration-as-code:1775.v810dc950b_514

  installLatestPlugins: true

  installLatestSpecifiedPlugins: false

  additionalPlugins: []

  initializeOnce: false

  overwritePlugins: false

  overwritePluginsFromImage: true

  projectNamingStrategy: standard

  enableRawHtmlMarkupFormatter: false

  markupFormatter: plainText

  scriptApproval: []

  initScripts: {}
  initConfigMap:

  existingSecret:

  additionalExistingSecrets: []

  additionalSecrets: []

  secretClaims: []

  cloudName: "kubernetes"

  JCasC:
    defaultConfig: true

    overwriteConfiguration: false
    configUrls: []
    configScripts: {}

    security:
      apiToken:
        creationOfLegacyTokenEnabled: false
        tokenGenerationOnCreationEnabled: false
        usageStatisticsEnabled: true

    securityRealm: |-
      local:
        allowsSignup: false
        enableCaptcha: false
        users:
        - id: admin
          name: admin
          password: "${jenkins_admin_password}"

    authorizationStrategy: |-
      loggedInUsersCanDoAnything:
        allowAnonymousRead: false
  customInitContainers: []

  sidecars:
    configAutoReload:
      enabled: true
      image:
        registry: docker.io
        repository: kiwigrid/k8s-sidecar
        tag: 1.26.1
      imagePullPolicy: IfNotPresent
      resources: {}

      scheme: http
      skipTlsVerify: false

      reqRetryConnect: 10
      sleepTime:

      envFrom: []
      env: {}

      sshTcpPort: 1044
      folder: "/var/jenkins_home/casc_configs"

      containerSecurityContext:
        readOnlyRootFilesystem: true
        allowPrivilegeEscalation: false

    additionalSidecarContainers: []

  schedulerName: ""

  nodeSelector: {}

  tolerations: []
  terminationGracePeriodSeconds:
  terminationMessagePath:
  terminationMessagePolicy:

  affinity: {}

  priorityClassName:

  podAnnotations: {}
  statefulSetAnnotations: {}

  updateStrategy: {}

  ingress:
    enabled: false

    paths: []

    apiVersion: "extensions/v1beta1"
    labels: {}
    annotations: {}

    path:

    hostName:
    resourceRootUrl:
    tls: []

  secondaryingress:
    enabled: false
    paths: []
    apiVersion: "extensions/v1beta1"
    labels: {}
    annotations: {}
    hostName:
    tls:

  backendconfig:
    enabled: false
    apiVersion: "extensions/v1beta1"
    name:
    labels: {}
    annotations: {}
    spec: {}

  route:
    enabled: false
    labels: {}
    annotations: {}
    path:

  hostAliases: []

  prometheus:

    enabled: false
    serviceMonitorAdditionalLabels: {}
    serviceMonitorNamespace:
    scrapeInterval: 60s

    scrapeEndpoint: /prometheus

    alertingrules: []
    alertingRulesAdditionalLabels: {}
    prometheusRuleNamespace: ""

    relabelings: []
    metricRelabelings: []

  googlePodMonitor:
    enabled: false
    scrapeInterval: 60s
    scrapeEndpoint: /prometheus

  testEnabled: true

  httpsKeyStore:
    enable: false
    jenkinsHttpsJksSecretName: ""
    jenkinsHttpsJksSecretKey: "jenkins-jks-file"
    jenkinsHttpsJksPasswordSecretName: ""
    jenkinsHttpsJksPasswordSecretKey: "https-jks-password"
    disableSecretMount: false

    httpPort: 8081
    path: "/var/jenkins_keystore"
    fileName: "keystore.jks"
    password: "password"

    jenkinsKeyStoreBase64Encoded:

agent:
  enabled: true
  defaultsProviderTemplate: ""

  jenkinsUrl:

  jenkinsTunnel:
  kubernetesConnectTimeout: 5
  kubernetesReadTimeout: 15
  maxRequestsPerHostStr: "32"
  retentionTimeout: 5
  waitForPodSec: 600
  namespace:
  podLabels: {}
  jnlpregistry:
  image:
    repository: "jenkins/inbound-agent"
    tag: "3206.vb_15dcf73f6a_9-3"
  workingDir: "/home/jenkins/agent"
  nodeUsageMode: "NORMAL"
  customJenkinsLabels: []
  imagePullSecretName:
  componentName: "jenkins-agent"
  websocket: false
  directConnection: false
  privileged: false
  runAsUser:
  runAsGroup:
  hostNetworking: false
  resources:
    requests:
      cpu: "512m"
      memory: "512Mi"
    limits:
      cpu: "512m"
      memory: "512Mi"
  livenessProbe: {}

  alwaysPullImage: false
  restrictedPssSecurityContext: false
  podRetention: "Never"
  showRawYaml: true

  TTYEnabled: false
  containerCap: 10
  podName: "default"

  idleMinutes: 0


  yamlTemplate: ""

  yamlMergeStrategy: "override"
  connectTimeout: 100
  annotations: {}

  additionalContainers: []

  disableDefaultAgent: false

  podTemplates: {}

additionalAgents: {}

additionalClouds: {}

persistence:
  enabled: true

  existingClaim:

  storageClass:
  annotations: {}
  labels: {}
  accessMode: "ReadWriteOnce"
  size: "8Gi"

  dataSource: {}

  subPath:
  volumes: []

  mounts: []

networkPolicy:
  enabled: false

  apiVersion: networking.k8s.io/v1
  internalAgents:
    allowed: true
    podLabels: {}
    namespaceLabels: {}
  externalAgents:
    ipCIDR:
    except: []

rbac:
  create: true
  readSecrets: false

serviceAccount:
  create: true

  name:
  annotations: {}
  extraLabels: {}
  imagePullSecretName:


serviceAccountAgent:
  create: false

  name:
  annotations: {}
  extraLabels: {}
  imagePullSecretName:

checkDeprecation: true

awsSecurityGroupPolicies:
  enabled: false
  policies:
    - name: ""
      securityGroupIds: []
      podSelector: {}

helmtest:
  bats:
    image:
      registry: "docker.io"
      repository: "bats/bats"
      tag: "1.11.0"
