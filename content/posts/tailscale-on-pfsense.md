---
title: "Using Tailscale in pfSense to access my LAN"
date: 2025-04-21T11:47:02+02:00
tags: ["Tailscale", "pfSense", "Homelab", "VPN", "Networking"]
showToc: true
TocOpen: false
---

{{< dynamic-image light="/img/tailscale-pfsense-header-light.png" dark="/img/tailscale-pfsense-header-dark.png" alt="Tailscale + pfSense" >}}

In this post we're going to explore how to set up **Tailscale** in **pfSense** to be able to both route all traffic through pfSense for secure browsing and how to route traffic to local subnets with split DNS to resolve local hostnames.


## My history with VPNs

I've had a [pfSense](https://www.pfsense.org/) box now for a few years and been relying on its [OpenVPN](https://en.wikipedia.org/wiki/OpenVPN) integration to access my internal network from the outside. This has been working fine, but a few years ago I stumbled upon [ZeroTier](https://www.zerotier.com/) which is a kind of VPN service that via [UDP hole punching](https://en.wikipedia.org/wiki/UDP_hole_punching) can create a flat and global network without the need to open ports. This technology is called [Software-Defined Wide Area Network (SD-WAN)](https://en.wikipedia.org/wiki/SD-WAN). I could now use ZeroTier to access firewalled devices without opening any ports!

But even with good things there can be **drawbacks**:

- OpenVPN
  - A VPN server per LAN is required
  - Some setup is required with certificate distribution
- ZeroTier
  - All of the devices need to have the ZeroTier service running
  - No official pfSense package


## Entering Tailscale

[Tailscale](https://tailscale.com/) is a service that is very similar to ZeroTier. It enables a point-to-point network by combining UDP hole punching and the [WireGuard](https://www.wireguard.com/) protocol. Using Tailscale I can connect to all of my devices and servers together in a Tailscale network (or [tailnet](https://tailscale.com/kb/1136/tailnet)) as if they were on the same LAN.

Another major upside is that an official package exist for pfSense which enables a remote Tailscale device to access hosts on a local subnet behind the pfSense firewall.


## Setting up Tailscale in pfSense

### Prerequisites

- A Tailscale account
- A pfSense firewall

### Installation and initial setup

#### Installing package

Make sure that the `Tailscale` package in pfSense is installed. To do this, navigate to *System > Package Manager > Available Packages* and find the `Tailscale` package in the list.

After installation a new *Tailscale* item should appear under the *VPN* menu.


#### Adding pfSense to our tailnet

To add pfSense to our tailnet we need to create an authentication key.

1. Navigate to the [keys settings at Tailscale's backend](https://login.tailscale.com/admin/settings/keys)
2. Click *Generate auth key...*
3. Use default settings and click *Generate key*. This key is only used for authentication, and will thus be very short lived.
4. Make sure to take a copy the key

Now to back in pfSense...

1. Navigate to *VPN > Tailscale > Authentication*
2. Paste the newly generated auth key in *Pre-authentication Key*
3. Click *Save*
4. Navigate to *Settings*
5. Check *Enable Tailscale*
6. Scroll down and click *Save*

To grant pfSense access to our tailnet we need to approve the device. It's also a good idea to disable the key expiration for this device since the device is trusted and we don't want it to expire.

1. Navigate to [*Tailscale backend > Machines*](https://login.tailscale.com/admin/machines)
2. Click the three dots on the new device and click
    - *Approve*
    - *Disable key expiry*

pfSense is now a part of the tailnet!


### Enabling Exit Node

To let other devices on our tailnet to route traffic as they were on the pfSense's LAN, we need to advertise it as an exit node.

1. In the pfSense, navigate to *VPN > Tailscale > Settings > Routing*
2. Check *Advertise Exit Node*
3. Click *Save*
4. In the Tailscale backend, click the three dots by the pfSense machine and click *Edit route settings...*
5. Check *Use as exit node*

Now any other device on the tailnet can route their traffic through pfSense by selecting pfSense in their *Use exit node* menu.


### Subnet routing

For a remote device on the tailnet to be able access **any** host on a subnet behind pfSense, even those that are not on the tailnet, we can enable subnet routing.
What subnet routing practically does is that if tailnet node *A* sends traffic to an IP address on a subnet that tailnet node *B* is set up to route to, that traffic will be routed *through* node *B* to its local subnet making *A* reach the non-Tailscale device.

Here we need to decide what subnet to route to, in this example my LAN is `192.168.0.0/24`.

1. In pfSense, navigate to *VPN > Tailscale > Settings > Routing*
2. Under *Advertised Routes*, add subnet (`192.168.0.0/24`) and press *Save*
3. In the Tailscale backend, click the three dots on pfSense and click *Edit route settings...*
4. Under *Subnet routes*, check the newly added subnet

You should now be able to access the LAN behind pfSense from any device on your tailnet.


### Local DNS via Split DNS

IP addresses aren't always fun to use, especially when pfSense has a nice DNS server with records for all local hosts via the DHCP reservations.
To be able to access the hosts on the internal subnet behind pfSense via their hostname we need to tell Tailscale to use pfSense's DNS server.

1. On the Tailscale backend, navigate to *DNS > Nameservers*
2. Press *Add nameserver > Custom...*
3. Under *Nameserver*
    1. Enter the internal IP address of the pfSense box (or where the internal DNS server is hosted)
    2. Enable Split DNS by checking *Restrict to domain*
    3. Enter the domain name suffix, e.g. `example.com` to be able access a host with `server.example.com` as hostname. This way only the internal records are resolved by pfSense.

It should now be possible to resolve internal hostnames from a tailnet device outside of the LAN.


## Conclusion

In this post we've set up a pfSense firewall to let external devices to both use it as an exit node for secure browsing, and also use it to access hosts on local subnets by their hostnames like they were on the same LAN.

---

{{< hackernews "https://news.ycombinator.com/item?id=43750790" >}}
