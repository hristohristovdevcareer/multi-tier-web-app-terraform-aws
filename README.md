# Multi-tier, AWS web app #

## Project Overview ##
This project represents a comprehensive journey into advanced DevOps practices, designed and implemented as a practical learning initiative. The objective was to create a production-grade infrastructure while navigating real-world constraints - particularly the challenge of maintaining zero cost through strategic service selection and implementation. While certain choices, such as t2.micro instances, custom automation of self-signed certificates, or custom NAT solutions, might not be typical production selections, they demonstrate the ability to architect functional solutions within specific constraints.

The infrastructure implements industry best practices across multiple domains: high availability through multi-AZ deployment, security through defense-in-depth principles, cost optimization through strategic resource selection, and automation through Infrastructure as Code. The project deliberately focuses on AWS services due to their market dominance and free tier offerings, providing valuable hands-on experience with industry-standard tools.

While numerous enhancements could be implemented (such as more sophisticated container orchestration through Kubernetes, advanced security measures, or comprehensive monitoring solutions), the project's scope was intentionally bounded to demonstrate practical DevOps skills while maintaining forward momentum in professional development. The infrastructure serves as a foundation for future exploration of advanced concepts in CI/CD, security hardening, and automated operations. Furthermore, there is plenty of room for cleanup and improvements on smaller-scale parts of the infrastructure like NAT, ECS agent setup, monitoring, and other general amends.

## Prerequisites ##

- Gitlab account
- AWS account
- AWS CLI v2 installed
- AWS credentials configured
- Cloudflare account
- Cloudflare registered domain name
- Terraform 
- Hashicorp Vault
- Docker & Docker Compose
- Node.js for server/client setup and management
- Git
- JSON processor jq for vault scripts


## Project setup ##
1. Install locally: Node, Terraform, Vault, Docker & Docker Compose, jq, Git
2. Add AWS access credentials locally using `aws configure`
3. Pull project locally from Gitlab
4. Relocate to the terraform folder
5. Fill environment variable values in .env according to the provided example
6. Make all script files executable (look at "**Automated Setup**" section for instructions)
7. Apply environment variables to environment (script: set-env-vars.sh)
8. Set up Vault (Setup instructions underneath)
9. Set up state management by creating an S3 bucket
10. Run terraform  with `terraform plan` and then `terraform apply` (requires point 9 to be done)

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
    1.2. var (base64 encoded) - nat_ssh_private_key
2. Group - gitlab_keys \
    2.1. var (base64 encoded) - gitlab_private_key \
    2.2. var - gitlab_public_key
3. Group - db_credentials \
    3.1. var - username \
    3.2. var - password
4. Group - cloudflare \
    4.1. var - cloudflare_api_token \
    4.2. var - cloudflare_zone_id

### Automated Setup ###
1. Add secrets to vault.json according to vault.example.json located in the terraform folder
2. From the terraform folder, make the init_vault.sh script executable:
`chmod -x init_vault.sh`
3. Run init_vault.sh
`source init_vault.sh`
4. Copy the displayed token after the script is ran and use it to login to the provided vault address

## State Setup ##
From the main terraform folder, after setting up Vault:
1. Run `terraform -chdir=tf-state init`
2. Run `terraform -chdir=tf-state plan`
3. Run `terraform -chdir=tf-state apply`

When cleaning up, AFTER destroying the infrastructure, destroy the state management S3 bucket:
1. Run `terraform -chdir=tf-state destroy`

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
**Value of automation, cloud services, and IAC tools** \
Cloud services can be quite beneficial in large, corporate-level architectures, where traffic can constantly vary. Security can be further enhanced compared totraditional computing, and, depending on the use-case, might reduce costs. Automation can simplify and speed-up the process of development by a lot. It is a way of thinking that helps with early detection of issues, while helping form project structure. Furthermore, it can make everything much more straightforward and simple when it comes to setup. Terraform's declarative approach makes it easy to think about the final product, rather than how to build it manually. Furthermore, it can be efficiently utilised to manage multiple clouds due to its provider-agnostic features.

**Efficiency, scalability, and maintainability of modularity in infrastructure** \
Initially, everything was done with poor levels of modularity which led to harder debugging and extra issues. Project structure changed a couple of times due to the little experience with working with terraform. With time, as code quality got improved, management became easier and more effective. Of course, when it comes to project structure, it depends to the professional working on the project to an extent so there could be multiple ways of structuring things. But, good fragmentation is in general a key aspect of code quality. For example, SG's can be put together with their relating components, or placed in a completely separated SG module as in the current project. Overall, it does include personal preference as well.

**How different AWS services and resources function together** \
Developing this infrastructure provided deep insights into the interconnections between AWS services. Understanding the nuanced relationships between networking components (VPC, subnets, route tables), compute resources (EC2, ECS), and security mechanisms (IAM, Security Groups) proved essential for creating a functioning system. It has been concluded that usually there can be multiple solutions to a given problem with various degrees of automation, security, and drawbacks to each of them. The more services were discovered, the better the architecture became.

