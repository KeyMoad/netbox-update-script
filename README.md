# NetBox Update Script
## Overview
This Bash script is designed to streamline the process of updating NetBox installations. It provides options for updating to the latest version or specifying a particular version to upgrade/downgrade to.

## Usage
### Basic Usage
To update NetBox to the latest version:

```bash
./netbox-update.sh
```

### Upgrade/Downgrade to Specific Version
To upgrade or downgrade to a specific NetBox version, use the following:

```bash
./netbox-update.sh --version <version>
```
Replace <version> with the desired NetBox version.

### Help
For detailed usage and options, run:

```bash
./netbox-update.sh --help
```

or

```bash
./netbox-update.sh -h
```

### Dependencies
Before running the script, ensure that you have reviewed the [NetBox upgrade documentation](https://github.com/netbox-community/netbox/blob/develop/docs/installation/upgrading.md).

### Important Notes
* _Dependencies_: Make sure to review and update dependencies as per NetBox's requirements.
* _Housekeeping Script_: After updating, verify the existence of the NetBox housekeeping script.

### License
This script is released under the MIT License.