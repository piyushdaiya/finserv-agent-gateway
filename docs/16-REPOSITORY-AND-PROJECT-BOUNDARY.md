# Repository and Project Boundary

## Repository authority

`finserv-agent-gateway` is an independent product repository.

Its architecture must be understandable and implementable without reading any other private project repository.

## External projects

Other repositories may provide:

- design inspiration;
- future adapters;
- future workflow packs;
- compatibility fixtures;
- independent test environments.

They do not become product dependencies unless an explicit ADR and dependency contract adds them.

## Prohibited implicit coupling

Do not make core code depend on:

- another project's internal Go/Rust/Python packages;
- another project's private database schema;
- another project's hostnames/ports;
- another project's authentication credentials;
- another project's model-routing assumptions;
- another project's engineering workflow or task runner.

## Engineering-system independence

The product repository contains product design, source code, tests, release engineering, and product-facing operational documentation. It does not document or depend on the internal mechanics of whichever external engineering system happens to generate or modify that source code.

## Future workflow repositories

A workflow pack may live:

- in this repository under `workflow-packs/` if open and generally reusable; or
- in a separate repository if customer-specific, licensed, or independently versioned.

In either case it consumes the public workflow-pack/adapter contract rather than privileged core internals.
