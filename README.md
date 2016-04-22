# AutoPilot Pattern WordPress

*A robust and highly-scalable implementation of WordPress in Docker using the Autopilot Pattern*

[![DockerPulls](https://img.shields.io/docker/pulls/autopilotpattern/wordpress.svg)](https://registry.hub.docker.com/u/autopilotpattern/wordpress/)
[![DockerStars](https://img.shields.io/docker/stars/autopilotpattern/wordpress.svg)](https://registry.hub.docker.com/u/autopilotpattern/wordpress/)
[![ImageLayers](https://badge.imagelayers.io/autopilotpattern/wordpress:latest.svg)](https://imagelayers.io/?images=autopilotpattern/wordpress:latest)
[![Join the chat at https://gitter.im/autopilotpattern/general](https://badges.gitter.im/autopilotpattern/general.svg)](https://gitter.im/autopilotpattern/general)

---

### Containerized and easily scalable

This project uses the Autopilot Pattern to automate operations, including discovery and configuration, for easy scaling to any size. All component containers use [ContainerPilot](https://www.joyent.com/containerpilot) and [Consul](https://consul.io/) to configure themselves. This also allows each service to be scaled independently to handle incoming traffic and as more services are added, the containers that consume these services will reconfigure themselves accordingly.

### Project Architecure

A running cluster includes the following components:

- [ContainerPilot](https://www.joyent.com/containerpilot): included in our MySQL containers orchestrate bootstrap behavior and coordinate replication using keys and checks stored in Consul in the `preStart`, `health`, and `onChange` handlers.
- [Autopilot-MySQL](https://github.com/autopilotpattern/mysql/): we're using the Autopilot-MySQL project to leverage the great features built into this container. It users MySQL5.6 via [Percona Server](https://www.percona.com/software/mysql-database/percona-server), and [`xtrabackup`](https://www.percona.com/software/mysql-database/percona-xtrabackup) for running hot snapshots.
- [Memcached](https://github.com/autpilotpattern/memcached/): Caches often accessed data in memory so WordPress doesn't always have to access the database
- [Nginx](https://github.com/autopilotpattern/nginx): Front-end load balancer for the WordPress envrionment, passes traffic from users to the WordPress containers on the back-end.
- [NFS](https://github.com/autpilotpattern/nfsserver/): Stores user uploaded files so these files can be shared between many WordPress containers and served to the world
- [Consul](https://www.consul.io/): used to coordinate replication and failover
- [Manta](https://www.joyent.com/object-storage): the Joyent object store, for securely and durably storing our MySQL snapshots.

### How do I use this thing?

Clone this repository and place the WordPress theme you want to use into the `var/www/html/content/themes` directory. Follow the instructions below to set up your system to run containers on [Triton](https://www.joyent.com/), or anywhere that supports the Autopilot Pattern.

### Getting started on Triton

1. [Get a Joyent account](https://my.joyent.com/landing/signup/) and [add your SSH key](https://docs.joyent.com/public-cloud/getting-started).
1. Install the [Docker Toolbox](https://docs.docker.com/installation/mac/) (including `docker` and `docker-compose`) on your laptop or other environment, as well as the [Joyent Triton CLI](https://www.joyent.com/blog/introducing-the-triton-command-line-tool) (`triton` replaces our old `sdc-*` CLI tools)
1. [Configure Docker and Docker Compose for use with Joyent](https://docs.joyent.com/public-cloud/api-access/docker):

```bash
curl -O https://raw.githubusercontent.com/joyent/sdc-docker/master/tools/sdc-docker-setup.sh && chmod +x sdc-docker-setup.sh
./sdc-docker-setup.sh -k us-east-1.api.joyent.com <ACCOUNT> ~/.ssh/<PRIVATE_KEY_FILE>
```
### Configure your envrionment

Check that everything is configured correctly by running `./setup.sh`, you will need to pass the path of the ssh key you configured on your Joyent account with the `-k` flag. If it returns without an error you're all set. This script will create and `_env` file that includes the variables that you will need to run your WordPress envrionment.

### Environment

There are several sections in the _env file that you will need to configure for your specific environment.

#### MySQL settings

```
# Environment variables for MySQL service
MYSQL_DATABASE=test
MYSQL_USER=wpuser
MYSQL_PASSWORD=wppass
MYSQL_REPL_USER=repluser
MYSQL_REPL_PASSWORD=replpass
```

Configure the database info for your WordPress install, database name, user and password will be used in `wp-config.php`. The last two options are used by the Autopilot Pattern MySQL container to set up its replication when scaled up to more than a single container. You can keep `repluser`, but set a unique password for your environment.

#### Manta Settings

```
# Environment variables for backups to Manta
MANTA_URL=https://us-east.manta.joyent.com
MANTA_USER=joyentuser
MANTA_BUCKET=/joyentuser/stor/mysql
```

The MySQL container will take a backup during its `preStart` handler and periodically while running. Configure these Manta settings to specify how and where this backup is stored. Here you need to specify the `MANTA_URL` for the datacenter you will be using, the `MANTA_USER`, and also the `MANTA_BUCKET` where the backups will be stored.

#### WordPress configuration

```
WORDPRESS_URL=http://localhost
WORDPRESS_SITE_TITLE=test site
WORDPRESS_ADMIN_EMAIL=username@domain.com
WORDPRESS_ADMIN_USER=username
WORDPRESS_ADMIN_PASSWORD=password
WORDPRESS_ACTIVE_THEME=theme
WORDPRESS_CACHE_KEY_SALT=some-unique-string
```

This block is the typical information you must provide when installing WordPress. The URL of the site, the site title and admin user information are all straightforward. `WORDPRESS_ACTIVE_THEME` is the theme that will be activated automatically when the container starts. This will typically be theme that you are developing in this repo, or one of the default themes. `WORDPRESS_CACHE_KEY_SALT` should be set to a unique string, the object caching in WordPress will use this salt to determine the cache keys for information it sets on the Memcached container.

If you are not bringing your own theme in this repo, you can choose from these default themes for the `WORDPRESS_ACTIVE_THEME` variable:

- `twentyfifteen`
- `twentyfourteen`
- `twentysixteen`

#### WordPress unique salts

```
WORDPRESS_AUTH_KEY=
WORDPRESS_SECURE_AUTH_KEY=
WORDPRESS_LOGGED_IN_KEY=
WORDPRESS_NONCE_KEY=
WORDPRESS_AUTH_SALT=
WORDPRESS_SECURE_AUTH_SALT=
WORDPRESS_LOGGED_IN_SALT=
WORDPRESS_NONCE_SALT=
```

More WordPress configuration, these variables are how WordPress secures your logins and other secret info. These should be unique for your site. You can use [this WordPress tool](https://api.wordpress.org/secret-key/1.1/salt/) to generate a unique set for your site and include them here.

#### Configure Consul in Joyent CNS

```
CONSUL=consul.svc.{your-account-uuid}.{target-data-center}.cns.joyent.com
```

Finally we need to configure an envrionment variable with the location of our consul container in Joyent's Container Name Service. This name will allow the other containers in our environment to find Consul via a DNS lookup. Your account UUID by executing `triton account get` on your command line. In the local-compose.yml file you will notice that this varible is overridden to be simply 'consul' for local development.

#### A note on Nginx

This project also builds it's own Nginx container that is based on the [AutoPilot Pattern Nginx project](https://github.com/autopilotpattern/nginx). We build a custom Nginx container to more easily inject our custom configurations. The configs located in the `/nginx` directory should work well for most use cases of this project, but they can be customized and baked into the nginx image if the need arises.

#### Start the containers!

After configuring everything, we are now ready to start the containers. To do that simply execute `docker-compose up -d`, this will build the WordPress and Nginx images, containing your theme from this repo, and spin it up on Triton. Change the DNS settings for your `WORDPRESS_URL` to point to the ip address for your Nginx container and open in a browser.
