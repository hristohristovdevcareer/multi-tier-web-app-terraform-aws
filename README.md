# Multi-tier, AWS web app #

## Project Overview ##
This project represents a comprehensive journey into advanced DevOps practices, designed and implemented as a practical learning initiative. The objective was to create a production-grade infrastructure while navigating real-world constraints - particularly the challenge of maintaining zero cost through strategic service selection and implementation. While certain choices, such as t2.micro instances, custom automation of self-signed certificates, or custom NAT solutions, might not be typical production selections, they demonstrate the ability to architect functional solutions within specific constraints.

The infrastructure implements industry best practices across multiple domains: high availability through multi-AZ deployment, security through defense-in-depth principles, cost optimization through strategic resource selection, and automation through Infrastructure as Code. The project deliberately focuses on AWS services due to their market dominance and free tier offerings, providing valuable hands-on experience with industry-standard tools.

While numerous enhancements could be implemented (such as more sophisticated container orchestration through Kubernetes, advanced security measures, or comprehensive monitoring solutions), the project's scope was intentionally bounded to demonstrate practical DevOps skills while maintaining forward momentum in professional development. The infrastructure serves as a foundation for future exploration of advanced concepts in CI/CD, security hardening, and automated operations.

## Prerequisites ##

- Gitlab account
- AWS account
- AWS CLI installed
- AWS credentials configured locally
- Cloudflare account
- Cloudflare registered domain name
- Terraform
- Hashicorp Vault
- Docker & Docker Compose
- Node.js for server/client setup and management
- Git
- JSON processor jq for vault scripts


## Project setup ##
1. Relocate to the terraform folder
2. Fill environment variable values in .env according to the provided example
3. Apply environment variables to environment
4. Set up Vault (Setup instructions underneath)
5. Run terraform

## Vault setup ##

### Manual Setup ###
1. Run Vault on the machine through "vault server -dev"
2. Open Vault in the browser through the provided link
3. Copy the root token that is provided upon startup and add to the token auth page
4. Locate to secrets and add all Groups/Secrets as per documentation
5. Set vault address to the env variables and re-run environment variable setup script (set-env-vars.sh)

Variables that need to be set in vault:
1. Group - ec2_ssh \
    1.1. var - ec2_ssh_public_key \
    1.2. var - nat_ssh_private_key
2. Group - gitlab_keys \
    2.1. var - gitlab_private_key \
    2.2. var - gitlab_public_key
3. Group - db_credentials \
    3.1. var - username \
    3.2. var - password
4. Group - cloudflare \
    4.1. var - cloudflare_api_token \
    4.2. var - cloudflare_zone_id

### Automated Setup ###
1. From the terraform folder, make the init_vault.sh script executable:
`chmod -x init_vault.sh`
2. Run init_vault.sh
`source init_vault.sh`
3. Copy the displayed token after the script is ran and use it to login to the provided vault address


## Project Context ##

### Objective: ###
This project has been initiated with an educational purpose. The objective is to achieve knowledge and experience on advanced DevOps skills and concepts. It aims to create a complex, as close as possible to production-grade level infrastructure, that follows industry's best standards regarding automation, security, both financial, and resource efficiencies, similar to real-world use-cases. The product should achieve high automation levels by utilising terraform for simple and rapid generation of infrastructure. It focuses on the AWS cloud provider due to its large share of the cloud technology market. 

### Architecture: ###
Architecture is based on microservices, which isolates all system fragments. A VPC holds the client services in a public subnet, while all server instances and databases are kept in a private one. The infrastructure is based on multiple AZ's in order to simulate a real-world scenario. All ingress traffic going into the VPC goes through a general internet gateway. Servers from the private subnet communicate with public subnet resources through custom NAT gateways, and respectfully, with any databases directly since they are also located in the private subnet. The system includes auto-scaling to achieve optimal availability while minimizing costs, as well as multiple load balancers from separate cloud providers, each for its own advantages.

