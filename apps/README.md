### The Apps Cookbook

This is the apps cookbook. The idea here is to use definitions to lay out how all apps of a certain type are deployed. So all apps of the same type get deployed the same way. All apps are deployed to use runit and even setup iptables rules. These definitions make use of databags to store installation and configuration data. Each app is expected to have a databag item in a databag called "apps", the databag item name and app name are expected to be the same. The definition will pull the databag item for an app and deploy it using that data. Additionally the definition can accept an app_options parameter which can be used for config data not stored in a databag, generally this would be based on search or something dynamically determined at chef-client run time. This cookbook includes an example erlang, jvm and ruby recipe and files. The following databag item should work with it. Note that jvm and erlang applications ues "fat" jars and tarballs while ruby uses git.

### Databag Item Example

#### erlang

    {
        "config": {
            "host": "localhost",
            "port": 55555
        },
        "system": {
            "group": "example",
            "gid": 400,
            "uid": 400,
            "home": "/home/example",
            "user": "example"
        },
        "install": {
            "repo_url": "http://somehost/builds",
            "path": "/opt/example"
        },
        "id": "example",
        "version": "0.1",
        "type": "erlang",
        "erlang": {
            "max_ports": 4096,
            "kernel_polling": true,
            "async_threads": 5,
            "cookie": "oatmealrasin",
            "fullsweep_after": 10
        }
    }

#### jvm

    {
      "dependencies": {
        "recipes": [
        ]
      },
      "jvm": {
        "class": "com.yourcompany.dosomething",
        "opts": "-XX:+AggressiveOpts",
        "gc_opts": "-Xms1G -Xmx1G"
      },
      "config": {
        "additional_config_templates": [
        ],
        "example": {
          "client_port": 2181,
          "data_dir": "/srv/data"
        },
        "ulimit": {
          "n": 2000
        },
        "additional_directories": [
          "/srv/something/data"
        ]
      },
      "system": {
        "group": "example",
        "gid": 406,
        "uid": 406,
        "home": "/home/example",
        "user": "example"
      },
      "id": "example",
      "checksum": "jarchecksum",
      "install": {
        "repo_url": "http://somehost/builds",
        "path": "/opt/example"
      },
      "type": "jvm",
      "version": "0.1"
    }

#### ruby

    {
      "dependencies": {
        "system": [
        ],
        "recipes": [
        ],
        "gems": {
          "thin": "latest",
          "json": "latest"
        }
      },
      "config": {
        "port": 4100,
        "database": {
          "port": 3306,
          "username": "example",
          "type": "mysql",
          "database": "example",
          "hostname": "host",
          "password": "example"
        },
        "git": {
          "repository": "git@github.com:something/repo.git"
          "reference": "HEAD"
        },
        "environment": "production",
        "key": {
          "public": "pub",
          "private": "private"
        },
        "additional_directories": [
        ]
      },
      "system": {
        "group": "example",
        "gid": 431,
        "uid": 431,
        "home": "/home/example",
        "user": "example"
      },
      "id": "example",
      "install": {
        "path": "/opt/example"
      },
      "type": "ruby"
    }


The definition expects a certain databag layout, above is an example. 

#### "config"

The 'config' hash can store any config data you would like to use in templates and etc. A vm.args and a NAME.config file are expected by the erlang_app definition, the latter needs to be supplied by you and can use any data in the databag or app_options you would like. Within the config hash there can be a special key called "additional_config_templates" this is a list of any other config templates that need to be applied when the definition is run, these also have access to the databag and app_options data. Another special case is the "iptables" field which is expected to be a boolean. If set to true the definition will apply a template named "iptables_rules.erb" via the iptables cookbook.

#### "system"

This hash is currently only used by the definition for setting up a system level user.

#### "install"

Here you specify the http location of the app builds (one directory above "releases" and "upgrades" directories, where you store your release and upgrade tarballs) as well as the filesystem path of where you want your release installed.

#### "id"

This is the name of the databag and app.

#### "version"

For erlang deploys this is the version set in your reltool.config.

#### "type"

The type of application you are deploying.

#### "erlang", "jvm" and "ruby"

This has contains details specific to the type of app you are deploying, generally it contains VM configuration and start up options.

### Templates

The definition expects certain templates to be in place and also has some default ones it will use for all apps of the same type. Each app needs to have it's own templates under "templates/default/{type}/{appname}". For erlang apps it expects 'config.erb' and "{appname}.erb", the latter being the script used to start the app via runit. Also it uses the standard vm.args at "templates/default/erlang/vm.args". Standard runit templates are also used for apps of all types.