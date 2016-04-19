# AutoPilot Pattern WordPress
*a Docker Compose leveraging services from many containers to create an robust WordPress envrionment*

### Containerized and discoverable via Consul
This project uses Consul for service discovery, and all component containers announce themselves to Consul and get the information they need about other services from Consul. This allows each container to configure itself once the services it depends on are online. It also allows each service to be scaled up to handle incoming traffic and as more services are added, the containers that consume these services will reconfigure themselves accordingly.

### Project Architecure
A running cluster includes the following components:

- [Consul](https://www.consul.io/): used to coordinate replication and failover
- [Autopilot-MySQL](https://github.com/autopilotpattern/mysql/): we're using the Autopilot-MySQL project to leverage the great features built into this container. It users MySQL5.6 via [Percona Server](https://www.percona.com/software/mysql-database/percona-server), and [`xtrabackup`](https://www.percona.com/software/mysql-database/percona-xtrabackup) for running hot snapshots.
- [Manta](https://www.joyent.com/object-storage): the Joyent object store, for securely and durably storing our MySQL snapshots.
- [ContainerPilot](https://www.joyent.com/containerpilot): included in our MySQL containers orchestrate bootstrap behavior and coordinate replication using keys and checks stored in Consul in the `preStart`, `health`, and `onChange` handlers.
- [NFS](https://github.com/autpilotpattern/nfsserver/): Stores user uploaded files so these files can be shared between many WordPress containers and served to the world
- [Memcached](https://github.com/autpilotpattern/memcached/): Caches often accessed data in memory so WordPress doesn't always have to access the database
- [Nginx](https://github.com/autopilotpattern/nginx): Front-end load balancer for the WordPress envrionment, passes traffic from users to the WordPress containers on the back-end.

### Getting started

1. [Get a Joyent account](https://my.joyent.com/landing/signup/) and [add your SSH key](https://docs.joyent.com/public-cloud/getting-started).
1. Install the [Docker Toolbox](https://docs.docker.com/installation/mac/) (including `docker` and `docker-compose`) on your laptop or other environment, as well as the [Joyent Triton CLI](https://www.joyent.com/blog/introducing-the-triton-command-line-tool) (`triton` replaces our old `sdc-*` CLI tools)
1. [Configure Docker and Docker Compose for use with Joyent](https://docs.joyent.com/public-cloud/api-access/docker):

```bash
curl -O https://raw.githubusercontent.com/joyent/sdc-docker/master/tools/sdc-docker-setup.sh && chmod +x sdc-docker-setup.sh
./sdc-docker-setup.sh -k us-east-1.api.joyent.com <ACCOUNT> ~/.ssh/<PRIVATE_KEY_FILE>
```
### Joyent Manta configuration
```
write this:
needs ssh keys for manta
```



Check that everything is configured correctly by running `./setup.sh`. If it returns without an error you're all set. This script will create and `_env` file that includes the Triton CNS name for the Consul service. You'll want to edit this file to update the username and password for Couchbase.
