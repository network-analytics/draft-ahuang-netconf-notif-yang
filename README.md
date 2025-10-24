```shell
$ pyang ietf-yp-notification@2025-10-20.yang -f tree -p dependencies --tree-line-length=69 --tree-print-structures
$ pyang ietf-yp-observation@2025-09-11.yang -f tree -p dependencies --tree-line-length=69 --tree-print-structures
$ pyang dependencies/ietf-yang-push@2019-05-21.yang ietf-yp-observation@2025-09-11.yang -f tree -p dependencies --tree-line-length=69 --tree-print-structures --tree-depth=2
```

```shell
$ pyang example-foo-extension.yang -f tree  --yang-line-length=69 --keep-comments -p dependencies --tree-print-structures --tree-line-length=69
```


Format for Datatracker
```shell
$ pyang ietf-yp-notification@2025-09-11.yang -f yang --yang-line-length=69 -p dependencies
$ pyang ietf-yp-observation@2025-09-11.yang -f yang --yang-line-length=69 -p dependencies
$ pyang example-foo-extension.yang -f yang --yang-line-length=69 -p dependencies
```
