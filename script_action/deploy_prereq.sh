#!/bin/bash

AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
    sudo tee /etc/apt/sources.list.d/azure-cli.list

curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

sudo apt-get update
sudo apt-get -y install apt-transport-https azure-cli
sudo echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCz6eAQ1/Ai20W+8yVJlRmzmjEj4LGdhv44Z0EUIajjyvxlgWRyRgjzMn1qM9+C9ObwT8ga25TMUyuecbRCLhZ5jcsFMBbquxhqC+TcXm0kmwBIAUCb6LmE1s91h7XXdqKbUfNt6I3K2oDyrdOIaKyPa71FoE9ZKA46cHQlk+Qe0kCUS7kAt+Q/oFhplzhPvR2I7rUDoNjicOa7qhcMXRrx8sp6v4ElgErb8+ghNOIweUVk2YaTJq1d6vTb4Av8luzxS8TIrYG5m2HsrrxGuplT72DecWwleA8atjCEkAoUSZQVdzbAW4uEXkHTHfiJMj/dR8E5PW12EaaWaBNEUaj1 jenkins@vm-dev-jenkins01" >> /home/$1/.ssh/authorized_keys
