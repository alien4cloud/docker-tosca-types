# docker-tosca-types

This project aims at providing a TOSCA nearly-normative set of types for Docker support within Alien4Cloud.

We are not following the exact types from TOSCA as we are not fully inline with their current implementation. We plan anyway to provide compatibility with TOSCA types later.

Current TOSCA types for containers implies specific *Capabilities* and *Requirements*. We believe this to be a wrong approach and that the difference between a Docker-based component and a non-Docker component should be handled by the orchestrator. For instance, deploying a MongoDb via a Docker image in a container or through Scripts in a compute should in our opinion lead to a *MongoCapability* that derives from *tosca.capabilities.Endpoint* in both implementations.

In the future, this approach will lead to the ability to deploy topologies with both containers and non-container nodes (based on orchestrators support).

## Docker-types description
The node_type *tosca.nodes.Container.Application.DockerContainer* is derived_from the existing type *tosca.nodes.Container.Application*.

### Defining operations
- The implementation value of the *Create* operation takes the Docker image, as explained below.
- Inputs given to the *Start* operation are planned to used by the orchestrators as arguments for the container **Entrypoint**.
ATM, we do not support giving a plain command to the container.

### Docker CLI arguments
It is possible to define arguments for the Docker CLI using the *docker_cli_args* property as a map of key/pairs. It is also possible
(and recommended) to create a custom datatype if specific CLI args are expected for the application ([see the Nodecellar example](/examples/nodecellar_types_sample.yml)).

### Docker images
We defined a specific artifact to represent Docker images. This allow us to provide the path to a Docker image to
the create operation. A docker path recognizable by alien is as follow: **[registry/][repository/]image[:tag].dockerimg**.
While feeling like a workaround, the *.dockerimg* file extension is mandatory for now.

### Defining capabilities
#### Modularity
We aim for topologies where Docker containers and non-docker apps can live together. As such, capabilities for Docker containers should inherit usual capabilities. For instance, in the [Nodecellar sample](/examples/nodecellar_types_sample.yml), we defined :
- The **alien.capabilities.endpoint.Mongo** capability, which inherits *tosca.capabilities.Endpoint* and is the generic ability to expose a Mongo database,
- The **alien.capabilities.endpoint.docker.Mongo** capability, which derives from the latter. This capability is exposed by the *mongo_db* capability of the *MongoDocker* Node-type.
Using inheritance, this means that any other Node-type requiring *alien.capabilities.endpoint.Mongo* can use the MongoDocker through a classic **ConnectsTo** relationship.

#### Bridging between container and host ports
To allow bridge networking between the container and it's host, we added the *docker_port_mapping* property to the *alien.capabilities.endpoint.docker.Mongo* relationship. This will be interpreted by the Orchestrator as the Host port, while the *port* property (which we inherited from the Endpoint capability) represents the port inside the container. If the value is 0, the Orchestrator will randomly allocate a port. If no value is specified, then Host networking will be used.

### Hosting requirements
As per the usual *host* requirement, we decided to use a *lower_bound* value of 0. This allows definition of topologies with containers only, which we will be able to deploy onto a Marathon / Mesos cluster for instance.
