# syntax = docker/dockerfile:1

##################################################################################
#                           Carebility Devcontainer
##################################################################################
# Thin consumer image: all toolchain + dependency content lives in the shared
# base image and in runtime bind mounts / named volumes. No build stage, no
# workspace bake (the ..:/workspace bind mount in docker-compose.yml shadows it
# at runtime anyway). See docs/projects/devcontainer-image-optimization.

FROM ghcr.io/carebility/carebility-devcontainer:latest

ENV DEVCONTAINER_APP=keycloak-admin-ruby