**Differences between ECS and Kubernetes** \
Due to low familiarity with devops practices, ECS wasn't considered as significan't and it was decided that it can be done quite rapidly. Eventually, this was proven false, which led the author to research Kubernetes preemptively since it is part of the roadmap for a devops professional and it would require large amounts of time as well. From what was discovered, it was made clear that ECS is a bit simpler and AWS-based compared to Kubernetes, but for this, Kubernetes allows for greater flexibility and more complex architectures, with a large ecosystem of tools, and allowing for multi-cloud deployments. The project's implementation of ECS provided valuable experience with concepts that transfer directly to Kubernetes: container definitions, task specifications, service discovery, and orchestration principles. The decided custom approach actually enhanced understanding of container orchestration fundamentals that are often abstracted away in managed Kubernetes offerings.This knowledge will prove valuable when transitioning to Kubernetes, as it provides insight into the underlying mechanisms that Kubernetes automates.

**Balancing different aspects of the cloud for cost optimisations** \
Cost optimization emerged as a multidimensional challenge requiring careful balancing of various factors. The strategic use of Cloudflare's free tier for DNS management and DDoS protection demonstrated how third-party services can complement AWS offerings to reduce overall costs. Similarly, leveraging GitLab's CI/CD capabilities avoided the need for additional AWS services like CodePipeline. Furthermore, certain services had to substituted for custom - free ones. The project revealed that cost optimization isn't simply about choosing the cheapest option, but about making strategic trade-offs. For instance, investing development time in custom NAT solutions yielded significant long-term savings compared to managed NAT gateways, while the choice of t2.micro/t3.micro instances balanced performance needs with cost constraints. Perhaps most importantly, the experience highlighted how architectural decisions (like public/private subnet design and multi-AZ deployment) have profound impacts on both costs and system resilience, requiring careful consideration of these sometimes competing factors.

**Real-world application of security best practices** \
Implementing security best practices in a real-world context revealed the practical challenges of balancing security with usability and development velocity. The project successfully implemented defense-in-depth principles through network segmentation, least-privilege IAM policies, and secure secret management with Vault. The project established a solid security foundation that could be progressively hardened. Particularly valuable was the hands-on experience with IAM role assumption, security group design, secure HTTPS communication, and the practical implementation of the principle of least privilege across infrastructure components. Research done around security concepts highlighted variouse remote access principles like AWS Systems Manager, bastion hosts, and AWS web-based console access. These skills transfer directly to enterprise environments where security requirements are even more stringent. However, time constraints prevented implementation of some advanced security measures like comprehensive AWS Config rules, GuardDuty integration, or detailed CloudTrail analysis.

**Custom ECS configuration complications and challenges without ECS-optimized AMIs** \
The decision to implement ECS without ECS-optimized AMIs created significant technical challenges that ultimately yielded valuable learning opportunities. Configuring standard Ubuntu instances to function as ECS container hosts required deep dives into the ECS agent configuration, Docker daemon settings, and networking configurations. Numerous issues emerged during this process, including container networking problems, agent connectivity failures, and task definition incompatibilities.
Resolving these challenges required extensive troubleshooting, AWS documentation research, and iterative testing. The process revealed the intricate details of how ECS actually works under the hood - knowledge that remains hidden when using pre-configured AMIs. This deep understanding proved invaluable when diagnosing subsequent issues and will transfer to other container orchestration platforms. While more time-consuming than using managed options, this approach confirmed that investing in deep technical understanding pays dividends in troubleshooting capabilities and architectural flexibility.

**Custom NAT gateways vs managed gateways and knowledge around their aspects** \
The initial test and costs of managed NAT gateways have been quite motivating and convincing to look deeper into custom NAT solutions. Of course, depending on use-case and budget, it might be more beneficial to utilise managed services. But having the knowledge to create custom such, will be of great aid to smaller companies which cannot afford the costs of a managed gateway, or in times where developer time is more highly available and allows for development and management of custom resources. The skill of knowing that, makes it possible and brings options and flexibility. The implementation process required deep understanding of Linux networking, IP forwarding, and AWS routing configurations. While more complex to set up initially, the custom solution provided greater control over the NAT functionality and significant cost savings. This experience demonstrated that managed services aren't always the optimal choice, particularly for cost-sensitive deployments or organizations with the technical capacity to maintain custom solutions. The knowledge gained about network address translation, routing, and security considerations for internet-facing services will be applicable across cloud providers and on-premises environments.

**Significance of logging and monitoring tools** \
Initial skepticism about the value of comprehensive logging and monitoring was quickly dispelled as the project progressed. CloudWatch proved instrumental in troubleshooting complex issues, particularly those related to container startup failures, networking problems, and resource constraints. The ability to correlate logs across different components of the infrastructure revealed system interactions that would have been nearly impossible to diagnose otherwise. Beyond troubleshooting, monitoring tools provided valuable insights into system performance, resource utilization, and potential optimization opportunities. This experience transformed the perception of logging and monitoring from optional extras to essential infrastructure components, highlighting their critical role in maintaining system reliability and informing capacity planning decisions.

**Custom automation for security features** \
The implementation of self-signed certificates through custom automation demonstrates a security-first approach while avoiding additional costs of managed services like API Gateway. This direct certificate implementation provides tight control over the secure communication between frontend and backend microservices, potentially offering enhanced security compared to some managed alternatives. The process provided valuable insights into certificate management, secure service-to-service communication, and how to maintain high security standards while working within project constraints. The experience reinforced that effective security automation is essential for maintaining consistent security posture across complex, distributed systems.

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

**Further reviews, debugging, and cleaning of startup scripts**

## Development Journey and Notes ##