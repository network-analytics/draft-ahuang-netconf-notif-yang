
Works on ubuntu

```shell
$ ./rfcfold.sh -s 1 -i observation-timestamp-1.json -o observation-wrapped-1.json 
$ ./rfcfold.sh -s 1 -i observation-timestamp-2.json -o observation-wrapped-2.json 
$ ./rfcfold.sh -s 1 -i push-update-initial-example.json -o wrapped.json 
$ ./rfcfold.sh -s 1 -i push-change-update_example_json_example.json -o wrapped.json 
```

Waiting for support
```bash
$ /home/vagrant/Unyte/libyang/build/yanglint -p ../yangs/dependencies ../yangs/ietf-yp-notification@2025-06-04.yang push-update-initial-example.json -f json
```
