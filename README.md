# Keycloak in Pot

This repository contains a script to create a [Pot](https://github.com/bsdpot/pot)
that will run keycloak on FreeBSD.

## Usage

- You need a Postgres database. You can get one as a pot as well!
```sh
git clone https://github.com/jomy10/postgres-pot
cd postgres-pot
sh pot_build.sh <postgres-password>
```

- Start postgres
```sh
pot start postgres
```

- Now build the Keycloak pot. This will also initialize the database
```sh
sh pot_build.sh <hostname> <postgres-password>
```
**NOTE** *hostname should include protocol (https)*

- Now you can run Keycloak on FreeBSD!
```sh
pot start keycloak
```

## Stopping keycloak

```sh
pot exec -p keycloak service keycloak stop
pot stop keycloak
```

## Troubleshooting

If the pot starts succesfully, but you can't access keycloak, you can look at the logs:
```sh
pot term keycloak
tail -f /var/log/keycloak/keycloak.out
```

