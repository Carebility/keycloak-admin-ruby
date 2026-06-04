# syntax = docker/dockerfile:1

##################################################################################
#                                 Base Image
##################################################################################

FROM ghcr.io/carebility/carebility-devcontainer:latest as base

ENV DEVCONTAINER_APP=keycloak-admin-ruby
##################################################################################
#                                 Build Image
##################################################################################
# We have a middle build stage to help reduce size of final image
FROM base AS build

USER root

# Copy application code
COPY --link . .

##################################################################################
#                                 Final Image
##################################################################################
FROM base

# Copy built dependencies from build stage
COPY --from=build --chown=$USERNAME:$USERNAME /workspace /workspace
