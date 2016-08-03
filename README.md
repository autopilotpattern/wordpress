# AutoPilot Pattern WordPress

*A robust and highly-scalable implementation of WordPress in Docker using the Autopilot Pattern*

[![DockerPulls](https://img.shields.io/docker/pulls/autopilotpattern/wordpress.svg)](https://registry.hub.docker.com/u/autopilotpattern/wordpress/)
[![DockerStars](https://img.shields.io/docker/stars/autopilotpattern/wordpress.svg)](https://registry.hub.docker.com/u/autopilotpattern/wordpress/)
[![MicroBadger version](https://images.microbadger.com/badges/version/autopilotpattern/wordpress.svg)](http://microbadger.com/#/images/autopilotpattern/wordpress)
[![MicroBadger commit](https://images.microbadger.com/badges/commit/autopilotpattern/wordpress.svg)](http://microbadger.com/#/images/autopilotpattern/wordpress)

---

### Containerized and easily scalable

This project uses the Autopilot Pattern to automate operations, including discovery and configuration, for easy scaling to any size. All component containers use [ContainerPilot](https://www.joyent.com/containerpilot) and [Consul](https://consul.io/) to configure themselves. This also allows each service to be scaled independently to handle incoming traffic and as more services are added, the containers that consume these services will reconfigure themselves accordingly.

### Project architecture

A running cluster includes the following components:

- [ContainerPilot](https://www.joyent.com/containerpilot): included in our MySQL containers to orchestrate bootstrap behavior and coordinate replication using keys and checks stored in Consul in the `preStart`, `health`, and `onChange` handlers.
- [MySQL](https://github.com/autopilotpattern/mysql/): we're using the [Autopilot Pattern implementation of MySQL](https://www.joyent.com/blog/dbaas-simplicity-no-lock-in) for automatic backups and self-clustering so that we can deploy and scale easily
- [HyperDB](https://wordpress.org/plugins/hyperdb/): an "advanced database class that replaces a few of the WordPress built-in database functions" to support the MySQL cluster that's necessary for scaling WordPress; everything is automatically configured so running a scalable WordPress site is no more complex than running without the scaling features
- [Memcached](https://github.com/autpilotpattern/memcached/): improves performance by keeping frequently accessed data in memory so WordPress doesn't have to query the database for every request; the images include [tollmanz's Memcached plugin](https://github.com/tollmanz/wordpress-pecl-memcached-object-cache) pre-installed, and ContainerPilot automatically configures it as we scale
- [Nginx](https://github.com/autopilotpattern/nginx): the front-end load balancer for the WordPress environment; passes traffic from users to the WordPress containers on the back-end
- [NFS](https://github.com/autpilotpattern/nfsserver/): stores user uploaded files so these files can be shared between many WordPress containers
- [Consul](https://www.consul.io/): used to coordinate replication and failover
- [Manta](https://www.joyent.com/object-storage): the Joyent object store, for securely and durably storing our MySQL snapshots
- [Prometheus](https://github.com/autopilotpattern/prometheus): an optional, [open source monitoring tool](https://prometheus.io) that tracks the performance of each component and demonstrates [ContainerPilot telemetry](https://www.joyent.com/blog/containerpilot-telemetry)
- [WP-CLI](http://wp-cli.org/): to make managing WordPress easier

### How do I use this thing?

Pick the answer that fits:

1. For the hello world experience: follow the directions below for configuration, then `docker-compose up -d` and you're done.
1. For building your own WordPress in Docker: clone this repository and place the WordPress theme you want to use into the `var/www/html/content/themes` directory. Develop locally using the `local-compose.yml` file, then build your Docker image and run those in the cloud with your own `docker-compose.yml` file that specifies your custom image.

The instructions below will get you set up to run containers on [Triton](https://www.joyent.com/), or anywhere that supports the Autopilot Pattern.

### Getting started on Triton

1. [Get a Joyent account](https://my.joyent.com/landing/signup/) and [add your SSH key](https://docs.joyent.com/public-cloud/getting-started).
1. Install the [Docker Toolbox](http://docker.com/toolbox) (including `docker` and `docker-compose`) on your laptop or other environment, as well as the [Joyent Triton CLI](https://www.joyent.com/blog/introducing-the-triton-command-line-tool)
1. [Configure Docker and Docker Compose for use with Joyent](https://docs.joyent.com/public-cloud/api-access/docker):

```bash
curl -O https://raw.githubusercontent.com/joyent/sdc-docker/master/tools/sdc-docker-setup.sh && chmod +x sdc-docker-setup.sh
./sdc-docker-setup.sh -k us-east-1.api.joyent.com <ACCOUNT> ~/.ssh/<PRIVATE_KEY_FILE>
```

### Configure your environment

Check that everything is configured correctly by running `./setup.sh`. You'll need an SSH key that has access to Manta, the object store where the MySQL backups are stored. Pass the path of that SSH key as `./setup.sh ~/path/to/MANTA_SSH_KEY`. The script will create an `_env` file that names the variables that you will need to run your WordPress environment.

#### Manta settings

The script will set defaults for almost every config variable, but the Manta config is required and must be set manually. The two most important variables there are:

```
MANTA_BUCKET= # an existing Manta bucket
MANTA_USER= # a user with access to that bucket
```

The MySQL container will take a backup during its `preStart` handler and periodically while running. Configure these Manta settings to specify how and where this backup is stored. Here you need to specify the `MANTA_USER`, and also the `MANTA_BUCKET` where the backups will be stored.

#### WordPress configuration

The setup script will set working defaults for the entire WordPress configuration. The defaults will work for a quick "hello world" experience, but you'll probably want to set your own values for many fields.

```
# Environment variables for for WordPress site
WORDPRESS_URL=http://my-site.example.org/
WORDPRESS_SITE_TITLE=My Blog
WORDPRESS_ADMIN_EMAIL=user@example.net
WORDPRESS_ADMIN_USER=admin
WORDPRESS_ADMIN_PASSWORD=<random string>
WORDPRESS_ACTIVE_THEME=twentysixteen
WORDPRESS_CACHE_KEY_SALT=<random string>
#WORDPRESS_TEST_DATA=true # uncomment to import a collection of test content on start
```

This block is the typical information you must provide when installing WordPress. The URL of the site, the site title and admin user information are all straightforward. `WORDPRESS_ACTIVE_THEME` is the theme that will be activated automatically when the container starts. This will typically be theme that you are developing in this repo, or one of the default themes. `WORDPRESS_CACHE_KEY_SALT` should be set to a unique string, the object caching in WordPress will use this salt to determine the cache keys for information it sets on the Memcached container.

If you are not bringing your own theme in this repo, you can choose from these default themes for the `WORDPRESS_ACTIVE_THEME` variable:

- `twentyfifteen`
- `twentyfourteen`
- `twentysixteen`

The script will set a `WORDPRESS_URL` value for Triton users using [Container Name Service](https://www.joyent.com/blog/introducing-triton-container-name-service) that will make it easy to test the containers without setting any DNS information. You can [`CNAME` your site DNS](https://www.joyent.com/blog/introducing-triton-container-name-service#example-global-dns) to that to make it easy to scale and replace the Nginx containers at the front of your site without ever needing to update the DNS configuration.

Setting `WORDPRESS_TEST_DATA` will download the [manovotny/wptest](https://github.com/manovotny/wptest) content library when the WordPress container starts.

#### MySQL settings

The setup script will set default values for the MySQL configuration, including randomly generated passwords.

```
# Environment variables for MySQL service
# WordPress database/WPDB information
MYSQL_USER=wpdbuser
MYSQL_PASSWORD=<random string>
MYSQL_DATABASE=wp
# MySQL replication user, should be different from above
MYSQL_REPL_USER=repluser
MYSQL_REPL_PASSWORD=<random string>
```

These values will be automatically set in the `wp-config.php`. The last two options are used by the Autopilot Pattern MySQL container to set up its replication when scaled up to more than a single container. You can keep `repluser`, but set a unique password for your environment.

#### WordPress unique salts

As with most of the other configuration blocks, the setup script will set reasonable defaults for these values.

```
# Wordpress security salts
# These must be unique for your install to ensure the security of the site
WORDPRESS_AUTH_KEY=<random string>
WORDPRESS_SECURE_AUTH_KEY=<random string>
WORDPRESS_LOGGED_IN_KEY=<random string>
WORDPRESS_NONCE_KEY=<random string>
WORDPRESS_AUTH_SALT=<random string>
WORDPRESS_SECURE_AUTH_SALT=<random string>
WORDPRESS_LOGGED_IN_SALT=<random string>
WORDPRESS_NONCE_SALT=<random string>
```

These variables are how WordPress secures your logins and other secret info. These should be unique for your site. You can set your own values, or use [this WordPress tool](https://api.wordpress.org/secret-key/1.1/salt/) to generate a new set of random values.

#### Consul

Finally we need to configure an environment variable with the location of our Consul service. The setup script will pre-set this for Triton users.

```
CONSUL=<IP or DNS to Consul>
```

For local development, we use Docker links and simply set this to `CONSUL=consul`, but on Triton we use [Container Name Service](https://www.joyent.com/blog/introducing-triton-container-name-service) so that we can have a raft of Consul instances operating as a highly available service ([see example](https://www.joyent.com/blog/introducing-triton-container-name-service#example-consul-bootstrapping)).

### A note on Nginx

This project also builds it's own Nginx container that is based on the [AutoPilot Pattern Nginx](https://github.com/autopilotpattern/nginx). We build a custom Nginx container to more easily inject our custom configurations. The configs located in the `/nginx` directory should work well for most use cases of this project, but they can be customized and baked into the Nginx image if the need arises.

### Start the containers!

After configuring everything, we are now ready to start the containers. To do that simply execute `docker-compose up -d` to spin everything up on Triton. Open your browser to the `WORDPRESS_URL` and enjoy your new site!

For local development, use `docker-compose -f local-compose.yml up -d`.

### Going big

To scale, use `docker-compose scale...`. For example, the following will set the scale of the WordPress, Memcached, Nginx, and MySQL services to three instances each:

```bash
docker-compose scale wordpress=3 memcached=3 nginx=3 mysql=3
```

If there are few instances running for any of those services, more will be added to meet the specified count. As you scale, the application will automatically reconfigure itself so that everything is connected. All the Nginx instances will connect to all the WordPress instances, and those will connect to all the Memcached and MySQL instances. If an instance should unexpectedly crash, the other instances will automatically reconfigure to re-route requests around the failed instance.

To scale back down, simply run `docker-compose scale...` and specify a smaller number of instances.

### Compatibility

This project has been fully tested and documented to run in Docker in local development environments and on [Joyent Triton](https://www.joyent.com), however it has been demonstrated on, or is believe compatible with container environments including:

- [Mantl](http://mantl.io)
- [DC/OS](https://dcos.io)
- [Docker Swarm](https://www.docker.com/products/docker-swarm)
- [Kubernetes](http://kubernetes.io)
- Others

### Contributing

- Please [report bugs in Github](https://github.com/autopilotpattern/wordpress/issues) (and check the bug list for known bugs)
- It's open source, [pull requests welcome](https://github.com/autopilotpattern/wordpress/pulls)!

### Sponsors

Initial development of this project was sponsored by [Joyent](https://www.joyent.com) and [10up](http://10up.com).

### Building

This image implements [microbadger.com](https://microbadger.com/#/labels) label schema, but those labels require additional build args:

```
docker build --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
               --build-arg VCS_REF=`git rev-parse --short HEAD` .
```