### Tech: ###
1. **Ubuntu** - Ubuntu is one of the most popular Linux distributions for DevOps, infrastructure, and cloud providers. Overall, industry standard.
2. **AWS** - With the biggest market share, AWS is the most popular cloud provider. The free tier offers an excellent opportunity to study for an entire year, and the majority of jobs require it. List of utilised AWS services:
3. **Terraform** - The leading cloud-agnostic infrastructure as code (IAC) management solution is Terraform, allowing for simple expansion in the future. The degree of automation, modularity, and simplicity all influence this selection. It is well-established, has a sizable ecosystem, and integrates seamlessly with Gitlab and Ansible.
Hashicorp Vault - A standardised tool for secret management, security, and collaboration.Gitlab: The primary motivators are prior experience and superior UI/UX. Popular and provides a free tier as well.
4. **ECS** - Before moving on to a more sophisticated container orchestration solution like Kubernetes, the objective was to build a project on ECS, which initially appeared straightforward due to the initial idea to stay as close to AWS as possible. As research and development got underway, it became apparent that custom ECS-optimized AMIs are not free. Setting everything up manually would be one way to prevent any expenses. In terms of specifics of how ECS and its agents function, the automatic configuration of the ECS agent on all instances resulted in success, knowledge, and additional experience.
5. **Docker** - When it comes to containerisation, testing, and managing apps and environments, Docker is the obvious choice for any DevOps team. Effective at isolation, prevents errors that could be expensive on the cloud, simulates environments, and allows for local testing, which saves time and possible costs.
6. **Cloudflare** - Experience has shown that Cloudflare's DNS services are quite beneficial. Offers a free plan for certain services when a domain is bought. The extra benefits in the free plan include SSL certificates, load balancing, and free DDOS protection.

### Services: ###
1. **AWS Compute** \
    1.1. EC2 Instances \
    1.2. ECS (Elastic Container Service) \
    1.3. ECR (Elastic Container Registry) \
2. **AWS Networking** \
    2.1. VPC \
    2.2. ALB (Application Load Balancer) \
    2.3. Custom NAT \
    2.4. Security Groups \
3. **AWS Storage and Database** \
    3.1. RDS (PostgreSQL) \
    3.2. S3 \
    3.3. DynamoDB \
4. **AWS Management and Monitoring**
    4.1. Cloudwatch
    4.2. IAM


### Further Context and Thought Process ###
Further context: Project goals evaluation: The success of the project can be evaluated by setting clear goals and comparison to industry standards and establishing functioning infrastructure according to these goals. Utilising the cloud is done for a number of major benefits. These include: 
- Scalability
- Reduced costs
- Availability
- Performance
- Flexibility
- Security

For **scalability**, current architecture is simplified and utilises only horizontal scaling - a cost-effective approach that allows scaling without downtime. This means multiple tasks being created and/or destroyed on instances, while instances can be provisioned, or destroyed, depending whether the current ones can accommodate the required amount of tasks. Vertical scaling for the different parts of the infrastructure can be done in various ways, though it would require more complex changes. For tasks, it would require a significant architectural shift to utilize Lambda functions, as they provide better resource allocation flexibility than container-based tasks. For instances, this can be automated by setting up the Auto Scaling Groups to use mixed instances - a feature that allows different instance types in the same ASG, providing both performance and cost benefits. This approach suits the current architecture well. Alternatively, EC2 Fleet with Spot and on-demand instances could be implemented, offering a balance between cost savings and reliability. In the latter approach, when instances are being scaled, they are simply replaced with more powerful ones, instead of creating new ones, though this may involve brief downtimes during transitions. The implementation of rolling deployments through CI/CD will further complement this scalability approach, allowing for controlled instance updates without impacting the overall system capacity.

**Cost** Optimisations
1. **Infrastructure Choices:** \
    1.1. Custom NAT Gateway implementation instead of AWS managed NAT \
    1.2. Strategic instance type selection (t2.micro for general use, t3.micro for DB) \
    1.3. Frontend utilisation of t3.small due to Next.js requirements(later updated to t3.micro) \
    1.4. Auto-scaloing constraints to prevent over-provisioning \
    1.5. Multi-AZ deployment only where necessary
2. **Development and Testing:** \
    2.1. Development environment simulation locally \
    2.2. Docker utilization for local testing \
    2.3. Testing on cheaper instance types before production \
    2.4. Local Vault server for development
3. **Resource Management:** \
    3.1. Instance scaling restrictions based on actual needs \
    3.2. Auto-scaling group limitations to precent runaway costs \
    3.3. Efficient container resource allocatiomn \
    3.4. Proper instance shutdown procedures
