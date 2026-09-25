# SHERIN Azure UAE North VNet

Status: Succeeded
Region: UAE North (`uaenorth`)
Resource group: `shf-cloud-rg`
Virtual network: `shf-vnet`
Address space: `10.0.0.0/16`

Subnets:
- `sherin-app-subnet`: `10.0.1.0/24`
- `private-endpoints`: `10.0.2.0/24`

Initial optional services disabled:
- Azure Firewall
- Azure Bastion
- DDoS Protection
- NAT Gateway
- IPv6
- Azure Network Manager
- Extended Location

The deployment was confirmed successful in Azure Portal in UAE North. This document does not claim that this is the first customer VNet ever created in UAE North; Azure does not expose a public directory of all customer VNets.
