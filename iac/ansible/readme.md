# [Mitogen](https://github.com/mitogen-hq/mitogen) for Ansible


### download and extract mitogen-0.3.27.tar.gz

```
wget https://github.com/mitogen-hq/mitogen/releases/download/v0.3.27/mitogen-0.3.27.tar.gz
```

### modify ansible.cfg

```
[defaults]
strategy_plugins = /path/to/mitogen-0.3.27/ansible_mitogen/plugins/strategy
strategy = mitogen_linear
```