4. **Service Selection:** \
    4.1. Automated setup of certain custom resources instead of managed services \
    4.2. Cloudflare free tier for DNS and DDoS protection \
    4.3. Strategic region selection for reduced data transfer costs \
    4.4. S3 with proper lifecycle policies
5. **Architecture Decisions:** \
    5.1. Horizontal scaling for cost-effective resource utilization \
    5.2. Microservices for independent scaling \
    5.3. Private subnet usage for reduced data transfer costs \
    5.4. Load balancer optimization for traffic distribution


**Availability** is achieved through multiple AZ's, the overall microservice architecture, auto-scaling, and load-balancing. Multi AZ ensures resiliency against regional failures, while the architecture is resistant to single-point breakdowns. Auto-scaling is responsible for keeping the infrastructure running smooth and efficiently and avoiding any performance-related issues. Load-balancing works in sync with AZ's to distribute traffic and send it to only reachable, healthy end-points. Rolling deployments in the CI/CD pipeline ensure zero-downtime updates by gradually replacing instances and maintaining service continuity. Internal communication with the server due to it being located in a private subnets aids with enhanced security, lower latency, and better failover processes.

**Security** is tackled on various levels of the infrastructure.
1. **Network Security:** \
    1.1. VPC isolation with public and private subnets \
    1.2. Protocol restrictions (HTTPS, HTTP, SSH) \
    1.3. Private subnet positioning for critical resources \
    1.4. Custom NAT for controlled outbound traffic
2. **Access Control and Authentication:** \
    2.1. Passwordless SSH with key-pairs \
    2.2. Vault for secrets management \
    2.3. EC2 instance prodiles \
    2.4. IAM roles and policies
3. **Application Security:** \
    3.1. HTTPS enforcement \
    3.2. Environment variable management \
    3.3. Secure application configurations \
    3.4. Container isolation \
    3.5. Self-signed certificates for secure FE-BE communication
4. **Data Security:** \
    4.1. Databases in private subnets \
    4.2. Secrets encryption through Vault \
    4.3. S3 encryption \
    4.4. Terraform state encryption 
5. **Infrastructure Security:** \
    5.1. Infrastructure as Code (version control) \
    5.2. Resource tagging \
    5.3. Least privilege principle \
    5.4. Automated security configurations \
    5.5. Rolling deployments with automated rollback capabilities
6. **Availability Security:** \
    6.1. Auto-scaling mechanisms \
    6.2. Multi-AZ deployment \
    6.3. DDoS protection (cloudflare) \
    6.4. Load balancing
7. **Monitoring and Compliance:** \
    7.1. Audit trails \
    7.2. Resource monitoring \
    7.3. Health checks \
    7.4. CloudWatch logging

**Performance** is achieved through multiple architectural decisions and service implementations. The microservices architecture allows for independent optimization of each component, while the strategic positioning of resources enhances response times. Frontend services in public subnets maintain direct internet connectivity, while backend services in private subnets benefit from reduced network hops and optimized internal AWS routing. Load balancing across multiple AZs ensures efficient request distribution and reduced latency. The implementation of containerization through ECS enables precise resource allocation and improved resource utilization. Database performance is maintained through proper instance sizing and network proximity in the private subnet, while CloudWatch monitoring allows for continuous performance tracking and optimization opportunities. The utilization of Cloudflare's CDN capabilities further enhances content delivery performance for end-users across different geographical locations.

In the infrastructure, **flexibility** is demonstrated through several key aspects. The microservices architecture allows for independent scaling, updates, and modifications of individual components without affecting the entire system. Infrastructure as Code through Terraform enables rapid environment replication and consistent modifications across different stages. Container-based deployment provides platform independence and easy service portability. The multi-AZ design allows for resource redistribution based on regional requirements or constraints. Auto-scaling configurations can be adjusted based on varying workload patterns, while the custom NAT implementation demonstrates the ability to replace managed services with custom solutions when needed. The modular approach to infrastructure, with clear separation between networking, compute, and storage resources, enables straightforward modifications and potential future migrations.

## Lessons Learned ##
**Value of automation, cloud services, and IAC tools**
Describe the appreciation of cloud services, automation, and how if used wisely, can be pretty beneficial.

**Efficiency, scalability, and maintainability of modularity in infrastructure**
Start by explaining initial trouble with poor modularity, and the eventual efficiency increase with enhancement of code quality and fragmentation. Note that modules had to be completely recreated, and that alternative approaches to some aspects might be more beneficial than the current ones. For example, security groups might go with their respective components and infrastructure parts, than being all concentrated in a single SG module.

