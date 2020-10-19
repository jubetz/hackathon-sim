# Cumulus Linux Demo Environment

[![Pipeline](https://gitlab.com/cumulus-consulting/goldenturtle/cldemo2/badges/master/pipeline.svg)](https://gitlab.com/cumulus-consulting/goldenturtle/cldemo2/pipelines)
[![License](https://img.shields.io/badge/License-Apache%202.0-83389B.svg)](https://opensource.org/licenses/Apache-2.0)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![Slack Status](https://img.shields.io/badge/Slack-2800+-F1446F)](https://slack.cumulusnetworks.com)
[![Code of Conduct](https://img.shields.io/badge/Contributing-Code%20of%20Conduct-1EB5BD)](https://docs.cumulusnetworks.com/contributor-guide/#contributor-covenant-code-of-conduct)

<img src="https://www.ansible.com/hubfs/2016_Images/Assets/Ansible-Mark-Large-RGB-BlackOutline.png" height="150" title="Ansible" align="right" /> 
<img src="https://gitlab.com/cumulus-consulting/goldenturtle/cldemo2/-/raw/master/documentation/images/cumulus-logo.svg" height="150" title="Cumulus Networks" align="right" /> 

The Cumulus Networks `cldemo2` environment provides a spine and leaf network, out of band management and Cumulus NetQ server. 
This is used as the basis for all Cumulus Network demo environments. 

- [Cumulus Linux Demo Environment](#cumulus-linux-demo-environment)
  * [The Topology](#the-topology)
    + [Devices](#devices)
    + [The Connectivity](#the-connectivity)
    + [Out of Band Management](#out-of-band-management)
    + [NetQ Virtual Appliance](#netq-virtual-appliance)
  * [Understanding the file structure](#understanding-the-file-structure)
    + [ci-common](#ci-common)
    + [tests](#tests)
    + [simulation](#simulation)
  * [Running the Environment](#running-the-environment)
  * [Additional Demos](#additional-demos)


<br /><br/>

## The Topology

<img src="https://gitlab.com/cumulus-consulting/goldenturtle/cldemo2/-/raw/master/documentation/diagrams/cldemo2-diagram.svg" title="Network Topology" />

### Devices

The cldemo2 topology consists of the following devices:

- 4x Cumulus Linux 3.7 spines
- 2x Cumulus Linux 3.7 leafs
- 8x Ubuntu 18.04 servers
- 2x Cumulus Linux 3.7 border leafs
- 2x Cumulus Linux 3.7 "fw" devices providing inter-VRF connectivity
- 1x Ubuntu 18.04 out of band management server (`oob-mgmt-server`)
- 1x Cumulus Linux 3.7 out of band management switch (`oob-mgmt-sw`)
- 1x Cumulus NetQ 2.4 virtual appliance (`netq-ts`)

### The Connectivity

The network is connected as a spine and leaf with every leaf connected to every spine and no inter-spine connections.
Every server is connected to exactly two leaf or border switches.
All devices have their `eth0` interface connected to the out of band management switch.

### Out of Band Management

The out of band management server provides the following services:

- Out of band DHCP server
- Out of band web server (for zero touch provisioning) 
- External connectivity

The out of band management server is intended to be the point of entry for access into the environment. It connects the external world with the internal management network.

The out of band management switch is a simple layer 2 bridge with all ports in a single default vlan.

### NetQ Virtual Appliance

[Cumulus NetQ](https://cumulusnetworks.com/products/netq/) is a streaming telemetry and network operations tool. 
The zero-touch provisioning service on the `oob-mgmt-server` installs the NetQ agent on all devices at first boot.

Booting and using the NetQ appliance as part of the simulation is option.
However, NetQ is mandatory for testing or building CI for cldemo2.

## Understanding the file structure

### ci-common

`ci-common` is a collection of scripts used to build, teardown or cleanup for CI automation runs. This code is used across multiple demos, even if their individual tests are different.

### tests

`tests` contain the collection of CI tests to be run to validate this environment. This directory will be different for each demo.

### simulation

`simulation` defines the Vagrant + Libvirt configurations that allow this network to be stood up on any device with KVM, Libvirt and Vagrant.
Within the simulation folder lives the following additional files and directories

- `helper_scripts` - this is a collection of scripts to help bootstrap and initialize the simulation environment at first boot.
- `templates` - a set of templates used by Cumulus Networks [Topology Converter](https://gitlab.com/cumulus-consulting/tools/topology_converter) to generate an out of band management network.
- `Vagrantfile` - defines the connectivity and settings of all of the VMs in the simulation
- `cldemo2.dot` - is the dot file used to render the Vagrantfile. This is also the file used by PTM to validate the cabling. 

## Running the Environment

To run cldemo2 you can use the free [Cumulus in the Cloud](https://cumulusnetworks.com/citc) service and no configuration is required. 

Alternatively you may clone this repository to a server with KVM, libvirt and Vagrant and run it locally.
1) Clone the repo `git clone https://gitlab.com/cumulus-consulting/goldenturtle/cldemo2.git`
2) `cd cldemo2/simulation`  
**Note**: KVM will stand up all devices in parallel when `vagrant up` is used. It is important to stand up the out of band management devices (`oob-mgmt-server` and `oob-mgmt-switch` first to allow them to boot so they may provide DHCP addresses to other devices when they boot.
3) Stand up the environment with `vagrant up oob-mgmt-server oob-mgmt-switch && vagrant up /leaf/ /spine/ /server0/ /border/ /fw/` 
4) Once completed, ssh to the `oob-mgmt-server` to access the rest of the devices.  
**Note**: Only the `oob-mgmt-server` has external connectivity. `vagrant ssh` will not work to any other device.

The NetQ appliance is not required for this environment. If you have access to the NetQ cloud service and the required resources, you can provision the NetQ appliance with the following steps:

1) Download the NetQ Cloud OPTA vagrant box for libvirt provider
2) Add the image to vagrant `vagrant box add <path-to-box> --name="cumulus/tscloud"`
3) Clone the repo `git clone https://gitlab.com/cumulus-consulting/goldenturtle/cldemo2.git`
4) `cd cldemo2/simulation`
5) `vagrant up oob-mgmt-server oob-mgmt-switch && vagrant up`
6) `vagrant ssh oob-mgmt-server`
7) Provision the NetQ Cloud OPTA with config-key

## Additional Demos

This is the basis for additional Cumulus Networks demos. At this time the following demos are fully supported and available

- [EVPN Layer 2 Only](https://gitlab.com/cumulus-consulting/goldenturtle/dc_configs_vxlan_evpnl2only) - An EVPN-VXLAN environment with only layer 2 extension.
- [EVPN Centralized Routing](https://gitlab.com/cumulus-consulting/goldenturtle/dc_configs_vxlan_evpncent) - A EVPN-VXLAN environment with layer 2 extension between tenants with inter-tenant routing on a centralized (`fw`) device.
- [EVPN Symmetric Mode](https://gitlab.com/cumulus-consulting/goldenturtle/dc_configs_vxlan_evpnsym) - An EVPN-VXLAN environment with layer 2 extension, layer 3 VXLAN routing and VRFs for multi-tenancy.
