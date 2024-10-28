# Moodle with STACK Installation Script

This script automates the installation of Moodle 4.0.4 along with the STACK question type plugin on Ubuntu Server. This is intended for **development and testing purposes only** and should not be used on production servers or systems accessible from the internet. The intended use case is to set up an instance of Moodle with STACK locally on a virtual machine. 

For more information about configuring and using these systems, refer to:
- [Moodle Documentation](https://docs.moodle.org)
- [STACK Documentation](https://docs.stack-assessment.org)


## Security Warning ⚠️

This script sets highly permissive file permissions (0777) on certain directories to ensure smooth installation and initial setup. These permissions are **not secure** and should never be used on production systems or machines accessible from the internet.

## Prerequisites

- Ubuntu Server 24.04 LTS (fresh installation)
- Port forwarding configured to map host port 1080 to guest port 80 (if running in a virtual machine)

## Installation

1. Clone this repository:
```bash
git clone https://github.com/rohan-hitchcock/moodle-stack-install-script.git
cd moodle-stack-installer
```

2. Make the script executable:
```bash
chmod +x install_moodle_stack.sh
```

3. Run the script:
```bash
sudo ./install_moodle_stack.sh
```

The script will:
- Install all necessary packages and dependencies
- Set up MySQL database
- Install Moodle 4.0.4
- Install STACK question type and its dependencies
- Configure basic settings

## After Installation

1. Access Moodle at `http://localhost:1080/moodle` (or your configured address)
2. Complete the STACK plugin installation through the web interface
3. Run the STACK health check at: Site Administration > Plugins > Question Types > STACK
4. If the STACK health check produces errors, follow the troubleshooting guide [here](https://docs.stack-assessment.org/en/Installation/Testing_installation/)