**How different AWS services and resources function together**
General knowledge of how the various component work together, what configuration is available, and what are best practices, pros and cons.

**Differences between ECS and Kubernetes**
Explain how later deeper research into Kubernetes and ECS led to the realisation why Kubernetes is more widely used thann ECS. Pros and cons. Similarities, differences, and what knowledge that has been achieved in the development of this project, can be applied to Kubernetes. Also, the appreciation of potential simplicity and complexities. 

**Balancing different aspects of the cloud for cost optimisations**
Cloudflare utilisation, together with Gitlab for simple management and available free tier advantages.

**Real-world application of security best practices**
Mention all different security measures that have been learned, which ones were implemented, and which ones haven't. Do note that not all have been implemented due to time restrictions, although, in a real-world scenario, they will be fully considered and implemented. Learning them separately, might be a better idea since this will take less time. Eventually, they still might be added to the project. Some of them might even earn completely new projects.

**Custom ECS configuration complications and challenges without ECS-optimized AMIs**
Develop the topic that in search of challenges, large amounts of skills and knowledge has been achieved. The manual setup of ECS has led to long hours of tinkering, testing, trials, and eventually success. Many main, and side, details have been discovered and the dificulties haev payed off. Describe exact issues that have been had with the setup and the whole process. Knowing aspects in detail might be very beneficial and the outcomes have led the author to confirm the fact that learning things in-depth is well worth it for future development and debugging as long as they are reasoned.

**Custom NAT gateways vs managed gateways and knowledge around their aspects**
The initial test and costs of managed NAT gateways have been quite motivating and convincing to look deeper into custom NAT solutions. Of course, depending on use-case and budget, it might be more beneficial to utilise managed services. But having the knowledge to create custom such, will be of great aid to smaller companies which cannot afford the costs of a managed gateway, or in times where developer time is more highly available and allows for development and management of custom resources. The skill of knowing that, makes it possible and brings options and flexibility.

**Significance of logging and monitoring tools**
Initial doubt in the level of usefulness of services like CloudWatch due to low experience, and the eventual results from the error details, collected by cloudwatch. Explain how utilisation of cloudwatch has been of great help when it comes to debugging. The fact that automated reactions to events are possible, further confirma the significance of monitoring and logging tools.

**Custom automation for security features**
The implementation of self-signed certificates through custom automation demonstrates a security-first approach while avoiding additional costs of managed services like API Gateway. This direct certificate implementation provides tight control over the secure communication between frontend and backend microservices, potentially offering enhanced security compared to some managed alternatives. The process provided valuable insights into certificate management, secure service-to-service communication, and how to maintain high security standards while working within project constraints.

## Deployment Strategy ##
**Rolling Deployments**
The infrastructure implements a sophisticated rolling deployment strategy that enables zero-downtime updates across the application ecosystem. This approach:

1. **Ensures Service Continuity:** By gradually replacing instances rather than updating all at once, the system maintains availability throughout deployment processes.

2. **Reduces Deployment Risk:** The phased replacement of instances allows for early detection of issues before they affect the entire infrastructure.

3. **Enables Automated Rollbacks:** The deployment pipeline includes automated health checks with intelligent rollback capabilities if newly deployed instances fail to meet operational criteria.

4. **Complements Existing Architecture:** This capability works in harmony with the auto-scaling and multi-AZ design, further strengthening the infrastructure's resilience.

The implementation leverages CI/CD pipelines to orchestrate the deployment sequence, with careful coordination between instance termination and new instance provisioning to maintain capacity requirements. This capability represents a significant step toward enterprise-grade operational maturity.

## Future Potential Enhancements ##

**More powerful resources in order to make the project fully production-grade**

**Replacing custom NAT in cases where security is critical due to better default configuration and management**

**Utilisation of ECS-optimised AMI's and OS's for a more standardised infrastructure**

**Enhancing security on the custon NAT instance**

**Implementing an API Gateway that could replace the current certification management**

**Add database to infrastructure**

**Disaster recovery for data**

**Implement remote state management**

**Implement AWS WAF**

**Further testing implementation for pipeline**

**Enhanced monitoring and alerts**

**Fine-grained scaling according to use-case**

## Development Journey and Notes ##