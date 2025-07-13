
![Image](https://github.com/user-attachments/assets/ee2a1164-c712-4246-98ed-6da9d4081dee)

# Introduction
When using Helm, we typically create a single YAML template for Kubernetes resources, regardless of how many microservices are deployed in the cluster. This template serves as a reusable blueprint, and dynamic values are injected at runtime based on the contents of each service's values.yaml file (found within its Helm chart).
For example, under the metadata section, we can use Helm template syntax (e.g., {{ .Values.<key> }}) to inject dynamic values. Whatever you place inside these double curly braces represents a runtime-injected value, which Helm resolves using the data defined in the values.yaml file when deploying the microservices to the Kubernetes cluster.
We are going to write a Helm chart for a Spring Boot microservices-based Banking Application. This setup will include essential components such as:

Discovery Server
- Kafka
- Keycloak
- API Gateway
- Multiple Spring Boot Microservices

Additionally, we will configure observability using:
- Grafana (dashboards)
- Prometheus (metrics)
- Loki (logs)
- Tempo (traces)

Once the Helm chart is complete, we will deploy it to a Kubernetes cluster on AWS EKS, ensuring that all components and observability tools are fully integrated and operational.

# Problems That Helm Solves :
Packaging of YAML Files:
Helm allows you to package all the Kubernetes YAML manifest files for an application into a single unit called a Chart. This chart can then be distributed via public or private repositories, making deployment and sharing much more efficient.

Simplified Installation and Management:With Helm, you can install, upgrade, rollback, or uninstall an entire microservices-based application using a single command. This eliminates the need to manually run kubectl apply for each individual manifest file, greatly simplifying the deployment process.

Release and Version Management:Helm automatically tracks the version history of all installed releases. This means you can easily rollback your entire application stack to a previous known-good state. In contrast, when using raw Kubernetes manifests, rollback typically only applies to individual microservices, not the entire deployment. If you need to revert changes across your entire cluster, Helm provides a more reliable and manageable solution.
please note that Helm is a package manager for Kubernetes, which is very similar to other package managers like Pip and NPM.


Since we want to deploy our microservices, there is a Helm template file named deployment.yaml specifically for handling deployments. This file is located inside the templates directory of the Helm chart. When you open the deployment.yaml file, you'll notice that it follows the standard Kubernetes manifest structure, but with templating syntax provided by Helm.
The values.yaml file contains all the dynamic values required by the various templates within the Helm chart. These values are injected at runtime during deployment.It’s important to note that the values.yaml file provides values not only for the deployment.yaml template, but also for all other templates in the chart (e.g., service.yaml, ingress.yaml, configmap.yaml, etc.).

In our local workspace, we begin by creating a folder named Eazybank. Inside this folder, we create another directory called helm, which will contain the Helm chart required for deploying our microservices.
We initialize a new Helm chart by running the following command:

# helm create eazybank-common
We give this name "common" because we are going to build helm chart that is going to acts a common chart for all my microservices.

- We delete all default template files inside the templates/ directory, such as:
- Inside Template folder  we write our own ( configmap, deployment.yaml and service.yaml)
- Inside values.yaml since we don't want to follow default values, we can remove all the values.
- Inside this Chart.yaml, We maintained API version is v2,description, and type as application, and the version here is 0.1.0.

We use the name  "common.service" ({{- define "common.service" - }}) that you see at the starting and at the end with {{- end -}}
This approach allows us to encapsulate the entire template as a reusable block. Other microservice Helm charts can then include or import this common service using the name common.service. This promotes modularity and avoids duplication across charts.
Now after defining all the container-related properties, we should also try to inject environment variables that are required for 
our particular microservice (deployment.yaml).


env:
        {{- if .Values.appname_enabled }}
        
        - name: SPRING_APPLICATION_NAME
          value: {{ .Values.appName }}
        {{- end }}
        {{- if .Values.profile_enabled }}
        - name: SPRING_PROFILES_ACTIVE
          valueFrom: 
            configMapKeyRef:
              name: {{ .Values.global.configMapName }}
              key: SPRING_PROFILES_ACTIVE
        {{- end }}
        {{- if .Values.config_enabled }}
        - name: SPRING_CONFIG_IMPORT
          valueFrom: 
            configMapKeyRef:
              name: {{ .Values.global.configMapName }}
              key: SPRING_CONFIG_IMPORT
        {{- end }}
        {{- if .Values.discovery_enabled }}
        - name: SPRING.CLOUD.KUBERNETES.DISCOVERY.DISCOVERY-SERVER-URL
          valueFrom: 
            configMapKeyRef:
              name: {{ .Values.global.configMapName }}
              key: SPRING.CLOUD.KUBERNETES.DISCOVERY.DISCOVERY-SERVER-URL
        {{- end }}
        {{- if .Values.resouceserver_enabled }}
        - name: SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_JWK-SET-URI
          valueFrom: 
            configMapKeyRef:
              name: {{ .Values.global.configMapName }}
              key: SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_JWK-SET-URI
        {{- end }}
        {{- if .Values.otel_enabled }}
        - name: JAVA_TOOL_OPTIONS
          valueFrom: 
            configMapKeyRef:
              name: {{ .Values.global.configMapName }}
              key: JAVA_TOOL_OPTIONS
        - name: OTEL_EXPORTER_OTLP_ENDPOINT
          valueFrom: 
            configMapKeyRef:
              name: {{ .Values.global.configMapName }}
              key: OTEL_EXPORTER_OTLP_ENDPOINT
        - name: OTEL_METRICS_EXPORTER
          valueFrom: 
            configMapKeyRef:
              name: {{ .Values.global.configMapName }}
              key: OTEL_METRICS_EXPORTER
        - name: OTEL_LOGS_EXPORTER
          valueFrom:
            configMapKeyRef:
              name: {{ .Values.global.configMapName }}
              key: OTEL_LOGS_EXPORTER
        - name: OTEL_SERVICE_NAME
          value: {{ .Values.appName }}
        {{- end }}
        {{- if .Values.kafka_enabled }}
        - name: SPRING_CLOUD_STREAM_KAFKA_BINDER_BROKERS
          valueFrom: 
            configMapKeyRef:
              name: {{ .Values.global.configMapName }}
              key: SPRING_CLOUD_STREAM_KAFKA_BINDER_BROKERS
        {{- end }}
        
{{- end -}}

# configmap.yaml

{{- define "common.configmap" -}}

apiVersion: v1

kind: ConfigMap

metadata:

  name: {{ .Values.global.configMapName }}
  
data:
  SPRING_PROFILES_ACTIVE: {{ .Values.global.activeProfile }}
  
  SPRING_CONFIG_IMPORT: {{ .Values.global.configServerURL }}
  
  SPRING.CLOUD.KUBERNETES.DISCOVERY.DISCOVERY-SERVER-URL: {{ .Values.global.discoveryServerURL }}
  
  SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_JWK-SET-URI: {{ .Values.global.keyCloakURL }}
  
  JAVA_TOOL_OPTIONS: {{ .Values.global.openTelemetryJavaAgent }}
  
  OTEL_EXPORTER_OTLP_ENDPOINT: {{ .Values.global.otelExporterEndPoint }}
  
  OTEL_METRICS_EXPORTER: {{ .Values.global.otelMetricsExporter }}
  
  OTEL_LOGS_EXPORTER: {{ .Values.global.otelLogsExporter }}
  
  SPRING_CLOUD_STREAM_KAFKA_BINDER_BROKERS: {{ .Values.global.kafkaBrokerURL }}
{{- end -}}

# Note
We are not trying to mention the direct hard-coded values inside the "ConfigMap.yaml" because we may have different requirement. Like for Dev"" environment, I may have different profile, different URLs. And similarly for QA and Prod.
That is why we use variable names instead of hard-coded values inside this template file.We should ensure that the values.yaml file is empty in the eazybank-common Helm chart, as this chart is intended to be reused by other Helm charts. Any Helm chart that leverages this common chart will supply its own values.yaml file with the necessary values specific to that microservice.


# Creating Helm Charts For Accounts Microservice

We going create a helm chart for our Accounts microservice by leveraging the easybank-common helm chart. 
Because inside this easybank-common only, we have defined all the required Kubernetes manifest template files.

==> helm create accounts.

we need to delete all the templates that we received from the default helm chart and very similarly I will also delete the values.yaml content.
Inside the same chart.yaml,I need to define if this helm chart has any dependency on other helm charts.
We know that this helm chart which is accounts microservice related helm chart has a dependency on the easybank-commonhelmchart.

dependencies:
  - name: eazybank-common
    version: 0.1.0
    repository: file://../../eazybank-common

- we need to populate all the required values inside the values.yaml of accounts microservice

 deploymentName: accounts-deployment
 serviceName: accounts
 appLabel: accounts
 appName: accounts

When we run the command:
#  helm dependency build

Helm will compile the accounts Helm chart along with all its declared dependencies, and place those dependencies inside the charts/ directory.
After executing the command, you should see an output indicating that the dependency build was successful.

To validate this, navigate to the charts/ folder. You will find a compressed Helm chart named eazybank-common along with its specified version (easzybank-common-0.1.0.tgz).

As a next step, we need to create the helm chart for the remaining microservices cards, Loans , configserver, message and gatewayserver  as well. For this I'm not going to follow the all the steps that we have followed for account microservices.
So let's try to do the same very quickly behind the scene.

We are not trying to mention the direct hard-coded values inside the "ConfigMap.yaml" because we may have different requirement. Like for Dev"" environment, I may have different profile, different URLs. And similarly for QA and Prod.
- That is why we use variable names instead of hard-coded values inside this template file.
  
- We should ensure that the values.yaml file is empty in the eazybank-common Helm chart, as this chart is intended to be reused by other Helm charts.
Any Helm chart that leverages this common chart will supply its own values.yaml file with the necessary values specific to that microservice.

# Creating Helm Charts For Environments.
Let’s create a Helm chart specific to an environment, allowing us to deploy all our microservices with a single Helm command.
To achieve this, within the same directory where we have eazybank-common and eazybank-services, we will create a new folder named environments. Inside this environments folder, we will initialize a new Helm chart that will act as the entry point for environment-specific deployments (e.g., dev, staging, prod).

This environment-level chart will declare eazybank-common and eazybank-services as dependencies, enabling unified and consistent deployment of the entire microservices stack.

# We need to define the details of all the dependencies Helm charts (inside chart.yaml)

dependencies:

  - name: eazybank-common
    version: 0.1.0
    repository: file://../../eazybank-common

  - name: configserver
    version: 0.1.0
    repository: file://../../eazybank-services/configserver
    
  - name: accounts
    version: 0.1.0
    repository: file://../../eazybank-services/accounts
    
  - name: cards
    version: 0.1.0
    repository: file://../../eazybank-services/cards
    
  - name: loans
    version: 0.1.0
    repository: file://../../eazybank-services/loans

  - name: gatewayserver
    version: 0.1.0
    repository: file://../../eazybank-services/gatewayserver

  - name: message
    version: 0.1.0
    repository: file://../../eazybank-services/message

# As a next step, we should populate the values.yaml file.
Like you can see here, the prefix value that I have mentioned for all these values is global because whatever I'm going to define
inside this values.yaml, this is going to be applicable for all my microservice.

global:

  configMapName: eazybankdev-configmap
  
  activeProfile: default
  
  configServerURL: configserver:http://configserver:8071/
  
  discoveryServerURL: "http://spring-cloud-kubernetes-discoveryserver:80/"
  
  keyCloakURL: http://keycloak.default.svc.cluster.local:80/realms/master/protocol/openid-connect/certs
  
  openTelemetryJavaAgent: "-javaagent:/app/libs/opentelemetry-javaagent-2.11.0.jar"
  
  otelExporterEndPoint: http://tempo-grafana-tempo-distributor:4318
  
  otelMetricsExporter: none
  
  otelLogsExporter: none
  
  kafkaBrokerURL: kafka-controller-0.kafka-controller-headless.default.svc.cluster.local:9092

But this is not a mandatory or a standard from helm. This is a prefix that I want to maintain for my own understanding.
So under the "global" .configmap name, we are trying to give what is a configmap name. So the same is going to refer inside the configmap template that we have created.


We will leverage Bitnami Helm charts for deploying the following components: Keycloak , Kafka, Prometheus, Grafana Tempo
and Grafana Loki.Using Bitnami charts ensures reliable, production-ready configurations with active community support and frequent updates.

# Next Step: Provisioning the EKS Cluster with Terraform
In this step, we will provision our Amazon EKS (Elastic Kubernetes Service) cluster using Terraform. Terraform allows us to define our infrastructure as code, enabling repeatable, version-controlled, and automated cluster creation and management.

# Deployment to kubernetes
 We follow a step-by-step approach to deploy key components of the system, including:
 Discovery Server, Keycloak, Kafka, Prometheus, Grafana Tempo, Grafana Loki, EazyBank Microservices to EKS Cluster.
All components are deployed using Helm charts, and we validate their integration to ensure proper communication, observability, and overall system functionality.

# Deployment of Discovery Server
![Image](https://github.com/user-attachments/assets/d28e910a-2725-4040-af8a-eb1a53150430)

# Deployment of KeyCloak helm chart
![Image](https://github.com/user-attachments/assets/dd29179b-c474-4b68-afb0-237d8fccadcf)

# Deployment of Kafka helm chart
![Image](https://github.com/user-attachments/assets/4660b537-41e2-4662-89dd-dca8393e080d)

# Deployment of Kube-Prometheuse helm chart
![Image](https://github.com/user-attachments/assets/a56df5c9-e8de-411b-a0c9-905e5fbe1a30)

# Deployment of Grafana Loki helm chart
![Image](https://github.com/user-attachments/assets/c083037b-b80f-49eb-bfb7-2908b60680f5)

# Deployment of Grafana Tempo  helm chart
![Image](https://github.com/user-attachments/assets/c56437e2-e4d6-4fca-8366-5073fecbd87d)

# Deployment of Grafana  helm chart
![Image](https://github.com/user-attachments/assets/ff3662df-9234-4071-b9f0-ba86dd7d9266)

# Deployment of EazyBank helm chart
![Image](https://github.com/user-attachments/assets/73cb44e0-9079-4f3e-9b8b-a426b1849910)

# Validate That All Pods Are Running in the Kubernetes Cluster
To ensure all components are successfully deployed, run the following command to check the status of all pods in the cluster:

# ==> kubectl get pods 
![Image](https://github.com/user-attachments/assets/94fd0ef2-54fa-41ad-9139-c16071b32bc2)

# Validate That All Services Are Running in the Kubernetes Cluster
To verify that all services (e.g., microservices, system components like Keycloak, Kafka, Prometheus) are correctly exposed and functioning, use the following command:
# ==> kubectl get svc -A
![Image](https://github.com/user-attachments/assets/00ed50a8-cd04-4345-881f-bff352e2bde4)

# Configure Keycloak for Microservices Authentication
We access the Keycloak Admin Console to set up client-based authentication for our microservices. The configuration steps include:
- Create a new client named eazybankcallcenter-cc.
- Enable Client Authentication.
- Disable the following flows:
- Standard Flow
- Direct Access Grants
- Enable Service Accounts Roles to support machine-to-machine authentication.
# Create the following roles: accounts, cards and loans
Assign the respective roles to each corresponding microservice:
accounts role → Accounts microservice
cards role → Cards microservice
loans role → Loans microservice
This setup ensures secure and role-based access control for inter-service communication in the system.

![Image](https://github.com/user-attachments/assets/cc6c7b62-2b63-46f1-95da-c5879de8ce0b)

# Validate Observability Integration via Grafana
We access the Grafana UI to validate the integration of the observability stack, ensuring the following components are correctly connected and visualized:
Prometheus for metrics
Loki for logs
Tempo for traces

This step confirms that Grafana is successfully pulling data from each source, enabling full visibility into system performance, logging, and distributed tracing.
![Image](https://github.com/user-attachments/assets/29f5a727-311c-45e7-a4cc-d95c67fea9ae)

# Validate That Loki Is Pulling Logs and Grafana Is Visualizing Them
Ensure that Loki is successfully collecting logs from the Kubernetes cluster and that Grafana is properly configured to visualize those logs.
![Image](https://github.com/user-attachments/assets/8aa58d9d-5d67-422b-9479-4dee70bc3f77)

![Image](https://github.com/user-attachments/assets/2f27cc1e-41e3-46a0-842e-5bef7a78284a)

# Validate Prometheus and Build a Prometheus Dashboard
Ensure that Prometheus is properly scraping metrics from your services and that Grafana is configured to visualize those metrics.
![Image](https://github.com/user-attachments/assets/dd5b836c-7fb7-4261-8c01-54321023ee34)

![Image](https://github.com/user-attachments/assets/c1dec725-4962-4c30-97ce-fde9c9b8a520)

![Image](https://github.com/user-attachments/assets/90f721e6-4275-40b6-9a66-c6d0dd12278a)

![Image](https://github.com/user-attachments/assets/f62235cf-4106-4b7d-a01f-cf5d980f192a)

# In Conclusion:
Spans are crucial for visualizing the performance and flow of requests across various services in a distributed system. 
They help developers and operators effectively troubleshoot, monitor, and optimize application behavior.

# Did did we use the OpenTelemetry Collector to Send Data to Grafana?
Yes. The OpenTelemetry Collector acts as a lightweight agent that can receive, process, and export telemetry data such as traces, metrics, and logs.
It can collect trace data from applications and forward it to backends like Jaeger or Grafana Tempo.

Once traces are stored in Tempo, you can query and visualize them directly through Grafana. Similarly, if traces are sent to Jaeger, you can explore them via the Jaeger UI.
This setup decouples instrumentation from exporting logic and enables scalable, centralized observability across your microservices architecture.

