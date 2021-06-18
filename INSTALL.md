# Running BAHC Ohana API on your computer

## Clone this bad boy

Clone it on your computer and navigate to the project's directory:

    git clone git@github.com:bchd/bahc-ohana-api.git && cd bchd-ohana-api

## Elasticsearch Setup

- Install right version of ElasticSearch 
    
    [Elasticsearch 5.6 download](https://www.elastic.co/downloads/past-releases/elasticsearch-5-6-0)

- Download it and unzip it 

- Go to the elastic search directory using terminal and type the following command:
        
        $ bin/elasticsearch

- Go to: [http://localhost:9200](http://localhost:9200) and check that is running and the version is 5.6

## Local Setup

Before you can run Ohana API, you'll need to have the following software
packages installed on your computer: Git, PhantomJS, Postgres, Ruby 2.3+,
and RVM (or rbenv).
If you're on a Linux machine, you'll also need Node.js and `libpq-dev`.

If you don't already have all the prerequisites installed, there are two ways
you can install them:

- If you're on a Mac, the easiest way to install all the tools is to use
@monfresh's [laptop] script.

- Install everything manually: [Build tools], [Ruby with RVM], [PhantomJS],
[Postgres], and [Node.js][node] (Linux only).

[laptop]: https://github.com/monfresh/laptop
[Build tools]: https://github.com/codeforamerica/howto/blob/master/Build-Tools.md
[Ruby with RVM]: https://github.com/codeforamerica/howto/blob/master/Ruby.md
[PhantomJS]: https://github.com/jonleighton/poltergeist#installing-phantomjs
[Postgres]: https://github.com/codeforamerica/howto/blob/master/PostgreSQL.md
[node]: https://github.com/codeforamerica/howto/blob/master/Node.js.md

### PostgreSQL Accounts

On Linux, PostgreSQL authentication can be [set to _Trust_](http://www.postgresql.org/docs/9.1/static/auth-methods.html#AUTH-TRUST) [in `pg_hba.conf`](https://wiki.postgresql.org/wiki/Client_Authentication) for ease of installation. Create a user that can create new databases, whose name matches the logged-in user account:

    $ sudo -u postgres createuser --createdb --no-superuser --no-createrole `whoami`

On a Mac with Postgres.app or a Homebrew Postgres installation, this setup is
provided by default.

### Install the dependencies and populate the database with sample data:

    bin/setup

_Note: Installation and preparation can take several minutes to complete!_

### Load data from a dump file

    $ pg_restore --verbose --clean --no-acl --no-owner -h localhost -d ohana_api_development latest.dump

_Note: Make sure you put the full path to where your dump file is located_
### Reset Chewy (recreate indexes on Elasticsearch)

    rake chewy:reset

_Note: you have to make sure that Elasticsearch is up and running_
### Run the app

    ./start-rails.sh

### Data Admin page

Visit: 
    [http://localhost:8080/admin](http://localhost:8080/admin)

    email: masteradmin@ohanapi.org
    password: ohanatest

### Verify the app is returning JSON

[http://localhost:8080/api/locations](http://localhost:8080/api/locations)

[http://localhost:8080/api/search?keyword=food](http://localhost:8080/api/search?keyword=food)

We recommend the [JSONView][jsonview] Google Chrome extension for formatting
the JSON response so it is easier to read in the browser.

[jsonview]: https://chrome.google.com/webstore/detail/jsonview/chklaanhfefbnpoihckbnefhakgolnmc

## Set up the environment variables & customizable settings

#### Configure environment variables
Inside the `config` folder, you will find a file named `application.yml`.
Read through it to learn how to customize it to suit your needs.

#### Adjust customizable settings
Inside the `config` folder, you will also find a file called `settings.yml`.
In that file, there are many settings you can, and should, customize.
Read through the documentation to learn how you can customize the app to suit
your needs.

To customize the text the appears throughout the website
(such as error messages, titles, labels, branding), edit `config/locales/en.yml`.
You can also translate the text by copying and pasting the contents of `en.yml`
into a new locale for your language. Find out how in the
[Rails Internationalization Guide](http://guides.rubyonrails.org/i18n.html).

## Uploading and validating your own data

- [Prepare your data][prepare] in a format compatible with Ohana API.

- Place your CSV files in the `data` folder.

- From the command line, run `script/reset` to reset the database.

- Run `script/import` to import your CSV files, but first read the notes below.

If your Location entries don't already include a latitude and longitude, the
script will geocode them for you, but this can cause the script to fail with
`Geocoder::OverQueryLimitError`. If you get that error, set a sleep time to
slow down the script:
```
script/import 0.2
```

Alternatively, cache requests and/or use a different geocoding service that
allows more requests per second. See the [geocoding configuration][geocode]
section in the Wiki for more details.

If any entries contain invalid data, the script will output the CSV row
containing the error(s):
```
Importing your organizations...
Line 2: Organization name can't be blank.
```

Open the CSV file containing the error, fix it, save it to the `data` folder,
then run `script/import`. Repeat until your data is error-free.

[prepare]:https://github.com/codeforamerica/ohana-api/wiki/Populating-the-Postgres-database-from-the-Human-Services-Data-Specification-%28HSDS%29-compliant-CSV-files
[geocode]: https://github.com/codeforamerica/ohana-api/wiki/Customizing-the-geocoding-configuration

### Export the database

Once your data is clean, it's a good idea to save a copy of it to make it easy
and much faster to import, whether on your local machine, or on Heroku.
Run this command to export the database:

```
script/export_prod_db
```
This will create a filed called `ohana_api_production.dump` in the data folder.
This will also automatically remove all test users and admins before the export.

### Import the database locally

To restore your local database from your clean data:
```
script/restore_prod_db
```

### User and Admin authentication (for the developer portal and admin interface)

To access the developer portal, visit [http://localhost:8080/](http://localhost:8080/).

To access the admin interface, visit [http://localhost:8080/admin/](http://localhost:8080/admin/).

The app automatically sets up users and admins you can sign in with.
Their username and password are stored in [db/seeds.rb][seeds].

If you deleted these test users and admins (by running `script/export_prod_db`
for example), you can restore them by running `script/users`.

[seeds]: https://github.com/codeforamerica/ohana-api/blob/master/db/seeds.rb

The third admin in the seeds file is automatically set as a Super Admin. If you
would like to set additional admins as super admins, you will need to do it
manually for security reasons.

#### Setting an admin as a Super Admin

##### Locally:

    psql ohana_api_development
    UPDATE "admins" SET super_admin = true WHERE email = 'masteradmin@ohanapi.org';
    \q

Replace `masteradmin@ohanapi.org` in the command above with the email of the
admin you want to set as a super admin.

##### On Heroku:
Follow the same steps above, but replace `psql ohana_api_development` with
`heroku pg:psql -a your-heroku-app-name`.

## Docker Setup (recommended for Windows users)

1. Download, install, and launch [Docker]

1. Set up the Docker image and start the app:

        $ script/bootstrap

1. Set up the test users:

        $ script/users

Once the docker images are up and running, the app will be accessible at
[http://localhost:8080](http://localhost:8080).

### Verify the app is returning JSON

[http://localhost:8080/api/locations](http://localhost:8080/api/locations)

[http://localhost:8080/api/search?keyword=food](http://localhost:8080/api/search?keyword=food)

We recommend the [JSONView][jsonview] Google Chrome extension for formatting
the JSON response so it is easier to read in the browser.

[jsonview]: https://chrome.google.com/webstore/detail/jsonview/chklaanhfefbnpoihckbnefhakgolnmc

### More useful Docker commands

* Stop this running container: `docker-compose stop`
* Stop and delete the containers: `docker-compose down`
* Open a shell in the web container: `docker-compose run --rm web bash`

[Docker]: https://docs.docker.com/engine/installation/

# Troubleshooting

### Error: Using wrong ruby version: 

- Make sure to have asdf installed and run the following commands:

    $ asdf install ruby 2.5.3
    
    $ asdf global ruby 2.5.3

- Make sure that the right version is being used now:

    $ asdf current

### Error: Bundle install failing:
    $gem update --system
_Note: [reference here](https://bundler.io/blog/2019/05/14/solutions-for-cant-find-gem-bundler-with-executable-bundle.html)_

### Error: Could not install Yarn
    $yarn install --ignore-engines

### Error: Missing Required Configuration Keys
- You should be missing configuration definitions on your file: 
    
    /config/application.yml

_Note: you might have to ask a colleage for a fresh copy_
