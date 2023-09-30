## if you get this error
```hostfile_replace_entries: link /home/vagrant/.ssh/known_hosts to /home/vagrant/.ssh/known_hosts.old: Operation not permitted```
```update_known_hosts: hostfile_replace_entries failed for /home/vagrant/.ssh/known_hosts: Operation not permitted```

## Then run this command into vagrant box as vagrant user.
```ssh-keyscan -H github.com >> ~/.ssh/known_hosts```
