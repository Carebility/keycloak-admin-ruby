FROM ruby:3.2.2-slim-bullseye

# eMudhra intermediate-CA compromise (CVE-2026-91403,
# https://emudhra.we-have-a-problem.com/): Debian 11 has no patched
# ca-certificates (the bullseye-security package no longer downloads), so apply
# the documented distrust of the two affected roots directly and fail the build
# if either is still in the bundle OpenSSL parses. Runs before anything is
# fetched over HTTPS.
RUN set -eu; \
    sed -i -e 's|^mozilla/emSign_ECC_Root_CA_-_G3.crt|!&|' \
           -e 's|^mozilla/Comodo_AAA_Services_root.crt|!&|' /etc/ca-certificates.conf; \
    update-ca-certificates; \
    awk '/-----BEGIN CERTIFICATE-----/{c="openssl x509 -noout -fingerprint -sha256";p=1} p{print | c} /-----END CERTIFICATE-----/{close(c);p=0}' /etc/ssl/certs/ca-certificates.crt | cut -d= -f2 | tr -d ':' | tr 'A-F' 'a-f' > /tmp/fingerprints; \
    certs="$(grep -c -- '-----BEGIN CERTIFICATE-----' /etc/ssl/certs/ca-certificates.crt)"; \
    [ "$certs" -gt 100 ]; \
    [ "$(wc -l < /tmp/fingerprints)" -eq "$certs" ]; \
    if grep -E '86a1ecba089c4a8d3bbe2734c612ba341d813e043cf9e8a862cd5c57a36bbe6b|d7a7a0fb5d7e2731d771e9484ebcdef71d5f0c3e0a2948782bc83ee0ea699ef4' /tmp/fingerprints; then \
      echo 'emSign ECC Root CA - G3 or Comodo AAA root is still trusted' >&2; exit 1; \
    fi; \
    rm -f /tmp/fingerprints

RUN apt-get update -qq && apt-get install -y build-essential git ruby-dev && apt-get clean && \
  mkdir -p /usr/src/app/lib/keycloak-admin
WORKDIR /usr/src/app

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/
COPY keycloak-admin.gemspec /usr/src/app/
COPY lib/keycloak-admin/version.rb /usr/src/app/lib/keycloak-admin/
RUN bundle install
COPY . /usr/src/app
RUN bundle install